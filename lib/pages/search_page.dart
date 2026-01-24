import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/search_storage_service.dart';
import '../widgets/product_card.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive_helper.dart';
import '../core/providers/cart_provider.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchStorageService _storageService = SearchStorageService();
  
  List<Product> _searchResults = [];
  List<Product> _suggestions = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _storageService.getHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Clear suggestions if query is empty
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    // Debounce for 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final products = await ApiService.searchProducts(query);
        if (mounted) {
          setState(() {
            _suggestions = products;
          });
        }
      } catch (e) {
        // Silently fail for suggestions or log error
        debugPrint('Error fetching suggestions: $e');
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    // Add to history
    await _storageService.addToHistory(query);
    _loadHistory(); // Reload to update UI if needed (though we switch view)

    try {
      final products = await ApiService.searchProducts(query);
      setState(() {
        _searchResults = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _clearHistory() async {
    await _storageService.clearHistory();
    _loadHistory();
  }

  void _removeHistoryItem(String query) async {
    await _storageService.removeFromHistory(query);
    _loadHistory();
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header row: Back, Logo, Cart, Notifications
            _buildHeader(context, cartProvider),
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                onChanged: (value) {
                  _onSearchChanged(value);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 22, color: Colors.grey[600]),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _hasSearched = false;
                              _searchResults = [];
                              _suggestions = [];
                              _errorMessage = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.filter_list, size: 22, color: Colors.grey[600]),
                        onPressed: () {
                          // Filter functionality can be added here
                        },
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartProvider cartProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          // Logo + Name
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Cart
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
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      if (_suggestions.isNotEmpty && _searchController.text.isNotEmpty) {
        return _buildSuggestionsList();
      }
      if (_searchHistory.isNotEmpty) {
        return _buildHistoryView();
      }
      return _buildNoProductsView();
    }

    if (_searchResults.isEmpty) {
      return _buildNoProductsView();
    }

    return _buildResultsGrid();
  }

  /// Empty state: large magnifying glass + "No products found" (match first image)
  Widget _buildNoProductsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_searchHistory.isNotEmpty)
              TextButton(
                onPressed: _clearHistory,
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _searchHistory.map((term) {
            return GestureDetector(
              onTap: () {
                _searchController.text = term;
                _performSearch(term);
              },
              child: Chip(
                avatar: const Icon(Icons.history, size: 16, color: Colors.grey),
                label: Text(term),
                backgroundColor: Colors.grey[100],
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeHistoryItem(term),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
              ),
            );
          }).toList(),
        ),
        
        // Also show popular list style if preferred
        /*
        ..._searchHistory.map((term) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(term),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _removeHistoryItem(term),
          ),
          onTap: () {
            _searchController.text = term;
            _performSearch(term);
          },
        )).toList(),
        */
      ],
    );
  }

  Widget _buildResultsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
        final aspectRatio = ResponsiveHelper.getProductCardAspectRatio(context);
        final padding = ResponsiveHelper.getPadding(context);

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: _searchResults[index],
              onTap: () => _navigateToProductDetail(_searchResults[index]),
            );
          },
        );
      },
    );
  }
  Widget _buildSuggestionsList() {
    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Colors.grey),
          title: Text(product.name),
          trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
          onTap: () {
            _searchController.text = product.name;
            _performSearch(product.name);
            FocusScope.of(context).unfocus();
            // Clear suggestions so we show the results grid
            setState(() {
              _suggestions = [];
            });
          },
        );
      },
    );
  }
}
