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

class CategoryPage extends StatefulWidget {
  final String categoryName;
  final int? categoryId;
  final List<Product>? products; // Made optional, will fetch if categoryId is provided

  const CategoryPage({
    super.key,
    required this.categoryName,
    this.categoryId,
    this.products,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isGridView = true;
  String _sortBy = 'Default';
  String _filterBy = 'All';
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // If products are provided, use them
    if (widget.products != null) {
      setState(() {
        _products = widget.products!;
        _isLoading = false;
      });
      return;
    }

    // If categoryId is provided, fetch products by category
    if (widget.categoryId != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final products = await ApiService.getProductsByCategory(widget.categoryId!);
        setState(() {
          _products = products;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _products = [];
        });
      }
    } else {
      setState(() {
        _products = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    var products = List<Product>.from(_products);

    // Apply filter
    if (_filterBy != 'All') {
      products = products.where((p) => p.category == _filterBy).toList();
    }

    // Apply sort
    switch (_sortBy) {
      case 'Price: Low to High':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        products = products.reversed.toList();
        break;
      default:
        break;
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _products.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? _buildGridView()
                      : _buildListView(),
    );
  }

  Widget _buildGridView() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
        final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
        final padding = ResponsiveHelper.getPadding(context);
        
        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(padding),
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
              onTap: () => _navigateToProductDetail(product),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: _buildListProductCard(product),
        );
      },
    );
  }

  Widget _buildListProductCard(Product product) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Using AspectRatio for responsive sizing
            Flexible(
              flex: 0,
              child: SizedBox(
                width: 120,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusM),
                      bottomLeft: Radius.circular(AppTheme.radiusM),
                    ),
                    child: product.imageUrl.startsWith('http')
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  product.imageUrl,
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.h3.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No products found',
            style: AppTextStyles.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Try adjusting your filters',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Error loading products',
            style: AppTextStyles.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _errorMessage ?? 'Unknown error',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton(
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
      ),
      builder: (context) => _FilterBottomSheet(
        sortBy: _sortBy,
        filterBy: _filterBy,
        categories: _products.map((p) => p.category).toSet().toList(),
        onSortChanged: (value) {
          setState(() {
            _sortBy = value;
          });
        },
        onFilterChanged: (value) {
          setState(() {
            _filterBy = value;
          });
        },
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

  void _addToCart(Product product) {
    Provider.of<CartProvider>(context, listen: false).addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final String sortBy;
  final String filterBy;
  final List<String> categories;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onFilterChanged;

  const _FilterBottomSheet({
    required this.sortBy,
    required this.filterBy,
    required this.categories,
    required this.onSortChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Text(
                'Filter & Sort',
                style: AppTextStyles.h3,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                children: [
                  // Sort Section
                  Text(
                    'Sort By',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ...['Default', 'Price: Low to High', 'Price: High to Low', 'Rating', 'Newest']
                      .map((option) => RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: sortBy,
                            onChanged: (value) {
                              if (value != null) {
                                onSortChanged(value);
                                Navigator.pop(context);
                              }
                            },
                          ))
                      .toList(),
                  const SizedBox(height: AppTheme.spacingL),
                  // Filter Section
                  Text(
                    'Filter By Category',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  RadioListTile<String>(
                    title: const Text('All'),
                    value: 'All',
                    groupValue: filterBy,
                    onChanged: (value) {
                      if (value != null) {
                        onFilterChanged(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ...categories.map((category) => RadioListTile<String>(
                        title: Text(category),
                        value: category,
                        groupValue: filterBy,
                        onChanged: (value) {
                          if (value != null) {
                            onFilterChanged(value);
                            Navigator.pop(context);
                          }
                        },
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
