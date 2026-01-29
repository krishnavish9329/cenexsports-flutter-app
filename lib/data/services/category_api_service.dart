import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/category_model.dart';

class CategoryApiException implements Exception {
  final String message;
  final int? statusCode;

  CategoryApiException(this.message, {this.statusCode});

  @override
  String toString() => 'CategoryApiException: $message (Status: $statusCode)';
}

class CategoryApiService {
  CategoryApiService();

  /// Get all top-level categories (parent == 0)
  /// Set hideEmpty to false to show all categories including empty ones
  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int perPage = 100,
    bool hideEmpty = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'per_page': '$perPage',
        'page': '$page',
      };

      if (hideEmpty) {
        queryParams['hide_empty'] = 'true';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/products/categories')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final all = data
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
        // Filter only top‑level categories (parent == 0)
        return all.where((c) => c.parent == 0).toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch categories. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CategoryApiException) rethrow;
      throw CategoryApiException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get all categories (without parent filter)
  Future<List<CategoryModel>> getAllCategories({
    int page = 1,
    int perPage = 100,
    bool hideEmpty = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'per_page': '$perPage',
        'page': '$page',
      };

      if (hideEmpty) {
        queryParams['hide_empty'] = 'true';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/products/categories')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch all categories. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CategoryApiException) rethrow;
      throw CategoryApiException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get subcategories by parent ID
  /// Set hideEmpty to false to show all subcategories including empty ones
  Future<List<CategoryModel>> getSubCategories(int parentId, {bool hideEmpty = false}) async {
    try {
      final queryParams = <String, String>{
        'parent': '$parentId',
        'per_page': '100',
      };

      if (hideEmpty) {
        queryParams['hide_empty'] = 'true';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/products/categories')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch subcategories. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CategoryApiException) rethrow;
      throw CategoryApiException('Unexpected error: ${e.toString()}');
    }
  }
}
