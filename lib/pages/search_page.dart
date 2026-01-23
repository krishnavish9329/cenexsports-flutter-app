import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/search_storage_service.dart';
import '../widgets/product_card.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive_helper.dart';
import 'product_detail_page.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Try to pop first (if pushed as a route)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If part of MainNavigation, navigate to Home (index 0)
              // This will be handled by the bottom navigation bar
              // Just unfocus the keyboard
              FocusScope.of(context).unfocus();
            }
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search for products, brands and more',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
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
                  icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  onPressed: () {
                    _performSearch(_searchController.text);
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  },
                ),
              ],
            ),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: _buildBody(),
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
      // Show suggestions if available and user hasn't hit search yet
      if (_suggestions.isNotEmpty && _searchController.text.isNotEmpty) {
        return _buildSuggestionsList();
      }
      return _buildHistoryView();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsGrid();
  }

  Widget _buildHistoryView() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No recent searches', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ), // Fixed closing parenthesis
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50], // Light red background
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sentiment_dissatisfied, 
              size: 64, 
              color: Colors.red[400]
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sorry, no results found!',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.black87
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Please check the spelling or try searching for something else',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ],
      ),
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
