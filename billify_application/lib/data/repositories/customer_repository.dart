import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/remote_customer_datasource.dart';
import 'package:billify_application/data/models/customer_model.dart';
import 'package:billify_application/data/models/ledger_model.dart';
import 'package:billify_application/data/models/payment_model.dart';

class CustomerRepository {
  final LocalStorageService _storage;
  final RemoteCustomerDatasource _remoteDatasource;
  final String _userId;
  final String _businessId;

  CustomerRepository(this._storage, this._remoteDatasource, this._userId, this._businessId);

  String get _customerDataKey => AppConstants.businessKey(_userId, _businessId, 'customer_data');

  Future<List<Customer>> fetchCustomers({String? search, int page = 1}) async {
    try {
      final remoteCustomers = await _remoteDatasource.getCustomers(_businessId, search: search, page: page);
      if (search == null && page == 1) {
        await _storage.setString(
          _customerDataKey,
          jsonEncode(remoteCustomers.map((e) => e.toJson()).toList()),
        );
      }
      return remoteCustomers;
    } catch (e) {
      print("Error fetching customers: $e");
      if (search == null && page == 1) {
        return getLocalCustomers();
      }
      rethrow;
    }
  }

  List<Customer> getLocalCustomers() {
    final data = _storage.getString(_customerDataKey);
    if (data == null) return [];
    final List list = jsonDecode(data);
    return list.map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> saveCustomer(Customer customer) async {
    Customer savedCustomer;
    if (customer.id == null) {
      savedCustomer = await _remoteDatasource.createCustomer(customer);
    } else {
      savedCustomer = await _remoteDatasource.updateCustomer(customer);
    }
    return savedCustomer;
  }

  Future<bool> deleteCustomer(int id) async {
    return await _remoteDatasource.deleteCustomer(id);
  }

  Future<CustomerLedger> getCustomerLedger(int id) async {
    return await _remoteDatasource.getCustomerLedger(id);
  }

  Future<void> bulkImport(List<Customer> customers) async {
    await _remoteDatasource.bulkImport(customers);
  }

  Future<Payment> receivePayment(Map<String, dynamic> data) async {
    return await _remoteDatasource.receivePayment(data);
  }

  Future<Payment> givePayment(Map<String, dynamic> data) async {
    return await _remoteDatasource.givePayment(data);
  }

  Future<List<Payment>> getPayments({int? customerId}) async {
    return await _remoteDatasource.getPayments(customerId: customerId);
  }
}
