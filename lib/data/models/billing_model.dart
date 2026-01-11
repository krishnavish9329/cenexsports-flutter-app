/// Billing address model for WooCommerce orders
class BillingModel {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  BillingModel({
    required this.firstName,
    required this.lastName,
    this.company = '',
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'IN', // Default to India
    required this.email,
    required this.phone,
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
      'email': email,
      'phone': phone,
      // Company field removed from API request
    };
  }

  /// Create from JSON (for order response)
  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? 'IN',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
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
