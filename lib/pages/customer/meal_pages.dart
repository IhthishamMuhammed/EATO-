import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';

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

  @override
  void initState() {
    super.initState();
    // Set up search listener
    _searchController.addListener(_onSearchChanged);

    // Initialize food provider with meal type filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      foodProvider.setFilterMealTime(widget.mealType);
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
    // Existing implementation, no changes needed
    switch (widget.mealType) {
      case 'Breakfast':
        return [
          // Existing items
        ];
      // Other cases remain the same
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
}

// No changes needed to FoodCategoryItem
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
    // Existing implementation
    return GestureDetector(
      onTap: onTap,
      child: Container(
          // Existing implementation
          ),
    );
  }
}
