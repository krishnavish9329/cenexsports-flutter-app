import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable rating display widget
class RatingWidget extends StatelessWidget {
  final double rating;
  final int reviews;
  final double starSize;
  final bool showReviews;
  
  const RatingWidget({
    super.key,
    required this.rating,
    this.reviews = 0,
    this.starSize = 16,
    this.showReviews = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.star,
                size: starSize,
                color: Colors.white,
              ),
            ],
          ),
        ),
        if (showReviews && reviews > 0)
          Text(
            '($reviews)',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
