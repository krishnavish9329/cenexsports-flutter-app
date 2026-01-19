import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/line_item_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/services/customer_api_service.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import 'order_success_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final CustomerModel? existingCustomer;

  const CheckoutPage({
    super.key,
    this.existingCustomer,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _billingFormKey = GlobalKey<FormState>();
  final _shippingFormKey = GlobalKey<FormState>();

  // Billing Controllers
  final _billingFirstNameController = TextEditingController();
  final _billingLastNameController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingAddress2Controller = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPostcodeController = TextEditingController();
  final _billingCompanyController = TextEditingController();

  // Shipping Controllers
  final _shippingFirstNameController = TextEditingController();
  final _shippingLastNameController = TextEditingController();
  final _shippingAddress1Controller = TextEditingController();
  final _shippingAddress2Controller = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPostcodeController = TextEditingController();
  final _shippingCompanyController = TextEditingController();

  bool _sameAsBilling = true;
  String _paymentMethod = 'cod'; // Cash on Delivery
  String _paymentMethodTitle = 'Cash on Delivery';
  bool _isLoadingCustomer = false;
  CustomerModel? _currentCustomer;
  int? _customerId;

  // New state variables
  int _currentStep = 1; // 1: Address, 2: Summary, 3: Payment
  bool _isEditingAddress = false;

  // Payment method options
  final List<Map<String, String>> _paymentMethods = [
    {'value': 'cod', 'title': 'Cash on Delivery'},
    {'value': 'razorpay', 'title': 'Online Payment (Razorpay)'},
    {'value': 'stripe', 'title': 'Online Payment (Stripe)'},
    {'value': 'upi', 'title': 'UPI'},
  ];

  @override
  void initState() {
    super.initState();
    // Auto-fill form if customer data exists
    if (widget.existingCustomer != null) {
      _currentCustomer = widget.existingCustomer;
      _customerId = widget.existingCustomer!.id;
      _autoFillCustomerData(widget.existingCustomer!);
      // If we have customer data, start in view mode
      _isEditingAddress = false;
    } else {
      // Check if user is logged in
      _checkAndLoadCustomer();
    }
  }

  /// Check authentication state and load customer data
  Future<void> _checkAndLoadCustomer() async {
    final authState = ref.read(authProvider);
    
    if (authState.isAuthenticated && authState.customer != null) {
      // User is logged in - auto-fill from auth state
      _currentCustomer = authState.customer;
      _customerId = authState.customer!.id;
      _autoFillCustomerData(authState.customer!);
    } else {
      // User not logged in - ask for email first
      await _askForEmailAndLoadCustomer();
    }
  }

  /// Ask for email and search for customer
  Future<void> _askForEmailAndLoadCustomer() async {
    final emailController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Email'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'john@example.com',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Continue as Guest'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoadingCustomer = true;
      });

      try {
        final customerApiService = ref.read(customerApiServiceProvider);
        final customer = await customerApiService.getCustomerByEmail(result);
        
        if (customer != null && customer.id != null) {
          // Customer found - auto-fill
          _currentCustomer = customer;
          _customerId = customer.id;
          _autoFillCustomerData(customer);
        } else {
          // Customer not found - show empty form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer not found. Please fill the form manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customer: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isLoadingCustomer = false;
        });
      }
    }
  }

  void _autoFillCustomerData(CustomerModel customer) {
    // Fill billing fields
    _billingFirstNameController.text = customer.firstName ?? '';
    _billingLastNameController.text = customer.lastName ?? '';
    _billingEmailController.text = customer.email ?? '';
    
    // Fill billing address if available
    if (customer.billing != null) {
      final billing = customer.billing!;
      _billingPhoneController.text = billing.phone;
      _billingAddress1Controller.text = billing.address1;
      _billingAddress2Controller.text = billing.address2;
      _billingCityController.text = billing.city;
      _billingStateController.text = billing.state;
      _billingPostcodeController.text = billing.postcode;
      _billingCompanyController.text = billing.company;
    }
    
    // Copy to shipping if same as billing
    if (_sameAsBilling) {
      _copyBillingToShipping();
    }
  }

  @override
  void dispose() {
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPostcodeController.dispose();
    _billingCompanyController.dispose();
    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPostcodeController.dispose();
    _shippingCompanyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = provider.Provider.of<CartProvider>(context);
    final orderState = ref.watch(orderStateProvider);

    if (cartProvider.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: AppTheme.spacingM),
              const Text('Your cart is empty'),
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingCustomer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Delivery Address Section (Top)
                      _buildDeliveryAddressSection(),
                      
                      const SizedBox(height: AppTheme.spacingL),

                      // 2. Product List Section (Middle)
                      _buildProductListSection(cartProvider),
                      
                      const SizedBox(height: AppTheme.spacingL),

                      // 3. Payment Method Section
                      _buildPaymentMethodCard(),
                      
                      const SizedBox(height: AppTheme.spacingL),

                      // 4. Payment Summary Section (Bottom)
                      _buildPaymentSummaryCard(cartProvider),
                      
                      const SizedBox(height: AppTheme.spacingL),

                      // 5. Steps Indicator (Bottom)
                      _buildStepper(),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                    ],
                  ),
                ),
              ),
            ),
            // Place Order Button
            _buildPlaceOrderButton(cartProvider, orderState),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    if (_currentCustomer != null && !_isEditingAddress) {
      final billing = _currentCustomer?.billing;
      if (billing == null) {
        return _buildAddressFormSection();
      }
      
      return Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivering to',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${billing.address1}, ${billing.city}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingAddress = true;
                  });
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
      );
    } else {
      return _buildAddressFormSection();
    }
  }

  Widget _buildAddressFormSection() {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Billing Address',
                  style: AppTextStyles.h4,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildBillingForm(),
            const SizedBox(height: AppTheme.spacingL),
            CheckboxListTile(
              title: const Text('Same as billing address'),
              value: _sameAsBilling,
              onChanged: (value) {
                setState(() {
                  _sameAsBilling = value ?? true;
                  if (_sameAsBilling) {
                    _copyBillingToShipping();
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (!_sameAsBilling) ...[
              const SizedBox(height: AppTheme.spacingM),
              _buildShippingForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductListSection(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...cartProvider.items.map((item) => _buildProductCard(item, cartProvider)),
      ],
    );
  }

  Widget _buildProductCard(CartItem item, CartProvider cartProvider) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: SizedBox(
                width: 100,
                height: 100,
                child: item.product.imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: item.product.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand/Name
                  Text(
                    item.product.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Size/Color
                  Text(
                    'Size: M, Color: Black',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price and Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: item.quantity > 1
                                  ? () {
                                      cartProvider.updateQuantity(
                                        item.product.id,
                                        item.quantity - 1,
                                      );
                                    }
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text(
                              '${item.quantity}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                cartProvider.updateQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Payment Method',
                  style: AppTextStyles.h4,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            ..._paymentMethods.map((method) {
              return RadioListTile<String>(
                title: Text(method['title']!),
                subtitle: method['value'] == 'cod'
                    ? const Text('Pay when you receive')
                    : method['value'] == 'razorpay'
                        ? const Text('Online Payment (Razorpay)')
                        : const Text('Pay securely online'),
                value: method['value']!,
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value ?? 'cod';
                    _paymentMethodTitle = method['title']!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(CartProvider cartProvider) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildSummaryRow('Order Amount', cartProvider.subtotal),
            _buildSummaryRow('Tax', cartProvider.tax),
            if (cartProvider.discount > 0)
              _buildSummaryRow('Discount', -cartProvider.discount, isDiscount: true),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payment',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${cartProvider.grandTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if (cartProvider.discount > 0) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'You saved ₹${cartProvider.discount.toStringAsFixed(0)} on this purchase.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
          Text(
            isDiscount
                ? '-₹${amount.abs().toStringAsFixed(0)}'
                : '₹${amount.toStringAsFixed(0)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDiscount ? AppTheme.successColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          _buildStepItem(1, 'Address', _currentStep >= 1),
          _buildStepDivider(_currentStep >= 2),
          _buildStepItem(2, 'Order Summary', _currentStep >= 2),
          _buildStepDivider(_currentStep >= 3),
          _buildStepItem(3, 'Payment', _currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), // Align with circle center roughly
        alignment: Alignment.center, // Ensure it takes up space correctly
      ),
    );
  }

  Widget _buildSavedAddressCard() {
    final billing = _currentCustomer?.billing;
    if (billing == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Deliver to:', style: AppTextStyles.h4),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingAddress = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Change',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '${billing.firstName} ${billing.lastName}',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 4),
            Text(
              '${billing.address1}, ${billing.city}, ${billing.state} ${billing.postcode}',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              billing.phone,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          title,
          style: AppTextStyles.h4,
        ),
      ],
    );
  }

  Widget _buildBillingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _billingFirstNameController,
                        decoration: InputDecoration(
                          hintText: 'John',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _billingLastNameController,
                        decoration: InputDecoration(
                          hintText: 'Doe',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Email
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _billingEmailController,
              decoration: InputDecoration(
                hintText: 'your@gmail.com',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Phone
            const Text(
              'Phone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _billingPhoneController,
              decoration: InputDecoration(
                hintText: '+91 9876543210',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Company
            const Text(
              'Company',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _billingCompanyController,
              decoration: InputDecoration(
                hintText: 'Company Name',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Address Line 1
            const Text(
              'Address Line 1',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _billingAddress1Controller,
              decoration: InputDecoration(
                hintText: 'Street address',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Address Line 2
            const Text(
              'Address Line 2',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _billingAddress2Controller,
              decoration: InputDecoration(
                hintText: 'Apartment, suite, etc.',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingM),
            // City & State Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'City',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _billingCityController,
                        decoration: InputDecoration(
                          hintText: 'Mumbai',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'State',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _billingStateController,
                        decoration: InputDecoration(
                          hintText: 'Maharashtra',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Postcode
            const Text(
              'Postcode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _billingPostcodeController,
              decoration: InputDecoration(
                hintText: '400001',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Postcode is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _shippingFirstNameController,
                        decoration: InputDecoration(
                          hintText: 'John',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _shippingLastNameController,
                        decoration: InputDecoration(
                          hintText: 'Doe',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Company
            const Text(
              'Company',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _shippingCompanyController,
              decoration: InputDecoration(
                hintText: 'Company Name',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Address Line 1
            const Text(
              'Address Line 1',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _shippingAddress1Controller,
              decoration: InputDecoration(
                hintText: 'Street address',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Address Line 2
            const Text(
              'Address Line 2',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextFormField(
              controller: _shippingAddress2Controller,
              decoration: InputDecoration(
                hintText: 'Apartment, suite, etc.',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingM),
            // City & State Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'City',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _shippingCityController,
                        decoration: InputDecoration(
                          hintText: 'Mumbai',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'State',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _shippingStateController,
                        decoration: InputDecoration(
                          hintText: 'Maharashtra',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _shippingPostcodeController,
              decoration: const InputDecoration(
                labelText: 'Postcode *',
                hintText: '400001',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Postcode is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPlaceOrderButton(CartProvider cartProvider, OrderState orderState) {
    final isLoading = orderState.isLoading;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (orderState.error != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        orderState.error!,
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(orderStateProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _handlePlaceOrder(cartProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Place Order - ₹${cartProvider.grandTotal.toStringAsFixed(0)}',
                        style: AppTextStyles.button,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyBillingToShipping() {
    setState(() {
      _shippingFirstNameController.text = _billingFirstNameController.text;
      _shippingLastNameController.text = _billingLastNameController.text;
      _shippingAddress1Controller.text = _billingAddress1Controller.text;
      _shippingAddress2Controller.text = _billingAddress2Controller.text;
      _shippingCityController.text = _billingCityController.text;
      _shippingStateController.text = _billingStateController.text;
      _shippingPostcodeController.text = _billingPostcodeController.text;
      _shippingCompanyController.text = _billingCompanyController.text;
    });
  }

  Future<void> _handlePlaceOrder(CartProvider cartProvider) async {
    // Validate forms
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!_sameAsBilling) {
      // Validate shipping form if different from billing
      if (_shippingFirstNameController.text.isEmpty ||
          _shippingLastNameController.text.isEmpty ||
          _shippingAddress1Controller.text.isEmpty ||
          _shippingCityController.text.isEmpty ||
          _shippingStateController.text.isEmpty ||
          _shippingPostcodeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all shipping address fields'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }

    // Create billing model
    final billing = BillingModel(
      firstName: _billingFirstNameController.text.trim(),
      lastName: _billingLastNameController.text.trim(),
      company: _billingCompanyController.text.trim(),
      address1: _billingAddress1Controller.text.trim(),
      address2: _billingAddress2Controller.text.trim(),
      city: _billingCityController.text.trim(),
      state: _billingStateController.text.trim(),
      postcode: _billingPostcodeController.text.trim(),
      email: _billingEmailController.text.trim(),
      phone: _billingPhoneController.text.trim(),
    );

    // Create shipping model
    final shipping = _sameAsBilling
        ? ShippingModel(
            firstName: billing.firstName,
            lastName: billing.lastName,
            company: billing.company,
            address1: billing.address1,
            address2: billing.address2,
            city: billing.city,
            state: billing.state,
            postcode: billing.postcode,
          )
        : ShippingModel(
            firstName: _shippingFirstNameController.text.trim(),
            lastName: _shippingLastNameController.text.trim(),
            company: _shippingCompanyController.text.trim(),
            address1: _shippingAddress1Controller.text.trim(),
            address2: _shippingAddress2Controller.text.trim(),
            city: _shippingCityController.text.trim(),
            state: _shippingStateController.text.trim(),
            postcode: _shippingPostcodeController.text.trim(),
          );

    // Create line items from cart
    final lineItems = cartProvider.items.map((item) {
      return LineItemModel(
        productId: int.parse(item.product.id),
        quantity: item.quantity,
        name: item.product.name,
        price: item.product.price,
      );
    }).toList();

    // Create order model
    final order = OrderModel(
      customerId: _customerId,
      paymentMethod: _paymentMethod,
      paymentMethodTitle: _paymentMethodTitle,
      setPaid: false, // COD orders are not paid upfront
      status: 'pending',
      billing: billing,
      shipping: shipping,
      lineItems: lineItems,
    );

    // Place order
    final success = await ref.read(orderStateProvider.notifier).placeOrder(order);

    if (success && mounted) {
      // Update or create customer profile after successful order
      await _updateOrCreateCustomer(billing, shipping);

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessPage(
            order: ref.read(orderStateProvider).order!,
          ),
        ),
      );
      // Clear cart after successful order
      cartProvider.clearCart();
    }
  }

  /// Update existing customer or create new customer after order placement
  Future<void> _updateOrCreateCustomer(
    BillingModel billing,
    ShippingModel shipping,
  ) async {
    try {
      final customerApiService = ref.read(customerApiServiceProvider);
      
      if (_customerId != null) {
        // Customer exists - update profile with billing/shipping
        final updatedCustomer = CustomerModel(
          id: _customerId,
          email: billing.email,
          firstName: billing.firstName,
          lastName: billing.lastName,
          billing: billing,
          shipping: shipping,
        );
        
        // Use updateCustomerWithBilling for full address update
        await customerApiService.updateCustomerWithBilling(_customerId!, updatedCustomer);
      } else {
        // Guest checkout - create new customer
        // Generate username from email
        final username = billing.email.split('@')[0] + DateTime.now().millisecondsSinceEpoch.toString().substring(0, 4);
        
        final newCustomer = CustomerModel(
          email: billing.email,
          firstName: billing.firstName,
          lastName: billing.lastName,
          username: username,
          password: 'temp_password_${DateTime.now().millisecondsSinceEpoch}', // Temporary password
          billing: billing,
          shipping: shipping,
        );
        
        final createdCustomer = await customerApiService.createCustomer(newCustomer);
        
        // Save customer ID for future orders
        if (createdCustomer.id != null) {
          _customerId = createdCustomer.id;
          _currentCustomer = createdCustomer;
          
          // Also update auth state if user wants to stay logged in
          // This is optional - can be skipped for guest checkout
        }
      }
    } catch (e) {
      // Silent fail - order is already placed, customer update is optional
      print('Failed to update/create customer: $e');
    }
  }
}
