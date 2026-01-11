import 'dart:convert';

/// API Configuration - Centralized configuration for WooCommerce API
/// Uses environment variables for secure credential management
/// Falls back to existing API credentials if .env is not available
class ApiConfig {
  // Static configuration values - can be overridden from .env in main.dart
  static String _baseUrl = 'https://cenexsports.co.in/wp-json/wc/v3';
  static String _consumerKey = 'ck_66867a5f826ba9290cf9d476e5c4a23370538df7';
  static String _consumerSecret = 'cs_c2314e31215cf78d5d76afe285a09b34fdcee6d1';
  
  // Base URL
  static String get baseUrl => _baseUrl;
  
  // Consumer Key
  static String get consumerKey => _consumerKey;
  
  // Consumer Secret
  static String get consumerSecret => _consumerSecret;
  
  // Initialize from environment variables (called from main.dart)
  static void initialize({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
  }) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (consumerKey != null) _consumerKey = consumerKey;
    if (consumerSecret != null) _consumerSecret = consumerSecret;
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
