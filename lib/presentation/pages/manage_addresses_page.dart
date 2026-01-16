import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';
import '../../data/services/customer_api_service.dart';
import '../providers/auth_provider.dart';

/// Manage Addresses Page - Edit billing and shipping addresses
/// Email and username are read-only and cannot be updated
class ManageAddressesPage extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const ManageAddressesPage({
    super.key,
    required this.customer,
  });

  @override
  ConsumerState<ManageAddressesPage> createState() => _ManageAddressesPageState();
}

class _ManageAddressesPageState extends ConsumerState<ManageAddressesPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Billing Controllers
  final _billingFirstNameController = TextEditingController();
  final _billingLastNameController = TextEditingController();
  final _billingCompanyController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingAddress2Controller = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPostcodeController = TextEditingController();
  final _billingCountryController = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _billingEmailController = TextEditingController();

  // Shipping Controllers
  final _shippingFirstNameController = TextEditingController();
  final _shippingLastNameController = TextEditingController();
  final _shippingCompanyController = TextEditingController();
  final _shippingAddress1Controller = TextEditingController();
  final _shippingAddress2Controller = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPostcodeController = TextEditingController();
  final _shippingCountryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize billing data
    final billing = widget.customer.billing;
    if (billing != null) {
      _billingFirstNameController.text = billing.firstName;
      _billingLastNameController.text = billing.lastName;
      _billingCompanyController.text = billing.company;
      _billingAddress1Controller.text = billing.address1;
      _billingAddress2Controller.text = billing.address2;
      _billingCityController.text = billing.city;
      _billingStateController.text = billing.state;
      _billingPostcodeController.text = billing.postcode;
      _billingCountryController.text = billing.country;
      _billingPhoneController.text = billing.phone;
      _billingEmailController.text = billing.email;
    } else {
      // Use customer data as defaults
      _billingFirstNameController.text = widget.customer.firstName ?? '';
      _billingLastNameController.text = widget.customer.lastName ?? '';
      _billingEmailController.text = widget.customer.email ?? '';
      _billingCountryController.text = 'IN';
    }

    // Initialize shipping data
    final shipping = widget.customer.shipping;
    if (shipping != null) {
      _shippingFirstNameController.text = shipping.firstName;
      _shippingLastNameController.text = shipping.lastName;
      _shippingCompanyController.text = shipping.company;
      _shippingAddress1Controller.text = shipping.address1;
      _shippingAddress2Controller.text = shipping.address2;
      _shippingCityController.text = shipping.city;
      _shippingStateController.text = shipping.state;
      _shippingPostcodeController.text = shipping.postcode;
      _shippingCountryController.text = shipping.country;
    } else {
      // Use billing data as defaults for shipping
      _shippingFirstNameController.text = _billingFirstNameController.text;
      _shippingLastNameController.text = _billingLastNameController.text;
      _shippingAddress1Controller.text = _billingAddress1Controller.text;
      _shippingAddress2Controller.text = _billingAddress2Controller.text;
      _shippingCityController.text = _billingCityController.text;
      _shippingStateController.text = _billingStateController.text;
      _shippingPostcodeController.text = _billingPostcodeController.text;
      _shippingCountryController.text = _billingCountryController.text.isEmpty ? 'IN' : _billingCountryController.text;
    }
  }

  @override
  void dispose() {
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingCompanyController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPostcodeController.dispose();
    _billingCountryController.dispose();
    _billingPhoneController.dispose();
    _billingEmailController.dispose();
    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingCompanyController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPostcodeController.dispose();
    _shippingCountryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getPadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Account Information (Read-only)
                  _buildReadOnlySection(context),
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Billing Address Section
                  _buildBillingSection(context),
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Shipping Address Section
                  _buildShippingSection(context),
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Error Message
                  if (_errorMessage != null)
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
                          const Icon(Icons.error_outline, color: AppTheme.errorColor),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Addresses'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: ResponsiveHelper.getIconSize(context)),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Account Information',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Email and username cannot be changed',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: ResponsiveHelper.getTextScale(context) * 14,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Email (Read-only)
            TextFormField(
              initialValue: widget.customer.email ?? '',
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              enabled: false,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Username (Read-only)
            TextFormField(
              initialValue: widget.customer.username ?? '',
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              enabled: false,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, size: ResponsiveHelper.getIconSize(context)),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Billing Address',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // First Name & Last Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingFirstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
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
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Company
            TextFormField(
              controller: _billingCompanyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Address Line 1
            TextFormField(
              controller: _billingAddress1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Address Line 2
            TextFormField(
              controller: _billingAddress2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // City & State
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingCityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
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
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Postcode & Country
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingPostcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postcode *',
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _billingCountryController,
                    decoration: const InputDecoration(
                      labelText: 'Country *',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Phone
            TextFormField(
              controller: _billingPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Email (Read-only, uses customer email)
            TextFormField(
              controller: _billingEmailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: false,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, size: ResponsiveHelper.getIconSize(context)),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Shipping Address',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // First Name & Last Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shippingFirstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
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
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Company
            TextFormField(
              controller: _shippingCompanyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Address Line 1
            TextFormField(
              controller: _shippingAddress1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Address Line 2
            TextFormField(
              controller: _shippingAddress2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // City & State
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shippingCityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
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
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Postcode & Country
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shippingPostcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postcode *',
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _shippingCountryController,
                    decoration: const InputDecoration(
                      labelText: 'Country *',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fill all required fields';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (widget.customer.id == null) {
      setState(() {
        _errorMessage = 'Customer ID not found';
        _isLoading = false;
      });
      return;
    }

    try {
      // Create updated billing model (use customer email, not billing email)
      final updatedBilling = BillingModel(
        firstName: _billingFirstNameController.text.trim(),
        lastName: _billingLastNameController.text.trim(),
        company: _billingCompanyController.text.trim(),
        address1: _billingAddress1Controller.text.trim(),
        address2: _billingAddress2Controller.text.trim(),
        city: _billingCityController.text.trim(),
        state: _billingStateController.text.trim(),
        postcode: _billingPostcodeController.text.trim(),
        country: _billingCountryController.text.trim().isEmpty ? 'IN' : _billingCountryController.text.trim(),
        email: widget.customer.email ?? _billingEmailController.text.trim(), // Use customer email
        phone: _billingPhoneController.text.trim(),
      );

      // Create updated shipping model
      final updatedShipping = ShippingModel(
        firstName: _shippingFirstNameController.text.trim(),
        lastName: _shippingLastNameController.text.trim(),
        company: _shippingCompanyController.text.trim(),
        address1: _shippingAddress1Controller.text.trim(),
        address2: _shippingAddress2Controller.text.trim(),
        city: _shippingCityController.text.trim(),
        state: _shippingStateController.text.trim(),
        postcode: _shippingPostcodeController.text.trim(),
        country: _shippingCountryController.text.trim().isEmpty ? 'IN' : _shippingCountryController.text.trim(),
      );

      // Create updated customer with new billing and shipping
      // Keep email and username unchanged (they are read-only)
      final updatedCustomer = widget.customer.copyWith(
        firstName: _billingFirstNameController.text.trim(),
        lastName: _billingLastNameController.text.trim(),
        billing: updatedBilling,
        shipping: updatedShipping,
        // email and username remain unchanged
      );

      // Use updateCustomerWithBilling method which excludes email/username
      final apiService = CustomerApiService();
      final result = await apiService.updateCustomerWithBilling(
        widget.customer.id!,
        updatedCustomer,
      );

      // Update auth state with new customer data
      await ref.read(authProvider.notifier).updateProfile(
        widget.customer.id!,
        result,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Addresses updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('CustomerApiException: ', '');
        });
      }
    }
  }
}
