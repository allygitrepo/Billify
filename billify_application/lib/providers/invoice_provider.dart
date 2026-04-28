import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/data/datasources/remote_invoice_datasource.dart';
import 'package:billify/data/repositories/invoice_repository.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final remoteDatasource = ref.watch(remoteInvoiceDatasourceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user
      ?.id; // Allow null for user_id to prevent Postgres INTEGER cast errors
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return InvoiceRepository(storage, remoteDatasource, userId, businessId);
});

final invoiceProvider =
    StateNotifierProvider<InvoiceNotifier, List<InvoiceModel>>((ref) {
      final repo = ref.watch(invoiceRepositoryProvider);
      return InvoiceNotifier(repo);
    });

class InvoiceNotifier extends StateNotifier<List<InvoiceModel>> {
  final InvoiceRepository _repo;
  bool _isDisposed = false;

  InvoiceNotifier(this._repo) : super([]) {
    loadInvoices();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadInvoices() async {
    try {
      // Sync sequentially then set state
      await _repo.fetchAndSyncInvoices();
      final invoices = await _repo.getInvoices();
      if (!_isDisposed) {
        state = invoices;
      }
    } catch (e) {
      print("Error loading invoices: $e");
    }
  }

  // Changed to return Future<InvoiceModel> so billing caller can get the updated one
  Future<InvoiceModel> addInvoice(InvoiceModel invoice) async {
    final serverInvoice = await _repo.saveInvoice(invoice);
    state = [serverInvoice, ...state];
    return serverInvoice;
  }

  Future<void> deleteInvoice(String id) async {
    await _repo.deleteInvoice(id);
    state = state.where((e) => e.id != id).toList();
  }

  double getTodaySales() {
    final now = DateTime.now();
    return state
        .where((e) {
          final localDate = e.date.toLocal();
          return localDate.year == now.year &&
              localDate.month == now.month &&
              localDate.day == now.day;
        })
        .fold(0, (sum, e) => sum + e.final_amount);
  }

  int getTodayInvoiceCount() {
    final now = DateTime.now();
    return state.where((e) {
      final localDate = e.date.toLocal();
      return localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;
    }).length;
  }

  double getMonthlyRevenue() {
    final now = DateTime.now();
    return state
        .where((e) {
          final localDate = e.date.toLocal();
          return localDate.year == now.year && localDate.month == now.month;
        })
        .fold(0, (sum, e) => sum + e.final_amount);
  }

  Map<String, double> getTopSellingProducts(int count) {
    final Map<String, double> productSales = {};
    for (var invoice in state) {
      for (var item in invoice.items) {
        productSales[item.name] =
            (productSales[item.name] ?? 0) + item.subtotal;
      }
    }

    final sortedEntries = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(count));
  }

  List<double> getWeeklySalesData() {
    final now = DateTime.now();
    final List<double> dailyTotals = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      dailyTotals[i] = state
          .where((e) {
            final localDate = e.date.toLocal();
            return localDate.year == date.year &&
                localDate.month == date.month &&
                localDate.day == date.day;
          })
          .fold(0.0, (sum, e) => sum + e.final_amount);
    }
    return dailyTotals;
  }

  List<String> getWeeklyLabels() {
    final now = DateTime.now();
    final List<String> labels = [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      labels.add(days[date.weekday - 1]);
    }
    return labels;
  }

  List<double> getMonthlySalesData() {
    final now = DateTime.now();
    final List<double> monthlyTotals = List.filled(12, 0.0);

    for (int i = 0; i < 12; i++) {
      monthlyTotals[i] = state
          .where((e) {
            final localDate = e.date.toLocal();
            return localDate.year == now.year && localDate.month == (i + 1);
          })
          .fold(0.0, (sum, e) => sum + e.final_amount);
    }
    return monthlyTotals;
  }

  List<String> getMonthlyLabels() {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
  }

  Future<InvoiceModel?> getInvoiceById(String id) async {
    // 1. Check local state first
    final local = state
        .where((e) => e.id == id || e.id.toUpperCase() == id.toUpperCase())
        .firstOrNull;
    if (local != null) return local;

    // 2. Fetch from remote
    return await _repo.getInvoiceById(id);
  }
}
