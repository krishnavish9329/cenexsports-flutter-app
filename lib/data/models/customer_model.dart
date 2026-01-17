import 'billing_model.dart';
import 'shipping_model.dart';

/// Customer model for WooCommerce customer operations
class CustomerModel {
  final int? id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? password;
  final BillingModel? billing;
  final ShippingModel? shipping;
  final String? dateCreated;
  final String? dateModified;
  final String? role;
  final bool? isPayingCustomer;
  final List<Map<String, dynamic>>? metaData;

  CustomerModel({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.password,
    this.billing,
    this.shipping,
    this.dateCreated,
    this.dateModified,
    this.role,
    this.isPayingCustomer,
    this.metaData,
  });

  /// Convert to JSON for API request (POST /customers) and storage
  /// If password is present, it's a creation request - send: email, username, password, first_name, last_name, billing, shipping
  /// Otherwise, it's for storage/response - include all fields
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    // If password exists, this is a creation request - include billing and shipping addresses
    if (password != null) {
      if (email != null) json['email'] = email;
      if (username != null) json['username'] = username;
      json['password'] = password;
      if (firstName != null) json['first_name'] = firstName;
      if (lastName != null && lastName!.isNotEmpty) json['last_name'] = lastName;
      // Include billing and shipping addresses in creation request
      if (billing != null) json['billing'] = billing!.toJson();
      if (shipping != null) json['shipping'] = shipping!.toJson();
      return json;
    }
    
    // For storage/response: include all fields
    if (id != null) json['id'] = id;
    if (email != null) json['email'] = email;
    if (username != null) json['username'] = username;
    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    if (billing != null) json['billing'] = billing!.toJson();
    if (shipping != null) json['shipping'] = shipping!.toJson();
    if (dateCreated != null) json['date_created'] = dateCreated;
    if (dateModified != null) json['date_modified'] = dateModified;
    if (role != null) json['role'] = role;
    if (isPayingCustomer != null) json['is_paying_customer'] = isPayingCustomer;
    if (metaData != null && metaData!.isNotEmpty) {
      json['meta_data'] = metaData!.map((meta) => {
        'key': meta['key'],
        'value': meta['value'],
      }).toList();
    }
    
    return json;
  }

  /// Convert to JSON for update request (PUT /customers/{id})
  /// Simple version - only first_name, last_name (no username, email, billing/shipping)
  Map<String, dynamic> toUpdateJson() {
    final json = <String, dynamic>{};
    
    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null && lastName!.isNotEmpty) json['last_name'] = lastName;
    // Username and email are read-only (not sent in update request)
    // Billing/shipping removed from update request
    
    return json;
  }
  
  /// Convert to JSON for update request with billing and shipping addresses
  /// Note: email and username are NOT included as they cannot be updated
  Map<String, dynamic> toUpdateJsonWithBilling() {
    final json = <String, dynamic>{};
    
    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    // Username and email are read-only - NOT included in update request
    if (billing != null) json['billing'] = billing!.toJson();
    // Include shipping if it has meaningful data
    if (shipping != null && 
        (shipping!.address1.isNotEmpty || 
         shipping!.city.isNotEmpty || 
         shipping!.state.isNotEmpty)) {
      json['shipping'] = shipping!.toJson();
    }
    if (metaData != null && metaData!.isNotEmpty) {
      json['meta_data'] = metaData!.map((meta) => {
        'key': meta['key'],
        'value': meta['value'],
      }).toList();
    }
    
    return json;
  }

  /// Create from JSON (for API response)
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      billing: json['billing'] != null
          ? BillingModel.fromJson(json['billing'] as Map<String, dynamic>)
          : null,
      shipping: json['shipping'] != null
          ? ShippingModel.fromJson(json['shipping'] as Map<String, dynamic>)
          : null,
      dateCreated: json['date_created'] as String?,
      dateModified: json['date_modified'] as String?,
      role: json['role'] as String?,
      isPayingCustomer: json['is_paying_customer'] as bool?,
      metaData: json['meta_data'] != null
          ? (json['meta_data'] as List<dynamic>)
              .map((meta) => <String, dynamic>{
                    'key': meta['key'],
                    'value': meta['value'],
                  })
              .toList()
          : null,
    );
  }

  /// Check if customer data is valid for creation
  /// Required: email, username, password, first_name
  /// Optional: last_name
  bool get isValidForCreation {
    if (email == null || email!.isEmpty) return false;
    if (!_isValidEmail(email!)) return false;
    if (username == null || username!.isEmpty) return false;
    if (firstName == null || firstName!.isEmpty) return false;
    // last_name is optional - no check needed
    if (password == null || password!.isEmpty) return false;
    // Password validation removed - API accepts simple passwords
    return true;
  }

  /// Check if customer data is valid for update
  bool get isValidForUpdate {
    if (id == null) return false;
    if (email != null && !_isValidEmail(email!)) return false;
    return true;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength (min 8 chars, at least one uppercase, one lowercase, one number, one special char)
  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    return true;
  }

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email ?? 'User';
  }

  /// Get phone number from billing
  String get phone => billing?.phone ?? '';

  /// Copy with method for immutable updates
  CustomerModel copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    BillingModel? billing,
    ShippingModel? shipping,
    String? dateCreated,
    String? dateModified,
    String? role,
    bool? isPayingCustomer,
    List<Map<String, dynamic>>? metaData,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      password: password ?? this.password,
      billing: billing ?? this.billing,
      shipping: shipping ?? this.shipping,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      role: role ?? this.role,
      isPayingCustomer: isPayingCustomer ?? this.isPayingCustomer,
      metaData: metaData ?? this.metaData,
    );
  }
}
