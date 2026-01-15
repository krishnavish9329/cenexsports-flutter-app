import 'package:dio/dio.dart';
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
  late final Dio _dio;

  CategoryApiService({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            headers: ApiConfig.headers,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Get all top-level categories (parent == 0)
  /// Set hideEmpty to false to show all categories including empty ones
  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int perPage = 100,
    int? parent,
    bool hideEmpty = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };
      
      // Only add parent filter if specified (default to 0 for top-level)
      if (parent != null) {
        queryParams['parent'] = parent;
      } else {
        queryParams['parent'] = 0; // Default to top-level categories
      }
      
      // Only hide empty if explicitly set to true
      if (hideEmpty) {
        queryParams['hide_empty'] = true;
      }
      
      final response = await _dio.get(
        '/products/categories',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch categories. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw CategoryApiException(
        e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
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
      final queryParams = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };
      
      // Only hide empty if explicitly set to true
      if (hideEmpty) {
        queryParams['hide_empty'] = true;
      }
      
      final response = await _dio.get(
        '/products/categories',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch all categories. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw CategoryApiException(
        e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is CategoryApiException) rethrow;
      throw CategoryApiException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get subcategories by parent ID
  /// Set hideEmpty to false to show all subcategories including empty ones
  Future<List<CategoryModel>> getSubCategories(int parentId, {bool hideEmpty = false}) async {
    try {
      final queryParams = <String, dynamic>{
        'parent': parentId,
        'per_page': 100,
      };
      
      // Only hide empty if explicitly set to true
      if (hideEmpty) {
        queryParams['hide_empty'] = true;
      }
      
      final response = await _dio.get(
        '/products/categories',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch subcategories. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw CategoryApiException(
        e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is CategoryApiException) rethrow;
      throw CategoryApiException('Unexpected error: ${e.toString()}');
    }
  }
}
