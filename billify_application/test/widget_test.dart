import 'package:flutter_test/flutter_test.dart';
import 'package:billify/core/errors/app_exception.dart';
import 'package:billify/core/errors/app_failure.dart';
import 'package:billify/core/errors/result.dart';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/data/models/cart_item_model.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/providers/billing_provider.dart';
import 'package:billify/providers/state/product_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateRequired handles min and max length bounds', () {
      expect(Validators.validateRequired('John Doe', 'Name'), isNull);
      expect(Validators.validateRequired('', 'Name'), 'Name is required');
      expect(Validators.validateRequired(null, 'Name'), 'Name is required');
      expect(Validators.validateRequired('Ab', 'Name', minLength: 3), 'Name must be at least 3 characters');
      expect(Validators.validateRequired('Very long name here', 'Name', maxLength: 10), 'Name cannot exceed 10 characters');
    });

    test('validateEmail validates correctly', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(null, isOptional: true), isNull);
      expect(Validators.validateEmail('', isOptional: true), isNull);
    });

    test('validatePhone validates 10-digit phone number', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('12345'), isNotNull);
      expect(Validators.validatePhone('98765432100'), isNotNull);
      expect(Validators.validatePhone('98765abcde'), isNotNull);
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone(null, isOptional: true), isNull);
    });

    test('validatePassword validates minimum 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('validateConfirmPassword ensures passwords match', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(Validators.validateConfirmPassword('pass123', 'different'), 'Passwords do not match');
      expect(Validators.validateConfirmPassword('', 'pass123'), 'Please confirm your password');
      expect(Validators.validateConfirmPassword(null, 'pass123'), 'Please confirm your password');
    });

    test('validatePrice handles financial bounds and formatting', () {
      expect(Validators.validatePrice('199.99'), isNull);
      expect(Validators.validatePrice('0.00'), isNull);
      expect(Validators.validatePrice('-10'), isNotNull);
      expect(Validators.validatePrice('abc'), isNotNull);
      expect(Validators.validatePrice('100.9999'), isNotNull);
      expect(Validators.validatePrice('500', max: 200), isNotNull);
      expect(Validators.validatePrice(null, isRequired: false), isNull);
    });

    test('validateStock validates packaged vs weighted items', () {
      expect(Validators.validateStock('10'), isNull);
      expect(Validators.validateStock('10.5', isWeighted: true), isNull);
      expect(Validators.validateStock('10.5', isWeighted: false), 'Packaged stock must be a whole number');
      expect(Validators.validateStock('-5'), isNotNull);
      expect(Validators.validateStock('abc'), isNotNull);
      expect(Validators.validateStock(null, isRequired: false), isNull);
    });

    test('validatePercentage validates range between 0 and 100', () {
      expect(Validators.validatePercentage('18'), isNull);
      expect(Validators.validatePercentage('0'), isNull);
      expect(Validators.validatePercentage('100'), isNull);
      expect(Validators.validatePercentage('-5'), isNotNull);
      expect(Validators.validatePercentage('105'), isNotNull);
      expect(Validators.validatePercentage('abc'), isNotNull);
    });

    test('validatePaymentAmount enforces positive values', () {
      expect(Validators.validatePaymentAmount('500.00'), isNull);
      expect(Validators.validatePaymentAmount('0.01'), isNull);
      expect(Validators.validatePaymentAmount('0'), isNotNull);
      expect(Validators.validatePaymentAmount('-50'), isNotNull);
      expect(Validators.validatePaymentAmount('1000', maxAllowed: 500), isNotNull);
    });

    test('validateGstin validates Indian GSTIN format', () {
      expect(Validators.validateGstin('22AAAAA0000A1Z5'), isNull);
      expect(Validators.validateGstin('29ABCDE1234F2Z5'), isNull);
      expect(Validators.validateGstin('INVALIDGSTIN'), isNotNull);
      expect(Validators.validateGstin(null, isOptional: true), isNull);
      expect(Validators.validateGstin('', isOptional: true), isNull);
      expect(Validators.validateGstin('', isOptional: false), isNotNull);
    });

    test('validatePincode validates 6-digit postal code', () {
      expect(Validators.validatePincode('395007'), isNull);
      expect(Validators.validatePincode('110001'), isNull);
      expect(Validators.validatePincode('012345'), isNotNull); // Cannot start with 0
      expect(Validators.validatePincode('39500'), isNotNull); // 5 digits
      expect(Validators.validatePincode('3950071'), isNotNull); // 7 digits
      expect(Validators.validatePincode(null, isOptional: true), isNull);
    });

    test('validateBarcode validates alphanumeric identifiers', () {
      expect(Validators.validateBarcode('SKU-1001'), isNull);
      expect(Validators.validateBarcode('BARCODE_99'), isNull);
      expect(Validators.validateBarcode('AB'), isNotNull); // too short
      expect(Validators.validateBarcode('SKU#100'), isNotNull); // invalid special char
      expect(Validators.validateBarcode(null, isOptional: true), isNull);
    });

    test('validateDateRange ensures chronologically valid ranges', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 7));
      final past = now.subtract(const Duration(days: 7));

      expect(Validators.validateDateRange(past, future), isNull);
      expect(Validators.validateDateRange(now, now), isNull);
      expect(Validators.validateDateRange(future, past), 'Start date cannot be after end date');
      expect(Validators.validateDateRange(null, future), isNull);
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

  group('Result & AppException Unit Tests', () {
    test('Success returns data correctly', () {
      const Result<String, AppFailure> result = Success('Data Loaded');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'Data Loaded');
      expect(result.failureOrNull, isNull);
    });

    test('Failure returns AppFailure correctly', () {
      const Result<String, AppFailure> result = Failure(
        NetworkFailure(message: 'Timeout'),
      );
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull?.message, 'Timeout');
    });

    test('AppException maps status codes to appropriate failure type', () {
      const authEx = AppException(message: 'Session Expired', statusCode: 401);
      final failure = authEx.toFailure();
      expect(failure, isA<AuthFailure>());
      expect(failure.statusCode, 401);
    });
  });

  group('LocalStorageService Unit Tests', () {
    test('Handles JSON Map and List serialization cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // 1. JSON Map
      final userMap = {'id': 'user_101', 'name': 'John Merchant', 'active': true};
      await storage.setJson('user_profile', userMap);
      final retrieved = storage.getJson('user_profile');
      expect(retrieved?['id'], 'user_101');
      expect(retrieved?['active'], isTrue);

      // 2. JSON List
      final cart = [
        {'id': '1', 'qty': 2},
        {'id': '2', 'qty': 5},
      ];
      await storage.setJsonList('cart_cache', cart);
      final retrievedCart = storage.getJsonList('cart_cache');
      expect(retrievedCart?.length, 2);
      expect(retrievedCart?.first['qty'], 2);

      // 3. Clear by prefix
      await storage.setString('biz_1_product_1', 'Milk');
      await storage.setString('biz_1_product_2', 'Bread');
      await storage.setString('biz_2_product_1', 'Apples');

      final clearedCount = await storage.clearKeysWithPrefix('biz_1_');
      expect(clearedCount, 2);
      expect(storage.getString('biz_1_product_1'), isNull);
      expect(storage.getString('biz_2_product_1'), 'Apples');
    });
  });
}
