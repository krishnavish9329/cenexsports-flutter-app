import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_api_service.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/place_order_usecase.dart';

/// Order state for Riverpod
class OrderState {
  final bool isLoading;
  final OrderModel? order;
  final String? error;
  final bool isSuccess;

  OrderState({
    this.isLoading = false,
    this.order,
    this.error,
    this.isSuccess = false,
  });

  OrderState copyWith({
    bool? isLoading,
    OrderModel? order,
    String? error,
    bool? isSuccess,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      order: order ?? this.order,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Provider for OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl();
});

/// Provider for PlaceOrderUseCase
final placeOrderUseCaseProvider = Provider<PlaceOrderUseCase>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return PlaceOrderUseCase(repository);
});

/// Provider for order state management
final orderStateProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final useCase = ref.watch(placeOrderUseCaseProvider);
  return OrderNotifier(useCase);
});

/// StateNotifier for managing order state
class OrderNotifier extends StateNotifier<OrderState> {
  final PlaceOrderUseCase _useCase;
  bool _isSubmitting = false; // Prevent duplicate submissions

  OrderNotifier(this._useCase) : super(OrderState());

  /// Place an order
  /// 
  /// [order] - The order to be placed
  /// Returns true if successful, false otherwise
  Future<bool> placeOrder(OrderModel order) async {
    // Prevent duplicate submissions
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
    );

    try {
      // Validate order
      if (!order.isValid) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please fill all required fields',
          isSuccess: false,
        );
        _isSubmitting = false;
        return false;
      }

      // Execute use case
      final createdOrder = await _useCase.execute(order);

      state = state.copyWith(
        isLoading: false,
        order: createdOrder,
        isSuccess: true,
        error: null,
      );

      _isSubmitting = false;
      return true;
    } catch (e) {
      String errorMessage = 'Failed to place order';
      
      if (e is OrderApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isSuccess: false,
      );

      _isSubmitting = false;
      return false;
    }
  }

  /// Reset order state
  void reset() {
    state = OrderState();
    _isSubmitting = false;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
