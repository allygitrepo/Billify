import 'package:billify_application/data/models/uom_model.dart';
import 'package:billify_application/data/repositories/uom_repository.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uomRepositoryProvider = Provider<UomRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.businessOwnerId ?? user?.email ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return UomRepository(storage, userId, businessId);
});

class UomNotifier extends Notifier<List<UomModel>> {
  @override
  List<UomModel> build() {
    final repo = ref.watch(uomRepositoryProvider);
    return repo.getUoms();
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

final uomProvider = NotifierProvider<UomNotifier, List<UomModel>>(UomNotifier.new);
