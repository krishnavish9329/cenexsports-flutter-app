import '../../data/models/order_model.dart';
import '../repositories/order_repository.dart';

/// Use case for placing an order
/// Contains business logic for order creation
class PlaceOrderUseCase {
  final OrderRepository _repository;

  PlaceOrderUseCase(this._repository);

  /// Execute the use case to place an order
  /// 
  /// [order] - The order to be placed
  /// Returns the created order with ID
  /// 
  /// Throws [OrderApiException] on failure
  Future<OrderModel> execute(OrderModel order) async {
    // Additional business logic validation can be added here
    // For example: stock check, payment validation, etc.

    // Validate required fields
    if (order.lineItems.isEmpty) {
      throw Exception('Order must contain at least one product');
    }

    if (order.billing.email.isEmpty || !order.billing.email.contains('@')) {
      throw Exception('Valid email address is required');
    }

    if (order.billing.phone.isEmpty) {
      throw Exception('Phone number is required');
    }

    // Call repository to place order
    return await _repository.placeOrder(order);
  }
}
