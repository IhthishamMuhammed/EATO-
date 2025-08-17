// FILE: lib/pages/customer/homepage/meal_pages.dart
// Fixed version with proper method calls and error handling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/customer/homepage/shop_category_page.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MealPage extends StatefulWidget {
  final String? categoryTitle;
  final String? mealType;
  final bool showBottomNav;

  const MealPage({
    Key? key,
    this.categoryTitle,
    this.mealType,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  List<Food> _mealItems = [];
  List<Food> _filteredMealItems = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, price, rating

  // ✅ Get effective category title with fallback
  String get _effectiveCategoryTitle =>
      widget.categoryTitle ?? 'All Categories';

  @override
  void initState() {
    super.initState();

    // ✅ FIXED: Choose the right loading method based on input
    if (widget.categoryTitle != null) {
      _loadMealItems(); // Load items for specific category
    } else if (widget.mealType != null) {
      _loadMealTimeItems(); // Load representative items for meal time
    } else {
      _loadAllMealItems(); // Load all available meals
    }
  }

  // ✅ IMPROVED: Load meal items from FoodProvider based on specific category
  Future<void> _loadMealItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
          '🍽️ [MealPage] Loading meals for category: $_effectiveCategoryTitle');
      print('⏰ [MealPage] Meal time filter: ${widget.mealType}');

      // Get FoodProvider instance
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      List<Food> filteredMeals;

      if (widget.mealType != null) {
        // ✅ FIXED: Use the corrected method that gets meals by category AND time
        filteredMeals = await foodProvider.getMealsByCategoryAndTime(
            _effectiveCategoryTitle, widget.mealType);

        print(
            '✅ [MealPage] Found ${filteredMeals.length} meals for $_effectiveCategoryTitle at ${widget.mealType}');
      } else {
        // If no meal time specified, get all meals in category
        filteredMeals =
            await foodProvider.getMealsByCategory(_effectiveCategoryTitle);
        print(
            'ℹ️ [MealPage] No meal time filter, showing all ${filteredMeals.length} meals');
      }

      setState(() {
        _mealItems = filteredMeals;
        _filteredMealItems = List.from(filteredMeals);
        _isLoading = false;
      });

      if (filteredMeals.isEmpty) {
        setState(() {
          _error =
              'No meals found for $_effectiveCategoryTitle${widget.mealType != null ? ' at ${widget.mealType}' : ''}';
        });
        print(
            '⚠️ [MealPage] No meals found for $_effectiveCategoryTitle${widget.mealType != null ? ' at ${widget.mealType}' : ''}');
      }
    } catch (e) {
      print('❌ [MealPage] Error loading meal items: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load meals: $e';
      });
    }
  }

  // ✅ FIXED: Special handling for meal time routes (breakfast, lunch, dinner) without category
  Future<void> _loadMealTimeItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🍽️ [MealPage] Loading meal time items for: ${widget.mealType}');

      // Get FoodProvider instance
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      // Get all categories first
      final categories = await foodProvider.getAllCategories();
      print('📂 [MealPage] Found ${categories.length} categories');

      if (categories.isEmpty) {
        setState(() {
          _error = 'No food categories available';
          _isLoading = false;
        });
        return;
      }

      // For each category, get representative meals for the specified meal time
      List<Food> meals = [];
      for (String category in categories) {
        try {
          // ✅ FIXED: Use the corrected method with proper error handling
          final categoryMeals = await foodProvider.getMealsByCategoryAndTime(
              category, widget.mealType);

          // Add first meal as representative for this category
          if (categoryMeals.isNotEmpty) {
            meals.add(categoryMeals.first);
            print(
                '✅ [MealPage] Added ${categoryMeals.first.name} from $category');
          }
        } catch (e) {
          print('⚠️ [MealPage] Error loading meals for category $category: $e');
          continue;
        }
      }

      setState(() {
        _mealItems = meals;
        _filteredMealItems = List.from(meals);
        _isLoading = false;
      });

      if (meals.isEmpty) {
        setState(() {
          _error = 'No ${widget.mealType} meals available';
        });
        print('⚠️ [MealPage] No ${widget.mealType} meals found');
      } else {
        print(
            '✅ [MealPage] Loaded ${meals.length} representative ${widget.mealType} meals');
      }
    } catch (e) {
      print('❌ [MealPage] Error loading meal time items: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load ${widget.mealType} meals: $e';
      });
    }
  }

  // ✅ NEW: Load all available meals when no specific filter is applied
  Future<void> _loadAllMealItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🍽️ [MealPage] Loading all available meals');

      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      // Get all categories and then get meals from each
      final categories = await foodProvider.getAllCategories();
      List<Food> allMeals = [];

      for (String category in categories) {
        try {
          final categoryMeals = await foodProvider.getMealsByCategory(category);
          allMeals.addAll(categoryMeals);
        } catch (e) {
          print('⚠️ [MealPage] Error loading meals for category $category: $e');
          continue;
        }
      }

      // Remove duplicates based on food name
      final uniqueMeals = <String, Food>{};
      for (var meal in allMeals) {
        uniqueMeals[meal.name] = meal;
      }

      setState(() {
        _mealItems = uniqueMeals.values.toList();
        _filteredMealItems = List.from(_mealItems);
        _isLoading = false;
      });

      print('✅ [MealPage] Loaded ${_mealItems.length} unique meals');
    } catch (e) {
      print('❌ [MealPage] Error loading all meals: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load meals: $e';
      });
    }
  }

  // ✅ IMPROVED: Search functionality
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMealItems = List.from(_mealItems);
      } else {
        _filteredMealItems = _mealItems
            .where((meal) =>
                meal.name.toLowerCase().contains(query.toLowerCase()) ||
                meal.category.toLowerCase().contains(query.toLowerCase()) ||
                (meal.description
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  // ✅ IMPROVED: Sort functionality
  void _sortMeals(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'name':
          _filteredMealItems.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price':
          _filteredMealItems.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'category':
          _filteredMealItems.sort((a, b) => a.category.compareTo(b.category));
          break;
        default:
          break;
      }
    });
  }

  // Navigate to shop category page
  void _selectMealType(Food meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopCategoryPage(
          mealTitle: meal.name,
          categoryTitle: meal.category,
          showBottomNav: widget.showBottomNav,
        ),
      ),
    ).then((selectedTabIndex) {
      // ✅ Handle navigation back from ShopCategoryPage
      if (selectedTabIndex != null && selectedTabIndex is int) {
        Navigator.pop(context, selectedTabIndex);
      }
    });
  }

  // ✅ IMPROVED: Refresh functionality
  Future<void> _refreshData() async {
    if (widget.categoryTitle != null) {
      await _loadMealItems();
    } else if (widget.mealType != null) {
      await _loadMealTimeItems();
    } else {
      await _loadAllMealItems();
    }
  }

  // ✅ Get price display text with portion support using existing portionPrices structure
  String _getPriceDisplayText(Food meal) {
    if (meal.portionPrices.isNotEmpty) {
      // Find the cheapest portion
      double minPrice =
          meal.portionPrices.values.reduce((a, b) => a < b ? a : b);

      if (meal.portionPrices.length > 1) {
        return 'From ₹${minPrice.toStringAsFixed(2)}';
      } else {
        return '₹${minPrice.toStringAsFixed(2)}';
      }
    }
    return '₹${meal.price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.categoryTitle ?? widget.mealType ?? 'All Meals',
          style: EatoTheme.headingMedium.copyWith(color: Colors.black),
        ),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            onSelected: _sortMeals,
            icon: const Icon(Icons.sort, color: Colors.black),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              const PopupMenuItem(
                  value: 'category', child: Text('Sort by Category')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search meals...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: _performSearch,
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : _filteredMealItems.isEmpty
                        ? _buildEmptyWidget()
                        : _buildMealsList(),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                Navigator.pop(context, index);
              },
            )
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No meals found for "$_searchQuery"'
                  : 'No meals available',
              textAlign: TextAlign.center,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performSearch(''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EatoTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clear Search',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredMealItems.length,
        itemBuilder: (context, index) {
          final meal = _filteredMealItems[index];
          return _buildMealCard(meal);
        },
      ),
    );
  }

  Widget _buildMealCard(Food meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectMealType(meal),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Food Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: meal.imageUrl!,
                      width: 120,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.purple),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),

            // Food details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ✅ UPDATED: New price display logic with portion support
                    Text(
                      _getPriceDisplayText(meal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      meal.description ?? 'Delicious ${meal.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Category and meal time tags
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            meal.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            meal.time,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow icon
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
