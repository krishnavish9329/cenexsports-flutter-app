import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/language_provider.dart';
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    
    return provider.ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Cenex Sports',
      debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('hi', ''), // Hindi
        ],
        home: const MainNavigation(),
      ),
    );
  }
}
