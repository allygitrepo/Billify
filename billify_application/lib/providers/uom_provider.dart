import 'package:billify/data/datasources/remote_uom_datasource.dart';
import 'package:billify/data/models/uom_model.dart';
import 'package:billify/data/repositories/uom_repository.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uomRepositoryProvider = Provider<UomRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final remote = ref.watch(remoteUomDatasourceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.id?.toString() ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return UomRepository(storage, remote, userId, businessId);
});

class UomNotifier extends Notifier<List<UomModel>> {
  @override
  List<UomModel> build() {
    final repo = ref.watch(uomRepositoryProvider);
    // Trigger async sync when building
    Future.microtask(() => fetchAndSyncUoms());
    return repo.getUoms();
  }

  Future<void> fetchAndSyncUoms() async {
    final repo = ref.read(uomRepositoryProvider);
    await repo.fetchAndSyncUoms();
    state = repo.getUoms();
  }

  Future<void> saveUom(UomModel uom) async {
    final repo = ref.read(uomRepositoryProvider);
    await repo.saveUom(uom);
    state = repo.getUoms();
  }

  Future<void> deleteUom(String id) async {
    final repo = ref.read(uomRepositoryProvider);
    await repo.deleteUom(id);
    state = repo.getUoms();
  }
}

final uomProvider = NotifierProvider<UomNotifier, List<UomModel>>(
  UomNotifier.new,
);
