import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';
import 'checkout_page.dart';

/// Authentication page with Login and Signup tabs
class AuthPage extends ConsumerStatefulWidget {
  final String? initialEmail;
  final bool redirectToCheckout;

  const AuthPage({
    super.key,
    this.initialEmail,
    this.redirectToCheckout = false,
  });

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginEmailOrPhoneController = TextEditingController();

  // Signup controllers
  final _signupFirstNameController = TextEditingController();
  final _signupLastNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupUsernameController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  
  // Billing Address controllers
  final _address1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _phoneController = TextEditingController();

  // Shipping Address controllers (for different address)
  final _shippingAddress1Controller = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPostcodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _useSameAddressForShipping = true; // Default: use same address

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialEmail != null) {
      _signupEmailController.text = widget.initialEmail!;
      _loginEmailOrPhoneController.text = widget.initialEmail!;
      // Auto-select signup tab if email provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(1);
      });
    }
    // Listen to first name changes to update username placeholder
    _signupFirstNameController.addListener(() {
      setState(() {}); // Rebuild to update username hint text
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailOrPhoneController.dispose();
    _signupFirstNameController.dispose();
    _signupLastNameController.dispose();
    _signupEmailController.dispose();
    _signupUsernameController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _address1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPostcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In / Create Account'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(authState),
          _buildSignupTab(authState),
        ],
      ),
    );
  }

  Widget _buildLoginTab(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'Welcome Back',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Sign in to continue',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            TextFormField(
              controller: _loginEmailOrPhoneController,
              decoration: const InputDecoration(
                labelText: 'Email or Phone Number *',
                hintText: 'john@example.com or +91 9876543210',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email or phone is required';
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
                    Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: TextStyle(color: AppTheme.errorColor),
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
                    : () => _handleLogin(),
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
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupTab(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Create Account',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Sign up to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            TextFormField(
              controller: _signupFirstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name *',
                hintText: 'First Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _signupLastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                hintText: 'Last Name',
                prefixIcon: Icon(Icons.person),
              ),
              // Last name is optional - no validator
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _signupEmailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'user@gmail.com',
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
              controller: _signupUsernameController,
              decoration: InputDecoration(
                labelText: 'Username *',
                hintText: _signupFirstNameController.text.isNotEmpty 
                    ? _signupFirstNameController.text.toLowerCase()
                    : 'User',
                prefixIcon: const Icon(Icons.account_circle),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _signupPasswordController,
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Strong@123',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                // Simple validation - API accepts any password
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _signupConfirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Strong@123',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _signupPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingXL),
            // Address Section
            Text(
              'Address Information',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _address1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                hintText: '123 Main Street',
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'Ahmedabad',
                      prefixIcon: Icon(Icons.location_city),
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
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      hintText: 'GJ',
                      prefixIcon: Icon(Icons.map),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postcode *',
                      hintText: '380001',
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
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      hintText: '9876543210',
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
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            // Shipping Address Section
            Text(
              'Shipping Address',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppTheme.spacingS),
            CheckboxListTile(
              title: const Text('Use same address for shipping'),
              value: _useSameAddressForShipping,
              onChanged: (value) {
                setState(() {
                  _useSameAddressForShipping = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!_useSameAddressForShipping) ...[
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                controller: _shippingAddress1Controller,
                decoration: const InputDecoration(
                  labelText: 'Shipping Address Line 1 *',
                  hintText: '123 Main Street',
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (!_useSameAddressForShipping) {
                    if (value == null || value.isEmpty) {
                      return 'Shipping address is required';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _shippingCityController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping City *',
                        hintText: 'Ahmedabad',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (!_useSameAddressForShipping) {
                          if (value == null || value.isEmpty) {
                            return 'Shipping city is required';
                          }
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
                        labelText: 'Shipping State *',
                        hintText: 'GJ',
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: (value) {
                        if (!_useSameAddressForShipping) {
                          if (value == null || value.isEmpty) {
                            return 'Shipping state is required';
                          }
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
                  labelText: 'Shipping Postcode *',
                  hintText: '380001',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (!_useSameAddressForShipping) {
                    if (value == null || value.isEmpty) {
                      return 'Shipping postcode is required';
                    }
                  }
                  return null;
                },
              ),
            ],
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
                    Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: TextStyle(color: AppTheme.errorColor),
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
                    : () => _handleSignup(),
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
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).login(
      _loginEmailOrPhoneController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) {
      return;
    }

    ref.read(authProvider.notifier).clearError();

    // Create billing address
    final billing = BillingModel(
      firstName: _signupFirstNameController.text.trim(),
      lastName: _signupLastNameController.text.trim().isEmpty 
          ? _signupFirstNameController.text.trim() 
          : _signupLastNameController.text.trim(),
      address1: _address1Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postcode: _postcodeController.text.trim(),
      country: 'IN', // Default to India
      email: _signupEmailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // Create shipping address (same as billing or different based on checkbox)
    final shipping = ShippingModel(
      firstName: _signupFirstNameController.text.trim(),
      lastName: _signupLastNameController.text.trim().isEmpty 
          ? _signupFirstNameController.text.trim() 
          : _signupLastNameController.text.trim(),
      address1: _useSameAddressForShipping 
          ? _address1Controller.text.trim()
          : _shippingAddress1Controller.text.trim(),
      city: _useSameAddressForShipping 
          ? _cityController.text.trim()
          : _shippingCityController.text.trim(),
      state: _useSameAddressForShipping 
          ? _stateController.text.trim()
          : _shippingStateController.text.trim(),
      postcode: _useSameAddressForShipping 
          ? _postcodeController.text.trim()
          : _shippingPostcodeController.text.trim(),
      country: 'IN', // Default to India
    );

    // Create customer model - matching cURL API structure
    // Include: email, username, password, first_name, last_name, billing, shipping
    final customer = CustomerModel(
      email: _signupEmailController.text.trim(),
      firstName: _signupFirstNameController.text.trim(),
      lastName: _signupLastNameController.text.trim().isEmpty 
          ? null 
          : _signupLastNameController.text.trim(),
      username: _signupUsernameController.text.trim(),
      password: _signupPasswordController.text.trim(),
      billing: billing,
      shipping: shipping,
    );

    final success = await ref.read(authProvider.notifier).register(customer);

    if (success && mounted) {
      if (widget.redirectToCheckout) {
        // Navigate to checkout with new customer
        final authState = ref.read(authProvider);
        if (authState.customer != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutPage(
                existingCustomer: authState.customer,
              ),
            ),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }
}
