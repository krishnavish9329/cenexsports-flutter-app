import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// No Internet Connection Widget
/// Displays a clean UI when internet is not available
class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wi-Fi icon with slash
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wi-Fi icon
                    Icon(
                      Icons.wifi_off,
                      size: 64,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // "No Internet" text
              Text(
                'No Internet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // "Connection" text
              Text(
                'Connection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // Retry button (optional)
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
