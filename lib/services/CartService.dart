// File: lib/services/CartService.dart (Enhanced with location support)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Model/Order.dart';

class CartService {
  static const String _cartKey = 'cart_items';

  // ===================================
  // EXISTING CART METHODS
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

  /// Save cart items to local storage
  static Future<void> updateCartItems(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(items);
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Error updating cart items: $e');
    }
  }

  /// Add item to cart
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

  /// Remove item from cart
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

  /// Clear entire cart
  static Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  /// Get cart item count
  /// Get cart item count (EXPLICIT FIX)
  static Future<int> getCartItemCount() async {
    try {
      final cartItems = await getCartItems();
      int totalCount = 0; // Explicit int variable

      for (var item in cartItems) {
        final quantity = item['quantity'];
        if (quantity != null) {
          totalCount +=
              (quantity as num).toInt(); // Cast to num first, then toInt()
        }
      }

      return totalCount;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  /// Get cart total value (EXPLICIT FIX)
  static Future<double> getCartTotal() async {
    try {
      final cartItems = await getCartItems();
      double totalValue = 0.0; // Explicit double variable

      for (var item in cartItems) {
        final totalPrice = item['totalPrice'];
        if (totalPrice != null) {
          totalValue += (totalPrice as num)
              .toDouble(); // Cast to num first, then toDouble()
        }
      }

      return totalValue;
    } catch (e) {
      print('Error getting cart total: $e');
      return 0.0;
    }
  }

  static Future<void> emergencyClearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear both possible cart storage formats
      await prefs.remove('cart_items'); // String format
      await prefs.remove(_cartKey); // Current format

      // Also try to clear any List<String> format that might exist
      List<String> keys = prefs.getKeys().toList();
      for (String key in keys) {
        if (key.contains('cart')) {
          await prefs.remove(key);
          print('🗑️ Removed cart key: $key');
        }
      }

      print('🚨 Emergency cart clear completed - All cart data removed');
    } catch (e) {
      print('❌ Error during emergency clear: $e');
    }
  }

  /// Debug method to see all cart-related storage
  static Future<void> debugCartStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      print('=== CART STORAGE DEBUG ===');
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
  // ENHANCED ORDER PLACEMENT WITH LOCATION
  // ===================================

  /// Place orders with enhanced location support
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
          '🚀 [CartService] Starting enhanced order placement with location...');

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

      // Create one order per store
      for (var entry in itemsByStore.entries) {
        final storeId = entry.key;
        final storeItems = entry.value;

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
          deliveryLocation: orderLocation, // ENHANCED: Location object
          paymentMethod: paymentMethod,
          specialInstructions: specialInstructions,
          scheduledTime: scheduledTime,
          orderTime: DateTime.now(),
        );

        // Save to Firestore
        final docRef = await FirebaseFirestore.instance
            .collection('orders')
            .add(order.toMap());
        orderIds.add(docRef.id);

        // Create order request for the store
        await _createOrderRequest(docRef.id, order);

        print('✅ [CartService] Order created for store $storeId: ${docRef.id}');
      }

      // Clear cart after successful order placement
      await clearCart();

      print(
          '🎉 [CartService] Successfully created ${orderIds.length} orders with location data');
      return orderIds;
    } catch (e) {
      print('❌ [CartService] Error placing orders with location: $e');
      throw Exception('Failed to place orders: $e');
    }
  }

  /// Create order request for store owner (same as before)
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
      deliveryLocation: null, // No location data in legacy method
      locationDisplayText: null,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      scheduledTime: scheduledTime,
    );
  }

  // ===================================
  // UTILITY METHODS
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

  /// Validate cart before checkout
  static Future<Map<String, dynamic>> validateCart() async {
    try {
      final cartItems = await getCartItems();

      if (cartItems.isEmpty) {
        return {
          'isValid': false,
          'message': 'Cart is empty',
        };
      }

      // Check for any invalid items
      bool hasInvalidItems = cartItems.any((item) =>
          item['foodId'] == null ||
          item['foodName'] == null ||
          item['price'] == null ||
          item['quantity'] == null ||
          item['shopId'] == null);

      if (hasInvalidItems) {
        return {
          'isValid': false,
          'message': 'Cart contains invalid items',
        };
      }

      return {
        'isValid': true,
        'itemCount':
            cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int)),
        'totalValue': cartItems.fold(
            0.0, (sum, item) => sum + (item['totalPrice'] as double)),
        'storeCount': cartItems.map((item) => item['shopId']).toSet().length,
      };
    } catch (e) {
      print('Error validating cart: $e');
      return {
        'isValid': false,
        'message': 'Error validating cart: $e',
      };
    }
  }

  /// Update item quantity in cart
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
}
