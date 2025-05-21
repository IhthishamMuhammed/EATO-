import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/Firebase_Storage_Service.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this for GeoPoint

class ShopCategoryPage extends StatefulWidget {
  final String mealTitle; // The meal title (e.g., "Chicken Rice and Curry")
  final String categoryTitle; // The category (e.g., "Rice and Curry")
  final bool showBottomNav;

  const ShopCategoryPage({
    Key? key,
    required this.mealTitle,
    required this.categoryTitle,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<ShopCategoryPage> createState() => _ShopCategoryPageState();
}

class _ShopCategoryPageState extends State<ShopCategoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _shopItems = [];
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String _selectedFilter = "Best Match"; // Default filter option

  // Filter options
  final List<String> _filterOptions = [
    "Best Match",
    "Price: Low to High",
    "Price: High to Low",
    "Rating",
    "Distance"
  ];

  @override
  void initState() {
    super.initState();
    _loadShopsData();
  }

  // Load shops data from Firebase based on the meal title
  Future<void> _loadShopsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get FoodProvider instance
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      // Fetch all shops that offer this meal
      final shops = await foodProvider.getShopsForMeal(
          widget.mealTitle, widget.categoryTitle);

      // Process shop data
      List<Map<String, dynamic>> shopItems = [];

      for (var shopData in shops) {
        final store = shopData['store'] as Store;
        final food = shopData['food'] as Food;

        // Create shop item map with distance estimate
        final distance = _calculateDistance(store.coordinates);

        final shopItem = {
          'shopId': store.id,
          'shopName': store.name,
          'rating': store.rating ?? 4.0,
          'distance': distance,
          'deliveryTime': _estimateDeliveryTime(distance),
          'foodId': food.id,
          'foodName': food.name,
          'description': food.description ?? 'No description available',
          'price': food.price,
          'shopImage': store.imageUrl,
          'foodImage': food.imageUrl,
          'foodType': food.type,
          'variation': _getVariationName(food.type),
        };

        shopItems.add(shopItem);
      }

      // Sort shops based on selected filter
      _sortShopItems(shopItems, _selectedFilter);

      setState(() {
        _shopItems = shopItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shops data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate distance based on shop coordinates
  double _calculateDistance(GeoPoint? coordinates) {
    // In a real app, you would calculate the actual distance from user's location
    // This is a mock implementation
    if (coordinates == null) return 3.0;

    // Random distance between 0.5 and 5.0 km based on coordinates
    return (coordinates.latitude.abs() % 4.5) + 0.5;
  }

  // Estimate delivery time based on distance
  int _estimateDeliveryTime(double distance) {
    // Base time of 15 mins + 5 mins per km
    return 15 + (distance * 5).round();
  }

  // Get variation name based on food type
  String _getVariationName(String foodType) {
    switch (foodType) {
      case 'Vegetarian':
        return 'Vegetarian';
      case 'Non-Vegetarian':
        return 'Traditional';
      case 'Vegan':
        return 'Healthy';
      case 'Dessert':
        return 'Sweet';
      default:
        return 'Classic';
    }
  }

  // Apply sorting based on filter
  void _sortShopItems(List<Map<String, dynamic>> items, String filter) {
    switch (filter) {
      case "Price: Low to High":
        items.sort(
            (a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case "Price: High to Low":
        items.sort(
            (a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case "Rating":
        items.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case "Distance":
        items.sort((a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));
        break;
      case "Best Match":
      default:
        // Best match uses a weighted algorithm of rating, price and distance
        items.sort((a, b) {
          double aScore = (a['rating'] as double) * 0.5 -
              (a['distance'] as double) * 0.3 -
              (a['price'] as double) * 0.2;
          double bScore = (b['rating'] as double) * 0.5 -
              (b['distance'] as double) * 0.3 -
              (b['price'] as double) * 0.2;
          return bScore.compareTo(aScore);
        });
        break;
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
                        // App bar with back button and title
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Back button
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
                              const Spacer(),
                              // Time
                              Text(
                                _getCurrentTime(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Food and category title
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mealTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.categoryTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Filter selection
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFilter,
                                  icon: const Icon(Icons.keyboard_arrow_down,
                                      size: 16),
                                  isDense: true,
                                  isExpanded: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedFilter = newValue;
                                        _sortShopItems(
                                            _shopItems, _selectedFilter);
                                      });
                                    }
                                  },
                                  items: _filterOptions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Shop list
                        Expanded(
                          child: _shopItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Changed from Icons.store_off to Icons.store with a Stack
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.store,
                                            size: 60,
                                            color: Colors.grey.shade300,
                                          ),
                                          Icon(
                                            Icons.close,
                                            size: 72,
                                            color: Colors.red.withOpacity(0.6),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No shops available for this meal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try selecting a different meal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: _shopItems.length,
                                  itemBuilder: (context, index) {
                                    final shop = _shopItems[index];
                                    return _buildShopCard(shop);
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

  // Build shop card
  Widget _buildShopCard(Map<String, dynamic> shop) {
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
          // Navigate to food details or add to cart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Added ${shop['foodName']} from ${shop['shopName']} to cart'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Column(
          children: [
            // Top section with shop info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Shop image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: shop['shopImage'] != null &&
                            shop['shopImage'].isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: shop['shopImage'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[300],
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.purple),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, size: 24),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                            child: const Icon(Icons.store, size: 24),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Shop details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['shopName'] ?? 'Shop',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Rating
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (shop['rating'] ?? 0.0).toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Distance
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${shop['distance'].toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Delivery time
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${shop['deliveryTime']} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Food image and details
            Row(
              children: [
                // Food image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                  child:
                      shop['foodImage'] != null && shop['foodImage'].isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: shop['foodImage'],
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.purple),
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
                          '${shop['variation']} ${shop['foodName']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shop['description'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rs. ${shop['price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
          ],
        ),
      ),
    );
  }
}
