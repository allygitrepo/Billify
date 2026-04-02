import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/data/repositories/invoice_repository.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.businessOwnerId ?? user?.email ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return InvoiceRepository(storage, userId, businessId);
});

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, List<InvoiceModel>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return InvoiceNotifier(repo);
});

class InvoiceNotifier extends StateNotifier<List<InvoiceModel>> {
  final InvoiceRepository _repo;

  InvoiceNotifier(this._repo) : super([]) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = await _repo.getInvoices();
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _repo.saveInvoice(invoice);
    state = [invoice, ...state];
  }

  Future<void> deleteInvoice(String id) async {
    await _repo.deleteInvoice(id);
    state = state.where((e) => e.id != id).toList();
  }

  double getTodaySales() {
    final now = DateTime.now();
    return state
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold(0, (sum, e) => sum + e.final_amount);
  }

  int getTodayInvoiceCount() {
    final now = DateTime.now();
    return state.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).length;
  }

  double getMonthlyRevenue() {
    final now = DateTime.now();
    return state.where((e) => e.date.year == now.year && e.date.month == now.month).fold(0, (sum, e) => sum + e.final_amount);
  }

  Map<String, double> getTopSellingProducts(int count) {
    final Map<String, double> productSales = {};
    for (var invoice in state) {
      for (var item in invoice.items) {
        productSales[item.name] = (productSales[item.name] ?? 0) + item.subtotal;
      }
    }
    
    final sortedEntries = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(count));
  }

  List<double> getWeeklySalesData() {
    final now = DateTime.now();
    final List<double> dailyTotals = List.filled(7, 0.0);
    
    for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        dailyTotals[i] = state
            .where((e) => e.date.year == date.year && e.date.month == date.month && e.date.day == date.day)
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
            .where((e) => e.date.year == now.year && e.date.month == (i + 1))
            .fold(0.0, (sum, e) => sum + e.final_amount);
    }
    return monthlyTotals;
  }

  List<String> getMonthlyLabels() {
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  }
}
