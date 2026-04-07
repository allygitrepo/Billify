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
