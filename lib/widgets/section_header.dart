import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable section header widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: Icon(
                actionIcon ?? Icons.arrow_forward_ios,
                size: 16,
              ),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
