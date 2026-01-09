# WooCommerce Order API Integration

This document explains the WooCommerce Order Creation API integration in the Flutter app.

## Architecture

The implementation follows **Clean Architecture** principles with three main layers:

### 1. Data Layer (`lib/data/`)
- **Models**: `OrderModel`, `BillingModel`, `ShippingModel`, `LineItemModel`
- **Services**: `OrderApiService` - Handles HTTP requests to WooCommerce API
- **Config**: `ApiConfig` - Manages API credentials securely

### 2. Domain Layer (`lib/domain/`)
- **Repositories**: `OrderRepository` interface and `OrderRepositoryImpl`
- **Use Cases**: `PlaceOrderUseCase` - Contains business logic

### 3. Presentation Layer (`lib/presentation/`)
- **Providers**: `OrderProvider` - Riverpod state management
- **Pages**: `CheckoutPage`, `OrderSuccessPage` - UI components

## Setup Instructions

### 1. Environment Variables

Create a `.env` file in the project root:

```env
WOOCOMMERCE_BASE_URL=https://cenexsports.co.in/wp-json/wc/v3
WOOCOMMERCE_CONSUMER_KEY=your_consumer_key_here
WOOCOMMERCE_CONSUMER_SECRET=your_consumer_secret_here
```

**Important**: 
- Never commit `.env` file to version control
- The `.env` file is already added to `.gitignore`
- If `.env` is missing, the app will use default values from `ApiConfig`

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## API Integration Details

### Endpoint
- **URL**: `POST https://cenexsports.co.in/wp-json/wc/v3/orders`
- **Authentication**: Basic Auth (Consumer Key:Consumer Secret)
- **Content-Type**: `application/json`

### Order Payload Structure

```json
{
  "payment_method": "cod",
  "payment_method_title": "Cash on Delivery",
  "set_paid": false,
  "billing": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+91 9876543210",
    "address_1": "123 Main St",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postcode": "400001",
    "country": "IN"
  },
  "shipping": {
    "first_name": "John",
    "last_name": "Doe",
    "address_1": "123 Main St",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postcode": "400001",
    "country": "IN"
  },
  "line_items": [
    {
      "product_id": 123,
      "quantity": 2
    }
  ]
}
```

## Features

### ✅ Implemented

1. **Clean Architecture** - Separation of concerns across layers
2. **Secure API Key Storage** - Using `flutter_dotenv`
3. **State Management** - Riverpod for reactive state
4. **Error Handling** - Comprehensive error handling with user-friendly messages
5. **Form Validation** - Client-side validation before API call
6. **Loading States** - Progress indicators during API calls
7. **Duplicate Prevention** - Prevents multiple simultaneous submissions
8. **Success Screen** - Shows order details after successful placement
9. **Retry Mechanism** - Error messages with retry option
10. **Timeout Handling** - 30-second timeout for API requests

### Error Handling

The app handles common WooCommerce errors:

- **400**: Invalid order data
- **401**: Authentication failed
- **404**: Endpoint not found
- **500**: Server error
- **Timeout**: Network timeout errors
- **Connection Error**: No internet connection

## Usage Flow

1. User adds products to cart
2. User clicks "Proceed to Checkout" in cart
3. User fills billing and shipping address forms
4. User selects payment method
5. User clicks "Place Order"
6. App validates form data
7. App creates order via WooCommerce API
8. On success: Navigate to Order Success page
9. On error: Show error message with retry option

## Code Structure

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart          # API configuration
│   └── providers/
│       └── cart_provider.dart        # Cart state (Provider)
├── data/
│   ├── models/
│   │   ├── order_model.dart
│   │   ├── billing_model.dart
│   │   ├── shipping_model.dart
│   │   └── line_item_model.dart
│   └── services/
│       └── order_api_service.dart    # API service
├── domain/
│   ├── repositories/
│   │   └── order_repository.dart    # Repository interface & impl
│   └── usecases/
│       └── place_order_usecase.dart # Business logic
└── presentation/
    ├── providers/
    │   └── order_provider.dart      # Riverpod state
    └── pages/
        ├── checkout_page.dart        # Checkout UI
        └── order_success_page.dart   # Success screen
```

## Testing

### Manual Testing Checklist

- [ ] Place order with valid data
- [ ] Test form validation (empty fields)
- [ ] Test invalid email format
- [ ] Test network timeout (airplane mode)
- [ ] Test duplicate submission prevention
- [ ] Test "Same as billing" checkbox
- [ ] Verify order ID in success screen
- [ ] Test error messages display correctly

## Security Best Practices

1. ✅ API keys stored in `.env` file (not in code)
2. ✅ `.env` file in `.gitignore`
3. ✅ Basic Auth token generated securely
4. ✅ No hardcoded credentials in UI code
5. ✅ Timeout handling prevents hanging requests
6. ✅ Error messages don't expose sensitive info

## Future Enhancements

- [ ] Add payment gateway integration (Razorpay, Stripe)
- [ ] Order history page
- [ ] Order tracking
- [ ] Save addresses for future use
- [ ] Multiple payment methods
- [ ] Order cancellation
- [ ] Refund handling

## Troubleshooting

### Issue: API returns 401 Unauthorized
**Solution**: Check that `.env` file has correct `WOOCOMMERCE_CONSUMER_KEY` and `WOOCOMMERCE_CONSUMER_SECRET`

### Issue: Order creation fails with 400 Bad Request
**Solution**: Check that all required fields are filled and product IDs are valid

### Issue: Timeout errors
**Solution**: Check internet connection and increase timeout in `OrderApiService` if needed

### Issue: .env file not loading
**Solution**: Ensure `.env` file is in project root and `pubspec.yaml` includes it in assets

## Support

For issues or questions, please check:
- WooCommerce REST API Documentation: https://woocommerce.github.io/woocommerce-rest-api-docs/
- Flutter Documentation: https://flutter.dev/docs
