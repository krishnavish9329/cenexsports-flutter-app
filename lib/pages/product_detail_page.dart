import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart' as provider;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/price_widget.dart';
import '../widgets/rating_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/product_card.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/cart_provider.dart';
import 'cart_page.dart';
import '../presentation/pages/email_checkout_page.dart';
import '../presentation/pages/checkout_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  String? _selectedSize;
  String? _selectedColor;
  List<Product> _relatedProducts = [];
  bool _isRelatedLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await ApiService.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });

      // Load related products based on category
      _loadRelatedProducts(product.category);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRelatedProducts(String categoryName) async {
    setState(() {
      _isRelatedLoading = true;
    });

    try {
      // Fetch all products and filter by same category
      final allProducts = await ApiService.getProducts();
      final related = allProducts
          .where((p) => p.category == categoryName && p.id != _product?.id)
          .take(8)
          .toList();

      setState(() {
        _relatedProducts = related;
        _isRelatedLoading = false;
      });
    } catch (_) {
      // Silently ignore related errors
      setState(() {
        _relatedProducts = [];
        _isRelatedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                _errorMessage ?? 'Product not found',
                style: AppTextStyles.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton.icon(
                onPressed: _loadProduct,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final images = [product.imageUrl]; // In real app, get multiple images from API

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Image Carousel
                _buildImageCarousel(images),
                
                // Product Info
            Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      // Badges
                  if (product.isNew || product.isBestSeller)
                        Wrap(
                          spacing: AppTheme.spacingS,
                      children: [
                        if (product.isNew)
                              _buildBadge('NEW', AppTheme.successColor),
                            if (product.isBestSeller)
                              _buildBadge('BESTSELLER', AppTheme.warningColor),
                          ],
                        ),
                      if (product.isNew || product.isBestSeller)
                        const SizedBox(height: AppTheme.spacingM),
                      
                      // Product Name
                      Text(
                        product.name,
                        style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      const SizedBox(height: AppTheme.spacingS),
                      
                      // Rating & Reviews
                      Row(
                        children: [
                          RatingWidget(
                            rating: product.rating,
                            reviews: product.reviews,
                            starSize: 18,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              '${product.reviews} Reviews',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                      ],
                    ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Price
                      PriceWidget(
                        price: product.price,
                        originalPrice: product.originalPrice > product.price ? product.originalPrice : null,
                        discount: product.discount > 0 ? product.discount : null,
                        priceStyle: AppTextStyles.h1.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Availability
                  Row(
                    children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                            Text(
                            'In Stock',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Size Selector (only if product has sizes)
                      if (product.sizes != null && product.sizes!.isNotEmpty)
                        _buildSizeSelector(product.sizes!),
                      
                      // Color Selector (only if product has colors)
                      if (product.colors != null && product.colors!.isNotEmpty)
                        _buildColorSelector(product.colors!),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Description
                      _buildDescription(product.description),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Specifications
                      _buildSpecifications(product),

                      const SizedBox(height: AppTheme.spacingL),

                      // Related products (same category)
                      _buildRelatedSection(),

                      const SizedBox(height: 100), // Space for sticky buttons
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Back Button - Top Left
          SafeArea(
            child: Positioned(
              top: 0,
              left: 0,
              child: Container(
                margin: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          // Sticky Bottom CTA Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyButtons(product),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: images.length,
          itemBuilder: (context, index, realIndex) {
            final imageUrl = images[index];
            return Hero(
              tag: 'product_${widget.productId}_$index',
              child: ClipRRect(
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => const SkeletonLoader(
                          width: double.infinity,
                          height: 400,
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 400,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        height: 400,
                        color: Colors.grey[200],
                        child: Center(
                        child: Text(
                            imageUrl,
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                      ),
              ),
            );
          },
          options: CarouselOptions(
            height: 400,
            viewportFraction: 1.0,
            autoPlay: images.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _currentImageIndex,
                count: images.length,
                effect: const WormEffect(
                  dotColor: Colors.white70,
                  activeDotColor: Colors.white,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
    );
  }

  Widget _buildSizeSelector(List<String> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          children: sizes.map((size) {
            final isSelected = _selectedSize == size;
            return ChoiceChip(
              label: Text(size),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSize = selected ? size : null;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector(List<Map<String, dynamic>> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingM),
        Text(
          'Color',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          children: colors.map((colorData) {
            final colorName = colorData['name'] as String;
            final color = colorData['color'] as Color;
            final isSelected = _selectedColor == colorName;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = colorName;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(
            height: 1.5,
            color: Colors.grey[700],
          ),
          maxLines: _isDescriptionExpanded ? null : 3,
          overflow: _isDescriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (description.length > 100)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Read less' : 'Read more',
              ),
            ),
          ],
    );
  }

  Widget _buildSpecifications(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildSpecItem('Category', product.category),
        _buildSpecItem('Rating', '${product.rating} / 5.0'),
        _buildSpecItem('Reviews', '${product.reviews} reviews'),
        if (product.discount > 0)
          _buildSpecItem('Discount', '${product.discount}% OFF'),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSection() {
    if (_isRelatedLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingM),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Products',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacingM),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _relatedProducts.length,
            padding: const EdgeInsets.only(right: AppTheme.spacingM),
            itemBuilder: (context, index) {
              final related = _relatedProducts[index];
              return Container(
                width: 180,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : AppTheme.spacingM,
                ),
                child: ProductCard(
                  product: related,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          productId: int.parse(related.id),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStickyButtons(Product product) {
    final cartProvider = provider.Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(product.id);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  cartProvider.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isInCart
                            ? '${product.name} updated in cart'
                            : '${product.name} added to cart',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(
                        bottom: 100,
                        left: 16,
                        right: 16,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isInCart ? Icons.check : Icons.shopping_cart_outlined,
                ),
                label: Text(isInCart ? 'In Cart' : 'Add to Cart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (!isInCart) {
                    cartProvider.addToCart(product);
                  }
                  
                  // Check if user is logged in
                  final authState = ref.read(authProvider);
                  
                  if (authState.isAuthenticated) {
                    // Navigate directly to checkout
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutPage(),
                      ),
                    );
                  } else {
                    // Navigate to email-first checkout for login/guest
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmailCheckoutPage(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Buy at ₹${product.price.toStringAsFixed(0)}',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
