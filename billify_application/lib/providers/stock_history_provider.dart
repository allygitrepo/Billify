import 'package:billify_application/data/datasources/remote_inventory_datasource.dart';
import 'package:billify_application/data/models/stock_history_model.dart';
import 'package:billify_application/data/repositories/stock_history_repository.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final stockHistoryRepositoryProvider = Provider<StockHistoryRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final remote = ref.watch(remoteInventoryDatasourceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.id?.toString() ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return StockHistoryRepository(storage, remote, userId, businessId);
});

class StockHistoryNotifier extends Notifier<List<StockHistoryModel>> {
  @override
  List<StockHistoryModel> build() {
    final repo = ref.watch(stockHistoryRepositoryProvider);
    Future.microtask(() => fetchAndSyncHistory());
    return repo.getHistory();
  }

  Future<void> fetchAndSyncHistory() async {
    final repo = ref.read(stockHistoryRepositoryProvider);
    await repo.fetchAndSyncHistory();
    state = repo.getHistory();
  }

  Future<void> addHistory(StockHistoryModel history) async {
    final repo = ref.read(stockHistoryRepositoryProvider);
    await repo.saveHistory(history);
    state = repo.getHistory();
  }
}

final stockHistoryProvider = NotifierProvider<StockHistoryNotifier, List<StockHistoryModel>>(StockHistoryNotifier.new);
