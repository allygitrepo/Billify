class ApiEndpoints {
  static const String baseUrl = "http://192.168.1.9:3000/billify";

  // Auth Endpoints
  static const String login = "$baseUrl/auth/login";
  static const String googleLogin = "$baseUrl/auth/google";
  static const String register = "$baseUrl/auth/register";
  static const String updateProfile = "$baseUrl/users/profile/update";
  static const String changePassword = "$baseUrl/users/change-password";

  // Business Endpoints
  static const String getBusinesses = "$baseUrl/businesses/my-businesses";
  static const String createBusiness = "$baseUrl/businesses";

  // Category Endpoints
  static const String categoriesBase = "$baseUrl/categories";
  static String getCategories(String businessId) =>
      "$categoriesBase/business/$businessId";
  static const String createCategory = "$categoriesBase/create";
  static String updateCategory(String id) => "$categoriesBase/update/$id";
  static String deleteCategory(String id) => "$categoriesBase/delete/$id";

  // Product Endpoints
  static const String productsBase = "$baseUrl/products";
  static String getProducts(String businessId) =>
      "$productsBase/business/$businessId";
  static const String createProduct = "$productsBase/create";
  static String updateProduct(String id) => "$productsBase/update/$id";
  static String deleteProduct(String id) => "$productsBase/delete/$id";

  // Invoice Endpoints
  static const String invoicesBase = "$baseUrl/invoices";
  static String getInvoices(String businessId) =>
      "$invoicesBase/business/$businessId";
  static const String createInvoice = "$invoicesBase/create";

  // Inventory Endpoints
  static const String inventoryBase = "$baseUrl/inventory";
  static String getInventoryLog(String businessId) =>
      "$inventoryBase/business/$businessId";
  static const String updateStock = "$inventoryBase/update-stock";

  // UOM Endpoints
  static const String uomsBase = "$baseUrl/uoms";
  static String getUoms(String businessId) => "$uomsBase/business/$businessId";
  static const String createUom = "$uomsBase/create";
  static String updateUom(String id) => "$uomsBase/update/$id";
  static String deleteUom(String id) => "$uomsBase/delete/$id";

  // Staff & User Management Endpoints
  static const String usersBase = "$baseUrl/users";
  static String getUsersByBusiness(String businessId) =>
      "$usersBase/business/$businessId";
  static const String createUser = "$usersBase/create";
  static String updateUser(String id) => "$usersBase/update/$id";
  static String deleteUser(String id) => "$usersBase/delete/$id";

  // Role Endpoints
  static const String rolesBase = "$baseUrl/roles";
  static String getRolesByBusiness(String businessId) =>
      "$rolesBase/business/$businessId";
  static const String createRole = "$rolesBase/create";
  static String updateRole(String id) => "$rolesBase/update/$id";

  // Permission Endpoints
  static const String rolePermissionsBase = "$baseUrl/role-permissions";
  static String getPermissionsByRole(String roleId) =>
      "$rolePermissionsBase/$roleId";
  static const String savePermissions = rolePermissionsBase;

  // Customer Management Endpoints
  static const String customersBase = "$baseUrl/customers";
  static const String createCustomer = customersBase;
  static const String getCustomers = customersBase;
  static const String customerDropdown = "$customersBase/dropdown";
  static const String bulkImportCustomers = "$customersBase/bulk-import";
  static String updateCustomer(String id) => "$customersBase/$id";
  static String deleteCustomer(String id) => "$customersBase/$id";
  static String getCustomerLedger(String id) => "$customersBase/ledger/$id";

  // Payment Endpoints
  static const String paymentsBase = "$baseUrl/payments";
  static const String receivePayment = "$paymentsBase/receive";
  static const String givePayment = "$paymentsBase/give";
  static const String getPayments = paymentsBase;
  static String deletePayment(String id) => "$paymentsBase/$id";

  // Analytics Endpoints
  static const String analyticsBase = "$baseUrl/analytics";
  static String getSalesSummary(String businessId) =>
      "$analyticsBase/sales/summary/$businessId";
  static String getSalesTrend(String businessId) =>
      "$analyticsBase/sales/trend/$businessId";
  static String getTopProducts(String businessId) =>
      "$analyticsBase/sales/top-products/$businessId";
  static String getCategorySales(String businessId) =>
      "$analyticsBase/sales/category-wise/$businessId";
  static String getPaymentSummary(String businessId) =>
      "$analyticsBase/sales/payment-summary/$businessId";
  static String getSalesList(String businessId) =>
      "$analyticsBase/sales/invoices/$businessId";

  // Profit Endpoints
  static String getProfitSummary(String businessId) =>
      "$analyticsBase/profit/$businessId";
  static String getProfitByProducts(String businessId) =>
      "$analyticsBase/profit/products/$businessId";
  static String getProfitByCategories(String businessId) =>
      "$analyticsBase/profit/categories/$businessId";

  // Customer Analytics Endpoints
  static String getCustomersAnalytics(String businessId) =>
      "$analyticsBase/customers/$businessId";

  // Khata Analytics Endpoints
  static String getKhataSummary(String businessId) =>
      "$analyticsBase/khata/summary/$businessId";
  static String getKhataDueReport(String businessId) =>
      "$analyticsBase/khata/due/$businessId";
  static String getKhataPayments(String businessId) =>
      "$analyticsBase/khata/payments/$businessId";
  static String getKhataCreditReport(String businessId) =>
      "$analyticsBase/khata/credit/$businessId";
  static String getKhataCustomersAnalytics(String businessId) =>
      "$analyticsBase/khata/customers/$businessId";
}
