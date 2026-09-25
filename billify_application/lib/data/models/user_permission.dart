enum PermissionModule {
  dashboard('Dashboard'),
  reports('Reports'),
  analytics('Analytics & Reports'),
  products('Product'),
  categories('category'),
  userManagement('staff management'),
  billing('Billing'),
  transactionLogs('Transaction Logs'),
  inventory('Inventory'),
  uom('UOM'),
  customers('customer management'),
  payments('Khata management'),
  systemSettings('System Settings'),
  businesses('Bussinesses');

  final String label;
  const PermissionModule(this.label);

  static PermissionModule? fromString(String? key) {
    if (key == null || key.isEmpty) return null;
    final clean = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final module in PermissionModule.values) {
      final moduleNameClean =
          module.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final moduleLabelClean =
          module.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (moduleNameClean == clean || moduleLabelClean == clean) {
        return module;
      }
    }
    // Check aliases
    switch (clean) {
      case 'productsmaster':
      case 'productmaster':
      case 'product':
      case 'products':
        return PermissionModule.products;
      case 'categoriesmaster':
      case 'categorymaster':
      case 'category':
      case 'categories':
        return PermissionModule.categories;
      case 'staff':
      case 'staffmanagement':
      case 'usermanagement':
      case 'users':
      case 'user':
        return PermissionModule.userManagement;
      case 'pos':
      case 'billingpos':
      case 'billing':
      case 'invoice':
      case 'invoices':
        return PermissionModule.billing;
      case 'inventorymanagement':
      case 'inventory':
      case 'stock':
        return PermissionModule.inventory;
      case 'unitsofmeasurement':
      case 'units':
      case 'uom':
        return PermissionModule.uom;
      case 'customermanagement':
      case 'customer':
      case 'customers':
        return PermissionModule.customers;
      case 'khatamanagement':
      case 'khata':
      case 'payments':
      case 'payment':
        return PermissionModule.payments;
      case 'analyticsreports':
      case 'analytics':
        return PermissionModule.analytics;
      case 'reports':
        return PermissionModule.reports;
      case 'dashboard':
        return PermissionModule.dashboard;
      case 'transactionlogs':
      case 'transactions':
      case 'logs':
        return PermissionModule.transactionLogs;
      case 'systemsettings':
      case 'settings':
        return PermissionModule.systemSettings;
      case 'bussinesses':
      case 'businesses':
      case 'business':
        return PermissionModule.businesses;
      default:
        return null;
    }
  }
}

enum PermissionAction {
  add('Add'),
  view('View'),
  update('Update'),
  delete('Delete'),
  export('Export'),
  bulkUpload('Bulk Upload'),
  download('Download'),
  print('Print'),
  all('All');

  final String label;
  const PermissionAction(this.label);

  static PermissionAction? fromString(String? key) {
    if (key == null || key.isEmpty) return null;
    final clean = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final action in PermissionAction.values) {
      final actionNameClean =
          action.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final actionLabelClean =
          action.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (actionNameClean == clean || actionLabelClean == clean) {
        return action;
      }
    }
    switch (clean) {
      case 'create':
      case 'add':
      case 'canadd':
        return PermissionAction.add;
      case 'read':
      case 'view':
      case 'canview':
        return PermissionAction.view;
      case 'edit':
      case 'update':
      case 'canupdate':
        return PermissionAction.update;
      case 'remove':
      case 'delete':
      case 'candelete':
        return PermissionAction.delete;
      case 'export':
      case 'canexport':
        return PermissionAction.export;
      case 'import':
      case 'bulkupload':
      case 'canbulkupload':
        return PermissionAction.bulkUpload;
      case 'download':
      case 'candownload':
        return PermissionAction.download;
      case 'print':
      case 'canprint':
        return PermissionAction.print;
      case 'all':
      case 'canall':
        return PermissionAction.all;
      default:
        return null;
    }
  }
}
