import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../models/customer_model.dart';

/// Exception classes for customer API errors
class CustomerApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  CustomerApiException(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'CustomerApiException: $message (Status: $statusCode)';
}

/// API Service for WooCommerce Customer operations
class CustomerApiService {
  late final Dio _dio;

  CustomerApiService() {
    _dio = Dio(
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

  /// Get all customers (for search/login)
  /// 
  /// Returns list of all customers
  /// 
  /// Throws [CustomerApiException] on failure
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final response = await _dio.get('/customers');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw CustomerApiException(
          'Failed to get customers. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get customers');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Login customer by email OR phone
  /// 
  /// [emailOrPhone] - Email address or phone number
  /// Returns customer if found, null otherwise
  /// 
  /// Throws [CustomerApiException] on failure
  Future<CustomerModel?> loginCustomer(String emailOrPhone) async {
    try {
      // Get all customers
      final customers = await getAllCustomers();

      // Search for customer by email or phone
      for (final customer in customers) {
        // Check email
        if (customer.email != null && 
            customer.email!.toLowerCase() == emailOrPhone.toLowerCase()) {
          return customer;
        }
        
        // Check phone in billing
        if (customer.billing != null && 
            customer.billing!.phone.isNotEmpty &&
            customer.billing!.phone.replaceAll(RegExp(r'[^\d]'), '') == 
            emailOrPhone.replaceAll(RegExp(r'[^\d]'), '')) {
          return customer;
        }
      }

      // Customer not found
      return null;
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Get customer by ID
  /// 
  /// [customerId] - The customer ID
  /// Returns the customer data
  /// 
  /// Throws [CustomerApiException] on failure
  Future<CustomerModel> getCustomer(int customerId) async {
    try {
      final response = await _dio.get('/customers/$customerId');

      if (response.statusCode == 200) {
        return CustomerModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw CustomerApiException(
          'Failed to get customer. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get customer');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Get customer by email
  /// 
  /// [email] - The customer email address
  /// Returns the customer if found, null otherwise
  /// 
  /// Throws [CustomerApiException] on failure
  Future<CustomerModel?> getCustomerByEmail(String email) async {
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw CustomerApiException(
          'Invalid email format',
          statusCode: 400,
        );
      }

      final response = await _dio.get(
        '/customers',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        if (data.isEmpty) {
          return null; // Customer not found
        }
        // Return first matching customer
        return CustomerModel.fromJson(data[0] as Map<String, dynamic>);
      } else {
        throw CustomerApiException(
          'Failed to get customer by email. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // If 404, customer doesn't exist - return null
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioException(e, 'Failed to get customer by email');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Create a new customer
  /// 
  /// [customer] - The customer model containing all customer details
  /// Returns the created customer with ID and other response data
  /// 
  /// Throws [CustomerApiException] on failure
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      // Validate customer before sending
      if (!customer.isValidForCreation) {
        throw CustomerApiException(
          'Customer validation failed. Please check all required fields.',
          statusCode: 400,
        );
      }

      // Convert customer to JSON
      final customerJson = customer.toJson();
      
      // Debug: Print the JSON being sent (matching cURL structure)
      print('🔵 Creating customer with JSON:');
      print('Email: ${customerJson['email']}');
      print('Username: ${customerJson['username']}');
      print('Password: ${customerJson['password'] != null ? '***' : 'null'}');
      print('First Name: ${customerJson['first_name']}');
      print('Last Name: ${customerJson['last_name']}');
      print('Full JSON: $customerJson');

      // Make POST request to WooCommerce
      final response = await _dio.post(
        '/customers',
        data: customerJson,
      );

      // Check response status
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse and return customer response
        return CustomerModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw CustomerApiException(
          'Failed to create customer. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to create customer');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Update an existing customer
  /// 
  /// [customerId] - The customer ID to update
  /// [customer] - The customer model with updated data
  /// Returns the updated customer data
  /// 
  /// Throws [CustomerApiException] on failure
  Future<CustomerModel> updateCustomer(int customerId, CustomerModel customer) async {
    try {
      // Validate customer before sending
      if (!customer.isValidForUpdate) {
        throw CustomerApiException(
          'Customer validation failed. Please check all required fields.',
          statusCode: 400,
        );
      }

      // Convert customer to JSON (update format)
      final customerJson = customer.toUpdateJson();
      
      // Debug: Print the JSON being sent
      print('Updating customer with JSON: $customerJson');

      // Make PUT request to WooCommerce
      final response = await _dio.put(
        '/customers/$customerId',
        data: customerJson,
      );

      // Check response status
      if (response.statusCode == 200) {
        // Parse and return customer response
        return CustomerModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw CustomerApiException(
          'Failed to update customer. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to update customer');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Update customer with billing and shipping addresses
  /// 
  /// [customerId] - The customer ID to update
  /// [customer] - The customer model with billing/shipping data
  /// Returns the updated customer data
  /// 
  /// Throws [CustomerApiException] on failure
  Future<CustomerModel> updateCustomerWithBilling(int customerId, CustomerModel customer) async {
    try {
      // Validate customer before sending
      if (!customer.isValidForUpdate) {
        throw CustomerApiException(
          'Customer validation failed. Please check all required fields.',
          statusCode: 400,
        );
      }

      // Convert customer to JSON (with billing/shipping)
      final customerJson = customer.toUpdateJsonWithBilling();
      
      // Debug: Print the JSON being sent
      print('Updating customer with billing/shipping JSON: $customerJson');

      // Make PUT request to WooCommerce
      final response = await _dio.put(
        '/customers/$customerId',
        data: customerJson,
      );

      // Check response status
      if (response.statusCode == 200) {
        // Parse and return customer response
        return CustomerModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw CustomerApiException(
          'Failed to update customer. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to update customer');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Handle DioException and convert to CustomerApiException
  CustomerApiException _handleDioException(DioException e, String defaultMessage) {
    String errorMessage = defaultMessage;
    int? statusCode;

    if (e.response != null) {
      // Server responded with error
      statusCode = e.response!.statusCode;
      final errorData = e.response!.data;

      // Try to extract error message from WooCommerce response
      if (errorData is Map<String, dynamic>) {
        // Print full error for debugging
        print('🔴 WooCommerce API Error Response:');
        print('Status Code: $statusCode');
        print('Full Error Data: $errorData');
        
        // WooCommerce error structure: 
        // {code: "...", message: "...", data: {status: 400, params: {...}}}
        
        // First try to get message from top level
        if (errorData.containsKey('message') && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
          print('📝 Error Message: $errorMessage');
        }
        
        // Extract detailed validation errors from data.params (most important)
        if (errorData.containsKey('data')) {
          final data = errorData['data'];
          if (data is Map<String, dynamic>) {
            // Check for message in data
            if (data.containsKey('message') && data['message'] != null) {
              errorMessage = data['message'].toString();
              print('📝 Data Message: $errorMessage');
            }
            
            // WooCommerce validation errors in params (field-level errors)
            if (data.containsKey('params')) {
              final params = data['params'];
              print('📋 Validation Params: $params');
              
              if (params is Map<String, dynamic>) {
                final errors = <String>[];
                params.forEach((key, value) {
                  if (value is List && value.isNotEmpty) {
                    errors.add('$key: ${value.join(", ")}');
                  } else if (value is String && value.isNotEmpty) {
                    errors.add('$key: $value');
                  } else if (value != null) {
                    errors.add('$key: ${value.toString()}');
                  }
                });
                if (errors.isNotEmpty) {
                  errorMessage = errors.join('\n');
                  print('✅ Extracted Errors: $errorMessage');
                }
              }
            }
          }
        }
        
        // Fallback to code if no message found
        if (errorMessage == defaultMessage && errorData.containsKey('code')) {
          errorMessage = errorData['code'].toString();
          print('📝 Error Code: $errorMessage');
        }
        
        // Last resort: use full error data
        if (errorMessage == defaultMessage && errorData.isNotEmpty) {
          errorMessage = 'API Error: ${errorData.toString()}';
          print('⚠️ Using full error data');
        }
      } else if (errorData != null) {
        // If errorData is not a Map, convert to string
        errorMessage = 'API Error: ${errorData.toString()}';
        print('⚠️ Non-Map Error Data: $errorMessage');
      }

      // Common WooCommerce error codes (only if no specific message found)
      if (errorMessage == defaultMessage) {
        switch (statusCode) {
          case 400:
            errorMessage = 'Invalid customer data. Please check your information.';
            break;
          case 401:
            errorMessage = 'Authentication failed. Please check API credentials.';
            break;
          case 404:
            errorMessage = 'Customer not found.';
            break;
          case 409:
            errorMessage = 'Customer with this email already exists.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Request timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection. Please check your network.';
    }

    return CustomerApiException(
      errorMessage,
      statusCode: statusCode,
      error: e,
    );
  }
}
