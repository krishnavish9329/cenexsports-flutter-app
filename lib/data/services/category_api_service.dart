import 'dart:convert';
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
  final Dio _dio;

  CategoryApiService({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<CategoryModel>> getCategories({int page = 1, int perPage = 100}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/products/categories',
        queryParameters: {
          'consumer_key': ApiConfig.consumerKey,
          'consumer_secret': ApiConfig.consumerSecret,
          'per_page': perPage,
          'page': page,
          'hide_empty': true, // Optional: hide categories with no products
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw CategoryApiException(
          'Failed to fetch categories',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw CategoryApiException(
        e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw CategoryApiException('Unexpected error: $e');
    }
  }
}
