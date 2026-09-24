import 'package:flutter_test/flutter_test.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/providers/billing_provider.dart';
import 'package:billify/providers/state/product_state.dart';
import 'package:billify/data/models/cart_item_model.dart';
import 'package:billify/data/models/product_model.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail validates correctly', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('validatePhone validates 10-digit phone number', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('12345'), isNotNull);
      expect(Validators.validatePhone('98765432100'), isNotNull);
      expect(Validators.validatePhone('98765abcde'), isNotNull);
      expect(Validators.validatePhone(null), isNotNull);
    });

    test('validatePassword validates minimum 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });
  });

  group('BillingState Calculations Unit Tests', () {
    test('Calculates subtotal and tax percentages correctly', () {
      final p1 = ProductModel(
        id: '1',
        name: 'Item A',
        basePrice: 100.0,
        stock: 10,
        category_id: '1',
        uom: 'PCS',
        barcode: '111',
      );
      final p2 = ProductModel(
        id: '2',
        name: 'Item B',
        basePrice: 50.0,
        stock: 5,
        category_id: '1',
        uom: 'PCS',
        barcode: '222',
      );

      final state = BillingState(
        items: [
          CartItemModel(product: p1, quantity: 2), // 200.0
          CartItemModel(product: p2, quantity: 1), // 50.0
        ],
      );

      expect(state.subtotal, 250.0);
      expect(state.calculateTax(5.0), 12.5); // 5% of 250
      expect(state.getTotal(5.0, 18.0), 250.0 + 12.5 + 45.0); // Subtotal + 5% + 18% = 307.5
    });
  });

  group('ProductState Unit Tests', () {
    test('filteredProducts correctly applies search query and category filters', () {
      final p1 = ProductModel(
        id: '1',
        name: 'Organic Milk',
        basePrice: 50.0,
        stock: 20,
        category_id: 'dairy_cat',
        uom: 'LITRE',
        barcode: '1001',
      );
      final p2 = ProductModel(
        id: '2',
        name: 'Whole Wheat Bread',
        basePrice: 40.0,
        stock: 0,
        category_id: 'bakery_cat',
        uom: 'PCS',
        barcode: '1002',
      );

      final state = ProductState(
        products: [p1, p2],
        searchQuery: 'milk',
      );

      expect(state.filteredProducts.length, 1);
      expect(state.filteredProducts.first.name, 'Organic Milk');
      expect(state.inStockCount, 1);
      expect(state.outOfStockCount, 1);
    });
  });
}
