import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'home_page.dart';
import '../presentation/pages/categories/categories_screen.dart';
import 'category_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import '../models/product.dart';

/// Main navigation wrapper with bottom navigation bar
class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const CategoriesScreen(),
    const CartPage(),
    const ProfilePage(),
  ];

  // Map page index to destination index
  // Page indices: 0=Home, 1=Search, 2=Categories, 3=Cart, 4=Account
  // Destination indices: 0=Home, 1=Search, 2=Categories, 3=Cart, 4=Account
  // They now match directly!
  int _getDestinationIndex(int pageIndex) {
    return pageIndex.clamp(0, 4);
  }

  // Map destination index to page index
  int _getPageIndex(int destinationIndex) {
    return destinationIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getDestinationIndex(_currentIndex),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = _getPageIndex(index);
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n?.home ?? 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: l10n?.search ?? 'Search',
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: l10n?.categories ?? 'Categories',
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: l10n?.cart ?? 'Cart',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n?.account ?? 'Account',
          ),
        ],
      ),
    );
  }
}
