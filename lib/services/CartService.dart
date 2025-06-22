import 'package:shared_preferences/shared_preferences.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'dart:convert';

class CartService {
  static const String _cartKey = 'cart_items';
  static const String _orderHistoryKey = 'order_history';

  // ===============================
  // UPDATED CART METHODS WITH PORTION SUPPORT
  // ===============================

  /// Add item to cart with portion support
  static Future<void> addToCart(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(_cartKey) ?? [];

    bool itemExists = false;
    List<Map<String, dynamic>> decodedItems = cartItems
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();

    // Check if same item with same portion exists
    for (int i = 0; i < decodedItems.length; i++) {
      if (decodedItems[i]['shopId'] == item['shopId'] &&
          decodedItems[i]['foodId'] == item['foodId'] &&
          decodedItems[i]['portion'] == item['portion']) {
        // NEW: Check portion match
        decodedItems[i]['quantity'] += 1;
        decodedItems[i]['totalPrice'] =
            decodedItems[i]['quantity'] * decodedItems[i]['price'];
        itemExists = true;
        break;
      }
    }

    if (!itemExists) {
      item['quantity'] = 1;
      item['totalPrice'] = item['price'];
      item['addedAt'] = DateTime.now().toIso8601String();
      item['specialInstructions'] = '';

      // Ensure portion field exists (for backward compatibility)
      if (!item.containsKey('portion')) {
        item['portion'] = 'Full'; // Default portion
      }

      decodedItems.add(item);
    }

    List<String> encodedItems =
        decodedItems.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_cartKey, encodedItems);
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(_cartKey) ?? [];

    return cartItems
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }

  static Future<void> updateCartItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedItems = items.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_cartKey, encodedItems);
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<int> getCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(_cartKey) ?? [];

    int totalCount = 0;
    for (String item in cartItems) {
      Map<String, dynamic> decodedItem = json.decode(item);
      totalCount += decodedItem['quantity'] as int;
    }

    return totalCount;
  }

  // ===============================
  // UPDATED BACKEND INTEGRATION WITH PORTION SUPPORT
  // ===============================

  /// Place orders using the new backend system with portion information
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
    try {
      // Process cart items to include portion information in order items
      List<Map<String, dynamic>> processedCartItems = cartItems.map((item) {
        // Ensure portion information is included
        Map<String, dynamic> processedItem = Map.from(item);

        // Add portion to food name if not already included
        String foodName = processedItem['foodName'] ?? '';
        String portion = processedItem['portion'] ?? 'Full';

        if (!foodName.contains('($portion)')) {
          // Remove any existing portion suffix first
          foodName = foodName.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
          // Add the correct portion
          processedItem['foodName'] = '$foodName ($portion)';
        }

        return processedItem;
      }).toList();

      // Use the OrderProvider to place orders
      final orderIds = await orderProvider.placeOrdersFromCart(
        customer,
        processedCartItems,
        deliveryOption: deliveryOption,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
        scheduledTime: scheduledTime,
      );

      // Clear the cart after successful order placement
      await clearCart();

      // Add to local order history for offline viewing
      await _addOrdersToLocalHistory(orderIds, processedCartItems, customer, {
        'deliveryOption': deliveryOption,
        'paymentMethod': paymentMethod,
        'specialInstructions': specialInstructions,
        'totalAmount':
            _calculateTotalAmount(processedCartItems, deliveryOption),
      });

      return orderIds;
    } catch (e) {
      throw Exception('Failed to place orders: $e');
    }
  }

  /// Calculate total amount from cart items
  static double _calculateTotalAmount(
      List<Map<String, dynamic>> cartItems, String deliveryOption) {
    double subtotal = cartItems.fold(
        0.0, (sum, item) => sum + (item['totalPrice'] as double));
    double deliveryFee = deliveryOption == 'Delivery' ? 100.0 : 0.0;
    double serviceFee = subtotal * 0.05;
    return subtotal + deliveryFee + serviceFee;
  }

  /// Add orders to local history with portion information
  static Future<void> _addOrdersToLocalHistory(
    List<String> orderIds,
    List<Map<String, dynamic>> cartItems,
    CustomUser customer,
    Map<String, dynamic> orderDetails,
  ) async {
    for (int i = 0; i < orderIds.length; i++) {
      final orderId = orderIds[i];

      // Group items by store to match the order structure
      Map<String, List<Map<String, dynamic>>> itemsByStore = {};
      for (var item in cartItems) {
        final storeId = item['shopId'] as String;
        if (!itemsByStore.containsKey(storeId)) {
          itemsByStore[storeId] = [];
        }
        itemsByStore[storeId]!.add(item);
      }

      // Create local order record for each store
      for (var entry in itemsByStore.entries) {
        final storeItems = entry.value;

        // Create detailed item list with portion information
        List<String> itemDescriptions = storeItems.map((item) {
          String foodName = item['foodName'] ?? '';
          int quantity = item['quantity'] ?? 1;
          String portion = item['portion'] ?? 'Full';

          return '$foodName x$quantity';
        }).toList();

        final localOrder = {
          'orderId': orderId,
          'customerId': customer.id,
          'customerName': customer.name,
          'shopNames': [storeItems.first['shopName']],
          'items':
              itemDescriptions, // Include portion information in descriptions
          'detailedItems': storeItems, // Store complete item information
          'totalAmount':
              _calculateTotalAmount(storeItems, orderDetails['deliveryOption']),
          'status': 'Pending',
          'orderDate': DateTime.now().toIso8601String(),
          'deliveryOption': orderDetails['deliveryOption'],
          'paymentMethod': orderDetails['paymentMethod'],
          'specialInstructions': orderDetails['specialInstructions'],
          'itemCount': storeItems.fold(
              0, (sum, item) => sum + (item['quantity'] as int)),
        };

        await addOrderToHistory(localOrder);
      }
    }
  }

  // ===============================
  // LOCAL ORDER HISTORY (Updated with portion support)
  // ===============================

  static Future<void> addOrderToHistory(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_orderHistoryKey) ?? [];

    history.insert(0, json.encode(order));

    if (history.length > 50) {
      history = history.take(50).toList();
    }

    await prefs.setStringList(_orderHistoryKey, history);
  }

  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_orderHistoryKey) ?? [];

    return history
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }

  // ===============================
  // HELPER METHODS FOR PORTION HANDLING
  // ===============================

  /// Extract portion from food name
  static String extractPortionFromName(String foodName) {
    final regex = RegExp(r'\((\w+)\)$');
    final match = regex.firstMatch(foodName);
    return match?.group(1) ?? 'Full';
  }

  /// Remove portion from food name
  static String removePortionName(String foodName) {
    return foodName.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
  }

  /// Check if two cart items are the same (including portion)
  static bool isSameCartItem(
      Map<String, dynamic> item1, Map<String, dynamic> item2) {
    return item1['shopId'] == item2['shopId'] &&
        item1['foodId'] == item2['foodId'] &&
        item1['portion'] == item2['portion'];
  }

  /// Get display name for cart item with portion
  static String getDisplayName(Map<String, dynamic> item) {
    String foodName = item['foodName'] ?? '';
    String portion = item['portion'] ?? 'Full';

    // Remove existing portion suffix if any
    foodName = removePortionName(foodName);

    // Add portion suffix
    return '$foodName ($portion)';
  }
}
