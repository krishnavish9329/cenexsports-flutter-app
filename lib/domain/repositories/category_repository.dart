import '../../data/models/category_model.dart';
import '../../data/services/category_api_service.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<CategoryModel>> getAllCategories();
  Future<List<CategoryModel>> getSubCategories(int parentId);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryApiService _apiService;

  CategoryRepositoryImpl({CategoryApiService? apiService})
      : _apiService = apiService ?? CategoryApiService();

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final categories = await _apiService.getCategories();
      // Already filtered for top-level categories (parent == 0) in API service
      return categories;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      return await _apiService.getAllCategories();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> getSubCategories(int parentId) async {
    try {
      return await _apiService.getSubCategories(parentId);
    } catch (e) {
      rethrow;
    }
  }
}
