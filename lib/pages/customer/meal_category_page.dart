import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/Firebase_Storage_Service.dart';

class MealCategoryPage extends StatefulWidget {
  final String categoryTitle;
  final bool showBottomNav;

  const MealCategoryPage({
    Key? key,
    required this.categoryTitle,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<MealCategoryPage> createState() => _MealCategoryPageState();
}

class _MealCategoryPageState extends State<MealCategoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _foodItems = [];
  String _heroImageUrl = '';
  final FirebaseStorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // Load Firebase images
  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get hero image URL
      final heroImagePath = _getCategoryHeroImagePath(widget.categoryTitle);
      _heroImageUrl = await _storageService.getImageUrl(heroImagePath);

      // Get food items
      final items = _getFoodItemsForCategory(widget.categoryTitle);

      // Load image for each food item
      for (var item in items) {
        final imagePath = item['imagePath'] as String;
        final imageUrl = await _storageService.getImageUrl(imagePath);
        item['image'] = imageUrl;
      }

      setState(() {
        _foodItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading images: $e');
      setState(() {
        _isLoading = false;
      });
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero image with category title overlay
                        Stack(
                          children: [
                            // Hero image
                            SizedBox(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.28,
                              child: _heroImageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _heroImageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
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
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported),
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

                                    // Status bar time
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

                            // Category title
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Text(
                                widget.categoryTitle,
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
                            ),
                          ],
                        ),

                        // Food items list
                        Expanded(
                          child: _foodItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No items available in this category',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(top: 8),
                                  itemCount: _foodItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _foodItems[index];
                                    return _buildFoodItemCard(item);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Navigation Bar
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

  // Get current time for status bar
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  // Build food item card
  Widget _buildFoodItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        onTap: () {
          // Navigate to food details page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: ${item['title']}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Row(
          children: [
            // Food image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: item['image'] != null && item['image'].isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item['image'],
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
                      item['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
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
                        Text(
                          'Rs. ${item['price']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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

  // Get Firebase Storage path for category hero image
  String _getCategoryHeroImagePath(String category) {
    switch (category) {
      case 'Rice and Curry':
        return 'categories/rice_curry_hero.jpg';
      case 'String Hoppers':
        return 'categories/string_hoppers_hero.jpg';
      case 'Roti':
        return 'categories/roti_hero.jpg';
      case 'Egg Roti':
        return 'categories/egg_roti_hero.jpg';
      case 'Short Eats':
        return 'categories/short_eats_hero.jpg';
      case 'Hoppers':
        return 'categories/hoppers_hero.jpg';
      case 'Fried Rice':
        return 'categories/fried_rice_hero.jpg';
      case 'Pittu':
        return 'categories/pittu_hero.jpg';
      default:
        return 'categories/default_food_hero.jpg';
    }
  }

  // Get food items for selected category with Firebase image paths
  List<Map<String, dynamic>> _getFoodItemsForCategory(String category) {
    switch (category) {
      case 'Rice and Curry':
        return [
          {
            'title': 'Rice and Curry - Egg',
            'description': 'Steamed rice with egg curry and 3 vegetables',
            'price': '250.00',
            'imagePath': 'food_items/rice_curry_egg.jpg',
          },
          {
            'title': 'Rice and Curry - Chicken',
            'description': 'Steamed rice with chicken curry and 3 vegetables',
            'price': '350.00',
            'imagePath': 'food_items/rice_curry_chicken.jpg',
          },
          {
            'title': 'Rice and Curry - Fish',
            'description': 'Steamed rice with fish curry and 3 vegetables',
            'price': '300.00',
            'imagePath': 'food_items/rice_curry_fish.jpg',
          },
          {
            'title': 'Vegetable Rice',
            'description': 'Steamed rice with 5 different vegetables',
            'price': '200.00',
            'imagePath': 'food_items/vegetable_rice.jpg',
          },
        ];
      case 'String Hoppers':
        return [
          {
            'title': 'String Hoppers with Curry',
            'description':
                'String hoppers with chicken curry and coconut sambol',
            'price': '250.00',
            'imagePath': 'food_items/string_hoppers_curry.jpg',
          },
          {
            'title': 'String Hoppers with Kiri Hodi',
            'description':
                'String hoppers with coconut milk gravy and pol sambol',
            'price': '200.00',
            'imagePath': 'food_items/string_hoppers_kiri.jpg',
          },
        ];
      case 'Roti':
        return [
          {
            'title': 'Plain Roti',
            'description': 'Freshly made plain coconut roti (2 pieces)',
            'price': '120.00',
            'imagePath': 'food_items/plain_roti.jpg',
          },
          {
            'title': 'Vegetable Roti',
            'description': 'Roti stuffed with spiced vegetables',
            'price': '150.00',
            'imagePath': 'food_items/veg_roti.jpg',
          },
        ];
      // Add more categories as needed
      default:
        return [
          {
            'title': 'Default Item 1',
            'description': 'Description for default item 1',
            'price': '200.00',
            'imagePath': 'food_items/default_food.jpg',
          },
          {
            'title': 'Default Item 2',
            'description': 'Description for default item 2',
            'price': '250.00',
            'imagePath': 'food_items/default_food.jpg',
          },
        ];
    }
  }
}
