/// Strongly typed argument for ProductManagementPage
class ProductRouteArgs {
  final String? initialBarcode;

  const ProductRouteArgs({this.initialBarcode});
}

/// Strongly typed argument for AddPaymentScreen
class AddPaymentRouteArgs {
  final int customerId;

  const AddPaymentRouteArgs({required this.customerId});
}

/// Strongly typed argument for CustomerDetailScreen
class CustomerDetailRouteArgs {
  final int customerId;

  const CustomerDetailRouteArgs({required this.customerId});
}
