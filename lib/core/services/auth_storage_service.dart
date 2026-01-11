import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing authentication state in local storage
class AuthStorageService {
  static const String _customerIdKey = 'customer_id';
  static const String _customerDataKey = 'customer_data';
  static const String _isAuthenticatedKey = 'is_authenticated';

  /// Save customer ID
  static Future<void> saveCustomerId(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customerIdKey, customerId);
    await prefs.setBool(_isAuthenticatedKey, true);
  }

  /// Get customer ID
  static Future<int?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_customerIdKey);
  }

  /// Save customer data as JSON
  static Future<void> saveCustomerData(Map<String, dynamic> customerData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerDataKey, jsonEncode(customerData));
  }

  /// Get customer data from JSON
  static Future<Map<String, dynamic>?> getCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_customerDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  /// Clear all authentication data
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customerIdKey);
    await prefs.remove(_customerDataKey);
    await prefs.remove(_isAuthenticatedKey);
  }
}
