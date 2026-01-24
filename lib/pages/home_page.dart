import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<Product> _onSaleProducts = [];
  List<Product> _bestSellers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isScrolled = false;
  
  // Timer state
  Timer? _flashSaleTimer;
  Duration _remainingTime = const Duration(hours: 1, minutes: 18, seconds: 23);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startFlashSaleTimer();
    _loadProducts();
  }
  
  void _startFlashSaleTimer() {
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          } else {
            _flashSaleTimer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        // Products on sale (with discount > 0)
        _onSaleProducts = products.where((p) => p.discount > 0).take(10).toList();
        _bestSellers = products.where((p) => p.isBestSeller).take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        // No fallback - show empty state
        _products = [];
        _onSaleProducts = [];
        _bestSellers = [];
      });
    }
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _flashSaleTimer?.cancel();
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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadProducts,
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
              backgroundColor: Colors.white,
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
          // Promotional Banner
          SliverToBoxAdapter(
            child: _buildPromotionalBanner(context),
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
              )
          else if (_onSaleProducts.isNotEmpty)
              SliverToBoxAdapter(
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    SectionHeader(
                    title: 'On Sale',
                      actionLabel: 'See All',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryPage(
                            categoryName: 'On Sale',
                            products: _onSaleProducts,
                          ),
                          ),
                        );
                      },
                    ),
                    LayoutBuilder(
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
                          itemCount: _onSaleProducts.length > 2 ? 2 : _onSaleProducts.length,
                            itemBuilder: (context, index) {
                            final product = _onSaleProducts[index];
                              return Container(
                                width: itemWidth,
                                margin: EdgeInsets.only(
                                  right: ResponsiveHelper.getPadding(context),
                                ),
                              child: _buildOnSaleProductCard(product),
                              );
                            },
                          ),
                        );
                      },
                            ),
                          ],
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

            // All Products Section - Responsive Grid
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
                        childCount: crossAxisCount * 3, // Show 3 rows
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppTheme.spacingM,
                        right: AppTheme.spacingM,
                        top: 0,
                        bottom: AppTheme.spacingM,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Products',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.black87,
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
                              foregroundColor: const Color(0xFFFAECEC),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                        final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
                        final padding = ResponsiveHelper.getPadding(context);
                        final itemCount = _products.length > (crossAxisCount * 4) 
                            ? crossAxisCount * 4 
                            : _products.length;
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
                              final product = _products[index];
                              return ProductCard(
                                product: product,
                                onTap: () => _navigateToProductDetail(product),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],
                          ),
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
      color: Colors.white,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchPage()),
                          );
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

  Widget _buildPromotionalBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveHelper.getPadding(context);
        final fontScale = ResponsiveHelper.getFontScale(context);
        final isCompact = width < 360;
        final effectiveFontScale = fontScale * (isCompact ? 0.9 : 1.0);
        final bannerHeight = (width * 0.40)
            .clamp(160.0, 200.0)
            .toDouble();
        final imageWidth = (width * 0.35)
            .clamp(120.0, 180.0)
            .toDouble();
        final iconSize = (imageWidth * 0.6).clamp(48.0, 88.0).toDouble();
        final horizontalPadding = padding;

        return Container(
          margin: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            bottom: 0,
          ),
          height: bannerHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF5E6E6),
                const Color(0xFFF0D9D9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content on the left
              Positioned(
                left: horizontalPadding,
                top: 0,
                bottom: 0,
                right: imageWidth + horizontalPadding,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Collection Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D4037),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'New Collection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11 * effectiveFontScale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Discount Text
                      Text(
                        'Enjoy 20%\nDiscount',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 22 * effectiveFontScale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4037),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Shop Now Button
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Shop Now',
                                style: TextStyle(
                                  fontSize: 13 * effectiveFontScale,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_ios, size: 12 * effectiveFontScale, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Image on the right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: imageWidth,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/promo_model.jpg',
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
      },
    );
  }


  Widget _buildCategoriesSection(BuildContext context, AsyncValue<List<CategoryModel>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }
        final padding = ResponsiveHelper.getPadding(context);
        final categoryItemSize = ResponsiveHelper.getCategoryItemSize(context);
        // Some OEM devices (and accessibility settings) use larger textScaleFactor.
        // Give the horizontal category list enough height to avoid RenderFlex overflow.
        final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 2.0);
        final labelFontSize = 12.0 * textScale;
        final labelHeight = labelFontSize * 1.25; // approximate line-height
        final categoryListHeight = (categoryItemSize + 6 + labelHeight + 10).clamp(92.0, 220.0).toDouble();

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
                  const Expanded(
                    child: Text(
                      'Shop by Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
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
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildOnSaleProductCard(Product product) {
    return ProductCard(
      product: product,
      onTap: () => _navigateToProductDetail(product),
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
