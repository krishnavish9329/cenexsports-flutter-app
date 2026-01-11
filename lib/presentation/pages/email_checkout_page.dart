import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/customer_api_service.dart';
import '../../data/models/customer_model.dart';
import '../providers/auth_provider.dart';
import 'checkout_page.dart';
import 'auth_page.dart';

/// Email-first checkout page - asks for email before proceeding
class EmailCheckoutPage extends ConsumerStatefulWidget {
  const EmailCheckoutPage({super.key});

  @override
  ConsumerState<EmailCheckoutPage> createState() => _EmailCheckoutPageState();
}

class _EmailCheckoutPageState extends ConsumerState<EmailCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isChecking = false;
  String? _errorMessage;
  CustomerModel? _foundCustomer;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              Icon(
                Icons.email_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Enter Your Email',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'We\'ll check if you have an account and auto-fill your details',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'your.email@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isChecking,
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
              const SizedBox(height: AppTheme.spacingL),
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
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleCheckEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _foundCustomer = null;
    });

    try {
      final email = _emailController.text.trim();
      final apiService = CustomerApiService();

      // Check if customer exists by email
      final customer = await apiService.getCustomerByEmail(email);

      if (customer != null && customer.id != null) {
        // Customer exists - auto-fill and proceed to checkout
        setState(() {
          _foundCustomer = customer;
        });

        // Authenticate user
        await ref.read(authProvider.notifier).login(email);

        // Navigate to checkout with customer data
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutPage(
                existingCustomer: customer,
              ),
            ),
          );
        }
      } else {
        // Customer doesn't exist - show registration option
        if (mounted) {
          _showRegistrationDialog(email);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check email. Please try again.';
        _isChecking = false;
      });
    }
  }

  void _showRegistrationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Not Found'),
        content: Text(
          'No account found with email: $email\n\nWould you like to create a new account?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close email checkout page
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AuthPage(
                    initialEmail: email,
                    redirectToCheckout: true,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
