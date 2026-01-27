import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../core/providers/wishlist_provider.dart';
import '../widgets/product_card.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive_helper.dart';
import 'product_detail_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3),
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: const Color(0xFFF7F7F5),
        automaticallyImplyLeading: false, // Don't show back button in main tab
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          final products = wishlistProvider.items;

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Your wishlist is empty',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Save items you love to view them here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
                final padding = ResponsiveHelper.getPadding(context);
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: padding,
                    mainAxisSpacing: padding,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              productId: int.parse(product.id),
                            ),
                          ),
                        );
                      },
                      isWishlisted: true,
                      onWishlistTap: () {
                        wishlistProvider.removeFromWishlist(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} removed from wishlist'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
