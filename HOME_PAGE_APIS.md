# Home Page में Use होने वाली APIs

## 📍 Base URL
```
https://cenexsports.co.in/wp-json/wc/v3
```

## 🔑 Authentication
- **Type:** Basic Authentication
- **Consumer Key:** `ck_66867a5f826ba9290cf9d476e5c4a23370538df7`
- **Consumer Secret:** `cs_c2314e31215cf78d5d76afe285a09b34fdcee6d1`
- **Header Format:** `Authorization: Basic {base64(consumerKey:consumerSecret)}`

---

## 🛍️ APIs Used in Home Page

### 1. **Get All Products API**
**Endpoint:**
```
GET /products
```

**Full URL:**
```
https://cenexsports.co.in/wp-json/wc/v3/products
```

**Method:** `ApiService.getProducts()`

**Response:**
- Returns list of all products
- Used for:
  - All Products section
  - On Sale products (filtered by `discount > 0`)
  - Best Sellers (filtered by `isBestSeller = true`)

**Code Location:**
- `lib/services/api_service.dart` (line 16-32)
- `lib/pages/home_page.dart` (line 52)

---

### 2. **Get Categories API**
**Endpoint:**
```
GET /products/categories
```

**Full URL:**
```
https://cenexsports.co.in/wp-json/wc/v3/products/categories?parent=0&per_page=100&hide_empty=true
```

**Method:** `CategoryApiService.getCategories()`

**Query Parameters:**
- `parent=0` - Top-level categories only
- `per_page=100` - Number of categories per page
- `hide_empty=true` - Hide categories with no products

**Response:**
- Returns list of categories
- Used for: "Shop by Categories" section

**Code Location:**
- `lib/data/services/category_api_service.dart` (line 42-89)
- `lib/pages/home_page.dart` (line 96 - via Riverpod provider)

---

## 📝 API Details

### Products API Response Structure:
```json
{
  "id": 123,
  "name": "Product Name",
  "description": "Product description",
  "regular_price": "100.00",
  "sale_price": "80.00",
  "images": [
    {
      "src": "https://image-url.jpg"
    }
  ],
  "categories": [
    {
      "name": "Category Name"
    }
  ],
  "average_rating": "4.5",
  "rating_count": 10,
  "on_sale": true,
  "featured": false
}
```

### Categories API Response Structure:
```json
{
  "id": 15,
  "name": "Category Name",
  "parent": 0,
  "count": 25,
  "image": {
    "src": "https://category-image.jpg"
  }
}
```

---

## 🔧 Implementation Details

### Products Loading:
```dart
// lib/pages/home_page.dart
Future<void> _loadProducts() async {
  final products = await ApiService.getProducts();
  _products = products;
  _onSaleProducts = products.where((p) => p.discount > 0).take(10).toList();
  _bestSellers = products.where((p) => p.isBestSeller).take(10).toList();
}
```

### Categories Loading:
```dart
// lib/pages/home_page.dart (via Riverpod)
final categoriesAsync = ref.watch(categoriesProvider);
// This uses CategoryRepository which calls CategoryApiService
```

---

## 📦 API Service Files

1. **Products API:**
   - File: `lib/services/api_service.dart`
   - Uses: `http` package

2. **Categories API:**
   - File: `lib/data/services/category_api_service.dart`
   - Uses: `dio` package

3. **API Config:**
   - File: `lib/core/config/api_config.dart`
   - Contains base URL and authentication credentials

---

## 🎯 Summary

Home page में **2 main APIs** use हो रही हैं:

1. ✅ **Products API** - सभी products fetch करने के लिए
2. ✅ **Categories API** - Categories list fetch करने के लिए

दोनों APIs **WooCommerce REST API** का हिस्सा हैं और **Basic Authentication** use करती हैं।
