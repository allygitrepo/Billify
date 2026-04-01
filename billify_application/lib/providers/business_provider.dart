import 'package:billify_application/data/datasources/business_datasource.dart';
import 'package:billify_application/data/models/business_model.dart';
import 'package:billify_application/data/repositories/business_repository.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:billify_application/providers/state/business_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.businessOwnerId ?? user?.email ?? 'guest';
  final datasource = LocalBusinessDatasource(storage, userId);
  return BusinessRepository(datasource);
});

class BusinessNotifier extends Notifier<BusinessState> {
  @override
  BusinessState build() {
    final repo = ref.watch(businessRepositoryProvider);
    final businesses = repo.getBusinesses();
    final currentId = repo.getCurrentBusinessId();
    return BusinessState(
      businesses: businesses,
      currentBusinessId: currentId ?? (businesses.isNotEmpty ? businesses.first.id : null),
    );
  }

  Future<void> saveBusiness(BusinessModel business) async {
    final repo = ref.read(businessRepositoryProvider);
    await repo.saveBusiness(business);
    
    final businesses = repo.getBusinesses();
    state = state.copyWith(
      businesses: businesses,
      currentBusinessId: state.currentBusinessId ?? business.id,
    );
  }

  Future<void> switchBusiness(String id) async {
    final repo = ref.read(businessRepositoryProvider);
    await repo.setCurrentBusinessId(id);
    state = state.copyWith(currentBusinessId: id);
  }

  Future<void> deleteBusiness(String id) async {
    final repo = ref.read(businessRepositoryProvider);
    final remaining = state.businesses.where((b) => b.id != id).toList();
    
    // Simplistic clear for now, ideally we'd have a delete method in datasource
    await repo.clearAll();
    for (final b in remaining) {
      await repo.saveBusiness(b);
    }

    String? nextId;
    if (remaining.isNotEmpty) {
      nextId = remaining.first.id;
      await repo.setCurrentBusinessId(nextId);
    }

    state = BusinessState(
      businesses: remaining,
      currentBusinessId: nextId,
    );
  }

  Future<void> updateBusiness(BusinessModel business) async {
    final repo = ref.read(businessRepositoryProvider);
    await repo.saveBusiness(business);
    
    final businesses = repo.getBusinesses();
    state = state.copyWith(businesses: businesses);
  }

  Future<void> clearAll() async {
    final repo = ref.read(businessRepositoryProvider);
    await repo.clearAll();
    state = BusinessState();
  }
}

final businessProvider = NotifierProvider<BusinessNotifier, BusinessState>(() {
  return BusinessNotifier();
});
