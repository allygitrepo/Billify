import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/data/repositories/invoice_repository.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return InvoiceRepository(prefs);
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

  double getTotalCollected() {
    return state.fold(0, (sum, e) => sum + e.total);
  }

  int getInvoiceCount() {
    return state.length;
  }
}
