import 'billing_model.dart';
import 'shipping_model.dart';
import 'line_item_model.dart';

/// Order model for WooCommerce order creation and response
class OrderModel {
  final int? id; // Null for new orders, populated in response
  final String? status;
  final String? currency;
  final String? dateCreated;
  final String? dateModified;
  final double? total;
  final String paymentMethod;
  final String paymentMethodTitle;
  final bool setPaid;
  final BillingModel billing;
  final ShippingModel shipping;
  final List<LineItemModel> lineItems;
  final String? orderKey; // From response
  final int? customerId; // Optional
  final String? customerNote; // Optional

  OrderModel({
    this.id,
    this.status,
    this.currency,
    this.dateCreated,
    this.dateModified,
    this.total,
    required this.paymentMethod,
    required this.paymentMethodTitle,
    this.setPaid = false,
    required this.billing,
    required this.shipping,
    required this.lineItems,
    this.orderKey,
    this.customerId,
    this.customerNote,
  });

  /// Convert to JSON for API request (POST /orders)
  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': setPaid,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      if (customerId != null) 'customer_id': customerId,
      if (customerNote != null && customerNote.isNotEmpty) 'customer_note': customerNote,
    };
  }

  /// Create from JSON (for order response)
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      status: json['status'],
      currency: json['currency'],
      dateCreated: json['date_created'],
      dateModified: json['date_modified'],
      total: json['total'] != null ? double.tryParse(json['total'].toString()) : null,
      paymentMethod: json['payment_method'] ?? '',
      paymentMethodTitle: json['payment_method_title'] ?? '',
      setPaid: json['set_paid'] ?? false,
      billing: BillingModel.fromJson(json['billing'] ?? {}),
      shipping: ShippingModel.fromJson(json['shipping'] ?? {}),
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((item) => LineItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      orderKey: json['order_key'],
      customerId: json['customer_id'],
      customerNote: json['customer_note'],
    );
  }

  /// Check if order is valid for submission
  bool get isValid {
    if (lineItems.isEmpty) return false;
    if (billing.firstName.isEmpty || billing.lastName.isEmpty) return false;
    if (billing.email.isEmpty || !billing.email.contains('@')) return false;
    if (billing.phone.isEmpty) return false;
    if (billing.address1.isEmpty || billing.city.isEmpty) return false;
    if (shipping.firstName.isEmpty || shipping.lastName.isEmpty) return false;
    if (shipping.address1.isEmpty || shipping.city.isEmpty) return false;
    return true;
  }
}
