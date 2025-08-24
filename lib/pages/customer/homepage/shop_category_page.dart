// FILE: lib/pages/customer/shop_category_page.dart
// Fixed version with updated methods and cart confirmation modal

import 'package:eato/widgets/floating_notification_button.dart.dart';
import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/services/firebase_subscription_service.dart';
import 'package:eato/services/CartService.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/EatoComponents.dart';

class ShopCategoryPage extends StatefulWidget {
  final String mealTitle;
  final String categoryTitle;
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
  String _selectedFilter = "Best Match";
  Map<String, bool> _subscriptionStatus = {};
  String? _error;

  final List<String> _filterOptions = [
    "Best Match",
    "Price: Low to High",
    "Price: High to Low",
    "Rating",
    "Distance",
    "Fastest Delivery"
  ];

  @override
  void initState() {
    super.initState();
    _loadShopsData();
  }

  // ✅ FIXED: Updated to use the new getShopsForMealWithDetails method
  Future<void> _loadShopsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
          '📄 [ShopCategoryPage] Loading shops for ${widget.mealTitle} in ${widget.categoryTitle}');

      final foodProvider = Provider.of<FoodProvider>(context, listen: false);

      // ✅ FIXED: Use the new method that returns detailed shop information
      final shops = await foodProvider.getShopsForMealWithDetails(
          widget.mealTitle, widget.categoryTitle);

      print('✅ [ShopCategoryPage] Loaded ${shops.length} shops');

      // Load subscription status for each shop
      await _loadSubscriptionStatuses(shops);

      setState(() {
        _shopItems = shops;
        _isLoading = false;
      });

      if (shops.isEmpty) {
        setState(() {
          _error = 'No restaurants found serving ${widget.mealTitle}';
        });
      }
    } catch (e) {
      print('❌ [ShopCategoryPage] Error loading shops: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load restaurants: $e';
      });
    }
  }

  // Load subscription status for all shops
  Future<void> _loadSubscriptionStatuses(
      List<Map<String, dynamic>> shops) async {
    try {
      for (var shopItem in shops) {
        final storeId = shopItem['storeId'] as String;
        final isSubscribed =
            await FirebaseSubscriptionService.isSubscribed(storeId);
        _subscriptionStatus[storeId] = isSubscribed;
      }
    } catch (e) {
      print('⚠️ [ShopCategoryPage] Error loading subscription statuses: $e');
    }
  }

  // ✅ IMPROVED: Apply selected filter
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;

      switch (filter) {
        case "Price: Low to High":
          _shopItems.sort((a, b) =>
              (a['foodPrice'] as double).compareTo(b['foodPrice'] as double));
          break;
        case "Price: High to Low":
          _shopItems.sort((a, b) =>
              (b['foodPrice'] as double).compareTo(a['foodPrice'] as double));
          break;
        case "Rating":
          _shopItems.sort((a, b) => (b['storeRating'] as double)
              .compareTo(a['storeRating'] as double));
          break;
        case "Distance":
          _shopItems.sort((a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double));
          break;
        case "Fastest Delivery":
          _shopItems.sort((a, b) => (a['estimatedDeliveryTime'] as int)
              .compareTo(b['estimatedDeliveryTime'] as int));
          break;
        default: // Best Match
          _shopItems.sort((a, b) {
            // Sort by rating first, then by delivery time
            int ratingComparison = (b['storeRating'] as double)
                .compareTo(a['storeRating'] as double);
            if (ratingComparison != 0) return ratingComparison;
            return (a['estimatedDeliveryTime'] as int)
                .compareTo(b['estimatedDeliveryTime'] as int);
          });
          break;
      }
    });
  }

  // ✅ FIXED: Show cart modal instead of direct addition
  Future<void> _addToCart(Map<String, dynamic> shopItem) async {
    try {
      final food = shopItem['food'] as Food;
      final store = shopItem['store'] as Store;

      // Show the cart confirmation modal using EatoComponents
      await EatoComponents.showAddToCartModal(
        context: context,
        foodName: food.name,
        foodImage: food.imageUrl ?? '',
        basePrice: food.price,
        portionPrices: food.portionPrices,
        description: food.description,
        onAddToCart: (portion, quantity, instructions) async {
          // Calculate the effective price (from portion or base price)
          final effectivePrice = food.portionPrices[portion] ?? food.price;

          // Add to cart using CartService with correct parameters
          await CartService.addToCart(
            foodId: food.id,
            foodName: food.name,
            foodImage: food.imageUrl ?? '',
            price: effectivePrice,
            quantity: quantity,
            shopId: store.id,
            shopName: store.name,
            variation: portion.isNotEmpty ? portion : null,
            specialInstructions: instructions ?? '',
          );
        },
      );

      // Optional: Show success feedback or update UI
      setState(() {
        // Could update cart count or other UI elements
      });
    } catch (e) {
      print('❌ [ShopCategoryPage] Error showing cart modal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  // Toggle subscription status
  Future<void> _toggleSubscription(String storeId) async {
    try {
      final currentStatus = _subscriptionStatus[storeId] ?? false;

      if (currentStatus) {
        await FirebaseSubscriptionService.unsubscribeFromShop(storeId);
      } else {
        // Find the shop data for this store ID
        final shopItem = _shopItems.firstWhere(
          (item) => item['storeId'] == storeId,
          orElse: () => <String, dynamic>{},
        );

        if (shopItem.isNotEmpty) {
          final shopData = {
            'shopName': shopItem['storeName'],
            'shopImage': shopItem['storeImageUrl'] ?? '',
            'shopRating': shopItem['storeRating'] ?? 0.0,
            'shopContact': shopItem['storeContact'] ?? '',
            'shopLocation':
                shopItem['storeLocation'] ?? 'Location not specified',
            'isPickup': true, // Default value
            'distance': shopItem['distance'] ?? 2.5,
            'deliveryTime': shopItem['estimatedDeliveryTime'] ?? 30,
          };

          await FirebaseSubscriptionService.subscribeToShop(storeId, shopData);
        }
      }

      setState(() {
        _subscriptionStatus[storeId] = !currentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'Unsubscribed' : 'Subscribed!'),
          backgroundColor:
              currentStatus ? Colors.orange : EatoTheme.successColor,
        ),
      );
    } catch (e) {
      print('❌ [ShopCategoryPage] Error toggling subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating subscription'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  // ✅ IMPROVED: Refresh functionality
  Future<void> _refreshData() async {
    await _loadShopsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mealTitle,
              style: EatoTheme.headingMedium.copyWith(color: Colors.black),
            ),
            Text(
              '${_shopItems.length} restaurants',
              style: EatoTheme.bodySmall.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          // Filter button
          PopupMenuButton<String>(
            onSelected: _applyFilter,
            icon: const Icon(Icons.filter_list, color: Colors.black),
            itemBuilder: (context) => _filterOptions
                .map((filter) => PopupMenuItem(
                      value: filter,
                      child: Row(
                        children: [
                          if (_selectedFilter == filter)
                            const Icon(Icons.check,
                                color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          Text(filter),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                )
              : _error != null
                  ? _buildErrorWidget()
                  : _shopItems.isEmpty
                      ? _buildEmptyWidget()
                      : _buildShopsList(),
          const FloatingNotificationButton(),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                Navigator.pop(context, index);
              },
            )
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
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
              'No restaurants found serving ${widget.mealTitle}',
              textAlign: TextAlign.center,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for other meals or check back later',
              textAlign: TextAlign.center,
              style: EatoTheme.bodySmall.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsList() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // Filter indicator
          if (_selectedFilter != "Best Match")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.purple.withOpacity(0.1),
              child: Text(
                'Sorted by: $_selectedFilter',
                style: EatoTheme.bodySmall.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Shops list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _shopItems.length,
              itemBuilder: (context, index) {
                final shopItem = _shopItems[index];
                return _buildShopCard(shopItem);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shopItem) {
    final store = shopItem['store'] as Store;
    final food = shopItem['food'] as Food;
    final storeId = shopItem['storeId'] as String;
    final storeName = shopItem['storeName'] as String;
    final storeRating = shopItem['storeRating'] as double;
    final estimatedTime = shopItem['estimatedDeliveryTime'] as int;
    final distance = shopItem['distance'] as double;
    final foodPrice = shopItem['foodPrice'] as double;
    final isSubscribed = _subscriptionStatus[storeId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Store Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: shopItem['storeImageUrl'] != null &&
                          (shopItem['storeImageUrl'] as String).isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: shopItem['storeImageUrl'],
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

                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: EatoTheme.headingSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            storeRating.toStringAsFixed(1),
                            style: EatoTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${estimatedTime} min',
                            style: EatoTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: EatoTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Subscription Button
                IconButton(
                  onPressed: () => _toggleSubscription(storeId),
                  icon: Icon(
                    isSubscribed
                        ? Icons.notifications
                        : Icons.notifications_outlined,
                    color: isSubscribed ? EatoTheme.primaryColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Food Item
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Food Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: food.imageUrl!,
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
                        food.name,
                        style: EatoTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (food.description != null &&
                          food.description!.isNotEmpty)
                        Text(
                          food.description!,
                          style: EatoTheme.bodySmall.copyWith(
                            color: EatoTheme.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${foodPrice.toStringAsFixed(2)}',
                        style: EatoTheme.bodyMedium.copyWith(
                          color: EatoTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ FIXED: Add to Cart button shows modal instead of direct addition
                ElevatedButton(
                  onPressed: () => _addToCart(shopItem),
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
                      Icon(Icons.add_shopping_cart,
                          size: 16, color: Colors.white),
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
        ],
      ),
    );
  }
}
