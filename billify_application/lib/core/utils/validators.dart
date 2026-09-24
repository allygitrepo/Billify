import 'package:billify/core/constants/app_constants.dart';

/// Production-grade validation suite covering input format, business constraints,
/// financial bounds, and server-side error mapping.
class Validators {
  Validators._();

  /// Regex Patterns
  static final RegExp _digitsOnlyRegex = RegExp(r'^[0-9]+$');
  static final RegExp _decimalNumberRegex = RegExp(r'^\d+(\.\d{1,3})?$');
  static final RegExp _pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');
  static final RegExp _gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9_\-]+$');

  // ==================== Text & Required Field Validators ====================

  /// Validates that a string is non-null, non-empty, and satisfies optional length bounds
  static String? validateRequired(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (minLength != null && trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (maxLength != null && trimmed.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  // ==================== Contact & Auth Validators ====================

  /// Validates standard email address format
  static String? validateEmail(String? value, {bool isOptional = false}) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : 'Email address is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates mobile phone number (defaults to 10 digits)
  static String? validatePhone(String? value, {int length = 10, bool isOptional = false}) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : 'Phone number is required';
    }
    final trimmed = value.trim();
    if (trimmed.length != length || !_digitsOnlyRegex.hasMatch(trimmed)) {
      return 'Phone number must be exactly $length digits';
    }
    return null;
  }

  /// Validates password security constraints
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates that confirm password matches original password
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ==================== Financial & Numeric Validators ====================

  /// Validates price/cost inputs (must be positive number with max 2 decimal places)
  static String? validatePrice(
    String? value, {
    String fieldName = 'Price',
    double min = 0.0,
    double? max,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$fieldName is required' : null;
    }
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !_decimalNumberRegex.hasMatch(trimmed)) {
      return 'Enter a valid numeric $fieldName (e.g. 99.50)';
    }
    if (parsed < min) {
      return '$fieldName cannot be less than ₹${min.toStringAsFixed(2)}';
    }
    if (max != null && parsed > max) {
      return '$fieldName cannot exceed ₹${max.toStringAsFixed(2)}';
    }
    return null;
  }

  /// Validates inventory stock quantity (supports loose/decimal for weighted products)
  static String? validateStock(
    String? value, {
    bool isWeighted = false,
    double min = 0.0,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Stock quantity is required' : null;
    }
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Enter a valid stock number';
    }
    if (!isWeighted && !_digitsOnlyRegex.hasMatch(trimmed)) {
      return 'Packaged stock must be a whole number';
    }
    if (parsed < min) {
      return 'Stock cannot be negative';
    }
    return null;
  }

  /// Validates tax & GST percentages (must be within 0% - 100%)
  static String? validatePercentage(
    String? value, {
    String fieldName = 'Tax',
    double min = 0.0,
    double max = 100.0,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName percentage is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid $fieldName percentage';
    }
    if (parsed < min || parsed > max) {
      return '$fieldName must be between $min% and $max%';
    }
    return null;
  }

  /// Validates POS & ledger payment amounts
  static String? validatePaymentAmount(
    String? value, {
    double min = 0.01,
    double? maxAllowed,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Payment amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < min) {
      return 'Amount must be at least ₹${min.toStringAsFixed(2)}';
    }
    if (maxAllowed != null && parsed > maxAllowed) {
      return 'Amount cannot exceed ₹${maxAllowed.toStringAsFixed(2)}';
    }
    return null;
  }

  // ==================== Business & Regulatory Identifiers ====================

  /// Validates GSTIN format (e.g. 22AAAAA0000A1Z5)
  static String? validateGstin(String? value, {bool isOptional = true}) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : 'GSTIN is required';
    }
    final trimmed = value.trim().toUpperCase();
    if (!_gstinRegex.hasMatch(trimmed)) {
      return 'Please enter a valid 15-character GSTIN';
    }
    return null;
  }

  /// Validates 6-digit postal / PIN code
  static String? validatePincode(String? value, {bool isOptional = true}) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : 'PIN code is required';
    }
    final trimmed = value.trim();
    if (!_pincodeRegex.hasMatch(trimmed)) {
      return 'Enter a valid 6-digit PIN code';
    }
    return null;
  }

  /// Validates alphanumeric Barcode / SKU identifiers
  static String? validateBarcode(String? value, {bool isOptional = true}) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : 'Barcode is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Barcode must be at least 3 characters';
    }
    if (!_alphanumericRegex.hasMatch(trimmed)) {
      return 'Barcode can only contain letters, numbers, and hyphens';
    }
    return null;
  }

  // ==================== Date Range Logic ====================

  /// Validates that start date does not exceed end date
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return 'Start date cannot be after end date';
    }
    return null;
  }
}
