import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv';

/// API Configuration - Centralized configuration for WooCommerce API
/// Uses environment variables for secure credential management
class ApiConfig {
  // Base URL
  static String get baseUrl {
    return dotenv.env['WOOCOMMERCE_BASE_URL'] ?? 
           'https://cenexsports.co.in/wp-json/wc/v3';
  }
  
  // Consumer Key
  static String get consumerKey {
    return dotenv.env['WOOCOMMERCE_CONSUMER_KEY'] ?? '';
  }
  
  // Consumer Secret
  static String get consumerSecret {
    return dotenv.env['WOOCOMMERCE_CONSUMER_SECRET'] ?? '';
  }
  
  // Generate Basic Auth token
  static String get authToken {
    final credentials = '$consumerKey:$consumerSecret';
    final bytes = utf8.encode(credentials);
    final base64Str = base64.encode(bytes);
    return base64Str;
  }
  
  // Headers for API requests
  static Map<String, String> get headers => {
    'Authorization': 'Basic $authToken',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
