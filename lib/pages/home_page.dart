import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_loader.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive_helper.dart';
import '../core/providers/cart_provider.dart';
import 'product_detail_page.dart';
import 'category_page.dart';
import 'cart_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _bestSellers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
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
        _featuredProducts = products.where((p) => p.isNew).take(10).toList();
        _bestSellers = products.where((p) => p.isBestSeller).take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        // No fallback - show empty state
        _products = [];
        _featuredProducts = [];
        _bestSellers = [];
      });
    }
  }

  /// Get categories list (extracted from products)
  List<String> _getCategories() {
    // Extract unique categories from products
    final categories = _products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList();
    if (categories.isEmpty) {
      return ['All Products']; // Default category if no products
    }
    return ['All Products', ...categories];
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'cenexsports',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [

          Stack(
            children: [
          IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Sticky Search Bar
            SliverAppBar(
              pinned: true,
              floating: false,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: _isScrolled ? 1 : 0,
              toolbarHeight: MediaQuery.of(context).size.height * 0.09, // Responsive toolbar height
              flexibleSpace: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
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
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _searchController,
                            decoration: InputDecoration(
                            hintText: 'Search for products, brands and more',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.camera_alt_outlined),
                                onPressed: () {},
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            
            // Categories Section - Responsive
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final categorySize = ResponsiveHelper.getCategoryItemSize(context);
                  return Container(
                    height: categorySize + AppTheme.spacingM * 2,
                    margin: EdgeInsets.symmetric(
                      vertical: AppTheme.spacingM,
                      horizontal: ResponsiveHelper.getPadding(context),
                    ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _getCategories().length,
              itemBuilder: (context, index) {
                final category = _getCategories()[index];
                        return _buildCategoryItem(category, categorySize);
                      },
                    ),
                  );
              },
            ),
          ),

            // Featured Products Section - Responsive
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
                        itemCount: 3,
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
            else if (_featuredProducts.isNotEmpty)
              SliverToBoxAdapter(
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    SectionHeader(
                      title: 'Featured Products',
                      actionLabel: 'See All',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryPage(
                              categoryName: 'Featured',
                              products: _featuredProducts,
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
                            itemCount: _featuredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _featuredProducts[index];
                              return Container(
                                width: itemWidth,
                                margin: EdgeInsets.only(
                                  right: ResponsiveHelper.getPadding(context),
                                ),
                                child: ProductCard(
                                  product: product,
                                  onTap: () => _navigateToProductDetail(product),
                                ),
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

  Widget _buildCategoryItem(String category, double size) {
      return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(
              categoryName: category,
              products: _products.where((p) => p.category == category || category == 'All' || category == 'For You').toList(),
            ),
          ),
        );
      },
      child: Container(
        width: size,
        margin: EdgeInsets.only(
          right: ResponsiveHelper.getPadding(context) * 0.5,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
          ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
            children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(size * 0.15),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  size: size * 0.3,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingS),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                category,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                  maxLines: 2,
                overflow: TextOverflow.ellipsis,
                ),
              ),
              ),
            ],
          ),
        ),
      );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.apps;
      case 'For You':
        return Icons.favorite_border;
      case 'Fashion':
        return Icons.checkroom;
      case 'Mobiles':
        return Icons.smartphone;
      case 'Beauty':
        return Icons.face;
      case 'Electronics':
        return Icons.devices;
      case 'Home':
        return Icons.home;
      default:
        return Icons.category;
    }
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
    Provider.of<CartProvider>(context, listen: false).addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
