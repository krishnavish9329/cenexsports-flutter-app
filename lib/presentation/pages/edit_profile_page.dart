import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/customer_model.dart';
import '../providers/auth_provider.dart';

/// Edit Profile Page - Simple version with only basic fields
class EditProfilePage extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const EditProfilePage({
    super.key,
    required this.customer,
  });

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with existing customer data
    _firstNameController.text = widget.customer.firstName ?? '';
    _lastNameController.text = widget.customer.lastName ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Update your profile information',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              TextFormField(
                controller: _firstNameController,
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
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Last Name',
                  prefixIcon: Icon(Icons.person),
                ),
                // Last name is optional
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              TextFormField(
                controller: TextEditingController(text: widget.customer.email ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'john@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false, // Email cannot be changed (read-only)
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              TextFormField(
                controller: TextEditingController(text: widget.customer.username ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Username123',
                  prefixIcon: Icon(Icons.account_circle),
                ),
                enabled: false, // Username cannot be changed (read-only)
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
                      : const Text('Update Profile'),
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

    // Create updated customer model - ONLY first_name, last_name
    // Username and email are read-only (cannot be changed)
    // NO billing, NO shipping, NO email, NO username in update request
    final updatedCustomer = widget.customer.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty 
          ? null 
          : _lastNameController.text.trim(),
      // Username and email remain unchanged (read-only)
      username: widget.customer.username,
      email: widget.customer.email,
      // Keep existing billing/shipping but don't send in update
      billing: widget.customer.billing,
      shipping: widget.customer.shipping,
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
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Show error if update failed
          final error = ref.read(authProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update profile'),
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
