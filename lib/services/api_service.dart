import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://cenexsports.co.in/wp-json/wc/v3';
  static const String authToken =
      'Y2tfNjY4NjdhNWY4MjZiYTkyOTBjZjlkNDc2ZTVjNGEyMzM3MDUzOGRmNzpjc19jMjMxNGUzMTIxNWNmNzhkNWQ3NmFmZTI4NWEwOWIzNGZkY2VlNmQx';

  static Map<String, String> get headers => {
        'Authorization': 'Basic $authToken',
        'Content-Type': 'application/json',
      };

  // Get all products
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get single product by ID
  static Future<Product> getProductById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Search products
  static Future<List<Product>> searchProducts(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: {
          'search': query,
          'status': 'publish', // Ensure we only get published products
          'stock_status': 'instock', // explicit filter for available products if desired, or remove to show all
        },
      );
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Get products by category ID
  static Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: {'category': categoryId.toString()},
      );

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }
}

