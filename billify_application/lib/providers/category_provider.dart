import 'package:billify/data/models/category_model.dart';
import 'package:billify/data/datasources/remote_category_datasource.dart';
import 'package:billify/data/repositories/category_repository.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final remoteDatasource = ref.watch(remoteCategoryDatasourceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.businessOwnerId ?? user?.email ?? user?.mobile ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return CategoryRepository(storage, remoteDatasource, userId, businessId);
});

class CategoryNotifier extends Notifier<List<CategoryModel>> {
  @override
  List<CategoryModel> build() {
    final repo = ref.watch(categoryRepositoryProvider);
    // Trigger async sync when building
    Future.microtask(() async {
      await repo.fetchAndSyncCategories();
      state = repo.getCategories();
    });
    return repo.getCategories();
  }

  Future<void> saveCategory(CategoryModel category) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.saveCategory(category);
    state = repo.getCategories();
  }

  Future<void> deleteCategory(String id) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.deleteCategory(id);
    state = repo.getCategories();
  }
}

final categoryProvider =
    NotifierProvider<CategoryNotifier, List<CategoryModel>>(
      CategoryNotifier.new,
    );
