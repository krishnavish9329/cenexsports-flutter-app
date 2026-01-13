import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../../../pages/search_page.dart';
import '../../../../pages/cart_page.dart';
import '../../../../pages/category_page.dart';


class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int? _selectedParentId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
        data: (allCategories) {
          if (allCategories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          // 1. Filter Top-Level Categories (Parent == 0)
          final parentCategories = allCategories.where((c) => c.parent == 0).toList();
          
          // Default selection to the first parent if not set
          if (_selectedParentId == null && parentCategories.isNotEmpty) {
             _selectedParentId = parentCategories.first.id;
          }
          
          final currentParentId = _selectedParentId ?? (parentCategories.isNotEmpty ? parentCategories.first.id : 0);
          final currentCategory = parentCategories.firstWhere((c) => c.id == currentParentId, orElse: () => parentCategories.first);

          // 2. Filter Sub-Categories for the selected parent
          final subCategories = allCategories.where((c) => c.parent == currentParentId).toList();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SIDEBAR ---
              Container(
                width: 100, // Fixed width sidebar
                color: Colors.grey[100],
                child: ListView.builder(
                  itemCount: parentCategories.length,
                  itemBuilder: (context, index) {
                    final category = parentCategories[index];
                    final isSelected = category.id == currentParentId;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedParentId = category.id;
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.white : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Row(
                          children: [
                            // Selection Indicator
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                             if (isSelected) const SizedBox(width: 4),
                            
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Sidebar Icon/Image
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                      image: category.imageSrc != null && category.imageSrc!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(category.imageSrc!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    ),
                                    child: category.imageSrc == null || category.imageSrc!.isEmpty
                                        ? Opacity(opacity: 0.5, child: Icon(Icons.category_outlined, color: Colors.grey[600]))
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? Colors.black : Colors.grey[700],
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

              // --- CONTENT AREA ---
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header for the content area
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                currentCategory.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: subCategories.isEmpty 
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.style_outlined, size: 60, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Browse all ${currentCategory.name}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                         Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryPage(
                                                categoryName: currentCategory.name,
                                                products: const [], // TODO: Pass ID to fetch products
                                              ),
                                            ),
                                          );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                      ),
                                      child: const Text('View Products'),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
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
                                                products: const [], 
                                              ),
                                            ),
                                          );
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            shape: BoxShape.circle,
                                             image: subCat.imageSrc != null && subCat.imageSrc!.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(subCat.imageSrc!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          ),
                                           
                                           child: subCat.imageSrc == null || subCat.imageSrc!.isEmpty
                                              ? Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 30)
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          subCat.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
