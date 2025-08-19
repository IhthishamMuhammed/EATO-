import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/CartService.dart';
import 'package:eato/services/firebase_subscription_service.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/EatoComponents.dart';

class ShopMenuModal extends StatefulWidget {
  final String shopId;
  final String? shopName;

  const ShopMenuModal({
    Key? key,
    required this.shopId,
    this.shopName,
  }) : super(key: key);

  @override
  State<ShopMenuModal> createState() => _ShopMenuModalState();
}

class _ShopMenuModalState extends State<ShopMenuModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _shop;
  List<String> _availableCategories = [];
  List<Map<String, dynamic>> _currentFoods = [];
  String _selectedMealTime = 'Breakfast';
  String _selectedCategory = '';
  bool _isLoading = true;
  String? _error;
  bool _isSubscribed = false;

  final List<String> _mealTimes = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealTimes.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadShopData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedMealTime = _mealTimes[_tabController.index];
        _selectedCategory = ''; // Reset category when meal time changes
      });
      _loadCategoriesForMealTime();
    }
  }

  Future<void> _loadShopData() async {
    try {
      print('🏪 [ShopMenuModal] Loading shop data for ${widget.shopId}');

      // Load shop details
      final shopDoc =
          await _firestore.collection('stores').doc(widget.shopId).get();

      if (shopDoc.exists) {
        _shop = shopDoc.data();
        _shop!['id'] = shopDoc.id;
        print('✅ [ShopMenuModal] Shop loaded: ${_shop!['name']}');
      } else {
        _shop = {
          'id': widget.shopId,
          'name': widget.shopName ?? 'Restaurant',
          'contact': '',
          'imageUrl': '',
          'location': 'Location not specified',
          'rating': 0.0,
          'isPickup': true,
          'isActive': true,
          'isAvailable': true,
        };
        print('⚠️ [ShopMenuModal] Shop not found, using default data');
      }

      // Load subscription status
      await _loadSubscriptionStatus();

      // Load categories and foods for the default meal time
      await _loadCategoriesForMealTime();
    } catch (e) {
      print('❌ [ShopMenuModal] Error loading shop data: $e');
      setState(() {
        _error = 'Failed to load shop menu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final isSubscribed =
          await FirebaseSubscriptionService.isSubscribed(widget.shopId);
      setState(() {
        _isSubscribed = isSubscribed;
      });
    } catch (e) {
      print('⚠️ [ShopMenuModal] Error loading subscription status: $e');
    }
  }

  Future<void> _loadCategoriesForMealTime() async {
    try {
      print('🔍 [ShopMenuModal] Loading categories for $_selectedMealTime');

      // Get all foods for this meal time first
      final foodsSnapshot = await _firestore
          .collection('stores')
          .doc(widget.shopId)
          .collection('foods')
          .where('time', isEqualTo: _selectedMealTime)
          .where('isAvailable', isEqualTo: true)
          .get();

      print(
          '📊 [ShopMenuModal] Found ${foodsSnapshot.docs.length} foods for $_selectedMealTime');

      // Extract unique categories
      Set<String> categories = {};
      List<Map<String, dynamic>> allFoods = [];

      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        allFoods.add(data);

        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      print('📂 [ShopMenuModal] Found categories: $categories');

      setState(() {
        _availableCategories = categories.toList();
        if (_availableCategories.isNotEmpty && _selectedCategory.isEmpty) {
          _selectedCategory = _availableCategories.first;
        }
      });

      // Load foods for the selected category
      if (_selectedCategory.isNotEmpty) {
        await _loadFoodsForCategoryAndTime();
      } else {
        // If no categories, show all foods for this meal time
        setState(() {
          _currentFoods = allFoods;
        });
      }
    } catch (e) {
      print('❌ [ShopMenuModal] Error loading categories: $e');
    }
  }

  Future<void> _loadFoodsForCategoryAndTime() async {
    if (_selectedCategory.isEmpty) return;

    try {
      print(
          '🍽️ [ShopMenuModal] Loading foods for $_selectedCategory at $_selectedMealTime');

      final foodsSnapshot = await _firestore
          .collection('stores')
          .doc(widget.shopId)
          .collection('foods')
          .where('category', isEqualTo: _selectedCategory)
          .where('time', isEqualTo: _selectedMealTime)
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> foods = [];
      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        foods.add(data);
      }

      setState(() {
        _currentFoods = foods;
      });

      print(
          '✅ [ShopMenuModal] Loaded ${foods.length} foods for $_selectedCategory');
    } catch (e) {
      print('❌ [ShopMenuModal] Error loading foods: $e');
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      _loadFoodsForCategoryAndTime();
    }
  }

  // ✅ FIXED: Show cart modal instead of direct addition
  Future<void> _addToCart(Map<String, dynamic> foodData) async {
    try {
      // Convert food data to portionPrices format
      final portionPrices = foodData['portionPrices'] as Map<String, dynamic>?;
      final convertedPortionPrices = <String, double>{};

      if (portionPrices != null) {
        portionPrices.forEach((key, value) {
          convertedPortionPrices[key] = (value as num).toDouble();
        });
      }

      // Show the cart confirmation modal using EatoComponents
      await EatoComponents.showAddToCartModal(
        context: context,
        foodName: foodData['name'],
        foodImage: foodData['imageUrl'] ?? '',
        basePrice: (foodData['price'] as num).toDouble(),
        portionPrices: convertedPortionPrices,
        description: foodData['description'],
        onAddToCart: (portion, quantity, instructions) async {
          // Calculate the effective price (from portion or base price)
          final effectivePrice = convertedPortionPrices[portion] ??
              (foodData['price'] as num).toDouble();

          // Add to cart using CartService with correct parameters
          await CartService.addToCart(
            foodId: foodData['id'],
            foodName: foodData['name'],
            foodImage: foodData['imageUrl'] ?? '',
            price: effectivePrice,
            quantity: quantity,
            shopId: widget.shopId,
            shopName: _shop!['name'],
            variation: portion.isNotEmpty ? portion : null,
            specialInstructions: instructions ?? '',
          );
        },
      );

      // Optional: Update UI or show feedback
      setState(() {
        // Could update cart count or other UI elements
      });
    } catch (e) {
      print('❌ [ShopMenuModal] Error showing cart modal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _toggleSubscription() async {
    try {
      if (_isSubscribed) {
        await FirebaseSubscriptionService.unsubscribeFromShop(widget.shopId);
      } else {
        // Prepare shop data for subscription
        final shopData = {
          'shopName': _shop!['name'],
          'shopImage': _shop!['imageUrl'] ?? '',
          'shopRating': (_shop!['rating'] as num?)?.toDouble() ?? 0.0,
          'shopContact': _shop!['contact'] ?? '',
          'shopLocation': _shop!['location'] ?? 'Location not specified',
          'isPickup': _shop!['isPickup'] ?? true,
          'distance': 2.5, // Mock distance
          'deliveryTime': 30, // Mock time
        };

        await FirebaseSubscriptionService.subscribeToShop(
            widget.shopId, shopData);
      }

      setState(() {
        _isSubscribed = !_isSubscribed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSubscribed ? 'Subscribed!' : 'Unsubscribed'),
          backgroundColor:
              _isSubscribed ? EatoTheme.successColor : Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ [ShopMenuModal] Error toggling subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating subscription'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  String _getPriceDisplayText(Map<String, dynamic> foodData) {
    final portionPrices = foodData['portionPrices'] as Map<String, dynamic>?;

    if (portionPrices != null && portionPrices.isNotEmpty) {
      // Find the cheapest portion
      double minPrice = portionPrices.values
          .map((price) => (price as num).toDouble())
          .reduce((a, b) => a < b ? a : b);

      if (portionPrices.length > 1) {
        return 'From ₹${minPrice.toStringAsFixed(2)}';
      } else {
        return '₹${minPrice.toStringAsFixed(2)}';
      }
    }

    final price = (foodData['price'] as num).toDouble();
    return '₹${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: EatoTheme.bodyMedium.copyWith(
                          color: EatoTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Shop Header
            _buildShopHeader(),

            // Meal Time Tabs
            _buildMealTimeTabs(),

            // Category Selection (if categories available)
            if (_availableCategories.isNotEmpty) _buildCategorySelection(),

            // Foods List
            Expanded(
              child: _currentFoods.isEmpty
                  ? _buildEmptyState()
                  : _buildFoodsList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Shop Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _shop!['imageUrl'] != null && _shop!['imageUrl'].isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _shop!['imageUrl'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.store),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.store),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.store),
                  ),
          ),
          const SizedBox(width: 12),

          // Shop Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shop!['name'],
                  style: EatoTheme.headingMedium,
                ),
                const SizedBox(height: 4),
                if (_shop!['location'] != null && _shop!['location'].isNotEmpty)
                  Text(
                    _shop!['location'],
                    style: EatoTheme.bodySmall.copyWith(
                      color: EatoTheme.textSecondaryColor,
                    ),
                  ),
                if (_shop!['rating'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        (_shop!['rating'] as num).toStringAsFixed(1),
                        style: EatoTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Subscription Button
          IconButton(
            onPressed: _toggleSubscription,
            icon: Icon(
              _isSubscribed
                  ? Icons.notifications
                  : Icons.notifications_outlined,
              color: _isSubscribed ? EatoTheme.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeTabs() {
    return Container(
      height: 50,
      child: TabBar(
        controller: _tabController,
        labelColor: EatoTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: EatoTheme.primaryColor,
        tabs: _mealTimes.map((time) => Tab(text: time)).toList(),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableCategories.length,
        itemBuilder: (context, index) {
          final category = _availableCategories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onCategorySelected(category);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: EatoTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? EatoTheme.primaryColor : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'No ${_selectedMealTime.toLowerCase()} items available',
              textAlign: TextAlign.center,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            if (_availableCategories.isNotEmpty &&
                _selectedCategory.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'in $_selectedCategory category',
                textAlign: TextAlign.center,
                style: EatoTheme.bodySmall.copyWith(
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentFoods.length,
      itemBuilder: (context, index) {
        final food = _currentFoods[index];
        return _buildFoodCard(food);
      },
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Food Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: food['imageUrl'] != null && food['imageUrl'].isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: food['imageUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant),
                    ),
            ),
            const SizedBox(width: 12),

            // Food Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'],
                    style: EatoTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (food['description'] != null &&
                      food['description'].isNotEmpty)
                    Text(
                      food['description'],
                      style: EatoTheme.bodySmall.copyWith(
                        color: EatoTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _getPriceDisplayText(food),
                    style: EatoTheme.bodyMedium.copyWith(
                      color: EatoTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ FIXED: Add to Cart button shows modal
            ElevatedButton(
              onPressed: () => _addToCart(food),
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: EatoTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show the modal
  static Future<void> show({
    required BuildContext context,
    required String shopId,
    String? shopName,
  }) async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShopMenuModal(
          shopId: shopId,
          shopName: shopName,
        );
      },
    );
  }
}
