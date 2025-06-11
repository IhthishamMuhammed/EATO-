import 'package:shared_preferences/shared_preferences.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'dart:convert';

class CartService {
  static const String _cartKey = 'cart_items';
  static const String _orderHistoryKey = 'order_history';

  // ===============================
  // CART METHODS (Existing)
  // ===============================

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

  // ===============================
  // NEW BACKEND INTEGRATION
  // ===============================

  /// Place orders using the new backend system
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
      // Use the OrderProvider to place orders
      final orderIds = await orderProvider.placeOrdersFromCart(
        customer,
        cartItems,
        deliveryOption: deliveryOption,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
        scheduledTime: scheduledTime,
      );

      // Clear the cart after successful order placement
      await clearCart();

      // Add to local order history for offline viewing
      await _addOrdersToLocalHistory(orderIds, cartItems, customer, {
        'deliveryOption': deliveryOption,
        'paymentMethod': paymentMethod,
        'specialInstructions': specialInstructions,
        'totalAmount': _calculateTotalAmount(cartItems, deliveryOption),
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

  /// Add orders to local history
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
        final localOrder = {
          'orderId': orderId,
          'customerId': customer.id,
          'customerName': customer.name,
          'shopNames': [storeItems.first['shopName']],
          'items': storeItems.map((item) => item['foodName']).toList(),
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
  // LOCAL ORDER HISTORY (Existing)
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
}
