/// Line item model for WooCommerce order products
class LineItemModel {
  final int productId;
  final int quantity;
  final String? name; // Optional, for display purposes
  final double? price; // Optional, for display purposes

  LineItemModel({
    required this.productId,
    required this.quantity,
    this.name,
    this.price,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }

  /// Create from JSON (for order response)
  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      name: json['name'],
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
    );
  }
}
