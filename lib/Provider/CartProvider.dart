// File: lib/Provider/CartProvider.dart

import 'package:flutter/foundation.dart';
import '../services/CartService.dart';

class CartProvider with ChangeNotifier {
  int _cartCount = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _cartItems = [];

  // Getters
  int get cartCount => _cartCount;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get cartItems => _cartItems;

  CartProvider() {
    // Set up the callback for real-time updates
    CartService.onCartChanged = () {
      refreshCartCount();
    };

    // Load initial cart count
    refreshCartCount();
  }

  /// Refresh cart count from CartService
  Future<void> refreshCartCount() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get cart count from service
      final count = await CartService.getCartItemCount();
      final items = await CartService.getCartItems();

      _cartCount = count;
      _cartItems = items;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      print('Error refreshing cart count: $e');
      _cartCount = 0;
      _cartItems = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to cart
  Future<void> addToCart({
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
      _isLoading = true;
      notifyListeners();

      await CartService.addToCartWithCallback(
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

      // Cart count will be automatically updated via callback
    } catch (e) {
      print('Error adding to cart: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(
    String foodId,
    String shopId, {
    String? variation,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await CartService.removeFromCartWithCallback(
        foodId,
        shopId,
        variation: variation,
      );

      // Cart count will be automatically updated via callback
    } catch (e) {
      print('Error removing from cart: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(
    String foodId,
    String shopId,
    int newQuantity, {
    String? variation,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await CartService.updateItemQuantityWithCallback(
        foodId,
        shopId,
        newQuantity,
        variation: variation,
      );

      // Cart count will be automatically updated via callback
    } catch (e) {
      print('Error updating quantity: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      await CartService.clearCartWithCallback();

      // Cart count will be automatically updated via callback
    } catch (e) {
      print('Error clearing cart: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get cart total
  Future<double> getCartTotal() async {
    try {
      return await CartService.getCartTotal();
    } catch (e) {
      print('Error getting cart total: $e');
      return 0.0;
    }
  }

  /// Get item quantity in cart
  Future<int> getItemQuantity(
    String foodId,
    String shopId, {
    String? variation,
  }) async {
    try {
      return await CartService.getItemQuantity(
        foodId,
        shopId,
        variation: variation,
      );
    } catch (e) {
      print('Error getting item quantity: $e');
      return 0;
    }
  }

  /// Get cached cart count (synchronous)
  int getCachedCartCount() {
    return CartService.getCachedCartCount();
  }

  @override
  void dispose() {
    // Clear the callback when provider is disposed
    CartService.onCartChanged = null;
    super.dispose();
  }
}
