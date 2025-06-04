import 'package:eato/pages/customer/homepage/shop_category_page.dart';
import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/Firebase_Storage_Service.dart';
import 'package:eato/Model/Food&Store.dart';

class MealPage extends StatefulWidget {
  // Keep both parameters for backward compatibility
  final String? mealType; // Old parameter (used in main.dart routes)
  final String? categoryTitle; // New parameter
  final bool showBottomNav;

  // Constructor with both old and new parameters
  const MealPage({
    Key? key,
    this.mealType, // Make it optional
    this.categoryTitle, // Make it optional
    this.showBottomNav = true,
  })  : assert(mealType != null || categoryTitle != null,
            "Either mealType or categoryTitle must be provided"),
        super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMealType = '';
  bool _isLoading = true;
  List<Food> _mealItems = [];
  List<Food> _filteredMealItems = [];
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // Get the effective category title
  String get _effectiveCategoryTitle =>
      widget.categoryTitle ?? widget.mealType!;

  // ✅ FIXED: Only treat as meal time route when NO specific category is provided
  // This means we're coming from a direct route like "/breakfast" without a category
  bool get _isMealTimeRoute =>
      widget.categoryTitle == null &&
      widget.mealType != null &&
      (widget.mealType == 'Breakfast' ||
          widget.mealType == 'Lunch' ||
          widget.mealType == 'Dinner');

  @override
  void initState() {
    super.initState();
    // Set up search listener
    _searchController.addListener(_onSearchChanged);

    // Load meal items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMealTimeRoute) {
        // Only when coming from direct meal time routes without category
        // Load representative meals from all categories for that meal time
        _loadMealTimeItems();
      } else {
        // Normal category view - load meals from specific category
        // This will now be called when coming from category page
        _loadMealItems();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterMeals();
  }

  // Filter meals based on search query
  void _filterMeals() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMealItems = List.from(_mealItems);
      } else {
        _filteredMealItems = _mealItems
            .where((meal) =>
                meal.name.toLowerCase().contains(query) ||
                (meal.description?.toLowerCase().contains(query) ?? false))
            .toList();
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
          categoryTitle: _effectiveCategoryTitle,
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

  // ✅ IMPROVED: Load meal items from FoodProvider based on specific category
  Future<void> _loadMealItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          '🍽️ [MealPage] Loading meals for category: $_effectiveCategoryTitle');
      print('⏰ [MealPage] Meal time filter: ${widget.mealType}');

      // Get FoodProvider instance
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      List<Food> filteredMeals;

      if (widget.mealType != null) {
        // ✅ FIXED: Use the new method that gets meals by category AND time
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
        print(
            '⚠️ [MealPage] No meals found for $_effectiveCategoryTitle${widget.mealType != null ? ' at ${widget.mealType}' : ''}');
      }
    } catch (e) {
      print('❌ [MealPage] Error loading meal items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Special handling for meal time routes (breakfast, lunch, dinner) without category
  Future<void> _loadMealTimeItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🍽️ [MealPage] Loading meal time items for: ${widget.mealType}');

      // Get FoodProvider instance
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      // Get all categories first
      final categories = await foodProvider.getAllCategories();
      print('📂 [MealPage] Found ${categories.length} categories');

      // For each category, get representative meals for the specified meal time
      List<Food> meals = [];
      for (String category in categories) {
        try {
          final categoryMeals = await foodProvider.getMealsByCategory(category);

          // Filter meals by meal time
          final mealTimeFiltered = categoryMeals
              .where((meal) =>
                  meal.time.toLowerCase() == widget.mealType!.toLowerCase())
              .toList();

          // Add first meal as representative for this category
          if (mealTimeFiltered.isNotEmpty) {
            meals.add(mealTimeFiltered.first);
            print(
                '✅ [MealPage] Added ${mealTimeFiltered.first.name} from $category');
          }
        } catch (e) {
          print('⚠️ [MealPage] Error processing category $category: $e');
          continue;
        }
      }

      setState(() {
        _mealItems = meals;
        _filteredMealItems = List.from(meals);
        _isLoading = false;
      });

      print(
          '✅ [MealPage] Loaded ${meals.length} representative meals for ${widget.mealType}');
    } catch (e) {
      print('❌ [MealPage] Error loading meal time items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ Handle bottom nav taps
  void _onBottomNavTap(int index) {
    if (index == 0) {
      // Home tab - stay on current page or go back
      return;
    } else {
      // Other tabs - pass the index back through the navigation chain
      Navigator.pop(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ FIXED: Constrained layout to prevent overflow
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Header section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.arrow_back,
                                    size: 20, color: Colors.black87),
                                SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Title
                          const SizedBox(height: 16),
                          Text(
                            _effectiveCategoryTitle,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          // Subtitle
                          const SizedBox(height: 4),
                          Text(
                            widget.mealType != null
                                ? 'Select a ${widget.mealType!.toLowerCase()} meal'
                                : 'Select a meal',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          // Search bar
                          const SizedBox(height: 16),
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.search,
                                      color: Colors.grey.shade500, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search for meals',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8),
                                      ),
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                      },
                                      child: Icon(Icons.clear,
                                          size: 18,
                                          color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Meal items list
                  _isLoading
                      ? const SliverFillRemaining(
                          child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.purple),
                          ),
                        )
                      : _filteredMealItems.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.no_food,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No meals match your search'
                                          : widget.mealType != null
                                              ? 'No ${widget.mealType!.toLowerCase()} meals available in $_effectiveCategoryTitle'
                                              : 'No meals available in this category',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final meal = _filteredMealItems[index];
                                    return _buildMealItemCard(meal);
                                  },
                                  childCount: _filteredMealItems.length,
                                ),
                              ),
                            ),

                  // Add bottom padding for bottom nav
                  if (widget.showBottomNav)
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                ],
              ),
            ),

            // ✅ Bottom Navigation Bar with proper navigation handling
            if (widget.showBottomNav)
              BottomNavBar(
                currentIndex: 0, // Home tab is selected
                onTap: _onBottomNavTap,
              ),
          ],
        ),
      ),
    );
  }

  // Build meal item card
  Widget _buildMealItemCard(Food meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectMealType(meal),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Food image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: meal.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: meal.imageUrl,
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
                    // ✅ FIXED: Move price between name and type
                    Text(
                      'From Rs. ${meal.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.description ?? 'No description available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Food type tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _getFoodTypeColor(meal.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _getFoodTypeColor(meal.type).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            meal.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getFoodTypeColor(meal.type),
                            ),
                          ),
                        ),

                        // View shops button
                        Row(
                          children: [
                            Text(
                              'View Shops',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
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

  // Get color based on food type
  Color _getFoodTypeColor(String foodType) {
    switch (foodType) {
      case 'Vegetarian':
        return Colors.green;
      case 'Non-Vegetarian':
        return Colors.red;
      case 'Vegan':
        return Colors.teal;
      case 'Dessert':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
}
