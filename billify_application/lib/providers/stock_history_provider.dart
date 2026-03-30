import 'package:billify_application/data/models/stock_history_model.dart';
import 'package:billify_application/data/repositories/stock_history_repository.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final stockHistoryRepositoryProvider = Provider<StockHistoryRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return StockHistoryRepository(storage);
});

class StockHistoryNotifier extends Notifier<List<StockHistoryModel>> {
  @override
  List<StockHistoryModel> build() {
    final repo = ref.read(stockHistoryRepositoryProvider);
    return repo.getHistory();
  }

  Future<void> addHistory(StockHistoryModel history) async {
    final repo = ref.read(stockHistoryRepositoryProvider);
    await repo.saveHistory(history);
    state = repo.getHistory();
  }
}

final stockHistoryProvider = NotifierProvider<StockHistoryNotifier, List<StockHistoryModel>>(StockHistoryNotifier.new);
