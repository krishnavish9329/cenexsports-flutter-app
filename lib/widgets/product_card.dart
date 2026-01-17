import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../core/theme/app_theme.dart';
import 'price_widget.dart';

/// Modern, clean product card widget matching the design reference
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          // Image Section with Overlays - wrapped in InkWell for tap
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusM),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusM),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  product.imageUrl,
                                  style: const TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Category Label (Top Left) - like "Home" in reference image
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      product.category.isNotEmpty ? product.category : 'Product',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8B6F47), // Brown/gold color like reference
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Discount Badge (Top Left, only if discount exists and won't overlap)
                if (product.discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      margin: const EdgeInsets.only(top: 20), // Space for category label
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037), // Dark brown like reference
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Wishlist Heart Icon (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Implement wishlist functionality
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product Info Section - Compact to prevent overflow
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price Only (Rating removed as per requirement)
                  PriceWidget(
                    price: product.price,
                    originalPrice: product.originalPrice > product.price ? product.originalPrice : null,
                    discount: null, // Don't show discount badge here, already shown on image
                    priceStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}
