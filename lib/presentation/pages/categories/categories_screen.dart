import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../../../pages/search_page.dart';
import '../../../../pages/cart_page.dart';
import '../../../../pages/category_page.dart';
import '../../../../core/utils/responsive_helper.dart';


class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int? _selectedParentId;

  @override
  Widget build(BuildContext context) {
    // Use allCategoriesProvider to get all categories (including subcategories)
    // This ensures we can find categories like "Sari" even if they're subcategories
    final categoriesAsyncValue = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Categories',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
            IconButton(
              icon: const Icon(Icons.search), 
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
              }
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined), 
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
              }
            ),
        ],
      ),
      body: categoriesAsyncValue.when(
        data: (allCategoriesFromAPI) {
          if (allCategoriesFromAPI.isEmpty) {
            return Center(
              child: Text(
                'No categories found.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          // Use top-level categories if available, otherwise all
          final parentCategories =
              allCategoriesFromAPI.where((c) => c.parent == 0).toList();
          final displayCategories =
              parentCategories.isNotEmpty ? parentCategories : allCategoriesFromAPI;

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getPadding(context),
              vertical: ResponsiveHelper.getPadding(context),
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              return _buildCategoryBannerCard(context, category);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildCategoryBannerCard(BuildContext context, CategoryModel category) {
  final borderRadius = BorderRadius.circular(16);

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubCategoriesPage(parentCategory: category),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: category.imageSrc != null && category.imageSrc!.isNotEmpty
                  ? Image.network(
                      category.imageSrc!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),
            // Gradient overlay (left side) for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Category name text
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Page that shows subcategories for a given parent category
/// in a 2-column grid with large image cards (like the provided design).
class SubCategoriesPage extends ConsumerWidget {
  final CategoryModel parentCategory;

  const SubCategoriesPage({super.key, required this.parentCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCategoriesAsync = ref.watch(subCategoriesProvider(parentCategory.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          parentCategory.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: const [
          Icon(Icons.swap_vert),
          SizedBox(width: 12),
          Icon(Icons.sort),
          SizedBox(width: 8),
        ],
      ),
      body: subCategoriesAsync.when(
        data: (subCategories) {
          if (subCategories.isEmpty) {
            // If no subcategories, fall back to showing products of parent category
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryPage(
                        categoryName: parentCategory.name,
                        categoryId: parentCategory.id,
                      ),
                    ),
                  );
                },
                child: Text('View ${parentCategory.name} Products'),
              ),
            );
          }

          final padding = ResponsiveHelper.getPadding(context);

          return GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final subCat = subCategories[index];
              return _SubCategoryCard(subCategory: subCat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load categories',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  final CategoryModel subCategory;

  const _SubCategoryCard({required this.subCategory});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPage(
              categoryName: subCategory.name,
              categoryId: subCategory.id,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: subCategory.imageSrc != null && subCategory.imageSrc!.isNotEmpty
                  ? Image.network(
                      subCategory.imageSrc!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                      ),
                    ),
            ),
            // Light card background overlay for rounded-rectangle feel
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Category name at top-left
            Positioned(
              left: 10,
              top: 10,
              child: Text(
                subCategory.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.white70,
                      offset: Offset(0, 0),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
