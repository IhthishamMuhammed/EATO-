// File: lib/pages/customer/ShopCategoryPage.dart (Complete Fixed Version)

import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/services/Firebase_Storage_Service.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/services/firebase_subscription_service.dart';
// ✅ IMPORTANT: Import the main CartService (NOT the local one)
import 'package:eato/services/CartService.dart';

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
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String _selectedFilter = "Best Match";
  Map<String, bool> _subscriptionStatus = {};

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

  Future<void> _loadShopsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      final shops = await foodProvider.getShopsForMealWithDetails(
          widget.mealTitle, widget.categoryTitle);

      setState(() {
        _shopItems = shops;
        _isLoading = false;
      });

      _sortShopItems(_shopItems, _selectedFilter);
      _loadSubscriptionStatus();
    } catch (e) {
      print('Error loading shops data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      print(
          'ℹ️ [ShopCategoryPage] User not authenticated, skipping subscription status');
      return;
    }

    try {
      Map<String, bool> status = {};
      for (var shop in _shopItems) {
        final shopId = shop['shopId'];
        if (shopId != null) {
          status[shopId] =
              await FirebaseSubscriptionService.isSubscribed(shopId);
        }
      }

      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
        });
      }

      print(
          '✅ [ShopCategoryPage] Loaded subscription status for ${status.length} shops');
    } catch (e) {
      print('❌ [ShopCategoryPage] Error loading subscription status: $e');
    }
  }

  void _sortShopItems(List<Map<String, dynamic>> items, String filter) {
    switch (filter) {
      case "Price: Low to High":
        items.sort((a, b) {
          double aPrice = _getLowestPrice(a);
          double bPrice = _getLowestPrice(b);
          return aPrice.compareTo(bPrice);
        });
        break;
      case "Price: High to Low":
        items.sort((a, b) {
          double aPrice = _getHighestPrice(a);
          double bPrice = _getHighestPrice(b);
          return bPrice.compareTo(aPrice);
        });
        break;
      case "Rating":
        items.sort((a, b) =>
            (b['shopRating'] as double).compareTo(a['shopRating'] as double));
        break;
      case "Distance":
        items.sort((a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));
        break;
      case "Fastest Delivery":
        items.sort((a, b) =>
            (a['deliveryTime'] as int).compareTo(b['deliveryTime'] as int));
        break;
      default: // Best Match
        items.sort((a, b) {
          double aScore = (a['shopRating'] as double) * 0.4 +
              (5.0 - (a['distance'] as double).clamp(0, 5)) * 0.3 +
              (100 - _getLowestPrice(a).clamp(0, 100)) / 100 * 0.3;
          double bScore = (b['shopRating'] as double) * 0.4 +
              (5.0 - (b['distance'] as double).clamp(0, 5)) * 0.3 +
              (100 - _getLowestPrice(b).clamp(0, 100)) / 100 * 0.3;
          return bScore.compareTo(aScore);
        });
    }
    setState(() {});
  }

  // ✅ Helper method to get lowest price from portion prices
  double _getLowestPrice(Map<String, dynamic> shop) {
    final portionPrices = shop['portionPrices'] as Map<String, double>? ?? {};
    if (portionPrices.isEmpty) {
      return shop['price'] as double;
    }
    return portionPrices.values.reduce((a, b) => a < b ? a : b);
  }

  // ✅ Helper method to get highest price from portion prices
  double _getHighestPrice(Map<String, dynamic> shop) {
    final portionPrices = shop['portionPrices'] as Map<String, double>? ?? {};
    if (portionPrices.isEmpty) {
      return shop['price'] as double;
    }
    return portionPrices.values.reduce((a, b) => a > b ? a : b);
  }

  // ✅ Build portion selection widget
  Widget _buildPortionSelection(Map<String, dynamic> shop) {
    // Extract portion prices from shop data
    final portionPrices = shop['portionPrices'] as Map<String, double>? ?? {};

    // If no portion prices, fall back to single price
    if (portionPrices.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Rs. ${shop['price'].toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple)),
          ElevatedButton.icon(
            onPressed: () => _addToCartWithPortion(shop, 'Full', shop['price']),
            icon: Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
            label: Text('Add to Cart',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      );
    }

    // Show portion selection dropdown
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price range display
        Text(
          _getPriceRangeText(portionPrices),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple),
        ),

        const SizedBox(height: 8),

        // Portion selection dropdown
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text('Select portion', style: TextStyle(fontSize: 12)),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, size: 16),
              items: portionPrices.entries.map((entry) {
                final portion = entry.key;
                final price = entry.value;
                return DropdownMenuItem<String>(
                  value: portion,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(portion, style: TextStyle(fontSize: 12)),
                      Text('Rs. ${price.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (selectedPortion) {
                if (selectedPortion != null) {
                  final price = portionPrices[selectedPortion]!;
                  _addToCartWithPortion(shop, selectedPortion, price);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Helper method to get price range text
  String _getPriceRangeText(Map<String, double> portionPrices) {
    if (portionPrices.isEmpty) return '';

    final prices = portionPrices.values.toList()..sort();
    final minPrice = prices.first;
    final maxPrice = prices.last;

    if (minPrice == maxPrice) {
      return 'Rs. ${minPrice.toStringAsFixed(2)}';
    } else {
      return 'From Rs. ${minPrice.toStringAsFixed(2)}';
    }
  }

  // ✅ Helper method for food type colors
  Color _getFoodTypeColor(String? foodType) {
    if (foodType == null) return Colors.purple;

    switch (foodType.toLowerCase()) {
      case 'vegetarian':
        return Colors.green;
      case 'non-vegetarian':
        return Colors.red;
      case 'vegan':
        return Colors.teal;
      case 'dessert':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  // ✅ FIXED: Add to cart method with standardized CartService
  Future<void> _addToCartWithPortion(
      Map<String, dynamic> shop, String portion, double price) async {
    try {
      print(
          '🛒 [ShopCategoryPage] Adding to cart: ${shop['foodName']} ($portion) - Rs. $price');

      // Use the standardized CartService.addToCart method
      await CartService.addToCart(
        foodId: shop['foodId'] ?? '',
        foodName: '${shop['foodName']} ($portion)',
        foodImage: shop['foodImage'] ?? '',
        price: price,
        quantity: 1,
        shopId: shop['shopId'] ?? '',
        shopName: shop['shopName'] ?? '',
        variation: portion, // Store portion as variation
        specialInstructions: '',
      );

      print('✅ [ShopCategoryPage] Successfully added to cart');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('${shop['foodName']} ($portion) added to cart'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ [ShopCategoryPage] Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.purple),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: Text(
          'Please log in to subscribe to restaurants and get updates about their menu and offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Subscribe/Unsubscribe to shop
  Future<void> _toggleSubscription(Map<String, dynamic> shop) async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      _showAuthRequiredDialog();
      return;
    }

    final shopId = shop['shopId'];
    if (shopId == null) {
      print('❌ [ShopCategoryPage] Shop ID is null');
      return;
    }

    final isCurrentlySubscribed = _subscriptionStatus[shopId] ?? false;

    try {
      if (isCurrentlySubscribed) {
        await FirebaseSubscriptionService.unsubscribeFromShop(shopId);

        if (mounted) {
          setState(() {
            _subscriptionStatus[shopId] = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.unsubscribe, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Unsubscribed from ${shop['shopName']}'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Prepare shop data for Firebase
        final shopData = {
          'shopName': shop['shopName'] ?? 'Unknown Shop',
          'shopImage': shop['shopImage'] ?? '',
          'shopRating': (shop['shopRating'] ?? 0.0).toDouble(),
          'shopContact': shop['shopContact'] ?? '',
          'shopLocation': shop['shopLocation'] ?? 'Location not specified',
          'isPickup': shop['isPickup'] ?? true,
          'distance': (shop['distance'] ?? 0.0).toDouble(),
          'deliveryTime': shop['deliveryTime'] ?? 30,
        };

        await FirebaseSubscriptionService.subscribeToShop(shopId, shopData);

        if (mounted) {
          setState(() {
            _subscriptionStatus[shopId] = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Subscribed to ${shop['shopName']}'),
                ],
              ),
              backgroundColor: Colors.purple,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ShopCategoryPage] Error toggling subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to update subscription: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                        // Header with back button and title
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
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const Row(
                                  children: [
                                    Icon(Icons.arrow_back,
                                        size: 20, color: Colors.black87),
                                    SizedBox(width: 4),
                                    Text('Back',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(_getCurrentTime(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        // Title section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.mealTitle,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.categoryTitle,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 14, color: Colors.purple.shade600),
                                  SizedBox(width: 4),
                                  Text('Select portion size to add to cart',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple.shade600)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Filter section
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
                                      fontSize: 14, color: Colors.black87),
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
                                        value: value, child: Text(value));
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
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(Icons.store,
                                              size: 60,
                                              color: Colors.grey.shade300),
                                          Icon(Icons.close,
                                              size: 72,
                                              color:
                                                  Colors.red.withOpacity(0.6)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                          'No shops available for this meal',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      Text('Try selecting a different meal',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600)),
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

                  // Bottom nav with cart functionality
                  if (widget.showBottomNav)
                    BottomNavBar(
                      currentIndex: 0,
                      onTap: (index) {
                        if (index != 0) {
                          Navigator.pop(context, index);
                        }
                      },
                    ),
                ],
              ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ✅ Enhanced shop card with portion selection
  Widget _buildShopCard(Map<String, dynamic> shop) {
    final shopId = shop['shopId'];
    final isSubscribed = _subscriptionStatus[shopId] ?? false;

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
      child: Column(
        children: [
          // Shop header with subscribe button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      shop['shopImage'] != null && shop['shopImage'].isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: shop['shopImage'],
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[300],
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.purple),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[300],
                                child: const Icon(Icons.store, size: 24),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(shop['shopName'] ?? 'Shop',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          // Subscribe button
                          InkWell(
                            onTap: () => _toggleSubscription(shop),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSubscribed
                                    ? Colors.purple.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSubscribed
                                      ? Colors.purple
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSubscribed
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 14,
                                    color: isSubscribed
                                        ? Colors.purple
                                        : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isSubscribed ? 'Subscribed' : 'Subscribe',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSubscribed
                                          ? Colors.purple
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                              '${(shop['shopRating'] ?? 0.0).toStringAsFixed(1)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text('${shop['distance'].toStringAsFixed(1)} km',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text('${shop['deliveryTime']} min',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Food details section with portion selection
          Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.only(bottomLeft: Radius.circular(12)),
                child: shop['foodImage'] != null && shop['foodImage'].isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: shop['foodImage'],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.purple),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name
                      Text(shop['foodName'] ?? 'Food',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),

                      const SizedBox(height: 4),

                      // Food type badge
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getFoodTypeColor(shop['foodType'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getFoodTypeColor(shop['foodType'])
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          shop['foodType'] ?? 'Regular',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getFoodTypeColor(shop['foodType']),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Description
                      if (shop['description'] != null &&
                          shop['description'].isNotEmpty)
                        Text(shop['description'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),

                      const SizedBox(height: 12),

                      // Portion selection and pricing
                      _buildPortionSelection(shop),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ IMPORTANT: Remove the local CartService class completely from this file!
// The local CartService class that was here has been removed.
// Now this file uses the main CartService from 'package:eato/services/CartService.dart'
