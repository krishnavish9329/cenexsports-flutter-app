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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFAECEC), // Light peach/pink color from image
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    actionIcon ?? Icons.arrow_forward_ios,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
