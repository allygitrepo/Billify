enum PermissionModule {
  dashboard('Dashboard'),
  reports('Reports'),
  analytics('Analytics & Reports'),
  products('Products Master'),
  categories('Categories Master'),
  userManagement('User Management'),
  billing('Billing / POS'),
  transactionLogs('Transaction Logs'),
  inventory('Inventory Management'),
  uom('Units of Measurement'),
  customers('Customer Management'),
  payments('Payments & Khata'),
  systemSettings('System Settings');

  final String label;
  const PermissionModule(this.label);
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
}
