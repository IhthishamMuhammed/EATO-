import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/Firebase_Storage_Service.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/pages/customer/homepage/meal_pages.dart';
import 'package:eato/services/navigation_stack_manager.dart';

class MealCategoryPage extends StatefulWidget {
  final String?
      mealTime; // Optional meal time filter (Breakfast, Lunch, Dinner)
  final bool showBottomNav;

  const MealCategoryPage({
    Key? key,
    this.mealTime,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<MealCategoryPage> createState() => _MealCategoryPageState();
}

class _MealCategoryPageState extends State<MealCategoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categoryItems = [];
  List<Map<String, dynamic>> _filteredCategoryItems = [];
  String _heroImageUrl = '';
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TextEditingController _searchController = TextEditingController();

  // Default fallback images in case Firebase storage fails
  final Map<String, String> _defaultHeroImages = {
    'Breakfast':
        'https://images.unsplash.com/photo-1533089860892-a9b9ac6cd6b4?q=80&w=600',
    'Lunch':
        'https://images.unsplash.com/photo-1547592180-85f173990888?q=80&w=600',
    'Dinner':
        'https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=600',
    'default':
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=600',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterCategories();
  }

  // Filter categories based on search query
  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategoryItems = List.from(_categoryItems);
      } else {
        _filteredCategoryItems = _categoryItems
            .where((category) =>
                category['title'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // Load data from Firebase
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get hero image from Firebase
      if (widget.mealTime != null) {
        try {
          String heroImagePath =
              'categories/${widget.mealTime!.toLowerCase()}_hero.jpg';
          _heroImageUrl = await _storageService.getImageUrl(heroImagePath);
        } catch (e) {
          print('Error getting hero image from Firebase: $e');
          _heroImageUrl = _defaultHeroImages[widget.mealTime] ??
              _defaultHeroImages['default']!;
        }
      } else {
        try {
          _heroImageUrl = await _storageService
              .getImageUrl('categories/categories_hero.jpg');
        } catch (e) {
          print('Error getting default hero image: $e');
          _heroImageUrl = _defaultHeroImages['default']!;
        }
      }

      // Get FoodProvider instance
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      List<String> availableCategories = [];

      try {
        if (widget.mealTime != null) {
          // ✅ IMPROVED: Get categories specifically for this meal time
          print(
              '🔍 [MealCategoryPage] Getting categories for meal time: ${widget.mealTime}');
          availableCategories =
              await foodProvider.getCategoriesForMealTime(widget.mealTime!);
        } else {
          // Get all categories if no meal time specified
          print('🔍 [MealCategoryPage] Getting all categories');
          availableCategories = await foodProvider.getAllCategories();
        }
      } catch (e) {
        print('❌ [MealCategoryPage] Error getting categories: $e');

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error loading categories. Using fallback options.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Fallback to hardcoded categories
        availableCategories = [
          'Rice and Curry',
          'String Hoppers',
          'Roti',
          'Egg Roti',
          'Short Eats',
          'Hoppers',
        ];
      }

      print(
          '✅ [MealCategoryPage] Found ${availableCategories.length} categories: $availableCategories');

      // Build category items
      final List<Map<String, dynamic>> categories = [];

      for (var category in availableCategories) {
        String imageUrl = '';
        try {
          final imagePath = _getCategoryImagePath(category);
          imageUrl = await _storageService.getImageUrl(imagePath);
        } catch (e) {
          print(
              '⚠️ [MealCategoryPage] Error getting image for category $category: $e');
          // Use a generic category icon URL as fallback
          imageUrl =
              'https://via.placeholder.com/150?text=${Uri.encodeComponent(category)}';
        }

        categories.add({
          'title': category,
          'imageUrl': imageUrl,
        });
      }

      // Add default categories if none found and meal time is specified
      if (categories.isEmpty && widget.mealTime != null) {
        print('⚠️ [MealCategoryPage] No categories found, adding defaults');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No ${widget.mealTime} categories found. Showing sample categories.'),
            backgroundColor: Colors.orange,
          ),
        );

        categories.addAll([
          {
            'title': 'Rice and Curry',
            'imageUrl': 'https://via.placeholder.com/150?text=Rice+and+Curry',
          },
          {
            'title': 'String Hoppers',
            'imageUrl': 'https://via.placeholder.com/150?text=String+Hoppers',
          },
        ]);
      }

      setState(() {
        _categoryItems = categories;
        _filteredCategoryItems = List.from(categories);
        _isLoading = false;
      });

      print(
          '✅ [MealCategoryPage] Loaded ${categories.length} categories for display');
    } catch (e) {
      print('❌ [MealCategoryPage] Critical error loading data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }

      setState(() {
        // Add minimal fallback categories
        _categoryItems = [
          {
            'title': 'Rice and Curry',
            'imageUrl': 'https://via.placeholder.com/150?text=Rice+and+Curry',
          }
        ];
        _filteredCategoryItems = List.from(_categoryItems);
        _isLoading = false;
      });
    }
  }

  // Get image path for category
  String _getCategoryImagePath(String category) {
    switch (category) {
      case 'Rice and Curry':
        return 'category_icons/rice_curry.png';
      case 'String Hoppers':
        return 'category_icons/string_hoppers.png';
      case 'Roti':
        return 'category_icons/roti.png';
      case 'Egg Roti':
        return 'category_icons/egg_roti.png';
      case 'Short Eats':
        return 'category_icons/short_eats.png';
      case 'Hoppers':
        return 'category_icons/hoppers.png';
      case 'Fried Rice':
        return 'category_icons/fried_rice.png';
      case 'Pittu':
        return 'category_icons/pittu.png';
      default:
        return 'category_icons/default_category.png';
    }
  }

  // ✅ IMPROVED: Navigate to meal page for selected category
  void _selectCategory(String category) {
    print(
        '🎯 [MealCategoryPage] Navigating to category: $category with mealTime: ${widget.mealTime}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPage(
          categoryTitle: category,
          mealType: widget.mealTime, // ✅ Pass the meal time to MealPage
          showBottomNav: widget.showBottomNav, // ✅ Preserve bottom nav setting
        ),
      ),
    ).then((selectedTabIndex) {
      // ✅ Handle navigation back from MealPage
      if (selectedTabIndex != null && selectedTabIndex is int) {
        Navigator.pop(context, selectedTabIndex);
      }
    });
  }

  // ✅ Handle bottom nav taps
  void _onBottomNavTap(int index) {
    if (index == 0) {
      // Home tab - go back to home
      Navigator.pop(context);
    } else {
      // Other tabs - pop back with the selected index
      Navigator.pop(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.purple))
            : Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // Hero image with title overlay
                        SliverToBoxAdapter(
                          child: Stack(
                            children: [
                              // Hero image
                              SizedBox(
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                                child: _heroImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _heroImageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.purple),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.purple.withOpacity(0.1),
                                          child: Center(
                                            child: Icon(
                                              _getIconForMealTime(
                                                  widget.mealTime),
                                              size: 48,
                                              color: Colors.purple
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.purple.withOpacity(0.1),
                                        child: Center(
                                          child: Icon(
                                            _getIconForMealTime(
                                                widget.mealTime),
                                            size: 48,
                                            color:
                                                Colors.purple.withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                              ),

                              // Dark gradient overlay for better text visibility
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),

                              // Status bar and back button
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Back button
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Row(
                                          children: [
                                            Icon(Icons.arrow_back,
                                                size: 20, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'Back',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Time
                                      Text(
                                        _getCurrentTime(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Category page title based on meal time
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.mealTime ?? 'Food Categories',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3.0,
                                            color: Color.fromARGB(150, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.mealTime != null
                                          ? 'Available ${widget.mealTime} options'
                                          : 'Discover delicious Sri Lankan cuisine',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3.0,
                                            color: Color.fromARGB(150, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Search bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
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
                                          hintText: 'Search categories',
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
                          ),
                        ),

                        // Categories grid
                        _filteredCategoryItems.isEmpty
                            ? SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isNotEmpty
                                            ? 'No categories match your search'
                                            : widget.mealTime != null
                                                ? 'No categories available for ${widget.mealTime}'
                                                : 'No food categories available',
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
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.0,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return _buildCategoryItem(
                                          _filteredCategoryItems[index]);
                                    },
                                    childCount: _filteredCategoryItems.length,
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

  // Get current time for status bar
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  // Get icon for meal time
  IconData _getIconForMealTime(String? mealTime) {
    if (mealTime == null) return Icons.restaurant_menu;

    switch (mealTime.toLowerCase()) {
      case 'breakfast':
        return Icons.coffee;
      case 'lunch':
        return Icons.restaurant;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant_menu;
    }
  }

  // Build category item widget
  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final title = category['title'] as String;
    final imageUrl = category['imageUrl'] as String? ?? '';

    return GestureDetector(
      onTap: () => _selectCategory(title),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8E1F4), // Light pink background
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
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
                        errorWidget: (context, url, error) => Container(
                          padding: const EdgeInsets.all(12),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              title.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade300,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            title.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade300,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            // Title
            Expanded(
              flex: 1,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
