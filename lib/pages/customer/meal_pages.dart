import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';

class MealPage extends StatefulWidget {
  final String mealType; // 'Breakfast', 'Lunch', or 'Dinner'

  const MealPage({
    Key? key,
    required this.mealType,
  }) : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    // Set up search listener
    _searchController.addListener(_onSearchChanged);

    // Initialize food provider with meal type filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      foodProvider.setFilterMealTime(widget.mealType);

      // You can fetch foods here if you have a storeId
      // foodProvider.fetchFoods('your-store-id');
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

    // Show a snackbar for now, you can replace with actual navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected category: $category'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Get the appropriate food category items based on meal type
  List<FoodCategoryItem> _getMealCategoryItems() {
    switch (widget.mealType) {
      case 'Breakfast':
        return [
          FoodCategoryItem(
            title: 'Rice and Curry',
            imagePath: 'assets/rice_curry.png',
            onTap: () => _selectCategory('Rice and Curry'),
          ),
          FoodCategoryItem(
            title: 'String Hoppers',
            imagePath: 'assets/string_hoppers.png',
            onTap: () => _selectCategory('String Hoppers'),
          ),
          FoodCategoryItem(
            title: 'Roti',
            imagePath: 'assets/roti.png',
            onTap: () => _selectCategory('Roti'),
          ),
          FoodCategoryItem(
            title: 'Egg Roti',
            imagePath: 'assets/egg_roti.png',
            onTap: () => _selectCategory('Egg Roti'),
          ),
          FoodCategoryItem(
            title: 'Short Eats',
            imagePath: 'assets/short_eats.png',
            onTap: () => _selectCategory('Short Eats'),
          ),
          FoodCategoryItem(
            title: 'Hoppers',
            imagePath: 'assets/hoppers.png',
            onTap: () => _selectCategory('Hoppers'),
          ),
        ];
      case 'Lunch':
        return [
          FoodCategoryItem(
            title: 'Rotti',
            imagePath: 'assets/roti.png',
            onTap: () => _selectCategory('Rotti'),
          ),
          FoodCategoryItem(
            title: 'Rice and Curry',
            imagePath: 'assets/rice_curry.png',
            onTap: () => _selectCategory('Rice and Curry'),
          ),
          FoodCategoryItem(
            title: 'String Hopper',
            imagePath: 'assets/string_hoppers.png',
            onTap: () => _selectCategory('String Hopper'),
          ),
          FoodCategoryItem(
            title: 'Fried Rice',
            imagePath: 'assets/fried_rice.png',
            onTap: () => _selectCategory('Fried Rice'),
          ),
          FoodCategoryItem(
            title: 'Shorties',
            imagePath: 'assets/shorties.png',
            onTap: () => _selectCategory('Shorties'),
          ),
          FoodCategoryItem(
            title: 'Pittu',
            imagePath: 'assets/pittu.png',
            onTap: () => _selectCategory('Pittu'),
          ),
        ];
      case 'Dinner':
        return [
          FoodCategoryItem(
            title: 'Rice and Curry',
            imagePath: 'assets/rice_curry.png',
            onTap: () => _selectCategory('Rice and Curry'),
          ),
          FoodCategoryItem(
            title: 'String Hoppers',
            imagePath: 'assets/string_hoppers.png',
            onTap: () => _selectCategory('String Hoppers'),
          ),
          FoodCategoryItem(
            title: 'Roti',
            imagePath: 'assets/roti.png',
            onTap: () => _selectCategory('Roti'),
          ),
          FoodCategoryItem(
            title: 'Egg Roti',
            imagePath: 'assets/egg_roti.png',
            onTap: () => _selectCategory('Egg Roti'),
          ),
          FoodCategoryItem(
            title: 'Short Eats',
            imagePath: 'assets/short_eats.png',
            onTap: () => _selectCategory('Short Eats'),
          ),
          FoodCategoryItem(
            title: 'Hoppers',
            imagePath: 'assets/hoppers.png',
            onTap: () => _selectCategory('Hoppers'),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title
                    const SizedBox(height: 20),
                    Text(
                      widget.mealType,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    // Search bar
                    const SizedBox(height: 20),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey.shade500),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by Category',
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                },
                                child: const Icon(Icons.clear, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Menu items grid
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: _getMealCategoryItems(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar
            BottomNavBar(
              currentIndex: 0, // Home tab is selected
              onTap: (index) {
                // If not the home tab, pop and return the index
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
}

class FoodCategoryItem extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const FoodCategoryItem({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8D7F3), // Light pink color
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Food Image
            SizedBox(
              height: 100,
              width: 100,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            // Food Category Name
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
