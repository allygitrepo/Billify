import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/core/services/sync_queue_service.dart';
import 'package:billify/core/utils/catalog_search_engine.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/product_variant_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Scalability & Offline Sync Queue Tests', () {
    late LocalStorageService storage;
    late SyncQueueService syncQueue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
      syncQueue = SyncQueueService(storage);
    });

    test('Enqueue offline tasks, persist in storage, and retrieve pending', () async {
      final task1 = await syncQueue.enqueue(
        action: 'CREATE_INVOICE',
        businessId: 'biz_1',
        payload: {'invoice_id': 'INV-100', 'total': 450.0},
      );

      final task2 = await syncQueue.enqueue(
        action: 'ADJUST_STOCK',
        businessId: 'biz_1',
        payload: {'product_id': 'p1', 'quantity': 10.0},
      );

      expect(syncQueue.pendingCount(businessId: 'biz_1'), equals(2));
      expect(syncQueue.pendingCount(businessId: 'biz_2'), equals(0));

      final pending = syncQueue.getPendingTasks(businessId: 'biz_1');
      expect(pending.length, equals(2));
      expect(pending.first.id, equals(task1.id));
      expect(pending.last.id, equals(task2.id));
    });

    test('Process queue executes handlers and cleans up completed tasks', () async {
      await syncQueue.enqueue(
        action: 'CREATE_INVOICE',
        businessId: 'biz_1',
        payload: {'invoice_id': 'INV-101', 'total': 200.0},
      );

      await syncQueue.enqueue(
        action: 'CREATE_INVOICE',
        businessId: 'biz_1',
        payload: {'invoice_id': 'INV-102', 'total': 500.0},
      );

      final processed = await syncQueue.processQueue(
        (task) async => true, // Successfully synced
        businessId: 'biz_1',
      );

      expect(processed, equals(2));
      expect(syncQueue.pendingCount(businessId: 'biz_1'), equals(0));
    });

    test('Failed tasks increment attempt counts until max retries', () async {
      final task = await syncQueue.enqueue(
        action: 'ADD_CUSTOMER',
        businessId: 'biz_1',
        payload: {'name': 'John'},
        maxAttempts: 2,
      );

      // Attempt 1: Fail
      await syncQueue.processQueue((t) async => false, businessId: 'biz_1');
      var pending = syncQueue.getPendingTasks(businessId: 'biz_1');
      expect(pending.length, equals(1));
      expect(pending.first.attempts, equals(1));

      // Attempt 2: Fail (hits maxAttempts 2)
      await syncQueue.processQueue((t) async => false, businessId: 'biz_1');
      pending = syncQueue.getPendingTasks(businessId: 'biz_1');
      expect(pending.length, equals(0)); // Dropped from active pending queue
    });
  });

  group('CatalogSearchEngine Indexing & Sub-millisecond Query Tests', () {
    late CatalogSearchEngine searchEngine;
    late List<ProductModel> catalog;

    setUp(() {
      searchEngine = CatalogSearchEngine();
      catalog = [
        ProductModel(
          id: 'p1',
          barcode: '8901030383848',
          name: 'Amul Butter 500g',
          basePrice: 275.0,
          stock: 100.0,
          category_id: 'dairy',
          uom: 'pcs',
        ),
        ProductModel(
          id: 'p2',
          barcode: '8901030383855',
          name: 'Amul Cow Milk 1L',
          basePrice: 66.0,
          stock: 50.0,
          category_id: 'dairy',
          uom: 'ltr',
          hasVariants: true,
          variants: [
            ProductVariantModel(id: 'v1', name: '500ml Pack', sku: 'AMUL-COW-500', price: 34.0, stock: 30.0, uom: 'ml'),
          ],
        ),
        ProductModel(
          id: 'p3',
          barcode: '8901234000001',
          name: 'Tata Salt 1kg',
          basePrice: 28.0,
          stock: 200.0,
          category_id: 'groceries',
          uom: 'kg',
        ),
      ];
      searchEngine.indexProducts(catalog);
    });

    test('Barcode fast lookup returns exact product immediately', () {
      final results = searchEngine.search(query: '8901030383848');
      expect(results.length, equals(1));
      expect(results.first.name, equals('Amul Butter 500g'));
    });

    test('Tokenized search finds products matching multiple keywords', () {
      final results = searchEngine.search(query: 'Amul Milk');
      expect(results.length, equals(1));
      expect(results.first.id, equals('p2'));
    });

    test('Category filter narrows search results', () {
      final results = searchEngine.search(categoryId: 'dairy');
      expect(results.length, equals(2));

      final grocResults = searchEngine.search(categoryId: 'groceries');
      expect(grocResults.length, equals(1));
      expect(grocResults.first.name, equals('Tata Salt 1kg'));
    });

    test('Variant token indexing allows finding products by variant name or SKU', () {
      final results = searchEngine.search(query: 'AMUL-COW-500');
      expect(results.length, equals(1));
      expect(results.first.name, equals('Amul Cow Milk 1L'));
    });
  });
}
