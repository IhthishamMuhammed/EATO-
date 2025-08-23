import 'package:eato/Provider/CartProvider.dart';
import 'package:eato/pages/location/location_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/services/CartService.dart';
import 'package:eato/services/StripePaymentService.dart';
import 'package:eato/EatoComponents.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/widgets/stripe_payment_widget.dart';

class OrdersPage extends StatefulWidget {
  final bool showBottomNav;

  const OrdersPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  // Cart Management
  List<Map<String, dynamic>> _cartItems = [];
  int _totalCartItems = 0;
  double _totalCartValue = 0.0;
  bool _isLoading = true;
  bool _isPlacingOrder = false; // NEW: For Stripe integration

  // Order Options
  DeliveryType _deliveryOption = DeliveryType.pickup;
  PaymentType _paymentMethod = PaymentType.cash;
  String _specialInstructions = '';
  DateTime? _scheduledTime;

  // Location data
  String _deliveryAddress = '';
  GeoPoint? _deliveryLocation;
  String _locationDisplayText = '';

  // Store availability data
  Map<String, Map<String, dynamic>> _storeAvailability = {};
  bool _checkingStoreAvailability = false;

  // UI Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCartItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).addListener(() {
        if (mounted) {
          _loadCartItems();
        }
      });
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  // ===================================
  // CART LOADING WITH STORE AVAILABILITY
  // ===================================

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await CartService.getCartItems();
      print('🛒 [OrdersPage] Loaded ${items.length} cart items');

      setState(() {
        _cartItems = items;
        _isLoading = false;
      });

      _updateCartTotals();
      await _checkStoreAvailability();
    } catch (e) {
      print('❌ [OrdersPage] Error loading cart items: $e');
      setState(() {
        _cartItems = [];
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading cart. Please try again.');
    }
  }

  void _updateCartTotals() {
    try {
      _totalCartItems = 0;
      _totalCartValue = 0.0;

      for (var item in _cartItems) {
        final quantity = item['quantity'];
        if (quantity != null) {
          _totalCartItems += (quantity as num).toInt();
        }

        final totalPrice = item['totalPrice'];
        if (totalPrice != null) {
          _totalCartValue += (totalPrice as num).toDouble();
        }
      }

      print(
          '📊 [OrdersPage] Cart totals - Items: $_totalCartItems, Value: $_totalCartValue');
    } catch (e) {
      print('❌ [OrdersPage] Error calculating totals: $e');
      _totalCartItems = 0;
      _totalCartValue = 0.0;
    }
  }

  // ===================================
  // STORE AVAILABILITY CHECKING
  // ===================================

  Future<void> _checkStoreAvailability() async {
    if (_cartItems.isEmpty) return;

    setState(() {
      _checkingStoreAvailability = true;
    });

    try {
      final storeIds =
          _cartItems.map((item) => item['shopId'] as String).toSet();

      for (String storeId in storeIds) {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();

        if (storeDoc.exists) {
          final storeData = storeDoc.data() as Map<String, dynamic>;

          // Parse delivery mode
          String deliveryMode = storeData['deliveryMode'] ?? 'pickup';
          bool supportsPickup =
              deliveryMode == 'pickup' || deliveryMode == 'both';
          bool supportsDelivery =
              deliveryMode == 'delivery' || deliveryMode == 'both';

          _storeAvailability[storeId] = {
            'name': storeData['name'] ?? 'Unknown Store',
            'supportsPickup': supportsPickup,
            'supportsDelivery': supportsDelivery,
            'deliveryMode': deliveryMode,
            'isActive': storeData['isActive'] ?? true,
            'isAvailable': storeData['isAvailable'] ?? true,
          };
        }
      }

      // Update delivery option based on store availability
      _updateDeliveryOptionBasedOnAvailability();
    } catch (e) {
      print('❌ Error checking store availability: $e');
    } finally {
      setState(() {
        _checkingStoreAvailability = false;
      });
    }
  }

  void _updateDeliveryOptionBasedOnAvailability() {
    if (_storeAvailability.isEmpty) return;

    bool allStoresSupportPickup = _storeAvailability.values
        .every((store) => store['supportsPickup'] == true);
    bool allStoresSupportDelivery = _storeAvailability.values
        .every((store) => store['supportsDelivery'] == true);

    // If current option is not supported by all stores, switch to supported option
    if (_deliveryOption == DeliveryType.delivery && !allStoresSupportDelivery) {
      if (allStoresSupportPickup) {
        setState(() {
          _deliveryOption = DeliveryType.pickup;
        });
        _showInfoSnackBar(
            'Switched to Pickup - some restaurants don\'t deliver');
      }
    } else if (_deliveryOption == DeliveryType.pickup &&
        !allStoresSupportPickup) {
      if (allStoresSupportDelivery) {
        setState(() {
          _deliveryOption = DeliveryType.delivery;
        });
        _showInfoSnackBar(
            'Switched to Delivery - some restaurants are pickup only');
      }
    }
  }

  // ===================================
  // CART ITEM MANAGEMENT
  // ===================================

  Future<void> _updateCartItemQuantity(int index, int change) async {
    try {
      final currentQuantity = (_cartItems[index]['quantity'] as num).toInt();
      final price = (_cartItems[index]['price'] as num).toDouble();
      final newQuantity = currentQuantity + change;

      setState(() {
        if (newQuantity <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index]['quantity'] = newQuantity;
          _cartItems[index]['totalPrice'] = newQuantity * price;
        }
        _updateCartTotals();
      });

      await CartService.updateCartItems(_cartItems);
    } catch (e) {
      print('❌ [OrdersPage] Error updating quantity: $e');
      _loadCartItems(); // Reload on error
    }
  }

  Future<void> _removeCartItem(int index) async {
    try {
      setState(() {
        _cartItems.removeAt(index);
        _updateCartTotals();
      });

      await CartService.updateCartItems(_cartItems);
      _showSuccessSnackBar('Item removed from cart');
    } catch (e) {
      print('❌ [OrdersPage] Error removing item: $e');
      _loadCartItems(); // Reload on error
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await _showClearCartDialog();
    if (!confirmed) return;

    try {
      await CartService.clearCart();
      setState(() {
        _cartItems.clear();
        _updateCartTotals();
      });
      _showSuccessSnackBar('Cart cleared successfully');
    } catch (e) {
      print('❌ Error clearing cart: $e');
      _showErrorSnackBar('Failed to clear cart');
    }
  }

  // ===================================
  // ORDER PLACEMENT WITH STRIPE INTEGRATION
  // ===================================

  // NEW: Enhanced place order method with Stripe handling
  Future<void> _handlePlaceOrder() async {
    // Validate required fields first
    if (!_validateOrderDetails()) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final calculation = StripePaymentService.calculateFees(
        subtotal: _totalCartValue,
        paymentMethod: _paymentMethod,
        deliveryMethod: _deliveryOption,
      );

      // Show confirmation dialog
      final confirmed = await _showOrderConfirmationDialog();
      if (!confirmed) {
        setState(() => _isPlacingOrder = false);
        return;
      }

      // Handle different payment methods
      if (_paymentMethod == PaymentType.stripe) {
        // Handle Stripe payment
        await _handleStripePayment(calculation);
      } else {
        // Handle cash/card payments as before
        await _placeOrderWithBackend();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to place order: $e');
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  // NEW: Synchronous wrapper for the button callback
  void _handlePlaceOrderSync() {
    _handlePlaceOrder();
  }

  // NEW: Stripe payment handling method
  Future<void> _handleStripePayment(FeeCalculation calculation) async {
    // Generate order ID first
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Show Stripe payment modal
    StripePaymentHelper.showStripePayment(
      context: context,
      amount: calculation.totalAmount,
      orderId: orderId,
      customerId: currentUserId,
      onSuccess: (result) async {
        // Payment successful - proceed with order
        await _placeOrderWithStripePayment(result);
      },
      onError: (error) {
        // Show error message
        _showErrorSnackBar('Payment failed: $error');
      },
    );
  }

  // NEW: Method for Stripe order submission
  Future<void> _placeOrderWithStripePayment(Map<String, dynamic> paymentResult) async {
    // Show loading dialog
    _showLoadingDialog('Placing your orders...');

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (userProvider.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Place orders with notifications
      final orderIds = await orderProvider.placeOrdersWithNotifications(
        customerId: userProvider.currentUser!.id,
        customerName: userProvider.currentUser!.name,
        customerPhone: userProvider.currentUser!.phoneNumber ?? '',
        cartItems: _cartItems,
        deliveryOption: _deliveryOption.displayName,
        deliveryAddress: _deliveryAddress,
        deliveryLocation: _deliveryLocation,
        locationDisplayText: _locationDisplayText,
        paymentMethod: _paymentMethod.displayName,
        specialInstructions:
            _specialInstructions.isNotEmpty ? _specialInstructions : null,
        scheduledTime: _scheduledTime,
      );

      Navigator.pop(context); // Close loading dialog

      if (orderIds.isNotEmpty) {
        // Send payment confirmation for Stripe payments
        await orderProvider.sendPaymentConfirmation(
          orderId: orderIds.first,
          amount: paymentResult['amount'] ?? 0.0,
          paymentMethod: 'Stripe',
        );

        // Clear cart after successful order placement
        await CartService.clearCart();
        setState(() {
          _cartItems.clear();
          _updateCartTotals();
        });

        // Start listening to customer orders for real-time updates
        orderProvider.listenToCustomerOrders(userProvider.currentUser!.id);

        // Show success dialog
        _showOrderSuccessDialog(orderIds.length);
      } else {
        throw Exception('No orders were created');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showOrderFailureDialog(e.toString());
    }
  }

  // NEW: Validation method
  bool _validateOrderDetails() {
    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Your cart is empty');
      return false;
    }

    if (_deliveryOption == DeliveryType.delivery) {
      if (_deliveryLocation == null && _deliveryAddress.trim().isEmpty) {
        _showErrorSnackBar('Please select a delivery location');
        return false;
      }
    }

    return true;
  }

  // EXISTING: Original backend order placement method
  Future<void> _placeOrderWithBackend() async {
    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Your cart is empty');
      return;
    }

    // Validate delivery location for delivery orders
    if (_deliveryOption == DeliveryType.delivery) {
      if (_deliveryLocation == null && _deliveryAddress.trim().isEmpty) {
        _showErrorSnackBar('Please select delivery location');
        return;
      }
    }

    // Show confirmation dialog
    final confirmed = await _showOrderConfirmationDialog();
    if (!confirmed) return;

    // Show loading overlay
    _showLoadingDialog('Placing your orders...');

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (userProvider.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Place orders with notifications
      final orderIds = await orderProvider.placeOrdersWithNotifications(
        customerId: userProvider.currentUser!.id,
        customerName: userProvider.currentUser!.name,
        customerPhone: userProvider.currentUser!.phoneNumber ?? '',
        cartItems: _cartItems,
        deliveryOption: _deliveryOption.displayName,
        deliveryAddress: _deliveryAddress,
        deliveryLocation: _deliveryLocation,
        locationDisplayText: _locationDisplayText,
        paymentMethod: _paymentMethod.displayName,
        specialInstructions:
            _specialInstructions.isNotEmpty ? _specialInstructions : null,
        scheduledTime: _scheduledTime,
      );

      Navigator.pop(context); // Close loading dialog

      if (orderIds.isNotEmpty) {
        // Clear cart after successful order placement
        await CartService.clearCart();
        setState(() {
          _cartItems.clear();
          _updateCartTotals();
        });

        // Start listening to customer orders for real-time updates
        orderProvider.listenToCustomerOrders(userProvider.currentUser!.id);

        // Show success dialog
        _showOrderSuccessDialog(orderIds.length);
      } else {
        throw Exception('No orders were created');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showOrderFailureDialog(e.toString());
    }
  }

  // ===================================
  // LOCATION PICKER INTEGRATION
  // ===================================

  Future<void> _selectDeliveryLocation() async {
    try {
      final result = await Navigator.push<LocationData>(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerPage(
            initialLocation: _deliveryLocation,
            initialAddress: _locationDisplayText,
          ),
        ),
      );

      if (result != null) {
        setState(() {
          _deliveryLocation = result.geoPoint;
          _locationDisplayText = result.formattedAddress;
          _deliveryAddress = result.formattedAddress;
        });
        _showSuccessSnackBar('Delivery location selected');
      }
    } catch (e) {
      print('Error selecting location: $e');
      _showErrorSnackBar('Error selecting location. Please try again.');
    }
  }

  // ===================================
  // UI BUILDERS
  // ===================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      appBar: EatoComponents.appBar(
        context: context,
        title: 'My Cart',
        titleIcon: Icons.shopping_cart,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Cart count indicator
          if (_totalCartItems > 0) _buildCartIndicator(),

          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _cartItems.isEmpty
                    ? _buildEmptyCart()
                    : _buildCartContent(),
          ),

          if (widget.showBottomNav)
            BottomNavBar(
              currentIndex: 2,
              onTap: (index) {
                if (index != 2) {
                  Navigator.pushReplacementNamed(
                      context, _getRouteForIndex(index));
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCartIndicator() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: EatoTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: EatoTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_cart,
                        color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_totalCartItems items in your cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rs. ${_totalCartValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_getUniqueShopCount()} restaurants',
                      style: TextStyle(
                        color: EatoTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: EatoTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Loading your cart...',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return EatoComponents.emptyState(
      message: 'Your cart is empty\nAdd some delicious items to get started!',
      icon: Icons.shopping_cart_outlined,
      actionText: 'Browse Meals',
      onActionPressed: () => Navigator.pushNamed(context, '/home'),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Cart items
              ...List.generate(_cartItems.length,
                  (index) => _buildCartItem(_cartItems[index], index)),

              SizedBox(height: 24),

              // Delivery options
              _buildDeliveryOptions(),

              SizedBox(height: 16),

              // Payment method
              _buildPaymentMethod(),

              SizedBox(height: 16),

              // Special instructions
              _buildSpecialInstructions(),

              SizedBox(height: 16),

              // Schedule order
              _buildScheduleOrder(),

              SizedBox(height: 16),

              // Order summary
              _buildOrderSummary(),

              SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),

        // Place order button
        _buildPlaceOrderButton(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final foodName = item['foodName']?.toString() ?? 'Unknown Food';
    final shopName = item['shopName']?.toString() ?? 'Unknown Shop';
    final variation = item['variation']?.toString() ?? 'Regular';
    final foodImage = item['foodImage']?.toString() ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Food image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: foodImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: foodImage,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: EatoTheme.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, error, stackTrace) =>
                              Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.fastfood,
                                color: EatoTheme.primaryColor),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.fastfood,
                              color: EatoTheme.primaryColor),
                        ),
                ),

                SizedBox(width: 16),

                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: EatoTheme.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: EatoTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              variation,
                              style: TextStyle(
                                color: EatoTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shopName,
                              style: TextStyle(
                                color: EatoTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Rs. ${price.toStringAsFixed(2)} each',
                        style: TextStyle(
                          color: EatoTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: () => _removeCartItem(index),
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 22),
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),

          // Quantity controls and total
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EatoTheme.backgroundColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => _updateCartItemQuantity(index, -1),
                        color: Colors.red.shade400,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '$quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: EatoTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => _updateCartItemQuantity(index, 1),
                        color: Colors.green.shade400,
                      ),
                    ],
                  ),
                ),

                // Item total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: EatoTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      'Rs. ${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: EatoTheme.primaryColor,
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.delivery_dining, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Delivery Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: EatoTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (_checkingStoreAvailability)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: EatoTheme.primaryColor),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Checking store availability...',
                    style: TextStyle(color: EatoTheme.textSecondaryColor),
                  ),
                ],
              ),
            )
          else
            _buildDeliveryOptionsList(),
          if (_deliveryOption == DeliveryType.delivery) ...[
            Divider(height: 1),
            _buildLocationSelector(),
          ],
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptionsList() {
    bool pickupAvailable = _storeAvailability.values
        .every((store) => store['supportsPickup'] == true);
    bool deliveryAvailable = _storeAvailability.values
        .every((store) => store['supportsDelivery'] == true);

    return Column(
      children: [
        if (pickupAvailable)
          _buildDeliveryOptionTile(
            type: DeliveryType.pickup,
            title: 'Pickup',
            subtitle: 'Collect from restaurant',
            icon: Icons.store,
            selected: _deliveryOption == DeliveryType.pickup,
          ),
        if (deliveryAvailable)
          _buildDeliveryOptionTile(
            type: DeliveryType.delivery,
            title: 'Delivery',
            subtitle: 'Deliver to your location',
            icon: Icons.delivery_dining,
            selected: _deliveryOption == DeliveryType.delivery,
          ),
        if (!pickupAvailable || !deliveryAvailable)
          _buildStoreAvailabilityWarning(),
      ],
    );
  }

  Widget _buildDeliveryOptionTile({
    required DeliveryType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => setState(() => _deliveryOption = type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? EatoTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: selected
              ? Border.all(color: EatoTheme.primaryColor, width: 1)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? EatoTheme.primaryColor
                    : EatoTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : EatoTheme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: selected
                          ? EatoTheme.primaryColor
                          : EatoTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: EatoTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: EatoTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreAvailabilityWarning() {
    List<String> pickupOnlyStores = [];
    List<String> deliveryOnlyStores = [];

    _storeAvailability.forEach((storeId, data) {
      if (data['supportsPickup'] && !data['supportsDelivery']) {
        pickupOnlyStores.add(data['name']);
      } else if (!data['supportsPickup'] && data['supportsDelivery']) {
        deliveryOnlyStores.add(data['name']);
      }
    });

    if (pickupOnlyStores.isEmpty && deliveryOnlyStores.isEmpty)
      return SizedBox();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pickupOnlyStores.isNotEmpty)
                  Text(
                    'Pickup only: ${pickupOnlyStores.join(', ')}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                if (deliveryOnlyStores.isNotEmpty)
                  Text(
                    'Delivery only: ${deliveryOnlyStores.join(', ')}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Location',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: EatoTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: _selectDeliveryLocation,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EatoTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: EatoTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _deliveryLocation != null
                        ? Icons.location_on
                        : Icons.add_location,
                    color: EatoTheme.primaryColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationDisplayText.isNotEmpty
                              ? _locationDisplayText
                              : 'Select delivery location',
                          style: TextStyle(
                            fontSize: 14,
                            color: _locationDisplayText.isNotEmpty
                                ? EatoTheme.textPrimaryColor
                                : EatoTheme.textSecondaryColor,
                          ),
                        ),
                        if (_deliveryLocation != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'GPS: ${_deliveryLocation!.latitude.toStringAsFixed(4)}, ${_deliveryLocation!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: EatoTheme.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final calculation = StripePaymentService.calculateFees(
      subtotal: _totalCartValue,
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryOption,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.payment, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: EatoTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          ...PaymentType.values
              .map((payment) => _buildPaymentMethodTile(payment)),

          // Fee savings message
          if (StripePaymentService.getFeeSavingsMessage(
                  _paymentMethod, _deliveryOption) !=
              null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings, color: Colors.green.shade600, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      StripePaymentService.getFeeSavingsMessage(
                          _paymentMethod, _deliveryOption)!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentType payment) {
    final bool selected = _paymentMethod == payment;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = payment),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? EatoTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: selected
              ? Border.all(color: EatoTheme.primaryColor, width: 1)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? EatoTheme.primaryColor
                    : EatoTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                StripePaymentService.getPaymentMethodIcon(payment),
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: selected
                          ? EatoTheme.primaryColor
                          : EatoTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    StripePaymentService.getPaymentMethodDescription(payment),
                    style: TextStyle(
                      fontSize: 12,
                      color: EatoTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: EatoTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: EatoTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Any specific requests for your order...',
                hintStyle: TextStyle(color: EatoTheme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: EatoTheme.primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EatoTheme.primaryColor),
                ),
                filled: true,
                fillColor: EatoTheme.backgroundColor,
              ),
              maxLines: 3,
              onChanged: (value) =>
                  setState(() => _specialInstructions = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOrder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Schedule Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: EatoTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: _selectScheduleTime,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EatoTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: EatoTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _scheduledTime == null
                          ? Icons.access_time
                          : Icons.schedule,
                      color: EatoTheme.primaryColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _scheduledTime == null
                            ? 'Order now'
                            : 'Scheduled for ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: EatoTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Text(
                      _scheduledTime == null ? 'Set Time' : 'Change',
                      style: TextStyle(
                        color: EatoTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final calculation = StripePaymentService.calculateFees(
      subtotal: _totalCartValue,
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryOption,
    );

    return Column(
      children: [
        // Restaurant Contact Information
        _buildRestaurantContacts(),

        SizedBox(height: 16),

        // Order Summary
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: EatoTheme.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: EatoTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildSummaryRow(
                    'Subtotal ($_totalCartItems items)', calculation.subtotal),
                if (calculation.deliveryFee > 0)
                  _buildSummaryRow('Delivery Fee', calculation.deliveryFee),
                if (calculation.serviceFee > 0)
                  _buildSummaryRow('Service Fee', calculation.serviceFee),
                if (calculation.paymentProcessingFee > 0)
                  _buildSummaryRow(
                      'Processing Fee', calculation.paymentProcessingFee),
                Divider(
                    thickness: 1,
                    color: EatoTheme.primaryColor.withOpacity(0.3)),
                _buildSummaryRow('Total Amount', calculation.totalAmount,
                    isTotal: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantContacts() {
    if (_cartItems.isEmpty) return SizedBox();

    // Get unique store IDs and their details
    Map<String, Map<String, dynamic>> storeDetails = {};
    for (var item in _cartItems) {
      final storeId = item['shopId']?.toString() ?? '';
      final storeName = item['shopName']?.toString() ?? 'Unknown Store';

      if (storeId.isNotEmpty && !storeDetails.containsKey(storeId)) {
        storeDetails[storeId] = {
          'name': storeName,
          'contact': null, // Will be fetched
        };
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Restaurant Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: EatoTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...storeDetails.entries.map((entry) =>
                _buildStoreContactCard(entry.key, entry.value['name'])),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreContactCard(String storeId, String storeName) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EatoTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: EatoTheme.primaryColor),
                ),
                SizedBox(width: 12),
                Text('Loading $storeName contact...'),
              ],
            ),
          );
        }

        final storeData = snapshot.data!.data() as Map<String, dynamic>?;
        final contact = storeData?['contact']?.toString() ?? '';

        if (contact.isEmpty) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange.shade600, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$storeName - Contact not available',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store, color: Colors.blue.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      contact,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _callStore(contact, storeName),
                icon: Icon(Icons.call, size: 16),
                label: Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(70, 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? EatoTheme.textPrimaryColor
                  : EatoTheme.textSecondaryColor,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color:
                  isTotal ? EatoTheme.primaryColor : EatoTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ENHANCED: Place Order Button with Stripe Integration
  Widget _buildPlaceOrderButton() {
    final calculation = StripePaymentService.calculateFees(
      subtotal: _totalCartValue,
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryOption,
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs. ${calculation.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: EatoTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${_getUniqueShopCount()} restaurants • ${_deliveryOption.displayName}',
                    style: TextStyle(
                      color: EatoTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          EatoComponents.primaryButton(
            text: _isPlacingOrder ? 'Processing...' : 'Place Orders',
            onPressed: _isPlacingOrder ? null : () async { await _handlePlaceOrder(); },
            icon: Icons.shopping_cart_checkout,
          ),
        ],
      ),
    );
  }

  // ===================================
  // CALL FUNCTIONALITY
  // ===================================

  Future<void> _callStore(String phoneNumber, String storeName) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Fallback: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        _showInfoSnackBar('Phone number copied: $phoneNumber');
      }
    } catch (e) {
      print('Error launching phone call: $e');
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      _showInfoSnackBar('Phone number copied: $phoneNumber');
    }
  }

  // ===================================
  // HELPER METHODS
  // ===================================

  void _selectScheduleTime() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(Duration(hours: 1))),
    );

    if (time != null) {
      setState(() {
        _scheduledTime =
            DateTime(now.year, now.month, now.day, time.hour, time.minute);
      });
    }
  }

  int _getUniqueShopCount() {
    try {
      return _cartItems.map((item) => item['shopId']).toSet().length;
    } catch (e) {
      print('Error getting shop count: $e');
      return 0;
    }
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/subscribed';
      case 3:
        return '/activity';
      case 4:
        return '/account';
      default:
        return '/home';
    }
  }

  // ===================================
  // DIALOG METHODS
  // ===================================

  Future<bool> _showClearCartDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Text('Clear Cart'),
              ],
            ),
            content: Text(
                'Are you sure you want to remove all items from your cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              EatoComponents.primaryButton(
                text: 'Clear All',
                onPressed: () => Navigator.pop(context, true),
                height: 40,
                width: 100,
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showOrderConfirmationDialog() async {
    final calculation = StripePaymentService.calculateFees(
      subtotal: _totalCartValue,
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryOption,
    );

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Text('Confirm Order'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to place orders with ${_getUniqueShopCount()} restaurants.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EatoTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                          'Total: Rs. ${calculation.totalAmount.toStringAsFixed(2)}'),
                      Text('Payment: ${_paymentMethod.displayName}'),
                      Text('Method: ${_deliveryOption.displayName}'),
                      if (_deliveryOption == DeliveryType.delivery)
                        Text(
                            'Address: ${_locationDisplayText.isNotEmpty ? _locationDisplayText : _deliveryAddress}'),
                      if (_scheduledTime != null)
                        Text(
                            'Scheduled: ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              EatoComponents.primaryButton(
                text: 'Confirm',
                onPressed: () => Navigator.pop(context, true),
                height: 40,
                width: 100,
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: EatoTheme.primaryColor),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showOrderSuccessDialog(int orderCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              'Orders Placed Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: EatoTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '✅ Placed $orderCount orders successfully',
              style: TextStyle(color: EatoTheme.textSecondaryColor),
            ),
            SizedBox(height: 8),
            Text(
              'Your orders have been sent to the restaurants. You will receive notifications about order status.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: EatoTheme.textSecondaryColor),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/activity');
                    },
                    child: Text('View Orders'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: EatoComponents.primaryButton(
                    text: 'Great!',
                    onPressed: () => Navigator.pop(context),
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderFailureDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error, color: Colors.red, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              'Order Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: EatoTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Failed to place orders: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: EatoTheme.textSecondaryColor),
            ),
            SizedBox(height: 24),
            EatoComponents.primaryButton(
              text: 'Try Again',
              onPressed: () => Navigator.pop(context),
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  // ===================================
  // SNACKBAR METHODS
  // ===================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}