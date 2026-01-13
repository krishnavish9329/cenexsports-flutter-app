import '../../data/models/category_model.dart';
import '../../data/services/category_api_service.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryApiService _apiService;

  CategoryRepositoryImpl({CategoryApiService? apiService})
      : _apiService = apiService ?? CategoryApiService();

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final categories = await _apiService.getCategories();
      // Filter for top-level categories only (parent == 0)
      return categories.where((c) => c.parent == 0).toList();
    } catch (e) {
      rethrow;
    }
  }
}
