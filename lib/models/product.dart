class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final int discount;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String category;
  final bool isNew;
  final bool isBestSeller;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.category,
    this.isNew = false,
    this.isBestSeller = false,
  });

  // Factory constructor to create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse price
    final regularPrice = double.tryParse(json['regular_price'] ?? '0') ?? 0.0;
    final salePrice = double.tryParse(json['sale_price'] ?? '0') ?? 0.0;
    final price = salePrice > 0 ? salePrice : regularPrice;
    
    // Calculate discount
    int discount = 0;
    if (regularPrice > 0 && salePrice > 0) {
      discount = ((regularPrice - salePrice) / regularPrice * 100).round();
    }

    // Get image URL
    String imageUrl = '📦'; // Default emoji
    if (json['images'] != null && 
        (json['images'] as List).isNotEmpty) {
      imageUrl = json['images'][0]['src'] ?? '📦';
    }

    // Get category
    String category = 'Electronics'; // Default
    if (json['categories'] != null && 
        (json['categories'] as List).isNotEmpty) {
      category = json['categories'][0]['name'] ?? 'Electronics';
    }

    // Get rating
    double rating = 4.0; // Default
    if (json['average_rating'] != null) {
      rating = double.tryParse(json['average_rating'].toString()) ?? 4.0;
    }

    // Get review count
    int reviews = 0;
    if (json['rating_count'] != null) {
      reviews = int.tryParse(json['rating_count'].toString()) ?? 0;
    }

    // Check if on sale (new) or featured (bestseller)
    final bool isNew = json['on_sale'] ?? false;
    final bool isBestSeller = json['featured'] ?? false;

    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? 'Product',
      description: _stripHtmlTags(json['description'] ?? ''),
      price: price,
      originalPrice: regularPrice,
      discount: discount,
      rating: rating,
      reviews: reviews,
      imageUrl: imageUrl,
      category: category,
      isNew: isNew,
      isBestSeller: isBestSeller,
    );
  }

  // Helper function to remove HTML tags from description
  static String _stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}

