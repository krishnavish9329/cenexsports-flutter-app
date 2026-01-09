import 'package:flutter/material.dart';

/// Helper class for responsive design calculations
class ResponsiveHelper {
  /// Get responsive padding based on screen width
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 32.0; // Desktop
    if (width > 600) return 24.0; // Tablet
    return 16.0; // Mobile
  }

  /// Get responsive font size multiplier
  static double getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 1.2; // Desktop
    if (width > 600) return 1.1; // Tablet
    return 1.0; // Mobile
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4; // Desktop
    if (width > 800) return 3; // Large tablet
    if (width > 600) return 3; // Tablet
    return 2; // Mobile
  }

  /// Get responsive child aspect ratio for product cards
  /// Adjusted to prevent overflow - cards need more vertical space
  static double getProductCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 0.6; // Desktop - wider cards, more height
    if (width > 600) return 0.65; // Tablet - more height for content
    return 0.7; // Mobile - taller cards to fit content without overflow
  }

  /// Get responsive horizontal list item width
  static double getHorizontalListItemWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 250.0; // Desktop
    if (width > 600) return 220.0; // Tablet
    return 180.0; // Mobile
  }

  /// Get responsive category item size
  static double getCategoryItemSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 100.0; // Tablet/Desktop
    return 80.0; // Mobile
  }

  /// Get responsive horizontal list height
  static double getHorizontalListHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 320.0; // Tablet/Desktop
    return 280.0; // Mobile
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
}
