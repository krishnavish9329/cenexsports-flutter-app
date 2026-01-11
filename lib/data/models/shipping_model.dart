/// Shipping address model for WooCommerce orders
class ShippingModel {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  ShippingModel({
    required this.firstName,
    required this.lastName,
    this.company = '',
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'IN', // Default to India
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      // Company field removed from API request
    };
  }

  /// Create from JSON (for order response)
  factory ShippingModel.fromJson(Map<String, dynamic> json) {
    return ShippingModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? 'IN',
    );
  }

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get full address
  String get fullAddress {
    final parts = [
      address1,
      if (address2.isNotEmpty) address2,
      city,
      state,
      postcode,
      country,
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }
}
