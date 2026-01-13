import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/cart_provider.dart';
import 'core/config/api_config.dart';
import 'pages/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    // Initialize ApiConfig with values from .env
    ApiConfig.initialize(
      baseUrl: dotenv.env['WOOCOMMERCE_BASE_URL'],
      consumerKey: dotenv.env['WOOCOMMERCE_CONSUMER_KEY'],
      consumerSecret: dotenv.env['WOOCOMMERCE_CONSUMER_SECRET'],
    );
  } catch (e) {
    // If .env file doesn't exist, use default values from ApiConfig
    debugPrint('Warning: .env file not found. Using default API config.');
  }
  
  runApp(
    // Wrap with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Cenex Sports',
      debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Automatically switch based on system settings
        home: const MainNavigation(),
      ),
    );
  }
}
