import 'package:flutter/foundation.dart';
import '../../models/product.dart';

/// Cart item model
class CartItem {
  final Product product;
  int quantity;
  
  CartItem({
    required this.product,
    this.quantity = 1,
  });
  
  double get totalPrice => product.price * quantity;
}

/// Cart state management provider
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  double get subtotal => totalAmount;
  
  double get tax => totalAmount * 0.18; // 18% GST
  
  double get discount => 0.0; // Can be calculated based on promo codes
  
  double get grandTotal => subtotal + tax - discount;
  
  bool get isEmpty => _items.isEmpty;
  
  /// Add product to cart
  void addToCart(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    
    notifyListeners();
  }
  
  /// Remove product from cart
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }
  
  /// Update quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }
  
  /// Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
  
  /// Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }
  
  /// Get quantity of a product in cart
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product(
        id: '',
        name: '',
        description: '',
        price: 0,
        originalPrice: 0,
        discount: 0,
        rating: 0,
        reviews: 0,
        imageUrl: '',
        category: '',
      )),
    );
    return item.quantity;
  }
}
