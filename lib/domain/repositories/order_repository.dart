import '../../data/models/order_model.dart';
import '../../data/services/order_api_service.dart';

/// Abstract repository interface for order operations
/// Follows Clean Architecture - Domain layer doesn't depend on data layer implementation
abstract class OrderRepository {
  /// Place a new order
  /// 
  /// [order] - The order to be placed
  /// Returns the created order with ID and status
  /// 
  /// Throws [OrderApiException] on failure
  Future<OrderModel> placeOrder(OrderModel order);
}

/// Implementation of OrderRepository
/// Uses OrderApiService to communicate with WooCommerce API
class OrderRepositoryImpl implements OrderRepository {
  final OrderApiService _apiService;

  OrderRepositoryImpl({OrderApiService? apiService})
      : _apiService = apiService ?? OrderApiService();

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    try {
      // Validate order before API call
      if (!order.isValid) {
        throw OrderApiException(
          'Order validation failed. Please check all required fields.',
          statusCode: 400,
        );
      }

      // Call API service to create order
      return await _apiService.createOrder(order);
    } catch (e) {
      // Re-throw to preserve error information
      rethrow;
    }
  }
}
