// File: lib/services/CartService.dart (Enhanced with better cart clearing and callbacks)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Model/Order.dart';

class CartService {
  static const String _cartKey = 'cart_items';

  // ✅ NEW: Callback for real-time cart updates
  static Function()? onCartChanged;

  // ✅ NEW: Cache for faster cart count access
  static int? _cachedCartCount;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(seconds: 5);

  // ===================================
  // ENHANCED CART METHODS WITH CALLBACKS
  // ===================================

  /// Get cart items from local storage
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        return cartList.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('Error getting cart items: $e');
      return [];
    }
  }

  /// Save cart items to local storage with callback
  static Future<void> updateCartItems(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(items);
      await prefs.setString(_cartKey, cartJson);

      // ✅ ENHANCED: Update cache and trigger callback
      _updateCacheAndNotify(items);
    } catch (e) {
      print('Error updating cart items: $e');
    }
  }

  /// ✅ NEW: Update cache and notify listeners
  static void _updateCacheAndNotify(List<Map<String, dynamic>> items) {
    // Update cached count
    _cachedCartCount = items.fold<int>(0, (sum, item) {
      final quantity = item['quantity'];
      final quantityInt = (quantity as num?)?.toInt() ?? 0;
      return sum + quantityInt;
    });
    _lastCacheUpdate = DateTime.now();

    // Notify listeners
    if (onCartChanged != null) {
      onCartChanged!();
    }
  }

  /// ✅ ENHANCED: Add item to cart with callback
  static Future<void> addToCart({
    required String foodId,
    required String foodName,
    required String foodImage,
    required double price,
    required int quantity,
    required String shopId,
    required String shopName,
    String? variation,
    String? specialInstructions,
  }) async {
    try {
      final cartItems = await getCartItems();

      // Check if item already exists
      final existingIndex = cartItems.indexWhere((item) =>
          item['foodId'] == foodId &&
          item['shopId'] == shopId &&
          item['variation'] == variation);

      if (existingIndex != -1) {
        // Update existing item
        cartItems[existingIndex]['quantity'] += quantity;
        cartItems[existingIndex]['totalPrice'] =
            cartItems[existingIndex]['quantity'] * price;
      } else {
        // Add new item
        cartItems.add({
          'foodId': foodId,
          'foodName': foodName,
          'foodImage': foodImage,
          'price': price,
          'quantity': quantity,
          'totalPrice': price * quantity,
          'shopId': shopId,
          'shopName': shopName,
          'variation': variation,
          'specialInstructions': specialInstructions,
        });
      }

      await updateCartItems(cartItems);
    } catch (e) {
      print('Error adding to cart: $e');
      throw Exception('Failed to add item to cart');
    }
  }

  /// ✅ ENHANCED: Remove item from cart with callback
  static Future<void> removeFromCart(String foodId, String shopId,
      {String? variation}) async {
    try {
      final cartItems = await getCartItems();

      cartItems.removeWhere((item) =>
          item['foodId'] == foodId &&
          item['shopId'] == shopId &&
          item['variation'] == variation);

      await updateCartItems(cartItems);
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  /// ✅ ENHANCED: Clear entire cart with proper cleanup and callback
  static Future<void> clearCart() async {
    try {
      print('🧹 [CartService] Starting cart clear...');
      final prefs = await SharedPreferences.getInstance();

      // Clear all possible cart storage formats
      await prefs.remove(_cartKey);
      await prefs.remove('cart_items'); // Legacy key

      // Also clear any other cart-related keys that might exist
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        if (key.contains('cart')) {
          await prefs.remove(key);
          print('🗑️ Removed cart key: $key');
        }
      }

      // ✅ ENHANCED: Clear cache and notify immediately
      _cachedCartCount = 0;
      _lastCacheUpdate = DateTime.now();

      if (onCartChanged != null) {
        onCartChanged!();
      }

      print('✅ [CartService] Cart cleared successfully');
    } catch (e) {
      print('❌ Error clearing cart: $e');
      // Even if there's an error, try to clear cache and notify
      _cachedCartCount = 0;
      _lastCacheUpdate = DateTime.now();

      if (onCartChanged != null) {
        onCartChanged!();
      }
    }
  }

  /// ✅ NEW: Force clear cart (for emergency situations)
  static Future<void> forceEmergencyClear() async {
    try {
      print('🚨 [CartService] Force clearing cart...');
      final prefs = await SharedPreferences.getInstance();

      // Get all keys and remove anything cart-related
      final allKeys = prefs.getKeys().toList();
      for (String key in allKeys) {
        if (key.toLowerCase().contains('cart') ||
            key.toLowerCase().contains('order') ||
            key.contains(_cartKey)) {
          await prefs.remove(key);
          print('🗑️ Force removed key: $key');
        }
      }

      // Reset all cache
      _cachedCartCount = 0;
      _lastCacheUpdate = DateTime.now();

      // Notify listeners
      if (onCartChanged != null) {
        onCartChanged!();
      }

      print('✅ [CartService] Force clear completed');
    } catch (e) {
      print('❌ Error during force clear: $e');
    }
  }

  /// ✅ OPTIMIZED: Fast cart count with caching
  static Future<int> getCartItemCount() async {
    try {
      // Use cache if valid
      if (_cachedCartCount != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration) {
        return _cachedCartCount!;
      }

      // Otherwise fetch from storage
      final cartItems = await getCartItems();
      int totalCount = 0;

      for (var item in cartItems) {
        final quantity = item['quantity'];
        if (quantity != null) {
          totalCount += (quantity as num).toInt();
        }
      }

      // Update cache
      _cachedCartCount = totalCount;
      _lastCacheUpdate = DateTime.now();

      return totalCount;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  /// ✅ NEW: Get cart count synchronously from cache (for immediate UI updates)
  static int getCachedCartCount() {
    return _cachedCartCount ?? 0;
  }

  /// ✅ ENHANCED: Update item quantity with callback
  static Future<void> updateItemQuantity(
    String foodId,
    String shopId,
    int newQuantity, {
    String? variation,
  }) async {
    try {
      final cartItems = await getCartItems();

      final itemIndex = cartItems.indexWhere((item) =>
          item['foodId'] == foodId &&
          item['shopId'] == shopId &&
          item['variation'] == variation);

      if (itemIndex != -1) {
        if (newQuantity <= 0) {
          cartItems.removeAt(itemIndex);
        } else {
          cartItems[itemIndex]['quantity'] = newQuantity;
          cartItems[itemIndex]['totalPrice'] =
              cartItems[itemIndex]['price'] * newQuantity;
        }

        await updateCartItems(cartItems);
      }
    } catch (e) {
      print('Error updating item quantity: $e');
    }
  }

  // ===================================
  // QUICK ACCESS METHODS WITH CALLBACKS
  // ===================================

  /// ✅ NEW: Add item with immediate callback
  static Future<void> addToCartWithCallback({
    required String foodId,
    required String foodName,
    required String foodImage,
    required double price,
    required int quantity,
    required String shopId,
    required String shopName,
    String? variation,
    String? specialInstructions,
  }) async {
    await addToCart(
      foodId: foodId,
      foodName: foodName,
      foodImage: foodImage,
      price: price,
      quantity: quantity,
      shopId: shopId,
      shopName: shopName,
      variation: variation,
      specialInstructions: specialInstructions,
    );
    // Callback is automatically triggered in updateCartItems
  }

  /// ✅ NEW: Remove item with immediate callback
  static Future<void> removeFromCartWithCallback(
    String foodId,
    String shopId, {
    String? variation,
  }) async {
    await removeFromCart(foodId, shopId, variation: variation);
    // Callback is automatically triggered in updateCartItems
  }

  /// ✅ NEW: Clear cart with immediate callback
  static Future<void> clearCartWithCallback() async {
    await clearCart();
    // Callback is automatically triggered in clearCart
  }

  /// ✅ NEW: Update quantity with immediate callback
  static Future<void> updateItemQuantityWithCallback(
    String foodId,
    String shopId,
    int newQuantity, {
    String? variation,
  }) async {
    await updateItemQuantity(foodId, shopId, newQuantity, variation: variation);
    // Callback is automatically triggered in updateCartItems
  }

  // ===================================
  // CART VALIDATION AND MANAGEMENT
  // ===================================

  /// ✅ NEW: Validate cart integrity
  static Future<Map<String, dynamic>> validateCartIntegrity() async {
    try {
      final cartItems = await getCartItems();
      final issues = <String>[];
      final validItems = <Map<String, dynamic>>[];

      for (var item in cartItems) {
        // Check required fields
        if (item['foodId'] == null || item['foodId'].toString().isEmpty) {
          issues.add('Item missing foodId');
          continue;
        }

        if (item['shopId'] == null || item['shopId'].toString().isEmpty) {
          issues.add('Item missing shopId');
          continue;
        }

        if (item['quantity'] == null || (item['quantity'] as num) <= 0) {
          issues.add('Item has invalid quantity');
          continue;
        }

        if (item['price'] == null || (item['price'] as num) <= 0) {
          issues.add('Item has invalid price');
          continue;
        }

        validItems.add(item);
      }

      // If we found invalid items, update cart with only valid items
      if (validItems.length != cartItems.length) {
        await updateCartItems(validItems);
        print(
            '🔧 [CartService] Fixed ${cartItems.length - validItems.length} invalid cart items');
      }

      return {
        'isValid': issues.isEmpty,
        'issues': issues,
        'validItemCount': validItems.length,
        'removedItemCount': cartItems.length - validItems.length,
      };
    } catch (e) {
      print('❌ Error validating cart: $e');
      return {
        'isValid': false,
        'issues': ['Validation error: $e'],
        'validItemCount': 0,
        'removedItemCount': 0,
      };
    }
  }

  // ===================================
  // EXISTING METHODS (keeping all your original functionality)
  // ===================================

  /// Get cart total value
  static Future<double> getCartTotal() async {
    try {
      final cartItems = await getCartItems();
      double totalValue = 0.0;

      for (var item in cartItems) {
        final totalPrice = item['totalPrice'];
        if (totalPrice != null) {
          totalValue += (totalPrice as num).toDouble();
        }
      }

      return totalValue;
    } catch (e) {
      print('Error getting cart total: $e');
      return 0.0;
    }
  }

  /// Debug method to see all cart-related storage
  static Future<void> debugCartStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      print('=== CART STORAGE DEBUG ===');
      print('Cached count: $_cachedCartCount');
      print('Last cache update: $_lastCacheUpdate');

      for (String key in allKeys) {
        if (key.contains('cart')) {
          final value = prefs.get(key);
          print('Key: $key');
          print('Type: ${value.runtimeType}');
          print(
              'Value: ${value.toString().length > 100 ? value.toString().substring(0, 100) + '...' : value}');
          print('---');
        }
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// Fix corrupted cart data by converting old format to new format
  static Future<void> fixCorruptedCartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if there's old List<String> format data
      final oldCartData = prefs.getStringList('cart_items');
      if (oldCartData != null && oldCartData.isNotEmpty) {
        print('🔄 Found old cart format, converting...');

        List<Map<String, dynamic>> convertedItems = [];

        for (String itemJson in oldCartData) {
          try {
            final Map<String, dynamic> item = json.decode(itemJson);
            convertedItems.add(item);
          } catch (e) {
            print('⚠️ Skipping corrupted item: $e');
          }
        }

        // Save in new format
        if (convertedItems.isNotEmpty) {
          await updateCartItems(convertedItems);
          print('✅ Converted ${convertedItems.length} items to new format');
        }

        // Remove old format
        await prefs.remove('cart_items');
        print('🗑️ Removed old cart format');
      }
    } catch (e) {
      print('❌ Error fixing cart data: $e');
    }
  }

  // ===================================
  // ENHANCED ORDER PLACEMENT (keeping your existing logic)
  // ===================================

  /// ✅ OPTIMIZED: Place orders with enhanced location support and faster processing
  static Future<List<String>> placeOrdersWithBackendLocation(
    OrderProvider orderProvider,
    CustomUser customer,
    List<Map<String, dynamic>> cartItems, {
    required String deliveryOption,
    required String deliveryAddress,
    GeoPoint? deliveryLocation,
    String? locationDisplayText,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
  }) async {
    try {
      print(
          '🚀 [CartService] Starting optimized order placement with location...');

      // Group cart items by store
      Map<String, List<Map<String, dynamic>>> itemsByStore = {};
      for (var item in cartItems) {
        final storeId = item['shopId'] as String;
        if (!itemsByStore.containsKey(storeId)) {
          itemsByStore[storeId] = [];
        }
        itemsByStore[storeId]!.add(item);
      }

      List<String> orderIds = [];
      List<Future<String>> orderFutures = [];

      // ✅ OPTIMIZED: Create all orders in parallel for faster processing
      for (var entry in itemsByStore.entries) {
        orderFutures.add(_createSingleOrder(
          storeId: entry.key,
          storeItems: entry.value,
          customer: customer,
          deliveryOption: deliveryOption,
          deliveryAddress: deliveryAddress,
          deliveryLocation: deliveryLocation,
          locationDisplayText: locationDisplayText,
          paymentMethod: paymentMethod,
          specialInstructions: specialInstructions,
          scheduledTime: scheduledTime,
        ));
      }

      // Wait for all orders to complete
      orderIds = await Future.wait(orderFutures);

      // ✅ ENHANCED: Clear cart immediately with callback after successful order placement
      await clearCartWithCallback();

      print(
          '🎉 [CartService] Successfully created ${orderIds.length} orders in parallel');
      print('✅ [CartService] Cart cleared after successful order placement');

      return orderIds;
    } catch (e) {
      print('❌ [CartService] Error placing orders with location: $e');
      throw Exception('Failed to place orders: $e');
    }
  }

  /// ✅ NEW: Create single order (helper method for parallel processing)
  static Future<String> _createSingleOrder({
    required String storeId,
    required List<Map<String, dynamic>> storeItems,
    required CustomUser customer,
    required String deliveryOption,
    required String deliveryAddress,
    GeoPoint? deliveryLocation,
    String? locationDisplayText,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
  }) async {
    // Calculate totals for this store
    double subtotal = storeItems.fold(
        0.0, (sum, item) => sum + (item['totalPrice'] as double));
    double deliveryFee = deliveryOption == 'Delivery' ? 100.0 : 0.0;
    double serviceFee = subtotal * 0.05;
    double totalAmount = subtotal + deliveryFee + serviceFee;

    // Convert cart items to order items
    List<OrderItem> orderItems = storeItems
        .map((item) => OrderItem(
              foodId: item['foodId'] ?? '',
              foodName: item['foodName'] ?? '',
              foodImage: item['foodImage'] ?? '',
              price: (item['price'] as num).toDouble(),
              quantity: item['quantity'] as int,
              totalPrice: (item['totalPrice'] as num).toDouble(),
              specialInstructions: item['specialInstructions'],
              variation: item['variation'],
            ))
        .toList();

    // Create location object if location data is provided
    OrderLocation? orderLocation;
    if (deliveryLocation != null) {
      orderLocation = OrderLocation(
        geoPoint: deliveryLocation,
        formattedAddress: locationDisplayText ?? deliveryAddress,
      );
    }

    // Create enhanced order with location
    final order = CustomerOrder(
      id: '', // Will be set by Firestore
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phoneNumber ?? '',
      storeId: storeId,
      storeName: storeItems.first['shopName'] ?? '',
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      deliveryOption: deliveryOption,
      deliveryAddress: locationDisplayText ?? deliveryAddress,
      deliveryLocation: orderLocation,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      scheduledTime: scheduledTime,
      orderTime: DateTime.now(),
    );

    // Save to Firestore
    final docRef = await FirebaseFirestore.instance
        .collection('orders')
        .add(order.toMap());

    // Create order request for the store (non-blocking)
    _createOrderRequest(docRef.id, order).catchError((e) {
      print('❌ [CartService] Error creating order request: $e');
    });

    print('✅ [CartService] Order created for store $storeId: ${docRef.id}');
    return docRef.id;
  }

  /// Create order request for store owner
  static Future<void> _createOrderRequest(
      String orderId, CustomerOrder order) async {
    try {
      final request = OrderRequest(
        id: '',
        orderId: orderId,
        customerId: order.customerId,
        customerName: order.customerName,
        storeId: order.storeId,
        storeName: order.storeName,
        status: OrderRequestStatus.pending,
        requestTime: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('order_requests')
          .add(request.toMap());

      print('📋 [CartService] Order request created for order $orderId');
    } catch (e) {
      print('❌ [CartService] Error creating order request: $e');
      throw Exception('Failed to create order request');
    }
  }

  // ===================================
  // LEGACY METHOD (for backward compatibility)
  // ===================================

  /// Legacy method for placing orders (kept for backward compatibility)
  static Future<List<String>> placeOrdersWithBackend(
    OrderProvider orderProvider,
    CustomUser customer,
    List<Map<String, dynamic>> cartItems, {
    required String deliveryOption,
    required String deliveryAddress,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
  }) async {
    // Call the enhanced method without location data
    return placeOrdersWithBackendLocation(
      orderProvider,
      customer,
      cartItems,
      deliveryOption: deliveryOption,
      deliveryAddress: deliveryAddress,
      deliveryLocation: null,
      locationDisplayText: null,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      scheduledTime: scheduledTime,
    );
  }

  // ===================================
  // UTILITY METHODS (unchanged but enhanced)
  // ===================================

  /// Check if cart contains items from specific store
  static Future<bool> hasItemsFromStore(String storeId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems.any((item) => item['shopId'] == storeId);
    } catch (e) {
      print('Error checking store items: $e');
      return false;
    }
  }

  /// Get unique store count in cart
  static Future<int> getUniqueStoreCount() async {
    try {
      final cartItems = await getCartItems();
      final storeIds = cartItems.map((item) => item['shopId']).toSet();
      return storeIds.length;
    } catch (e) {
      print('Error getting store count: $e');
      return 0;
    }
  }

  /// Get cart items grouped by store
  static Future<Map<String, List<Map<String, dynamic>>>>
      getCartItemsByStore() async {
    try {
      final cartItems = await getCartItems();
      Map<String, List<Map<String, dynamic>>> itemsByStore = {};

      for (var item in cartItems) {
        final storeId = item['shopId'] as String;
        if (!itemsByStore.containsKey(storeId)) {
          itemsByStore[storeId] = [];
        }
        itemsByStore[storeId]!.add(item);
      }

      return itemsByStore;
    } catch (e) {
      print('Error grouping cart items: $e');
      return {};
    }
  }

  /// ✅ ENHANCED: Validate cart before checkout with comprehensive checks
  static Future<Map<String, dynamic>> validateCart() async {
    try {
      final cartItems = await getCartItems();

      if (cartItems.isEmpty) {
        return {
          'isValid': false,
          'message': 'Cart is empty',
          'issues': ['No items in cart'],
        };
      }

      List<String> issues = [];
      int validItems = 0;
      double totalValue = 0.0;

      // Check each item
      for (var item in cartItems) {
        bool itemValid = true;

        if (item['foodId'] == null || item['foodId'].toString().isEmpty) {
          issues.add('Item missing food ID');
          itemValid = false;
        }

        if (item['foodName'] == null || item['foodName'].toString().isEmpty) {
          issues.add('Item missing food name');
          itemValid = false;
        }

        if (item['price'] == null || (item['price'] as num) <= 0) {
          issues.add('Item has invalid price');
          itemValid = false;
        }

        if (item['quantity'] == null || (item['quantity'] as num) <= 0) {
          issues.add('Item has invalid quantity');
          itemValid = false;
        }

        if (item['shopId'] == null || item['shopId'].toString().isEmpty) {
          issues.add('Item missing shop ID');
          itemValid = false;
        }

        if (itemValid) {
          validItems++;
          totalValue += (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final storeCount = cartItems
          .where((item) => item['shopId'] != null)
          .map((item) => item['shopId'])
          .toSet()
          .length;

      return {
        'isValid': issues.isEmpty,
        'message': issues.isEmpty ? 'Cart is valid' : 'Cart has issues',
        'issues': issues,
        'itemCount': cartItems.length,
        'validItemCount': validItems,
        'totalValue': totalValue,
        'storeCount': storeCount,
      };
    } catch (e) {
      print('Error validating cart: $e');
      return {
        'isValid': false,
        'message': 'Error validating cart: $e',
        'issues': ['Validation error'],
        'itemCount': 0,
        'validItemCount': 0,
        'totalValue': 0.0,
        'storeCount': 0,
      };
    }
  }

  /// Get item quantity in cart
  static Future<int> getItemQuantity(
    String foodId,
    String shopId, {
    String? variation,
  }) async {
    try {
      final cartItems = await getCartItems();

      final item = cartItems.firstWhere(
        (item) =>
            item['foodId'] == foodId &&
            item['shopId'] == shopId &&
            item['variation'] == variation,
        orElse: () => {},
      );

      return item['quantity'] ?? 0;
    } catch (e) {
      print('Error getting item quantity: $e');
      return 0;
    }
  }

  /// ✅ NEW: Get cart summary for quick overview
  static Future<Map<String, dynamic>> getCartSummary() async {
    try {
      final cartItems = await getCartItems();
      final cartTotal = await getCartTotal();
      final cartCount = await getCartItemCount();
      final storeCount = await getUniqueStoreCount();

      return {
        'itemCount': cartCount,
        'storeCount': storeCount,
        'totalValue': cartTotal,
        'isEmpty': cartItems.isEmpty,
        'items': cartItems,
      };
    } catch (e) {
      print('Error getting cart summary: $e');
      return {
        'itemCount': 0,
        'storeCount': 0,
        'totalValue': 0.0,
        'isEmpty': true,
        'items': [],
      };
    }
  }

  /// ✅ NEW: Emergency recovery method
  static Future<void> performEmergencyRecovery() async {
    try {
      print('🚨 [CartService] Performing emergency recovery...');

      // Step 1: Clear all cart data
      await forceEmergencyClear();

      // Step 2: Reset cache
      _cachedCartCount = 0;
      _lastCacheUpdate = DateTime.now();

      // Step 3: Validate storage
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null) {
        print('⚠️ Cart data still exists after clear, forcing removal...');
        await prefs.clear(); // Nuclear option
      }

      // Step 4: Notify listeners
      if (onCartChanged != null) {
        onCartChanged!();
      }

      print('✅ [CartService] Emergency recovery completed');
    } catch (e) {
      print('❌ [CartService] Emergency recovery failed: $e');
    }
  }

  /// ✅ NEW: Get cart statistics
  static Future<Map<String, dynamic>> getCartStatistics() async {
    try {
      final cartItems = await getCartItems();
      final now = DateTime.now();

      Map<String, int> itemsByStore = {};
      Map<String, double> valueByStore = {};
      double totalValue = 0.0;
      int totalItems = 0;

      for (var item in cartItems) {
        final storeId = item['shopId']?.toString() ?? 'unknown';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final itemTotal = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;

        itemsByStore[storeId] = (itemsByStore[storeId] ?? 0) + quantity;
        valueByStore[storeId] = (valueByStore[storeId] ?? 0.0) + itemTotal;

        totalItems += quantity;
        totalValue += itemTotal;
      }

      return {
        'totalItems': totalItems,
        'totalValue': totalValue,
        'storeCount': itemsByStore.length,
        'itemsByStore': itemsByStore,
        'valueByStore': valueByStore,
        'averageItemValue': totalItems > 0 ? totalValue / totalItems : 0.0,
        'lastUpdated': _lastCacheUpdate?.toIso8601String(),
        'cacheStatus': _cachedCartCount != null ? 'cached' : 'not_cached',
      };
    } catch (e) {
      print('Error getting cart statistics: $e');
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'storeCount': 0,
        'itemsByStore': {},
        'valueByStore': {},
        'averageItemValue': 0.0,
        'lastUpdated': null,
        'cacheStatus': 'error',
      };
    }
  }
}
