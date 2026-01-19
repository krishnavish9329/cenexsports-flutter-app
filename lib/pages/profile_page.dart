import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/language_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/pages/auth_page.dart';
import 'main_navigation.dart';
import '../presentation/pages/customer_dashboard_page.dart';
import '../presentation/pages/edit_profile_page.dart';
import '../presentation/pages/manage_addresses_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated && authState.customer != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        toolbarHeight: 0, // Hide default toolbar to use custom header
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Container(
              color: Theme.of(context).cardColor,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // 1. Header Section (Login CTA or User Info)
            if (!isAuthenticated)
              _buildLoginHeader(context)
            else
              _buildAuthenticatedHeader(context, authState.customer),
            
            const SizedBox(height: 12),

            // 2. Finance / Sponsored Section (Placeholder)
            _buildSectionContainer(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Best Deals',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.brownButtonColor.withOpacity(0.9),
                          AppTheme.brownButtonColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Huge Savings on Top Brands',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Get up to 50% off on your favorite products\n& free shipping on first order',
                          style: TextStyle(color: Colors.white),
                        ),
                         const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                             // Navigate to MainNavigation which defaults to Home (index 0)
                             Navigator.pushAndRemoveUntil(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => const MainNavigation(),
                               ),
                               (route) => false,
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.brownButtonColor,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Buy Now'),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

             const SizedBox(height: 12),



            // 4. Account Settings Section
            _buildSectionContainer(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                     style: AppTextStyles.h4.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.onSurface,
                     ),
                  ),
                  const SizedBox(height: 8),
                  // Show Edit Profile and Manage Addresses for authenticated users
                  if (isAuthenticated) ...[
                    _buildListTile(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              customer: authState.customer!,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.location_on_outlined,
                      title: 'Manage Addresses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageAddressesPage(
                              customer: authState.customer!,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  _buildListTile(
                    context: context,
                    icon: Icons.translate,
                    title: AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                    onTap: () => _showLanguageDialog(context, ref),
                  ),
                  _buildListTile(
                    context: context,
                    icon: Icons.notifications_none,
                    title: 'Notification Settings',
                    onTap: () {},
                  ),
                  _buildListTile(
                    context: context,
                    icon: Icons.headset_mic_outlined,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),



            // 6. Feedback & Information
            _buildSectionContainer(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback & Information',
                     style: AppTextStyles.h4.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.onSurface,
                     ),
                  ),
                  const SizedBox(height: 8),
                  _buildListTile(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'Terms, Policies and Licenses',
                    onTap: () {},
                  ),
                   _buildListTile(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Browse FAQs',
                    onTap: () {},
                  ),
                ],
              ),
            ),

             // Logout button if authenticated
             if (isAuthenticated) ...[
               const SizedBox(height: 12),
               _buildSectionContainer(
                 context: context,
                 child: SizedBox(
                   width: double.infinity,
                   child: OutlinedButton(
                     onPressed: () {
                         ref.read(authProvider.notifier).logout();
                     },
                     style: OutlinedButton.styleFrom(
                       foregroundColor: AppTheme.primaryColor,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     child: const Text('Log Out'),
                   ),
                 ),
               ),
             ],

             const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required BuildContext context, required Widget child}) {
    return Container(
      color: Theme.of(context).cardColor,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildLoginHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log in to get exclusive offers',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brownButtonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedHeader(BuildContext context, dynamic customer) {
     return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
           CircleAvatar(
             radius: 25,
             backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
             child: Text(
               customer.fullName.substring(0, 1).toUpperCase(),
               style: TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
                 color: Theme.of(context).colorScheme.primary,
               ),
             ),
           ),
           const SizedBox(width: 16),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Hello, ${customer.fullName}',
                 style: AppTextStyles.h3.copyWith(
                   fontWeight: FontWeight.bold,
                   color: Theme.of(context).colorScheme.onSurface,
                 ),
               ),
               Text(
                 customer.email ?? '',
                 style: AppTextStyles.bodySmall.copyWith(
                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
             ],
           ),
        ],
      ),
     );
  }

  Widget _buildLanguageChip(BuildContext context, String label, {bool isAction = false}) {
    return ActionChip(
      onPressed: () {},
      label: Text(label),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      ),
      labelStyle: TextStyle(
        color: isAction
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isAction ? FontWeight.bold : FontWeight.normal,
      ),
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        size: 20,
      ),
      onTap: onTap,
      dense: true,
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            l10n?.selectLanguage ?? 'Select Language',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale>(
                title: Text(
                  l10n?.english ?? 'English',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: const Locale('en'),
                groupValue: currentLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    ref.read(languageProvider.notifier).setLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<Locale>(
                title: Text(
                  l10n?.hindi ?? 'Hindi',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: const Locale('hi'),
                groupValue: currentLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    ref.read(languageProvider.notifier).setLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
