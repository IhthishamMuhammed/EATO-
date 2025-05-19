import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/Firebase_Storage_Service.dart';
import 'package:eato/pages/customer/meal_category_page.dart';

class MealPage extends StatefulWidget {
  final String mealType; // 'Breakfast', 'Lunch', or 'Dinner'
  final bool showBottomNav;

  const MealPage({
    Key? key,
    required this.mealType,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _categoryItems = [];
  final FirebaseStorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    // Set up search listener
    _searchController.addListener(_onSearchChanged);

    // Initialize food provider with meal type filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      foodProvider.setFilterMealTime(widget.mealType);
      _loadCategoryImages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    foodProvider.setSearchQuery(_searchController.text);
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? '' : category;
    });

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    foodProvider.setFilterCategory(_selectedCategory);

    // Navigate to MealCategoryPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealCategoryPage(
          categoryTitle: category,
          showBottomNav: widget.showBottomNav,
        ),
      ),
    );
  }

  // Load Firebase images for categories
  Future<void> _loadCategoryImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get category items based on meal type
      final List<Map<String, dynamic>> categories = _getMealCategoryItems();

      // Load image for each category
      for (var category in categories) {
        final imagePath = category['imagePath'] as String;
        final imageUrl = await _storageService.getImageUrl(imagePath);
        category['imageUrl'] = imageUrl;
      }

      setState(() {
        _categoryItems = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading category images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get the appropriate food category items based on meal type
  List<Map<String, dynamic>> _getMealCategoryItems() {
    final List<Map<String, dynamic>> categories = [];

    // Common categories for all meal types
    final commonCategories = [
      {'title': 'Rice and Curry', 'imagePath': 'category_icons/rice_curry.png'},
      {
        'title': 'String Hoppers',
        'imagePath': 'category_icons/string_hoppers.png'
      },
      {'title': 'Roti', 'imagePath': 'category_icons/roti.png'},
      {'title': 'Egg Roti', 'imagePath': 'category_icons/egg_roti.png'},
    ];

    // Add common categories first
    categories.addAll(commonCategories);

    // Add meal-specific categories
    switch (widget.mealType) {
      case 'Breakfast':
        categories.addAll([
          {'title': 'Short Eats', 'imagePath': 'category_icons/short_eats.png'},
          {'title': 'Hoppers', 'imagePath': 'category_icons/hoppers.png'},
        ]);
        break;
      case 'Lunch':
        categories.addAll([
          {
            'title': 'String Hopper',
            'imagePath': 'category_icons/string_hopper.png'
          },
          {'title': 'Fried Rice', 'imagePath': 'category_icons/fried_rice.png'},
          {'title': 'Shorties', 'imagePath': 'category_icons/shorties.png'},
          {'title': 'Pittu', 'imagePath': 'category_icons/pittu.png'},
        ]);
        break;
      case 'Dinner':
        categories.addAll([
          {'title': 'Short Eats', 'imagePath': 'category_icons/short_eats.png'},
          {'title': 'Hoppers', 'imagePath': 'category_icons/hoppers.png'},
        ]);
        break;
      default:
        break;
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                      widget.mealType,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    // Search bar
                    const SizedBox(height: 16),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Colors.grey.shade500, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by Category',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                },
                                child: Icon(Icons.clear,
                                    size: 18, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Menu items grid
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.purple),
                            )
                          : GridView.count(
                              crossAxisCount: 2,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              children: _categoryItems
                                  .map((category) =>
                                      _buildCategoryItem(category))
                                  .toList(),
                              padding: const EdgeInsets.only(bottom: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar - only if showBottomNav is true
            if (widget.showBottomNav)
              BottomNavBar(
                currentIndex: 0, // Home tab is selected
                onTap: (index) {
                  if (index != 0) {
                    Navigator.pop(context, index);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final title = category['title'] as String;
    final imageUrl = category['imageUrl'] as String? ?? '';

    return GestureDetector(
      onTap: () => _selectCategory(title),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8E1F4), // Light pink background
          borderRadius: BorderRadius.circular(16),
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
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.image_not_supported,
                        size: 32,
                        color: Colors.grey,
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
