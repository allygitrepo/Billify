class AppConstants {
  static const String appName = 'Billify';
  
  // SharedPreferences Keys
  static const String keyUserData = 'user_data';
  static const String keyBusinessData = 'business_data';
  static const String keyCurrentBusinessId = 'current_business_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyProductData = 'product_data';
  static const String keyInvoiceData = 'invoice_data';
  static const String keyStockHistory = 'stock_history';
  
  // Validation Regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  
  // Design Constants
  static const double borderRadius = 12.0;
  static const double padding = 16.0;
  static const double paddingLarge = 20.0;
}
