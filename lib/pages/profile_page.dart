import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/pages/auth_page.dart';
import '../presentation/pages/edit_profile_page.dart';
import '../presentation/pages/order_history_page.dart';
import '../presentation/pages/customer_dashboard_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: authState.isAuthenticated && authState.customer != null
          ? _buildAuthenticatedProfile(context, ref, authState.customer!)
          : _buildUnauthenticatedProfile(context),
    );
  }

  /// Build profile when user is NOT logged in (blank state)
  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'Welcome!',
              style: AppTextStyles.h2.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Sign in to view your profile, orders, and more',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign In / Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build profile when user IS logged in
  Widget _buildAuthenticatedProfile(
    BuildContext context,
    WidgetRef ref,
    customer,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Card
          _buildUserInfoCard(context, ref, customer),
          const SizedBox(height: AppTheme.spacingM),
          
          // Menu Items
          _buildMenuSection(
            context,
            title: 'Account',
            items: [
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  subtitle: 'View order history',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryPage(),
                      ),
                    );
                  },
                ),
              _MenuItem(
                icon: Icons.favorite_border,
                title: 'Wishlist',
                subtitle: 'Saved items',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wishlist coming soon')),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.location_on_outlined,
                title: 'Addresses',
                subtitle: 'Manage delivery addresses',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Addresses page coming soon')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Settings Section
          _buildMenuSection(
            context,
            title: 'Settings',
            items: [
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notifications',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle: 'Cards, UPI, etc.',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'FAQs, contact us',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version, terms',
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context, ref);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, WidgetRef ref, customer) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (customer.email != null)
                  Text(
                    customer.email!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                if (customer.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    customer.phone,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(customer: customer),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      item.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      item.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: AppTextStyles.bodySmall,
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: item.onTap,
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
