import '../models/product.dart';

/// In-memory cache service for fast app performance
/// Data is stored only in memory and cleared when app closes
class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache storage
  List<Product>? _cachedProducts;
  DateTime? _lastCacheTime;
  
  // Cache for other data types
  Map<int, List<Product>> _categoryProductsCache = {};
  Map<String, List<Product>> _searchCache = {};
  Map<int, Product> _productDetailCache = {};

  /// Get cached products if available
  List<Product>? getCachedProducts() {
    return _cachedProducts;
  }

  /// Check if cache exists and is valid
  bool hasCachedProducts() {
    return _cachedProducts != null && _cachedProducts!.isNotEmpty;
  }

  /// Cache products (only if new data is different)
  void cacheProducts(List<Product> newProducts, {bool forceUpdate = false}) {
    // If force update or no cache exists, update immediately
    if (forceUpdate || _cachedProducts == null) {
      _cachedProducts = List.from(newProducts);
      _lastCacheTime = DateTime.now();
      return;
    }

    // Check if new data is different from cached data
    if (_isDataChanged(_cachedProducts!, newProducts)) {
      _cachedProducts = List.from(newProducts);
      _lastCacheTime = DateTime.now();
    }
    // If data is same, keep existing cache (no update needed)
  }

  /// Check if new data is different from cached data
  bool _isDataChanged(List<Product> oldData, List<Product> newData) {
    // Quick check: different length means data changed
    if (oldData.length != newData.length) {
      return true;
    }

    // Check if product IDs or prices changed
    for (int i = 0; i < oldData.length && i < newData.length; i++) {
      final oldProduct = oldData[i];
      final newProduct = newData[i];
      
      // Check if ID, price, or name changed
      if (oldProduct.id != newProduct.id ||
          oldProduct.price != newProduct.price ||
          oldProduct.name != newProduct.name) {
        return true;
      }
    }

    return false;
  }

  /// Get cached products by category
  List<Product>? getCachedCategoryProducts(int categoryId) {
    return _categoryProductsCache[categoryId];
  }

  /// Cache category products
  void cacheCategoryProducts(int categoryId, List<Product> products) {
    _categoryProductsCache[categoryId] = List.from(products);
  }

  /// Get cached search results
  List<Product>? getCachedSearchResults(String query) {
    return _searchCache[query.toLowerCase()];
  }

  /// Cache search results
  void cacheSearchResults(String query, List<Product> products) {
    _searchCache[query.toLowerCase()] = List.from(products);
  }

  /// Get cached product detail
  Product? getCachedProductDetail(int productId) {
    return _productDetailCache[productId];
  }

  /// Cache product detail
  void cacheProductDetail(int productId, Product product) {
    _productDetailCache[productId] = product;
  }

  /// Clear all cache (called when app closes)
  void clearAllCache() {
    _cachedProducts = null;
    _lastCacheTime = null;
    _categoryProductsCache.clear();
    _searchCache.clear();
    _productDetailCache.clear();
  }

  /// Get cache info
  DateTime? getLastCacheTime() => _lastCacheTime;
  
  int getCacheSize() {
    int size = _cachedProducts?.length ?? 0;
    size += _categoryProductsCache.values.fold(0, (sum, list) => sum + list.length);
    size += _searchCache.values.fold(0, (sum, list) => sum + list.length);
    size += _productDetailCache.length;
    return size;
  }
}
