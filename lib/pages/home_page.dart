import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_loader.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive_helper.dart';
import '../core/providers/cart_provider.dart';
import '../presentation/providers/category_provider.dart';
import '../data/models/category_model.dart';
import 'product_detail_page.dart';
import 'category_page.dart';
import 'cart_page.dart';
import 'search_page.dart';
import 'main_navigation.dart';
import '../presentation/pages/categories/categories_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<Product> _bestSellers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isScrolled = false;
  int _bannerIndex = 0;
  // Flash sale timer state
  Duration _flashSaleDuration = const Duration(hours: 3, minutes: 15, seconds: 20);
  // Pagination for All Products
  int _displayedProductsCount = 0;
  bool _isLoadingMore = false;
  final int _productsPerPage = 5; // 5 rows at a time

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_onProductsScroll);
    _loadProducts();
    _startFlashSaleTimer();
  }
  
  void _onProductsScroll() {
    if (!_scrollController.hasClients) return;
    
    // Calculate if user is near bottom (80% scrolled)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;
    
    // Load more products when near bottom and not already loading
    if (currentScroll >= threshold && 
        !_isLoadingMore && 
        _displayedProductsCount < _products.length) {
      _loadMoreProducts();
    }
  }
  
  void _loadMoreProducts() {
    if (_isLoadingMore || _displayedProductsCount >= _products.length) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Simulate loading delay for smooth UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && context.mounted) {
        setState(() {
          // Calculate products per row based on screen width
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 2);
          final productsPerRow = crossAxisCount;
          final productsToAdd = productsPerRow * _productsPerPage; // 5 rows
          
          _displayedProductsCount = (_displayedProductsCount + productsToAdd)
              .clamp(0, _products.length);
          _isLoadingMore = false;
        });
      }
    });
  }
  
  void _startFlashSaleTimer() {
    // Update timer every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_flashSaleDuration.inSeconds > 0) {
            _flashSaleDuration = Duration(seconds: _flashSaleDuration.inSeconds - 1);
          } else {
            _flashSaleDuration = const Duration(hours: 24); // Reset to 24 hours when expired
          }
        });
        _startFlashSaleTimer();
      }
    });
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load products with caching (forceRefresh only when user manually refreshes)
      final products = await ApiService.getProducts(forceRefresh: forceRefresh);
      setState(() {
        _products = products;
        _bestSellers = products.where((p) => p.isBestSeller).take(10).toList();
        _isLoading = false;
        // Initialize displayed products count (5 rows initially) - use default if context not available
        if (_displayedProductsCount == 0) {
          // Default to 2 columns, 5 rows = 10 products initially
          final defaultProductsPerRow = 2;
          _displayedProductsCount = (defaultProductsPerRow * _productsPerPage).clamp(0, products.length);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        // No fallback - show empty state
        _products = [];
        _bestSellers = [];
      });
    }
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_onProductsScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isScrolled = _scrollController.offset > 50;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    }
  }

  double _getHeaderCollapsedHeight(BuildContext context) {
    // Collapsed: only top row (logo + icons).
    final topPadding = MediaQuery.of(context).padding.top;
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.6);
    // kToolbarHeight is a good baseline for icon buttons row.
    return topPadding + (kToolbarHeight + (textScale - 1.0) * 12.0);
  }

  double _getHeaderExpandedHeight(BuildContext context) {
    // Expanded: top row + search bar + spacing.
    final collapsed = _getHeaderCollapsedHeight(context);
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.6);
    // Search bar: padding (12*2) + content height (~20) = ~44, plus spacing
    const searchBarHeight = 44.0; // vertical padding 12*2 + icon/text height ~20
    final extraForTextScale = (textScale - 1.0) * 10.0;
    // Top spacing + search bar + bottom spacing
    return collapsed + AppTheme.spacingM + searchBarHeight + AppTheme.spacingM + extraForTextScale;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = provider_package.Provider.of<CartProvider>(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final collapsedHeaderHeight = _getHeaderCollapsedHeight(context);
    final expandedHeaderHeight = _getHeaderExpandedHeight(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(forceRefresh: true),
        child: ScrollbarTheme(
          data: const ScrollbarThemeData(
            thickness: MaterialStatePropertyAll(0),
          ),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
          // Custom Header with Location and Icons
            SliverAppBar(
              pinned: true,
              floating: false,
              primary: false,
              backgroundColor: const Color(0xFFF7F7F5),
              elevation: _isScrolled ? 1 : 0,
              automaticallyImplyLeading: false,
              collapsedHeight: collapsedHeaderHeight,
              expandedHeight: expandedHeaderHeight,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final currentHeight = constraints.biggest.height;
                  final t = ((currentHeight - collapsedHeaderHeight) /
                          (expandedHeaderHeight - collapsedHeaderHeight))
                      .clamp(0.0, 1.0);
                  return _buildCustomHeader(context, cartProvider, expandFactor: t);
                },
              ),
            ),
          // Banner Slider
          SliverToBoxAdapter(
            child: _buildBannerSlider(context),
          ),
          // Add spacing between banner and categories
          SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingL),
          ),
          // Shop by Categories Section
          SliverToBoxAdapter(
            child: _buildCategoriesSection(context, categoriesAsync),
          ),
          // On Sale Section
          if (_isLoading)
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = ResponsiveHelper.getHorizontalListItemWidth(context);
                    final listHeight = ResponsiveHelper.getHorizontalListHeight(context);
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: listHeight,
                        minHeight: 280,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getPadding(context),
                        ),
                      itemCount: 2,
                        itemBuilder: (context, index) => Container(
                          width: itemWidth,
                          margin: EdgeInsets.only(
                            right: ResponsiveHelper.getPadding(context),
                          ),
                          child: const ProductCardSkeleton(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Best Sellers Section - Responsive Grid
            if (_isLoading)
              SliverPadding(
                padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                    final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: ResponsiveHelper.getPadding(context),
                        mainAxisSpacing: ResponsiveHelper.getPadding(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ProductCardSkeleton(),
                        childCount: crossAxisCount * 2, // Show 2 rows
                      ),
                    );
                  },
                ),
              )
            else if (_bestSellers.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Best Sellers',
                      actionLabel: 'See All',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryPage(
                              categoryName: 'Best Sellers',
                              products: _bestSellers,
                            ),
                          ),
                        );
                      },
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                        final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
                        final padding = ResponsiveHelper.getPadding(context);
                        final itemCount = _bestSellers.length > (crossAxisCount * 2) 
                            ? crossAxisCount * 2 
                            : _bestSellers.length;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: padding),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: aspectRatio,
                              crossAxisSpacing: padding,
                              mainAxisSpacing: padding,
                            ),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              final product = _bestSellers[index];
                              return ProductCard(
                                product: product,
                                onTap: () => _navigateToProductDetail(product),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // All Products Section - Infinite Scroll Grid
            if (_isLoading)
              SliverPadding(
                padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                    final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
                    final padding = ResponsiveHelper.getPadding(context);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: padding,
                        mainAxisSpacing: padding,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ProductCardSkeleton(),
                        childCount: crossAxisCount * 5, // Show 5 rows initially
                      ),
                    );
                  },
                ),
              )
            else if (_errorMessage != null && _products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                        'Error loading products',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      ElevatedButton.icon(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'No products found',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Check back later for new products',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spacingM,
                    right: AppTheme.spacingM,
                    top: 0,
                    bottom: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Products',
                        style: AppTextStyles.h3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryPage(
                                categoryName: 'All Products',
                                products: _products,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // All Products Grid with Infinite Scroll
            if (!_isLoading && _products.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                    final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
                    final padding = ResponsiveHelper.getPadding(context);
                    
                    // Ensure displayed count is initialized
                    if (_displayedProductsCount == 0) {
                      final productsPerRow = crossAxisCount;
                      _displayedProductsCount = (productsPerRow * _productsPerPage).clamp(0, _products.length);
                    }
                    
                    final itemCount = _displayedProductsCount.clamp(0, _products.length);
                    
                    // If no items to show, show at least some products
                    final actualItemCount = itemCount > 0 ? itemCount : _products.length.clamp(0, crossAxisCount * _productsPerPage);
                    
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: padding,
                        mainAxisSpacing: padding,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < _products.length) {
                            final product = _products[index];
                            return ProductCard(
                              product: product,
                              onTap: () => _navigateToProductDetail(product),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: actualItemCount,
                      ),
                    );
                  },
                ),
              ),
            // Loading more indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            // Bottom spacing
            if (!_isLoading && _products.isNotEmpty)
              SliverToBoxAdapter(
                child: const SizedBox(height: AppTheme.spacingL),
              ),
        ],
        ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(
    BuildContext context,
    CartProvider cartProvider, {
    double expandFactor = 1.0,
  }) {
    return Container(
      color: const Color(0xFFF7F7F5),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        bottom: 0, // No bottom padding - spacing handled by SliverToBoxAdapter
      ),
      child: Column(
        children: [
          // Top Row: Logo and Icons
          Row(
            children: [
              // App Logo + Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.shopping_bag, size: 16, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'cenexsports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Shopping Bag
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartPage()),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cartProvider.itemCount > 9 ? '9+' : '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Bell Icon
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 24),
                onPressed: () {},
              ),
            ],
          ),
          // Search Bar (collapses on scroll)
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: expandFactor,
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.spacingM),
                  IgnorePointer(
                    ignoring: expandFactor < 0.05,
                    child: Opacity(
                      opacity: expandFactor,
                      child: GestureDetector(
                        onTap: () {
                          // Try to find MainNavigation in the widget tree and switch to search tab
                          final mainNav = MainNavigationProvider.of(context);
                          if (mainNav != null) {
                            // We're inside MainNavigation, just switch tabs
                            mainNav.switchToTab(2); // 2 = Search tab
                          } else {
                            // Not inside MainNavigation, navigate to it with search tab
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainNavigation(initialIndex: 2),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search products...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Icon(Icons.mic, size: 20, color: Colors.grey[400]),
                            ],
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
    );
  }

  Widget _buildBannerSlider(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(context);
    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding, top: 0, bottom: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fontScale = ResponsiveHelper.getFontScale(context);
          final isCompact = width < 360;
          final effectiveFontScale = fontScale * (isCompact ? 0.9 : 1.0);
          // Increased banner height to prevent overflow and accommodate all content
          final bannerHeight = (width * 0.45).clamp(180.0, 220.0).toDouble();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: bannerHeight,
                child: CarouselSlider.builder(
                  itemCount: 3,
                  itemBuilder: (context, index, realIndex) {
                    // Always use index (0, 1, 2) to ensure correct banner content
                    // realIndex can be null or different due to infinite scroll
                    final bannerIndex = index % 3; // Ensure it's always 0, 1, or 2
                    return _buildBannerSlide(
                      context, 
                      width, 
                      bannerHeight, 
                      effectiveFontScale, 
                      bannerIndex,
                    );
                  },
                  options: CarouselOptions(
                    height: bannerHeight,
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    enableInfiniteScroll: false, // Disable to ensure correct index mapping
                    autoPlay: false,
                    onPageChanged: (index, reason) {
                      if (mounted) setState(() => _bannerIndex = index);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSmoothIndicator(
                activeIndex: _bannerIndex,
                count: 3,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 4,
                  spacing: 6,
                  activeDotColor: const Color(0xFF5D4037),
                  dotColor: const Color(0xFF5D4037).withOpacity(0.3),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerSlide(BuildContext context, double width, double bannerHeight, double effectiveFontScale, int slideIndex) {
    // Different content for each banner slide - ensure unique content per banner
    // Map of banner data - each index has unique content
    final Map<String, String> currentBanner;
    
    // Explicitly set content and image based on slideIndex (0, 1, or 2)
    String bannerImage;
    switch (slideIndex % 3) {
      case 0:
        currentBanner = {
          'badge': 'New Collection',
          'discount': '20%',
          'headline': 'Enjoy 20% Discount',
        };
        bannerImage = 'assets/images/promo_model.jpg';
        break;
      case 1:
        currentBanner = {
          'badge': 'Summer Sale',
          'discount': '30%',
          'headline': 'Enjoy 30% Discount',
        };
        bannerImage = 'assets/images/promo_model_2.png';
        break;
      case 2:
        currentBanner = {
          'badge': 'Flash Sale',
          'discount': '25%',
          'headline': 'Enjoy 25% Discount',
        };
        bannerImage = 'assets/images/promo_model.jpg';
        break;
      default:
        currentBanner = {
          'badge': 'New Collection',
          'discount': '20%',
          'headline': 'Enjoy 20% Discount',
        };
        bannerImage = 'assets/images/promo_model.jpg';
    }
    
    final validIndex = slideIndex % 3;
    
    // Responsive calculations
    final horizontalPadding = (width * 0.04).clamp(12.0, 20.0).toDouble();
    final imageWidth = (width * 0.38).clamp(100.0, 160.0).toDouble();
    final iconSize = (imageWidth * 0.6).clamp(48.0, 88.0).toDouble();
    
    // Calculate available height for content (accounting for padding)
    final contentHeight = bannerHeight - (horizontalPadding * 2);
    final isCompact = bannerHeight < 180;
    
    // Responsive font scaling based on available space
    final baseFontScale = isCompact ? 0.85 : 1.0;
    final adjustedFontScale = effectiveFontScale * baseFontScale;
    
    // Premium color palette - soft pastels with premium accents
    const primaryBrown = Color(0xFF5D4037);
    const accentPink = Color(0xFFC97A7A); // Reddish-brown/pink for discount
    const lightPinkBg = Color(0xFFF5E6E6);
    const darkerPinkBg = Color(0xFFF0D9D9);
    
    // Responsive spacing
    final smallSpacing = isCompact ? 6.0 : 8.0;
    final mediumSpacing = isCompact ? 10.0 : 12.0;
    final largeSpacing = isCompact ? 12.0 : 14.0;
    
    return Container(
      key: ValueKey('banner_$validIndex'), // Unique key for each banner (0, 1, 2)
      width: width,
      height: bannerHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightPinkBg, darkerPinkBg],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left content section - responsive with constraints
          Positioned(
            left: horizontalPadding,
            top: horizontalPadding,
            bottom: horizontalPadding,
            right: imageWidth + horizontalPadding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium "New Collection" badge - pill-shaped
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * adjustedFontScale,
                              vertical: 5 * adjustedFontScale,
                            ),
                            decoration: BoxDecoration(
                              color: primaryBrown,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentBanner['badge'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9 * adjustedFontScale,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: smallSpacing * adjustedFontScale),
                          // Premium headline - single line style matching reference
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 22 * adjustedFontScale,
                                  fontWeight: FontWeight.w800,
                                  color: primaryBrown,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                                children: [
                                  TextSpan(text: 'Enjoy '),
                                  TextSpan(
                                    text: currentBanner['discount'] as String,
                                    style: TextStyle(
                                      color: accentPink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const TextSpan(text: ' Discount'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: mediumSpacing * adjustedFontScale),
                          // Premium CTA button with enhanced shadow
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(
                                    categoryName: 'All Products',
                                    products: _products,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * adjustedFontScale,
                                vertical: 10 * adjustedFontScale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Shop Now',
                                    style: TextStyle(
                                      fontSize: 13 * adjustedFontScale,
                                      fontWeight: FontWeight.w700,
                                      color: primaryBrown,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 6 * adjustedFontScale),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12 * adjustedFontScale,
                                    color: primaryBrown,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: smallSpacing * adjustedFontScale),
                          // Flash sale timer - responsive and compact
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Flash sale ends ',
                                    style: TextStyle(
                                      fontSize: 10 * adjustedFontScale,
                                      fontWeight: FontWeight.w500,
                                      color: primaryBrown.withOpacity(0.7),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6 * adjustedFontScale,
                                      vertical: 3 * adjustedFontScale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryBrown.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatDuration(_flashSaleDuration),
                                      style: TextStyle(
                                        fontSize: 11 * adjustedFontScale,
                                        fontWeight: FontWeight.w700,
                                        color: primaryBrown,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
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
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: imageWidth,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                bannerImage,
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.person, size: iconSize, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCategoriesSection(BuildContext context, AsyncValue<List<CategoryModel>> categoriesAsync) {
    final padding = ResponsiveHelper.getPadding(context);
    final categoryItemSize = ResponsiveHelper.getCategoryItemSize(context);
    // Some OEM devices (and accessibility settings) use larger textScaleFactor.
    // Give the horizontal category list enough height to avoid RenderFlex overflow.
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 2.0);
    final labelFontSize = 12.0 * textScale;
    final labelHeight = labelFontSize * 1.25; // approximate line-height
    final categoryListHeight = (categoryItemSize + 6 + labelHeight + 10).clamp(92.0, 220.0).toDouble();

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          // Show header even if no categories
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: 0,
                  bottom: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Shop by Categories',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoriesScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: categoryListHeight,
                child: Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: padding,
                right: padding,
                top: 0,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Shop by Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: categoryListHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: padding),
                itemCount: categories.length > 10 ? 10 : categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCircularCategoryItem(category, categoryItemSize);
                },
              ),
            ),
          ],
        );
      },
      loading: () {
        // Show loading skeleton for categories
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: padding,
                right: padding,
                top: 0,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Shop by Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: categoryListHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: padding),
                itemCount: 8, // Show 8 skeleton items
                itemBuilder: (context, index) {
                  return Container(
                    width: categoryItemSize,
                    margin: const EdgeInsets.only(right: AppTheme.spacingM),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: categoryItemSize,
                          height: categoryItemSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: categoryItemSize * 0.6,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        // Show error state but still show the section header
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: padding,
                right: padding,
                top: 0,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Shop by Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: categoryListHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load categories',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircularCategoryItem(CategoryModel category, double size) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(
              categoryName: category.name,
              categoryId: category.id,
            ),
          ),
        );
      },
      child: Container(
        width: size,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Icon/Image with shadow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: category.imageSrc != null && category.imageSrc!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: category.imageSrc!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.category,
                            size: size * 0.35,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.category,
                        size: size * 0.35,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Category Name
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          productId: int.parse(product.id),
        ),
      ),
    );
  }

}
