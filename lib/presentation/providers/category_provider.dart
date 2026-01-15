import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

// Provider for the CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  // You might want to use a provider for ApiService if it needs dependencies
  return CategoryRepositoryImpl();
});

// FutureProvider to fetch categories
// This automatically handles loading/error/data states
final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});

// Provider to fetch all categories (including subcategories)
final allCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

// Provider to fetch subcategories by parent ID
final subCategoriesProvider = FutureProvider.autoDispose.family<List<CategoryModel>, int>((ref, parentId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getSubCategories(parentId);
});