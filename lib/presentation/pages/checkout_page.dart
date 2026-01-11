import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../../core/providers/cart_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/line_item_model.dart';
import '../../data/models/customer_model.dart';
import '../providers/order_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Auto-fill form if customer data exists
    if (widget.existingCustomer != null) {
      _autoFillCustomerData(widget.existingCustomer!);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              _buildOrderSummaryCard(cartProvider),
              const SizedBox(height: AppTheme.spacingL),

              // Billing Address Section
              _buildSectionHeader('Billing Address', Icons.location_on),
              const SizedBox(height: AppTheme.spacingM),
              _buildBillingForm(),

              const SizedBox(height: AppTheme.spacingL),

              // Shipping Address Section
              _buildSectionHeader('Shipping Address', Icons.local_shipping),
              const SizedBox(height: AppTheme.spacingM),
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
              ),
              if (!_sameAsBilling) _buildShippingForm(),

              const SizedBox(height: AppTheme.spacingL),

              // Payment Method Section
              _buildSectionHeader('Payment Method', Icons.payment),
              const SizedBox(height: AppTheme.spacingM),
              _buildPaymentMethodSelector(),

              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildPlaceOrderButton(cartProvider, orderState),
    );
  }

  Widget _buildOrderSummaryCard(CartProvider cartProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: AppTextStyles.h4,
            ),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            ...cartProvider.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} x${item.quantity}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            _buildPriceRow('Subtotal', cartProvider.subtotal),
            _buildPriceRow('Tax (GST 18%)', cartProvider.tax),
            if (cartProvider.discount > 0)
              _buildPriceRow('Discount', -cartProvider.discount, isDiscount: true),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${cartProvider.grandTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            isDiscount
                ? '-₹${amount.abs().toStringAsFixed(0)}'
                : '₹${amount.toStringAsFixed(0)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDiscount ? AppTheme.successColor : null,
            ),
          ),
        ],
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingFirstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      hintText: 'John',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _billingLastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      hintText: 'Doe',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _billingEmailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'john.doe@example.com',
                prefixIcon: Icon(Icons.email),
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
            TextFormField(
              controller: _billingPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                hintText: '+91 9876543210',
                prefixIcon: Icon(Icons.phone),
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
            TextFormField(
              controller: _billingCompanyController,
              decoration: const InputDecoration(
                labelText: 'Company (Optional)',
                hintText: 'Company Name',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _billingAddress1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                hintText: 'Street address',
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
            TextFormField(
              controller: _billingAddress2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                hintText: 'Apartment, suite, etc.',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingCityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'Mumbai',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _billingStateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      hintText: 'Maharashtra',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _billingPostcodeController,
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

  Widget _buildShippingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shippingFirstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      hintText: 'John',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _shippingLastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      hintText: 'Doe',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _shippingCompanyController,
              decoration: const InputDecoration(
                labelText: 'Company (Optional)',
                hintText: 'Company Name',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _shippingAddress1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                hintText: 'Street address',
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
            TextFormField(
              controller: _shippingAddress2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                hintText: 'Apartment, suite, etc.',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shippingCityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'Mumbai',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _shippingStateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      hintText: 'Maharashtra',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
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

  Widget _buildPaymentMethodSelector() {
    return Card(
      child: RadioListTile<String>(
        title: const Text('Cash on Delivery'),
        subtitle: const Text('Pay when you receive'),
        value: 'cod',
        groupValue: _paymentMethod,
        onChanged: (value) {
          setState(() {
            _paymentMethod = value ?? 'cod';
            _paymentMethodTitle = 'Cash on Delivery';
          });
        },
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
      paymentMethod: _paymentMethod,
      paymentMethodTitle: _paymentMethodTitle,
      setPaid: false, // COD orders are not paid upfront
      billing: billing,
      shipping: shipping,
      lineItems: lineItems,
    );

    // Place order
    final success = await ref.read(orderStateProvider.notifier).placeOrder(order);

    if (success && mounted) {
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
}
