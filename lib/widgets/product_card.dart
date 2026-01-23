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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
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
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[100],
                                    child: Icon(Icons.image_not_supported, size: fallbackIconSize, color: Colors.grey[400]),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: Icon(Icons.image, size: fallbackIconSize, color: Colors.grey[400]),
                                ),
                          // Category badge
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.category.isNotEmpty ? product.category : 'Product',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                            ),
                          ),
                          // Discount badge
                          if (product.discount > 0)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5D4037),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${product.discount}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
                        left: tightLayout ? 10 : 12,
                        right: tightLayout ? 10 : 12,
                        top: tightLayout ? 8 : 10,
                        bottom: tightLayout ? 8 : 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                maxLines: tightLayout ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              PriceWidget(
                                price: product.price,
                                originalPrice: product.originalPrice > product.price ? product.originalPrice : null,
                                discount: null,
                                priceStyle: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: tightLayout ? (isCompact ? 28 : 32) : (isCompact ? 30 : 34),
                            child: ElevatedButton.icon(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: Icon(
                                Icons.add_shopping_cart,
                                size: buttonIconSize,
                                color: Colors.white,
                              ),
                              label: Flexible(
                                child: Text(
                                  'Add to Cart',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
