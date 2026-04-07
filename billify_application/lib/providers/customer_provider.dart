import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/remote_customer_datasource.dart';
import 'package:billify_application/data/models/customer_model.dart';
import 'package:billify_application/data/models/ledger_model.dart';
import 'package:billify_application/data/models/payment_model.dart';
import 'package:billify_application/data/repositories/customer_repository.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteCustomerDatasourceProvider = Provider<RemoteCustomerDatasource>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RemoteCustomerDatasource(apiService);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final remoteDatasource = ref.watch(remoteCustomerDatasourceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.id?.toString() ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return CustomerRepository(storage, remoteDatasource, userId, businessId);
});

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    return fetchCustomers();
  }

  Future<List<Customer>> fetchCustomers({String? search}) async {
    final repo = ref.read(customerRepositoryProvider);
    state = const AsyncLoading();
    try {
      final customers = await repo.fetchCustomers(search: search);
      state = AsyncData(customers);
      return customers;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> saveCustomer(Customer customer) async {
    final repo = ref.read(customerRepositoryProvider);
    await repo.saveCustomer(customer);
    await fetchCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    final repo = ref.read(customerRepositoryProvider);
    await repo.deleteCustomer(id);
    await fetchCustomers();
  }

  Future<void> bulkImport(List<Customer> customers) async {
    final repo = ref.read(customerRepositoryProvider);
    await repo.bulkImport(customers);
    await fetchCustomers();
  }

  Future<void> recordPayment({
    required int customerId,
    required double amount,
    required bool isCredit, // true: Gave (Credit), false: Got (Debit)
    String? note,
    DateTime? date,
    String method = 'Cash',
  }) async {
    print('DEBUG: Recording Payment - ID: $customerId, Amount: $amount, isCredit: $isCredit, Note: $note');
    final repo = ref.read(customerRepositoryProvider);
    final data = {
      'customer_id': customerId,
      'amount': amount,
      'note': note,
      'date': date?.toIso8601String(),
      'payment_method': method,
    };

    try {
      if (isCredit) {
        print('DEBUG: Calling givePayment (Credit)');
        await repo.givePayment(data);
      } else {
        print('DEBUG: Calling receivePayment (Got)');
        await repo.receivePayment(data);
      }
      print('DEBUG: Payment Recorded Successfully');
    } catch (e) {
      print('DEBUG: Error RecordPayment: $e');
      rethrow;
    }

    // Refresh both the list and the specific ledger if it's being watched
    await fetchCustomers();
    ref.invalidate(customerLedgerProvider(customerId));
  }
}

final customerProvider = AsyncNotifierProvider<CustomerNotifier, List<Customer>>(CustomerNotifier.new);

// Detail / Ledger Provider
final customerLedgerProvider = FutureProvider.family<CustomerLedger, int>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return await repo.getCustomerLedger(id);
});

// Payments Provider
final paymentsProvider = FutureProvider.family<List<Payment>, int?>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  return await repo.getPayments(customerId: customerId);
});
