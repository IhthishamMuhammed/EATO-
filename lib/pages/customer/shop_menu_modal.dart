// File: lib/pages/customer/shop_menu_modal.dart (Fixed version)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// IMPORTANT: Import CartService
import 'package:eato/services/CartService.dart';

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
  Map<String, dynamic>? _shop;
  bool _isLoading = true;
  String? _error;
  String _selectedMealTime = 'breakfast'; // FIXED: Start with lowercase
  String _selectedCategory = '';
  List<String> _availableCategories = [];
  List<Map<String, dynamic>> _currentFoods = [];

  final List<String> _mealTimes = ['breakfast', 'lunch', 'dinner'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        _selectedMealTime =
            _mealTimes[_tabController.index]; // This is already lowercase
        _selectedCategory = '';
      });
      _loadCategoriesForMealTime();
    }
  }

  Future<void> _loadShopData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 [ShopMenuModal] Loading shop data for: ${widget.shopId}');

      // Load shop details directly from Firestore
      final storeDoc =
          await _firestore.collection('stores').doc(widget.shopId).get();

      if (storeDoc.exists) {
        _shop = storeDoc.data();
        _shop!['id'] = storeDoc.id;
        print('✅ [ShopMenuModal] Shop loaded: ${_shop!['name']}');
      } else {
        // Create a basic shop object if not found in Firestore
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

  Future<void> _loadCategoriesForMealTime() async {
    try {
      // Get categories for this specific meal time and shop
      final categories = await _getCategoriesForShopAndMealTime(
          widget.shopId, _selectedMealTime);

      setState(() {
        _availableCategories = categories;
        _selectedCategory = categories.isNotEmpty ? categories.first : '';
      });

      if (_selectedCategory.isNotEmpty) {
        await _loadFoodsForCategoryAndTime();
      }
    } catch (e) {
      print('❌ [ShopMenuModal] Error loading categories: $e');
    }
  }

  Future<List<String>> _getCategoriesForShopAndMealTime(
      String shopId, String mealTime) async {
    try {
      print(
          '🔍 [ShopMenuModal] Getting categories for shop: $shopId, time: $mealTime');

      final foodsSnapshot = await _firestore
          .collection('stores')
          .doc(shopId)
          .collection('foods')
          .where('time', isEqualTo: mealTime)
          .where('isAvailable', isEqualTo: true)
          .get();

      print(
          '📊 [ShopMenuModal] Found ${foodsSnapshot.docs.length} foods for $mealTime');

      Set<String> categories = {};
      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        print(
            '   - Food: ${data['name']}, Category: $category, Time: ${data['time']}');
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      print('📂 [ShopMenuModal] Found categories for $mealTime: $categories');
      return categories.toList();
    } catch (e) {
      print('❌ [ShopMenuModal] Error getting categories: $e');
      return [];
    }
  }

  Future<void> _loadFoodsForCategoryAndTime() async {
    if (_selectedCategory.isEmpty) return;

    try {
      print(
          '🍽️ [ShopMenuModal] Loading foods for shop: ${widget.shopId}, time: $_selectedMealTime, category: $_selectedCategory');

      // Get foods for this specific shop, category, and meal time
      final foodsSnapshot = await _firestore
          .collection('stores')
          .doc(widget.shopId)
          .collection('foods')
          .where('time', isEqualTo: _selectedMealTime)
          .where('category', isEqualTo: _selectedCategory)
          .where('isAvailable', isEqualTo: true)
          .get();

      print(
          '📊 [ShopMenuModal] Query returned ${foodsSnapshot.docs.length} foods');

      List<Map<String, dynamic>> foods = [];
      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        foods.add(data);
        print('   - Added food: ${data['name']}');
      }

      setState(() {
        _currentFoods = foods;
      });

      print(
          '✅ [ShopMenuModal] Loaded ${foods.length} foods for $_selectedCategory ($_selectedMealTime)');
    } catch (e) {
      print('❌ [ShopMenuModal] Error loading foods: $e');
    }
  }

  IconData _getMealTimeIcon(String mealTime) {
    switch (mealTime.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildMenuContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'Loading menu...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error ?? 'Failed to load shop menu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadShopData,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    return Column(
      children: [
        // Shop header
        _buildShopHeader(),

        // Tab bar
        _buildTabBar(),

        // Content
        Expanded(
          child: _buildTabBarView(),
        ),
      ],
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Shop image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (_shop?['imageUrl']?.isNotEmpty == true)
                ? CachedNetworkImage(
                    imageUrl: _shop!['imageUrl'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.purple.shade100,
                      child: Icon(Icons.store, color: Colors.purple),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.purple.shade100,
                    child: Icon(Icons.store, color: Colors.purple),
                  ),
          ),

          SizedBox(width: 16),

          // Shop details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shop?['name'] ?? widget.shopName ?? 'Restaurant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                if ((_shop?['rating'] ?? 0) > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${(_shop?['rating'] ?? 0.0).toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _shop?['location'] ?? 'Location not specified',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Subscribe button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subscription feature coming soon!')),
              );
            },
            icon: Icon(Icons.favorite_border, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.purple,
        labelColor: Colors.purple,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        tabs: _mealTimes.map((time) {
          return Tab(
            text: time.toUpperCase(),
            icon: Icon(_getMealTimeIcon(time)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _mealTimes.map((mealTime) {
        return _buildMealTimeContent(mealTime);
      }).toList(),
    );
  }

  Widget _buildMealTimeContent(String mealTime) {
    if (_availableCategories.isEmpty) {
      return _buildEmptyMealTime(mealTime);
    }

    return Column(
      children: [
        // Category selector
        if (_availableCategories.length > 1) _buildCategorySelector(),

        // Food items
        Expanded(
          child:
              _currentFoods.isEmpty ? _buildEmptyCategory() : _buildFoodGrid(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableCategories.length,
        itemBuilder: (context, index) {
          final category = _availableCategories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _loadFoodsForCategoryAndTime();
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.purple : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodGrid() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _currentFoods.length,
      itemBuilder: (context, index) {
        return _buildFoodCard(_currentFoods[index]);
      },
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (food['imageUrl']?.isNotEmpty == true)
                ? CachedNetworkImage(
                    imageUrl: food['imageUrl'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.fastfood, color: Colors.grey),
                  ),
          ),

          SizedBox(width: 12),

          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        food['name'] ?? 'Food Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getFoodTypeColor(food['type'] ?? 'other'),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        food['type'] ?? 'Other',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                if (food['description']?.isNotEmpty == true)
                  Text(
                    food['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Rs. ${(food['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: (food['isAvailable'] ?? true)
                          ? () => _addToCart(food)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size(60, 32),
                      ),
                      child: Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMealTime(String mealTime) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMealTimeIcon(mealTime),
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No $mealTime items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This restaurant doesn\'t offer $mealTime items yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No items available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No $_selectedCategory items for $_selectedMealTime.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getFoodTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'vegetarian':
        return Colors.green;
      case 'non-vegetarian':
        return Colors.red;
      case 'vegan':
        return Colors.lightGreen;
      case 'dessert':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  // ✅ FIXED: Actually add items to cart
  Future<void> _addToCart(Map<String, dynamic> food) async {
    try {
      await CartService.addToCart(
        foodId: food['id'] ?? '',
        foodName: food['name'] ?? 'Food Item',
        foodImage: food['imageUrl'] ?? '',
        price: (food['price'] ?? 0.0).toDouble(),
        quantity: 1,
        shopId: widget.shopId,
        shopName: _shop?['name'] ?? widget.shopName ?? 'Restaurant',
        variation: 'Regular', // Default variation
        specialInstructions: '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('${food['name']} added to cart!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
