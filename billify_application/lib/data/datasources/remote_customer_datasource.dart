import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/customer_model.dart';
import 'package:billify_application/data/models/ledger_model.dart';
import 'package:billify_application/data/models/payment_model.dart';

class RemoteCustomerDatasource {
  final ApiService _apiService;

  RemoteCustomerDatasource(this._apiService);

  Future<List<Customer>> getCustomers(String businessId, {String? search, int page = 1}) async {
    final response = await _apiService.get(
      ApiEndpoints.getCustomers,
      queryParameters: {
        'business_id': businessId,
        if (search != null) 'search': search,
        'page': page,
      },
    );
    final List list = response.data['data'];
    return list.map((e) => Customer.fromJson(e)).toList();
  }

  Future<List<Customer>> getCustomerDropdown() async {
    final response = await _apiService.get(ApiEndpoints.customerDropdown);
    final List list = response.data['data'];
    return list.map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await _apiService.post(
      ApiEndpoints.createCustomer,
      data: customer.toJson(),
    );
    return Customer.fromJson(response.data['data']);
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final response = await _apiService.put(
      ApiEndpoints.updateCustomer(customer.id.toString()),
      data: customer.toJson(),
    );
    return Customer.fromJson(response.data['data']);
  }

  Future<bool> deleteCustomer(int id) async {
    final response = await _apiService.delete(ApiEndpoints.deleteCustomer(id.toString()));
    return response.data['success'];
  }

  Future<CustomerLedger> getCustomerLedger(int id) async {
    final response = await _apiService.get(ApiEndpoints.getCustomerLedger(id.toString()));
    return CustomerLedger.fromJson(response.data['data']);
  }

  Future<void> bulkImport(List<Customer> customers) async {
    await _apiService.post(
      ApiEndpoints.bulkImportCustomers,
      data: {'customers': customers.map((e) => e.toJson()).toList()},
    );
  }

  // Payments
  Future<Payment> receivePayment(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.receivePayment, data: data);
    return Payment.fromJson(response.data['data']);
  }

  Future<Payment> givePayment(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.givePayment, data: data);
    return Payment.fromJson(response.data['data']);
  }

  Future<List<Payment>> getPayments({int? customerId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getPayments,
      queryParameters: {if (customerId != null) 'customerId': customerId},
    );
    final List list = response.data['data'];
    return list.map((e) => Payment.fromJson(e)).toList();
  }
}
