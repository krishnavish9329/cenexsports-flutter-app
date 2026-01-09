import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable price display widget with discount support
class PriceWidget extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final int? discount;
  final TextStyle? priceStyle;
  final TextStyle? originalPriceStyle;
  final bool showDiscountBadge;
  
  const PriceWidget({
    super.key,
    required this.price,
    this.originalPrice,
    this.discount,
    this.priceStyle,
    this.originalPriceStyle,
    this.showDiscountBadge = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice! > price && discount != null && discount! > 0;
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: priceStyle ?? AppTextStyles.h3.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasDiscount) ...[
          Text(
            '₹${originalPrice!.toStringAsFixed(0)}',
            style: originalPriceStyle ?? AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (showDiscountBadge && discount! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${discount}% OFF',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ],
    );
  }
}
