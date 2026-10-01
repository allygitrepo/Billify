import 'package:billify/core/services/api_service.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/data/datasources/remote_customer_datasource.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/data/models/ledger_model.dart';
import 'package:billify/data/models/payment_model.dart';
import 'package:billify/data/repositories/customer_repository.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteCustomerDatasourceProvider = Provider<RemoteCustomerDatasource>((
  ref,
) {
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
    ref.watch(customerRepositoryProvider);
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

  Future<List<Customer>> fetchCustomersFromBusiness(String businessId, {String? search}) async {
    final repo = ref.read(customerRepositoryProvider);
    return await repo.fetchCustomersByBusinessId(businessId, search: search);
  }

  Future<void> importCustomersFromBusiness(List<Customer> customers) async {
    final currentBusinessId = ref.read(businessProvider).currentBusinessId ?? 'default';
    final repo = ref.read(customerRepositoryProvider);
    final mapped = customers.map((c) => Customer(
      businessId: currentBusinessId,
      name: c.name,
      phoneNumber: c.phoneNumber,
      openingBalance: 0.0,
      remainingBalance: 0.0,
      city: c.city,
      photo: c.photo,
      status: 'active',
    )).toList();
    await repo.bulkImport(mapped);
    await fetchCustomers();
  }

  Future<Customer> saveCustomer(Customer customer) async {
    final repo = ref.read(customerRepositoryProvider);
    final saved = await repo.saveCustomer(customer);
    await fetchCustomers();
    return saved;
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
    AppLogger.debug(
      'Recording Payment - ID: $customerId, Amount: $amount, isCredit: $isCredit, Note: $note',
      tag: 'CustomerNotifier',
    );
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
        AppLogger.debug('Calling givePayment (Credit)', tag: 'CustomerNotifier');
        await repo.givePayment(data);
      } else {
        AppLogger.debug('Calling receivePayment (Got)', tag: 'CustomerNotifier');
        await repo.receivePayment(data);
      }
      AppLogger.info('Payment Recorded Successfully', tag: 'CustomerNotifier');
    } catch (e, stack) {
      AppLogger.error('Error in recordPayment', tag: 'CustomerNotifier', error: e, stackTrace: stack);
      rethrow;
    }

    // Refresh both the list and the specific ledger if it's being watched
    await fetchCustomers();
    ref.invalidate(customerLedgerProvider(customerId));
  }
}

final customerProvider =
    AsyncNotifierProvider<CustomerNotifier, List<Customer>>(
      CustomerNotifier.new,
    );

// Detail / Ledger Provider
final customerLedgerProvider = FutureProvider.family<CustomerLedger, int>((
  ref,
  id,
) async {
  final repo = ref.watch(customerRepositoryProvider);
  return await repo.getCustomerLedger(id);
});

// Payments Provider
final paymentsProvider = FutureProvider.family<List<Payment>, int?>((
  ref,
  customerId,
) async {
  final repo = ref.watch(customerRepositoryProvider);
  return await repo.getPayments(customerId: customerId);
});
