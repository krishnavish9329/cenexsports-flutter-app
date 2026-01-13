import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/pages/auth_page.dart';
import 'main_navigation.dart';
import '../presentation/pages/customer_dashboard_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated && authState.customer != null;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background for sections
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: 0, // Hide default toolbar to use custom header
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: const Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Best Deals',
                    style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[800]!, Colors.blue[600]!],
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
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                     style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildListTile(
                    icon: Icons.translate,
                    title: 'Select Language',
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.notifications_none,
                    title: 'Notification Settings',
                    onTap: () {},
                  ),
                  _buildListTile(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback & Information',
                     style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildListTile(
                    icon: Icons.description_outlined,
                    title: 'Terms, Policies and Licenses',
                    onTap: () {},
                  ),
                   _buildListTile(
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

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildLoginHeader(BuildContext context) {
    return Container(
      color: Colors.white,
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
                    color: Colors.grey[700],
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
              backgroundColor: Colors.blue[700], // Brand color
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
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
           CircleAvatar(
             radius: 25,
             backgroundColor: Colors.blue[100],
             child: Text(
               customer.fullName.substring(0, 1).toUpperCase(),
               style: const TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
                 color: Colors.blue,
               ),
             ),
           ),
           const SizedBox(width: 16),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Hello, ${customer.fullName}',
                 style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
               ),
               Text(
                 customer.email ?? '',
                 style: AppTextStyles.bodySmall,
               ),
             ],
           ),
        ],
      ),
     );
  }

  Widget _buildLanguageChip(String label, {bool isAction = false}) {
    return ActionChip(
      onPressed: () {},
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[300]!),
      labelStyle: TextStyle(
        color: isAction ? Colors.blue[700] : Colors.black87,
        fontWeight: isAction ? FontWeight.bold : FontWeight.normal,
      ),
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue[700], size: 22),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      dense: true,
    );
  }
}
