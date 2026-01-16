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
        backgroundColor: Theme.of(context).cardColor,
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

          // 1. Filter Top-Level Categories (Parent == 0)
          final parentCategories = allCategoriesFromAPI.where((c) => c.parent == 0).toList();
          
          // If no parent categories found, show all categories as parent categories
          // This helps show categories like "Sari" even if they're not top-level
          final displayCategories = parentCategories.isEmpty 
              ? allCategoriesFromAPI 
              : parentCategories;
          
          // Default selection to the first parent if not set
          if (_selectedParentId == null && displayCategories.isNotEmpty) {
             _selectedParentId = displayCategories.first.id;
          }
          
          final currentParentId = _selectedParentId ?? (displayCategories.isNotEmpty ? displayCategories.first.id : 0);
          final currentCategory = displayCategories.firstWhere(
            (c) => c.id == currentParentId, 
            orElse: () => displayCategories.isNotEmpty ? displayCategories.first : allCategoriesFromAPI.first,
          );

          // 2. Fetch Sub-Categories for the selected parent using provider
          final subCategoriesAsyncValue = ref.watch(subCategoriesProvider(currentParentId));

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = ResponsiveHelper.isMobile(context);
              final sidebarWidth = isMobile ? 80.0 : 100.0;
              final iconSize = isMobile ? 40.0 : 50.0;
              final fontSize = isMobile ? 10.0 : 11.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SIDEBAR ---
                  SizedBox(
                    width: sidebarWidth,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: displayCategories.length,
                  itemBuilder: (context, index) {
                          final category = displayCategories[index];
                    final isSelected = category.id == currentParentId;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedParentId = category.id;
                        });
                      },
                      child: Container(
                              color: isSelected
                                  ? Theme.of(context).cardColor
                                  : Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 16,
                                horizontal: isMobile ? 4 : 8,
                              ),
                        child: Row(
                                mainAxisSize: MainAxisSize.min,
                          children: [
                            // Selection Indicator
                            if (isSelected)
                              Container(
                                      width: 3,
                                      height: isMobile ? 50 : 60,
                                decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                                  if (isSelected) SizedBox(width: isMobile ? 2 : 4),
                            
                            Expanded(
                              child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Sidebar Icon/Image
                                  Container(
                                          width: iconSize,
                                          height: iconSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.1),
                                            image: category.imageSrc != null &&
                                                    category.imageSrc!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(category.imageSrc!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    ),
                                          child: category.imageSrc == null ||
                                                  category.imageSrc!.isEmpty
                                              ? Opacity(
                                                  opacity: 0.5,
                                                  child: Icon(
                                                    Icons.category_outlined,
                                                    size: iconSize * 0.5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                )
                                        : null,
                                  ),
                                        SizedBox(height: isMobile ? 6 : 8),
                                        Flexible(
                                          child: Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight:
                                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onSurface
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                      ),
                ),
              ),

              // --- CONTENT AREA ---
              Expanded(
                child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header for the content area
                      Padding(
                            padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                currentCategory.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18 * ResponsiveHelper.getFontScale(context),
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                            child: subCategoriesAsyncValue.when(
                              data: (subCategories) {
                                if (subCategories.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                          Icon(
                                            Icons.style_outlined,
                                            size: 60,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.3),
                                          ),
                                    const SizedBox(height: 16),
                                          Flexible(
                                            child: Text(
                                      'Browse all ${currentCategory.name}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                                fontSize: 16 * ResponsiveHelper.getFontScale(context),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                         Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryPage(
                                                categoryName: currentCategory.name,
                                                    categoryId: currentCategory.id,
                                              ),
                                            ),
                                          );
                                      },
                                      style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(context).colorScheme.primary,
                                              foregroundColor:
                                                  Theme.of(context).colorScheme.onPrimary,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 32 * ResponsiveHelper.getFontScale(context),
                                                vertical: 12,
                                              ),
                                      ),
                                      child: const Text('View Products'),
                                    ),
                                  ],
                                ),
                                    ),
                                  );
                                }
                                
                                final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                                final itemSize = isMobile ? 60.0 : 70.0;
                                
                                return GridView.builder(
                                  padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: ResponsiveHelper.getPadding(context),
                                    mainAxisSpacing: ResponsiveHelper.getPadding(context),
                                ),
                                itemCount: subCategories.length,
                                itemBuilder: (context, index) {
                                  final subCat = subCategories[index];
                                  return InkWell(
                                    onTap: () {
                                       Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryPage(
                                                categoryName: subCat.name,
                                              categoryId: subCat.id,
                                              ),
                                            ),
                                          );
                                    },
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                          Flexible(
                                            child: Container(
                                              height: itemSize,
                                              width: itemSize,
                                          decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.05),
                                            shape: BoxShape.circle,
                                                image: subCat.imageSrc != null &&
                                                        subCat.imageSrc!.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(subCat.imageSrc!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          ),
                                              child: subCat.imageSrc == null ||
                                                      subCat.imageSrc!.isEmpty
                                                  ? Icon(
                                                      Icons.image_not_supported_outlined,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.4),
                                                      size: itemSize * 0.4,
                                                    )
                                              : null,
                                        ),
                                          ),
                                          SizedBox(height: isMobile ? 6 : 8),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                              child: Text(
                                          subCat.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: (isMobile ? 11 : 12) * ResponsiveHelper.getFontScale(context),
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stack) => Center(
                                child: Padding(
                                  padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 60,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Flexible(
                                        child: Text(
                                          'Failed to load subcategories',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryPage(
                                                categoryName: currentCategory.name,
                                                categoryId: currentCategory.id,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).colorScheme.primary,
                                          foregroundColor:
                                              Theme.of(context).colorScheme.onPrimary,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 32 * ResponsiveHelper.getFontScale(context),
                                            vertical: 12,
                                          ),
                                        ),
                                        child: const Text('View Products'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
              );
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
