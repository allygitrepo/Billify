import 'package:billify/core/enums/stock_mode.dart';
import 'package:billify/data/models/business_model.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/product_variant_model.dart';
import 'package:billify/data/models/cart_item_model.dart';
import 'package:billify/data/models/stock_history_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data Models Serialization Unit Tests', () {
    test('ProductModel serialization and deserialization roundtrip', () {
      final product = ProductModel(
        id: '101',
        name: 'Organic Milk 1L',
        basePrice: 65.0,
        stock: 40.0,
        barcode: '8901234567890',
        category_id: 'cat_dairy',
        uom: 'Litre',
        is_weighted: false,
        hasVariants: true,
        variants: [
          ProductVariantModel(id: 'v1', name: '500ml', sku: 'SKU-500ML', price: 35.0, stock: 20.0, uom: 'ml'),
        ],
      );

      final json = product.toJson();
      expect(json['id'], equals('101'));
      expect(json['name'], equals('Organic Milk 1L'));
      expect(json['basePrice'], equals(65.0));

      final restored = ProductModel.fromJson(json);
      expect(restored.id, equals(product.id));
      expect(restored.name, equals(product.name));
      expect(restored.basePrice, equals(product.basePrice));
      expect(restored.variants.length, equals(1));
      expect(restored.variants.first.name, equals('500ml'));
    });

    test('Customer model serialization and balance checks', () {
      final customer = Customer(
        id: 12,
        businessId: '1',
        name: 'Rahul Sharma',
        phoneNumber: '9876543210',
        city: 'Bangalore',
        openingBalance: 0.0,
        remainingBalance: 1500.0,
      );

      final json = customer.toJson();
      expect(json['id'], equals(12));
      expect(json['name'], equals('Rahul Sharma'));

      final restored = Customer.fromJson(json);
      expect(restored.id, equals(12));
      expect(restored.remainingBalance, equals(1500.0));
      expect(restored.phoneNumber, equals('9876543210'));
    });

    test('BusinessModel serialization handles optional fields cleanly', () {
      final business = BusinessModel(
        id: '1',
        name: 'SuperMart',
        phone: '9988776655',
        gstin: '29AAAAA0000A1Z5',
        tax_percentage: 5.0,
        gst_percentage: 18.0,
        invoice_prefix: 'SM-',
      );

      final json = business.toJson();
      expect(json['name'], equals('SuperMart'));
      expect(json['invoice_prefix'], equals('SM-'));

      final restored = BusinessModel.fromJson(json);
      expect(restored.name, equals(business.name));
      expect(restored.gst_percentage, equals(18.0));
      expect(restored.invoice_prefix, equals('SM-'));
    });

    test('CartItemModel computes subtotal accurately', () {
      final product = ProductModel(
        id: 'p1',
        barcode: '112233',
        name: 'Basmati Rice',
        basePrice: 120.0,
        price_per_unit: 120.0,
        stock: 50.0,
        uom: 'kg',
        is_weighted: true,
      );

      final item = CartItemModel(
        product: product,
        quantity: 2.5,
      );

      expect(item.subtotal, equals(300.0)); // 2.5 * 120 = 300
    });

    test('InvoiceModel serialization with line items', () {
      final product = ProductModel(
        id: 'p1',
        barcode: '112244',
        name: 'Apples',
        basePrice: 150.0,
        stock: 30.0,
        uom: 'kg',
      );

      final business = BusinessModel(
        id: '1',
        name: 'Fresh Fruits Store',
        phone: '9876543210',
        tax_percentage: 0.0,
        gst_percentage: 5.0,
      );

      final invoice = InvoiceModel(
        id: 'INV-001',
        date: DateTime(2026, 1, 15),
        business: business,
        items: [
          CartItemModel(product: product, quantity: 2.0),
        ],
        total_amount: 300.0,
        tax_amount: 0.0,
        gst_amount: 15.0,
        final_amount: 315.0,
        staff_name: 'Cashier 1',
        paid_amount: 315.0,
        payment_mode: 'Cash',
        customer_id: 5,
        customer_name: 'Priya Patel',
      );

      final json = invoice.toJson();
      expect(json['id'], equals('INV-001'));
      expect(json['total_amount'], equals(300.0));
      expect(json['payment_mode'], equals('Cash'));

      final restored = InvoiceModel.fromJson(json);
      expect(restored.id, equals('INV-001'));
      expect(restored.items.length, equals(1));
      expect(restored.items.first.product.name, equals('Apples'));
      expect(restored.final_amount, equals(315.0));
    });

    test('StockHistoryModel serialization', () {
      final history = StockHistoryModel(
        id: 'sh_10',
        product_id: 'p1',
        variant_name: 'Apples 1kg',
        quantity_change: 50.0,
        change_type: StockMode.inMode,
        createdAt: DateTime(2026, 1, 10),
        reason: 'PURCHASE',
      );

      final json = history.toJson();
      expect(json['id'], equals('sh_10'));
      expect(json['change_type'], equals('IN'));
      expect(json['reason'], equals('PURCHASE'));

      final restored = StockHistoryModel.fromJson(json);
      expect(restored.id, equals('sh_10'));
      expect(restored.quantity_change, equals(50.0));
      expect(restored.change_type, equals(StockMode.inMode));
    });
  });
}
