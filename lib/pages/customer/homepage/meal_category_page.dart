// COMPLETE ELEGANT THEMED meal_category_page.dart
// Matching EatoTheme with beautiful design, letter icons, and robust image loading

import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/pages/customer/homepage/meal_pages.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class MealCategoryPage extends StatefulWidget {
  final String? mealTime;
  final bool showBottomNav;

  const MealCategoryPage({
    Key? key,
    this.mealTime,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<MealCategoryPage> createState() => _MealCategoryPageState();
}

class _MealCategoryPageState extends State<MealCategoryPage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<Map<String, dynamic>> _categoryItems = [];
  List<Map<String, dynamic>> _filteredCategoryItems = [];
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ✅ ROBUST IMAGE LOADING: Multiple fallback URLs for each meal type
  final Map<String, List<String>> _heroImageOptions = {
    'Breakfast': [
      'https://images.unsplash.com/photo-1551218808-94e220e084d2?q=80&w=800',
      'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://cdn.pixabay.com/photo/2017/05/07/08/56/pancakes-2291908_960_720.jpg',
    ],
    'Lunch': [
      'https://images.unsplash.com/photo-1547592180-85f173990888?q=80&w=800',
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?q=80&w=800',
      'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://cdn.pixabay.com/photo/2017/12/09/08/18/pizza-3007395_960_720.jpg',
    ],
    'Dinner': [
      'https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=800',
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=800',
      'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://cdn.pixabay.com/photo/2016/12/26/17/28/spaghetti-1932466_960_720.jpg',
    ],
    'default': [
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=800',
      'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://cdn.pixabay.com/photo/2017/07/16/10/43/recipe-2509943_960_720.jpg',
    ],
  };

  // ✅ ELEGANT: Get first letter with themed colors
  Map<String, dynamic> _getCategoryDisplay(String category) {
    // Map categories to appropriate icons and colors
    final categoryIcons = {
      'Rice and Curry': Icons.rice_bowl,
      'String Hoppers': Icons.ramen_dining,
      'Roti': Icons.flatware,
      'Egg Roti': Icons.breakfast_dining,
      'Short Eats': Icons.fastfood,
      'Hoppers': Icons.soup_kitchen,
      'Kottu': Icons.restaurant,
      'Fried Rice': Icons.rice_bowl,
      'Noodles': Icons.ramen_dining,
      'Sandwich': Icons.lunch_dining,
      'Pizza': Icons.local_pizza,
      'Burger': Icons.lunch_dining,
      'Pasta': Icons.ramen_dining,
      'Chicken': Icons.set_meal,
      'Fish': Icons.set_meal,
      'Vegetarian': Icons.eco,
      'Desserts': Icons.cake,
      'Beverages': Icons.local_cafe,
      'Seafood': Icons.set_meal,
      'BBQ': Icons.outdoor_grill,
    };

    final categoryColors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
      EatoTheme.primaryColor,
      EatoTheme.accentColor,
    ];

    IconData icon = categoryIcons[category] ?? Icons.restaurant_menu;
    int colorIndex = category.hashCode.abs() % categoryColors.length;
    Color color = categoryColors[colorIndex];

    return {
      'icon': icon,
      'color': color,
      'lightColor': color.withOpacity(0.1),
      'mediumColor': color.withOpacity(0.2),
    };
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // ✅ ANIMATIONS: Elegant entrance animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // ✅ FIX: Defer data loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterCategories();
  }

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

  Future<void> _loadData() async {
    // ✅ FIX: Check if widget is still mounted before setState
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      List<String> availableCategories = [];

      try {
        if (widget.mealTime != null) {
          print(
              '🔍 [MealCategoryPage] Getting categories for meal time: ${widget.mealTime}');
          availableCategories =
              await foodProvider.getCategoriesForMealTime(widget.mealTime!);
        } else {
          print('🔍 [MealCategoryPage] Getting all categories');
          availableCategories = await foodProvider.getAllCategories();
        }
      } catch (e) {
        print('❌ [MealCategoryPage] Error getting categories: $e');

        // ✅ FIX: Check mounted before showing SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error loading categories. Using fallback options.'),
              backgroundColor: EatoTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }

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
          '✅ [MealCategoryPage] Found ${availableCategories.length} categories');

      final List<Map<String, dynamic>> categories =
          availableCategories.map((category) {
        final display = _getCategoryDisplay(category);
        return {
          'title': category,
          'letter': display['letter'],
          'color': display['color'],
          'bgColor': display['bgColor'],
          'gradient': display['gradient'],
        };
      }).toList();

      if (categories.isEmpty && widget.mealTime != null) {
        print('⚠️ [MealCategoryPage] No categories found, adding defaults');

        final fallbackCategories = ['Rice and Curry', 'Short Eats'];
        categories.addAll(fallbackCategories.map((category) {
          final display = _getCategoryDisplay(category);
          return {
            'title': category,
            'letter': display['letter'],
            'color': display['color'],
            'bgColor': display['bgColor'],
            'gradient': display['gradient'],
          };
        }));
      }

      // ✅ FIX: Check mounted before setState
      if (mounted) {
        setState(() {
          _categoryItems = categories;
          _filteredCategoryItems = List.from(categories);
          _isLoading = false;
        });
      }

      print('✅ [MealCategoryPage] Data loaded successfully');
    } catch (e) {
      print('❌ [MealCategoryPage] Critical error loading data: $e');

      // ✅ FIX: Check mounted before setState
      if (mounted) {
        setState(() {
          final fallbackDisplay = _getCategoryDisplay('Rice and Curry');
          _categoryItems = [
            {
              'title': 'Rice and Curry',
              'letter': fallbackDisplay['letter'],
              'color': fallbackDisplay['color'],
              'bgColor': fallbackDisplay['bgColor'],
              'gradient': fallbackDisplay['gradient'],
            }
          ];
          _filteredCategoryItems = List.from(_categoryItems);
          _isLoading = false;
        });
      }
    }
  }

  void _selectCategory(String category) {
    print('🎯 [MealCategoryPage] Navigating to category: $category');

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MealPage(
          categoryTitle: category,
          mealType: widget.mealTime,
          showBottomNav: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((selectedTabIndex) {
      if (selectedTabIndex != null && selectedTabIndex is int) {
        Navigator.pop(context, selectedTabIndex);
      }
    });
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context, index);
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  IconData _getIconForMealTime(String? mealTime) {
    switch (mealTime?.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant_menu;
    }
  }

  // ✅ ROBUST IMAGE LOADING: Widget with multiple fallback attempts
  Widget _buildHeroImage() {
    final options =
        _heroImageOptions[widget.mealTime] ?? _heroImageOptions['default']!;

    return _ImageWithFallbacks(
      imageUrls: options,
      fit: BoxFit.cover,
      loadingWidget: Container(
        decoration: BoxDecoration(
          gradient: EatoTheme.primaryGradient,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      errorWidget: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EatoTheme.primaryColor,
              EatoTheme.primaryDarkColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForMealTime(widget.mealTime),
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                widget.mealTime ?? 'Food',
                style: EatoTheme.headingMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ✅ ELEGANT HERO: Themed hero section with robust image loading
                  SliverToBoxAdapter(
                    child: Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: EatoTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            // ✅ ROBUST HERO IMAGE: Multiple fallback options
                            Positioned.fill(
                              child: _buildHeroImage(),
                            ),

                            // ✅ ELEGANT OVERLAY: Purple gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      EatoTheme.primaryColor.withOpacity(0.7),
                                      EatoTheme.primaryDarkColor
                                          .withOpacity(0.9),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Header content
                            Positioned(
                              top: 20,
                              left: 20,
                              right: 20,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _getCurrentTime(),
                                            style:
                                                EatoTheme.bodyMedium.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ✅ ELEGANT TITLE: Beautiful centered title section
                            Positioned(
                              bottom: 40,
                              left: 20,
                              right: 20,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          _getIconForMealTime(widget.mealTime),
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        widget.mealTime ?? 'Food Categories',
                                        style: EatoTheme.headingLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.mealTime != null
                                            ? 'Choose your ${widget.mealTime!.toLowerCase()} category'
                                            : 'Explore delicious food categories',
                                        style: EatoTheme.bodyMedium.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ✅ ELEGANT SEARCH: Themed search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: EatoTheme.primaryColor.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: EatoTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search categories...',
                              hintStyle: EatoTheme.bodyMedium.copyWith(
                                color: EatoTheme.textSecondaryColor,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: EatoTheme.primaryColor,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: EatoTheme.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  _isLoading
                      ? SliverToBoxAdapter(
                          child: Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    EatoTheme.primaryColor),
                              ),
                            ),
                          ),
                        )
                      : _filteredCategoryItems.isEmpty
                          ? SliverToBoxAdapter(
                              child: Container(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: EatoTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Icon(
                                          Icons.search_off,
                                          size: 48,
                                          color: EatoTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        _searchController.text.isNotEmpty
                                            ? 'No categories match your search'
                                            : widget.mealTime != null
                                                ? 'No categories available for ${widget.mealTime}'
                                                : 'No food categories available',
                                        style: EatoTheme.bodyMedium.copyWith(
                                          color: EatoTheme.textSecondaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 120),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        final delay = index * 0.1;
                                        final animationValue =
                                            Curves.easeOutBack.transform(
                                          ((_animationController.value - delay)
                                                      .clamp(0.0, 1.0) /
                                                  (1.0 - delay))
                                              .clamp(0.0, 1.0),
                                        );
                                        return Transform.scale(
                                          scale: animationValue,
                                          child: Opacity(
                                            opacity: animationValue,
                                            child: _buildCategoryItem(
                                                _filteredCategoryItems[index]),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  childCount: _filteredCategoryItems.length,
                                ),
                              ),
                            ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ✅ ALWAYS VISIBLE: Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // ✅ ELEGANT CATEGORY CARD: Beautiful letter-based cards with theme colors
  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final display = _getCategoryDisplay(category['title']);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _selectCategory(category['title']),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        display['color'],
                        display['color'].withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: display['color'].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    display['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 16),

                // Category title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['title'],
                        style: EatoTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: EatoTheme.textPrimaryColor,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle or description
                      Text(
                        'Explore options',
                        style: EatoTheme.bodySmall.copyWith(
                          color: EatoTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Small dot indicator
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: display['color'].withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: EatoTheme.textSecondaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ HELPER WIDGET: Image widget that tries multiple URLs automatically
class _ImageWithFallbacks extends StatefulWidget {
  final List<String> imageUrls;
  final BoxFit fit;
  final Widget loadingWidget;
  final Widget errorWidget;

  const _ImageWithFallbacks({
    required this.imageUrls,
    required this.fit,
    required this.loadingWidget,
    required this.errorWidget,
  });

  @override
  _ImageWithFallbacksState createState() => _ImageWithFallbacksState();
}

class _ImageWithFallbacksState extends State<_ImageWithFallbacks> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _currentIndex >= widget.imageUrls.length) {
      return widget.errorWidget;
    }

    if (_isLoading) {
      return Stack(
        children: [
          widget.loadingWidget,
          _buildCurrentImage(),
        ],
      );
    }

    return _buildCurrentImage();
  }

  Widget _buildCurrentImage() {
    if (_currentIndex >= widget.imageUrls.length) {
      return widget.errorWidget;
    }

    return Image.network(
      widget.imageUrls[_currentIndex],
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image loaded successfully
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          });
          return child;
        }
        // Still loading, show nothing (loading widget is shown from parent Stack)
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        print(
            '❌ Image failed to load: ${widget.imageUrls[_currentIndex]} - Error: $error');

        // Try next image URL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (_currentIndex < widget.imageUrls.length - 1) {
              // Try next image
              print(
                  '🔄 Trying next image URL: ${widget.imageUrls[_currentIndex + 1]}');
              setState(() {
                _currentIndex++;
                _isLoading = true;
              });
            } else {
              // All images failed, show error widget
              print(
                  '💥 All ${widget.imageUrls.length} image URLs failed, showing error widget');
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          }
        });

        return const SizedBox.shrink();
      },
    );
  }
}
