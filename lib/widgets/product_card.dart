import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/cart_provider.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 160;
        final textScale = MediaQuery.textScaleFactorOf(context);
        final tightLayout = isCompact || textScale > 1.15;
        final buttonFontSize = isCompact ? 10.0 : 12.0;
        final buttonIconSize = isCompact ? 14.0 : 16.0;
        final imageUrl = product.imageUrl.trim();
        final isNetworkImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
        final fallbackIconSize = (constraints.maxWidth * 0.35).clamp(28.0, 48.0);
        // Make image taller like the reference by giving it a fixed fraction
        // of the grid tile height (instead of AspectRatio > 1 which makes it short).
        // Keep image tall like reference, but give enough room to text/button to avoid overflow.
        final imageFlex = isCompact ? 64 : 66; // ~65% height to image
        final infoFlex = 100 - imageFlex;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 6),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity, // fill the Grid tile -> removes fake "extra gap"
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: imageFlex,
                    child: InkWell(
                      onTap: onTap,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isNetworkImage
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image_not_supported, size: fallbackIconSize, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, size: fallbackIconSize, color: Colors.grey),
                                ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                product.category.isNotEmpty ? product.category : 'Product',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8B6F47),
                                  fontStyle: FontStyle.italic,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (product.discount > 0)
                            Positioned(
                              top: 28,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5D4037),
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
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: infoFlex,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: tightLayout ? 12 : AppTheme.spacingM,
                        right: tightLayout ? 12 : AppTheme.spacingM,
                        top: tightLayout ? 6 : 8,
                        bottom: tightLayout ? 4 : 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.15,
                            ),
                            maxLines: tightLayout ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          PriceWidget(
                            price: product.price,
                            originalPrice: product.originalPrice > product.price ? product.originalPrice : null,
                            discount: null,
                            priceStyle: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (!tightLayout) const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: tightLayout ? (isCompact ? 26 : 28) : (isCompact ? 26 : 30),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Provider.of<CartProvider>(context, listen: false).addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
                                    backgroundColor: AppTheme.successColor,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: Icon(
                                Icons.add_shopping_cart,
                                size: buttonIconSize,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Flexible(
                                child: Text(
                                  'Add to Cart',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom black line
                  const SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
