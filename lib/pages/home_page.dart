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
import '../widgets/price_widget.dart';
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
    // Expanded: top row + search bar.
    final collapsed = _getHeaderCollapsedHeight(context);
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.6);
    const searchBarHeight = 44.0;
    final extraForTextScale = (textScale - 1.0) * 10.0;
    return collapsed + AppTheme.spacingS + searchBarHeight + AppTheme.spacingS + extraForTextScale;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = provider_package.Provider.of<CartProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final collapsedHeaderHeight = _getHeaderCollapsedHeight(context);
    final expandedHeaderHeight = _getHeaderExpandedHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadProducts,
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
                    SectionHeader(
                      title: 'All Products',
                      actionLabel: 'See All',
                      onActionTap: () {
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
        bottom: 0,
      ),
      child: Column(
        children: [
          // Location and Icons Row
          Row(
            children: [
              // App Logo + Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'cenexsports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Shopping Bag
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartPage()),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
        child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
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
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
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
                  const SizedBox(height: AppTheme.spacingS),
                  IgnorePointer(
                    ignoring: expandFactor < 0.05,
                    child: Opacity(
                      opacity: expandFactor,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SearchPage()),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, size: 20, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ruched top',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.mic, size: 20, color: Colors.grey),
                                  ],
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
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveHelper.getPadding(context);
        final fontScale = ResponsiveHelper.getFontScale(context);
        final isCompact = width < 360;
        final effectiveFontScale = fontScale * (isCompact ? 0.9 : 1.0);
        final bannerHeight = (width * (isCompact ? 0.52 : 0.42))
            .clamp(isCompact ? 180.0 : 150.0, 240.0)
            .toDouble();
        final imageWidth = (width * (isCompact ? 0.28 : 0.32))
            .clamp(isCompact ? 80.0 : 96.0, 160.0)
            .toDouble();
        final iconSize = (imageWidth * 0.6).clamp(48.0, 88.0).toDouble();
        final horizontalPadding = isCompact ? 12.0 : padding;
        final timerPadding = EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 3 : 4,
        );

        return Container(
          margin: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: horizontalPadding,
          ),
          height: bannerHeight,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5E6E6), // Light dusty pink (matches poster image tone)
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding * 0.5,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // New Collection Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D4037),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'New Collection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12 * effectiveFontScale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : AppTheme.spacingS),
                          // Discount Text
                          Text(
                            'Enjoy 20% Discount',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20 * effectiveFontScale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : AppTheme.spacingS),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Shop Now',
                                    style: TextStyle(
                                      fontSize: 14 * effectiveFontScale,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 16 * effectiveFontScale, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : AppTheme.spacingM),
                          // Countdown Timer
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Flash sale ends',
                                style: TextStyle(
                                  fontSize: 12 * effectiveFontScale,
                                  color: Colors.black54,
                                ),
                              ),
                              _buildTimerBox(
                                _formatDuration(_remainingTime.inHours),
                                fontSize: 14 * effectiveFontScale,
                                padding: timerPadding,
                              ),
                              Text(' : ', style: TextStyle(fontSize: 14 * effectiveFontScale, fontWeight: FontWeight.bold)),
                              _buildTimerBox(
                                _formatDuration(_remainingTime.inMinutes.remainder(60)),
                                fontSize: 14 * effectiveFontScale,
                                padding: timerPadding,
                              ),
                              Text(' : ', style: TextStyle(fontSize: 14 * effectiveFontScale, fontWeight: FontWeight.bold)),
                              _buildTimerBox(
                                _formatDuration(_remainingTime.inSeconds.remainder(60)),
                                fontSize: 14 * effectiveFontScale,
                                padding: timerPadding,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: imageWidth,
                height: bannerHeight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppTheme.radiusL),
                    bottomRight: Radius.circular(AppTheme.radiusL),
                  ),
                  child: Image.asset(
                    'assets/images/promo_model.jpg',
                    fit: BoxFit.cover,
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

  Widget _buildTimerBox(
    String value, {
    double fontSize = 14,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
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
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: AppTheme.spacingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Shop by Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                        color: Colors.black54,
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
            // Circular Icon/Image
            Container(
              width: size,
              height: size,
                decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: category.imageSrc != null && category.imageSrc!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: category.imageSrc!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category,
                          size: size * 0.38,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Icon(Icons.category, size: size * 0.38, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            // Category Name
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                    fontWeight: FontWeight.w500,
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

  void _addToCart(Product product) {
    provider_package.Provider.of<CartProvider>(context, listen: false).addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(int value) {
    return value.toString().padLeft(2, '0');
  }
}
