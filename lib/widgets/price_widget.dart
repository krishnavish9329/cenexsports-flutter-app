import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable price display widget with discount support.
/// Mapping: regular_price → MRP, sale_price → Discounted price (if on sale),
/// price → final amount customer pays.
class PriceWidget extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final int? discount;
  final TextStyle? priceStyle;
  final TextStyle? originalPriceStyle;
  final bool showDiscountBadge;
  /// When true: one line — pehle price (bada), phir MRP (chhota, strikethrough). Product card.
  final bool showLabels;

  const PriceWidget({
    super.key,
    required this.price,
    this.originalPrice,
    this.discount,
    this.priceStyle,
    this.originalPriceStyle,
    this.showDiscountBadge = true,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    // MRP = regular_price (originalPrice); strikethrough when on sale
    final hasSale = originalPrice != null && originalPrice! > price;
    final showBadge = showDiscountBadge && discount != null && discount! > 0;

    if (showLabels) {
      // Ek line: pehle price (bada, bold), phir MRP (chhota, kaata) — image 2 jaisa
      return Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Pehle: selling price (bada, prominent)
          Text(
            '₹${price.toStringAsFixed(0)}',
            style: priceStyle ?? AppTextStyles.h3.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Phir: MRP (chhota, grey) — hamesha jab originalPrice ho; kaata sirf jab sale ho
          if (originalPrice != null && originalPrice! > price) ...[
            Text(
              '₹${originalPrice!.toStringAsFixed(0)}',
              style: (originalPriceStyle ?? AppTextStyles.bodySmall).copyWith(
                color: Colors.grey,
                decoration: hasSale ? TextDecoration.lineThrough : null,
              ),
            ),
            if (showBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${discount}% OFF',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ],
      );
    }

    // Inline layout (e.g. product detail): main price + MRP strikethrough when discount
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
        if (hasSale) ...[
          Text(
            '₹${originalPrice!.toStringAsFixed(0)}',
            style: originalPriceStyle ?? AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (showBadge)
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
