import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'cache_service.dart';

class ApiService {
  static const String baseUrl = 'https://cenexsports.co.in/wp-json/wc/v3';
  static const String authToken =
      'Y2tfNjY4NjdhNWY4MjZiYTkyOTBjZjlkNDc2ZTVjNGEyMzM3MDUzOGRmNzpjc19jMjMxNGUzMTIxNWNmNzhkNWQ3NmFmZTI4NWEwOWIzNGZkY2VlNmQx';
  static final CacheService _cache = CacheService();

  static Map<String, String> get headers => {
        'Authorization': 'Basic $authToken',
        'Content-Type': 'application/json',
      };

  // Get all products with caching
  static Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cache.hasCachedProducts()) {
      return _cache.getCachedProducts()!;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        
        // Cache the products (only updates if data changed)
        _cache.cacheProducts(products, forceUpdate: forceRefresh);
        
        return products;
      } else {
        // If API fails, try to return cached data
        if (_cache.hasCachedProducts()) {
          return _cache.getCachedProducts()!;
        }
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      // If network error, try to return cached data
      if (_cache.hasCachedProducts()) {
        return _cache.getCachedProducts()!;
      }
      throw Exception('Error fetching products: $e');
    }
  }

  // Get single product by ID with caching
  static Future<Product> getProductById(int id, {bool forceRefresh = false}) async {
    // Return cached data if available
    if (!forceRefresh) {
      final cached = _cache.getCachedProductDetail(id);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final product = Product.fromJson(data);
        
        // Cache the product
        _cache.cacheProductDetail(id, product);
        
        return product;
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Search products with caching
  static Future<List<Product>> searchProducts(String query, {bool forceRefresh = false}) async {
    // Return cached search results if available
    if (!forceRefresh && query.trim().isNotEmpty) {
      final cached = _cache.getCachedSearchResults(query);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: {
          'search': query,
          'status': 'publish',
          'stock_status': 'instock',
        },
      );
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        
        // Cache search results
        if (query.trim().isNotEmpty) {
          _cache.cacheSearchResults(query, products);
        }
        
        return products;
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Get products by category ID with caching
  static Future<List<Product>> getProductsByCategory(int categoryId, {bool forceRefresh = false}) async {
    // Return cached category products if available
    if (!forceRefresh) {
      final cached = _cache.getCachedCategoryProducts(categoryId);
      if (cached != null) {
        return cached;
      }
    }

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
        final products = data.map((json) => Product.fromJson(json)).toList();
        
        // Cache category products
        _cache.cacheCategoryProducts(categoryId, products);
        
        return products;
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }
}

