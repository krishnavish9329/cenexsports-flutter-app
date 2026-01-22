import 'package:flutter/material.dart';

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
  final List<String>? sizes;
  final List<Map<String, dynamic>>? colors;

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
    this.sizes,
    this.colors,
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
    String imageUrl = ''; // No image by default
    if (json['images'] != null && 
        (json['images'] as List).isNotEmpty) {
      final dynamic src = json['images'][0]['src'];
      if (src is String && src.trim().isNotEmpty) {
        imageUrl = src.trim();
      }
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

    // Parse sizes from attributes (WooCommerce format)
    List<String>? sizes;
    if (json['attributes'] != null && json['attributes'] is List) {
      final attributes = json['attributes'] as List;
      try {
        // Try to find size attribute by name or id
        Map<String, dynamic>? sizeAttr;
        for (var attr in attributes) {
          if (attr is Map) {
            final attrMap = Map<String, dynamic>.from(attr);
            final attrName = attrMap['name']?.toString().toLowerCase() ?? '';
            final attrId = attrMap['id']?.toString() ?? '';
            if (attrName == 'size' || attrId == '1' || attrName.contains('size')) {
              sizeAttr = attrMap;
              break;
            }
          }
        }
        
        if (sizeAttr != null && sizeAttr['options'] != null) {
          if (sizeAttr['options'] is List) {
            final optionsList = sizeAttr['options'] as List;
            sizes = optionsList.map((opt) => opt.toString().trim()).where((s) => s.isNotEmpty).toList();
          } else if (sizeAttr['options'] is String) {
            // Sometimes options might be comma-separated string
            final optionsStr = sizeAttr['options'] as String;
            sizes = optionsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
        }
      } catch (e) {
        // If no size attribute found, sizes remains null
        sizes = null;
      }
    }

    // Parse colors from attributes (WooCommerce format)
    List<Map<String, dynamic>>? colors;
    if (json['attributes'] != null && json['attributes'] is List) {
      final attributes = json['attributes'] as List;
      try {
        // Try to find color attribute by name or id
        Map<String, dynamic>? colorAttr;
        for (var attr in attributes) {
          if (attr is Map) {
            final attrMap = Map<String, dynamic>.from(attr);
            final attrName = attrMap['name']?.toString().toLowerCase() ?? '';
            final attrId = attrMap['id']?.toString() ?? '';
            if (attrName == 'color' || attrName == 'colour' || attrId == '2' || attrName.contains('color')) {
              colorAttr = attrMap;
              break;
            }
          }
        }
        
        if (colorAttr != null && colorAttr['options'] != null) {
          List<dynamic> colorOptions = [];
          if (colorAttr['options'] is List) {
            colorOptions = colorAttr['options'] as List;
          } else if (colorAttr['options'] is String) {
            // Sometimes options might be comma-separated string
            final optionsStr = colorAttr['options'] as String;
            colorOptions = optionsStr.split(',').map((s) => s.trim()).toList();
          }
          
          colors = colorOptions.map((colorName) {
            final name = colorName.toString().trim();
            if (name.isEmpty) return null;
            
            // Map color names to Flutter Colors
            Color color;
            switch (name.toLowerCase()) {
              case 'black':
                color = Colors.black;
                break;
              case 'white':
                color = Colors.white;
                break;
              case 'red':
                color = Colors.red;
                break;
              case 'blue':
                color = Colors.blue;
                break;
              case 'green':
                color = Colors.green;
                break;
              case 'yellow':
                color = Colors.yellow;
                break;
              case 'orange':
                color = Colors.orange;
                break;
              case 'purple':
                color = Colors.purple;
                break;
              case 'pink':
                color = Colors.pink;
                break;
              case 'brown':
                color = Colors.brown;
                break;
              case 'grey':
              case 'gray':
                color = Colors.grey;
                break;
              default:
                color = Colors.grey;
            }
            return {'name': name, 'color': color};
          }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
        }
      } catch (e) {
        // If no color attribute found, colors remains null
        colors = null;
      }
    }

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
      sizes: sizes,
      colors: colors,
    );
  }

  // Helper function to remove HTML tags from description
  static String _stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}

