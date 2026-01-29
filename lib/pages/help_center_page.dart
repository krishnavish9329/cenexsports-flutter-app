import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? const Color(0xFFF7F7F5),
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          'Customer Support / Help Center',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact Information',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _ContactRow(
                icon: Icons.call_outlined,
                title: 'Phone',
                value: '+91 123467890',
              ),
              const SizedBox(height: AppTheme.spacingS),
              _ContactRow(
                icon: Icons.email_outlined,
                title: 'Email',
                value: 'support@cenexsports.co.in',
              ),
              const SizedBox(height: AppTheme.spacingS),
              _ContactRow(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: '123 Sports Complex, Mumbai, Maharashtra 400001',
                maxLines: 2,
              ),
              const SizedBox(height: AppTheme.spacingS),
              _ContactRow(
                icon: Icons.access_time,
                title: 'Business Hours',
                value: 'Monday - Sunday: 9:00 AM - 9:00 PM',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final int maxLines;

  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 22,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withOpacity(0.4),
          size: 18,
        ),
      ],
    );
  }
}

