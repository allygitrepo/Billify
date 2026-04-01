import 'package:billify_application/data/models/category_model.dart';
import 'package:billify_application/data/repositories/category_repository.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.businessOwnerId ?? user?.email ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return CategoryRepository(storage, userId, businessId);
});

class CategoryNotifier extends Notifier<List<CategoryModel>> {
  @override
  List<CategoryModel> build() {
    final repo = ref.watch(categoryRepositoryProvider);
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

final categoryProvider = NotifierProvider<CategoryNotifier, List<CategoryModel>>(CategoryNotifier.new);
