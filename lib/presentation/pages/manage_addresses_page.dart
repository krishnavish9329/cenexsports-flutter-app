import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';
import '../providers/auth_provider.dart';

/// Manage Addresses Page - Edit billing and shipping addresses
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
  
  // Billing Controllers
  final _billingFirstNameController = TextEditingController();
  final _billingLastNameController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingAddress2Controller = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPostcodeController = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _billingEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with existing billing data
    final billing = widget.customer.billing;
    if (billing != null) {
      _billingFirstNameController.text = billing.firstName;
      _billingLastNameController.text = billing.lastName;
      _billingAddress1Controller.text = billing.address1;
      _billingAddress2Controller.text = billing.address2;
      _billingCityController.text = billing.city;
      _billingStateController.text = billing.state;
      _billingPostcodeController.text = billing.postcode;
      _billingPhoneController.text = billing.phone;
      _billingEmailController.text = billing.email;
    } else {
      // Use customer data as defaults
      _billingFirstNameController.text = widget.customer.firstName ?? '';
      _billingLastNameController.text = widget.customer.lastName ?? '';
      _billingEmailController.text = widget.customer.email ?? '';
    }
  }

  @override
  void dispose() {
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPostcodeController.dispose();
    _billingPhoneController.dispose();
    _billingEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Billing Address',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingM),
              
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
              
              TextFormField(
                controller: _billingAddress1Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1 *',
                  prefixIcon: Icon(Icons.home),
                ),
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
                  labelText: 'Address Line 2',
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              
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
              
              TextFormField(
                controller: _billingPostcodeController,
                decoration: const InputDecoration(
                  labelText: 'Postcode *',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Postcode is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              TextFormField(
                controller: _billingPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              TextFormField(
                controller: _billingEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              if (authState.error != null)
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
                          authState.error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => _handleUpdate(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Address'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    ref.read(authProvider.notifier).clearError();

    if (widget.customer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID not found'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Create updated billing model
    final updatedBilling = BillingModel(
      firstName: _billingFirstNameController.text.trim(),
      lastName: _billingLastNameController.text.trim(),
      address1: _billingAddress1Controller.text.trim(),
      address2: _billingAddress2Controller.text.trim(),
      city: _billingCityController.text.trim(),
      state: _billingStateController.text.trim(),
      postcode: _billingPostcodeController.text.trim(),
      phone: _billingPhoneController.text.trim(),
      email: _billingEmailController.text.trim(),
    );

    // Create updated customer with new billing
    final updatedCustomer = widget.customer.copyWith(
      billing: updatedBilling,
      // Keep shipping same as billing for now
      shipping: ShippingModel(
        firstName: _billingFirstNameController.text.trim(),
        lastName: _billingLastNameController.text.trim(),
        address1: _billingAddress1Controller.text.trim(),
        address2: _billingAddress2Controller.text.trim(),
        city: _billingCityController.text.trim(),
        state: _billingStateController.text.trim(),
        postcode: _billingPostcodeController.text.trim(),
      ),
    );

    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        widget.customer.id!,
        updatedCustomer,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          final error = ref.read(authProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update address'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
