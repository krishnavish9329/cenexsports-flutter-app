import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../models/order_model.dart';

/// Exception classes for order API errors
class OrderApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  OrderApiException(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'OrderApiException: $message (Status: $statusCode)';
}

/// API Service for WooCommerce Order operations
class OrderApiService {
  late final Dio _dio;

  OrderApiService() {
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

  /// Create a new order in WooCommerce
  /// 
  /// [order] - The order model containing all order details
  /// Returns the created order with ID and other response data
  /// 
  /// Throws [OrderApiException] on failure
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      // Validate order before sending
      if (!order.isValid) {
        throw OrderApiException(
          'Order validation failed. Please check all required fields.',
          statusCode: 400,
        );
      }

      // Convert order to JSON
      final orderJson = order.toJson();

      // Make POST request to WooCommerce
      final response = await _dio.post(
        '/orders',
        data: orderJson,
      );

      // Check response status
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse and return order response
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw OrderApiException(
          'Failed to create order. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors
      String errorMessage = 'Failed to create order';
      int? statusCode;

      if (e.response != null) {
        // Server responded with error
        statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        // Try to extract error message from WooCommerce response
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else if (errorData.containsKey('code')) {
            errorMessage = errorData['code'].toString();
          } else if (errorData.containsKey('data')) {
            final data = errorData['data'];
            if (data is Map && data.containsKey('message')) {
              errorMessage = data['message'].toString();
            }
          }
        }

        // Common WooCommerce error codes
        switch (statusCode) {
          case 400:
            errorMessage = 'Invalid order data. Please check your information.';
            break;
          case 401:
            errorMessage = 'Authentication failed. Please check API credentials.';
            break;
          case 404:
            errorMessage = 'Order endpoint not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Request timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      throw OrderApiException(
        errorMessage,
        statusCode: statusCode,
        error: e,
      );
    } catch (e) {
      // Handle any other exceptions
      if (e is OrderApiException) {
        rethrow;
      }
      throw OrderApiException(
        'Unexpected error: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Get orders by customer ID
  /// 
  /// [customerId] - The customer ID to fetch orders for
  /// Returns list of orders for the customer
  /// 
  /// Throws [OrderApiException] on failure
  Future<List<OrderModel>> getOrdersByCustomer(int customerId) async {
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: {'customer': customerId},
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw OrderApiException(
          'Failed to get orders. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get orders');
    } catch (e) {
      if (e is OrderApiException) rethrow;
      throw OrderApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Cancel an order
  /// 
  /// [orderId] - The ID of the order to cancel
  /// Returns the updated order model
  /// 
  /// Throws [OrderApiException] on failure
  Future<OrderModel> cancelOrder(int orderId) async {
    try {
      final response = await _dio.put(
        '/orders/$orderId',
        data: {'status': 'cancelled'},
      );

      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw OrderApiException(
          'Failed to cancel order. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to cancel order');
    } catch (e) {
      if (e is OrderApiException) rethrow;
      throw OrderApiException('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Handle DioException and convert to OrderApiException
  OrderApiException _handleDioException(DioException e, String defaultMessage) {
    String errorMessage = defaultMessage;
    int? statusCode;

    if (e.response != null) {
      statusCode = e.response!.statusCode;
      final errorData = e.response!.data;

      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        } else if (errorData.containsKey('code')) {
          errorMessage = errorData['code'].toString();
        }
      }

      switch (statusCode) {
        case 400:
          errorMessage = 'Invalid request. Please check your information.';
          break;
        case 401:
          errorMessage = 'Authentication failed. Please check API credentials.';
          break;
        case 404:
          errorMessage = 'Orders not found.';
          break;
        case 500:
          errorMessage = 'Server error. Please try again later.';
          break;
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Request timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection. Please check your network.';
    }

    return OrderApiException(
      errorMessage,
      statusCode: statusCode,
      error: e,
    );
  }
}
