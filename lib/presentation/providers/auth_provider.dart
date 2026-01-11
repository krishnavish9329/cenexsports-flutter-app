import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/services/customer_api_service.dart';
import '../../core/services/auth_storage_service.dart';

/// Authentication state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final CustomerModel? customer;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.customer,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    CustomerModel? customer,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      customer: customer ?? this.customer,
      error: error ?? this.error,
    );
  }
}

/// Provider for CustomerApiService
final customerApiServiceProvider = Provider<CustomerApiService>((ref) {
  return CustomerApiService();
});

/// Provider for authentication state management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(customerApiServiceProvider);
  return AuthNotifier(apiService);
});

/// StateNotifier for managing authentication
class AuthNotifier extends StateNotifier<AuthState> {
  final CustomerApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState()) {
    _loadAuthState();
  }

  /// Load authentication state from local storage
  Future<void> _loadAuthState() async {
    try {
      final isAuthenticated = await AuthStorageService.isAuthenticated();
      if (isAuthenticated) {
        // Try to load from stored customer data first
        final customerData = await AuthStorageService.getCustomerData();
        if (customerData != null) {
          try {
            final customer = CustomerModel.fromJson(customerData);
            state = state.copyWith(
              isAuthenticated: true,
              customer: customer,
            );
            return;
          } catch (e) {
            // If parsing fails, try loading by ID
          }
        }
        
        // Fallback: Load by customer ID
        final customerId = await AuthStorageService.getCustomerId();
        if (customerId != null) {
          await loadCustomer(customerId);
        }
      }
    } catch (e) {
      // Silent fail on load
      state = AuthState();
    }
  }

  /// Load customer by ID
  Future<void> loadCustomer(int customerId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final customer = await _apiService.getCustomer(customerId);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        customer: customer,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  /// Register new customer
  Future<bool> register(CustomerModel customer) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (!customer.isValidForCreation) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please fill all required fields',
        );
        return false;
      }

      // Create customer
      final createdCustomer = await _apiService.createCustomer(customer);

      if (createdCustomer.id != null) {
        // Save to local storage
        await AuthStorageService.saveCustomerId(createdCustomer.id!);
        await AuthStorageService.saveCustomerData(createdCustomer.toJson());

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          customer: createdCustomer,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create customer account',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Failed to register';
      if (e is CustomerApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Login customer by email OR phone
  Future<bool> login(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      CustomerModel? customer;
      
      // First try to get by email (more efficient)
      if (emailOrPhone.contains('@')) {
        customer = await _apiService.getCustomerByEmail(emailOrPhone);
      }
      
      // If not found by email, try loginCustomer (searches by email or phone)
      if (customer == null) {
        customer = await _apiService.loginCustomer(emailOrPhone);
      }

      if (customer != null && customer.id != null) {
        // Save to local storage
        await AuthStorageService.saveCustomerId(customer.id!);
        await AuthStorageService.saveCustomerData(customer.toJson());

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          customer: customer,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Account not found, please sign up',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Failed to login';
      if (e is CustomerApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Update customer profile
  Future<bool> updateProfile(int customerId, CustomerModel customer) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (!customer.isValidForUpdate) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please fill all required fields',
        );
        return false;
      }

      // Update customer
      final updatedCustomer = await _apiService.updateCustomer(customerId, customer);

      // Update local storage
      await AuthStorageService.saveCustomerData(updatedCustomer.toJson());

      state = state.copyWith(
        isLoading: false,
        customer: updatedCustomer,
        error: null,
      );
      return true;
    } catch (e) {
      String errorMessage = 'Failed to update profile';
      if (e is CustomerApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await AuthStorageService.clearAuth();
    state = AuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
