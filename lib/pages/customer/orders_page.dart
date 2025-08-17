// File: lib/pages/customer/OrdersPage.dart (Fixed to handle cart data properly)

import 'package:eato/pages/location/location_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/services/CartService.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/widgets/test_notification_widget.dart';

class OrdersPage extends StatefulWidget {
  final bool showBottomNav;

  const OrdersPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // Cart Management
  List<Map<String, dynamic>> _cartItems = [];
  int _totalCartItems = 0;
  double _totalCartValue = 0.0;
  bool _isLoading = true;

  // Order Options
  String _deliveryOption = 'Delivery';
  String _specialInstructions = '';
  DateTime? _scheduledTime;
  String _paymentMethod = 'Cash on Delivery';

  // Location data - ENHANCED
  String _deliveryAddress = '';
  GeoPoint? _deliveryLocation;
  String _locationDisplayText = '';

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Card Payment',
    'Mobile Wallet',
    'Bank Transfer'
  ];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // ✅ FIXED: Load cart items with proper error handling
  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await CartService.getCartItems();
      print('📋 [OrdersPage] Loaded ${items.length} cart items');

      // Debug: Print each item structure
      for (int i = 0; i < items.length; i++) {
        print('   Item $i: ${items[i].keys.toList()}');
        print('   Data: ${items[i]}');
      }

      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
      _updateCartTotals();
    } catch (e) {
      print('❌ [OrdersPage] Error loading cart items: $e');
      setState(() {
        _cartItems = [];
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cart. Cart has been cleared.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Refresh',
              onPressed: _loadCartItems,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  // ✅ FIXED: Safe cart total calculation
  void _updateCartTotals() {
    try {
      _totalCartItems = 0;
      _totalCartValue = 0.0;

      for (var item in _cartItems) {
        // Safe quantity calculation
        final quantity = item['quantity'];
        if (quantity != null) {
          _totalCartItems += (quantity as num).toInt();
        }

        // Safe price calculation
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

  // ✅ FIXED: Safe quantity update
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ [OrdersPage] Error removing item: $e');
      _loadCartItems(); // Reload on error
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart'),
        content:
            Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CartService.clearCart();
      setState(() {
        _cartItems.clear();
        _updateCartTotals();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart cleared'), backgroundColor: Colors.red),
      );
    }
  }

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
          _deliveryAddress =
              result.formattedAddress; // For backward compatibility
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery location selected'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error selecting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting location. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===================================
  // ENHANCED BACKEND INTEGRATION
  // ===================================

  Future<void> _placeOrderWithBackend() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Your cart is empty'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Validate delivery location for delivery orders
    if (_deliveryOption == 'Delivery') {
      if (_deliveryLocation == null && _deliveryAddress.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select delivery location'),
              backgroundColor: Colors.orange),
        );
        return;
      }
    }

    // Show confirmation dialog
    final confirmed = await _showOrderConfirmationDialog();
    if (!confirmed) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 16),
            Text('Placing your orders...'),
          ],
        ),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (userProvider.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Place orders using the enhanced backend with location
      // Place orders with notifications
      final orderIds = await orderProvider.placeOrdersWithNotifications(
        customerId: userProvider.currentUser!.id,
        customerName: userProvider.currentUser!.name,
        customerPhone: userProvider.currentUser!.phoneNumber ?? '',
        cartItems: _cartItems,
        deliveryOption: _deliveryOption,
        deliveryAddress: _deliveryAddress,
        deliveryLocation: _deliveryLocation,
        locationDisplayText: _locationDisplayText,
        paymentMethod: _paymentMethod,
        specialInstructions: _specialInstructions,
        scheduledTime: _scheduledTime,
      );

      Navigator.pop(context); // Close loading dialog

      // Start listening to customer orders for real-time updates
      orderProvider.listenToCustomerOrders(userProvider.currentUser!.id);

      // Show success dialog
      _showOrderSuccessDialog(orderIds.length);

      // Refresh cart
      await _loadCartItems();
    } catch (e) {
      Navigator.pop(context);
      _showOrderFailureDialog(e.toString());
    }
  }

  Future<bool> _showOrderConfirmationDialog() async {
    final deliveryFee = _deliveryOption == 'Delivery' ? 100.0 : 0.0;
    final serviceFee = _totalCartValue * 0.05;
    final totalAmount = _totalCartValue + deliveryFee + serviceFee;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'You are about to place orders with ${_getUniqueShopCount()} restaurants.'),
                SizedBox(height: 8),
                Text('Total Amount: Rs. ${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Payment: $_paymentMethod'),
                Text(
                    '${_deliveryOption == 'Delivery' ? 'Delivery' : 'Pickup'}'),
                if (_deliveryOption == 'Delivery')
                  Text(
                      'Address: ${_locationDisplayText.isNotEmpty ? _locationDisplayText : _deliveryAddress}'),
                if (_scheduledTime != null)
                  Text(
                      'Scheduled: ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text('Confirm Order',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  int _getUniqueShopCount() {
    try {
      return _cartItems.map((item) => item['shopId']).toSet().length;
    } catch (e) {
      print('Error getting shop count: $e');
      return 0;
    }
  }

  void _showOrderSuccessDialog(int orderCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text('Orders Placed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅ Placed $orderCount orders successfully'),
            SizedBox(height: 8),
            Text(
                'Your orders have been sent to the restaurants. You will receive notifications about order status.'),
            SizedBox(height: 8),
            Text('Check the Activity tab for order updates.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('View Orders'),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Great!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOrderFailureDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red, size: 48),
        title: Text('Order Failed'),
        content: Text('Failed to place orders: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalAmount() {
    final deliveryFee = _deliveryOption == 'Delivery' ? 100.0 : 0.0;
    final serviceFee = _totalCartValue * 0.05;
    return _totalCartValue + deliveryFee + serviceFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text('My Cart',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
            if (_totalCartItems > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_totalCartItems items',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          // DEBUG: Add debug button
          IconButton(
            onPressed: () async {
              await CartService.getCartItems();
              _loadCartItems();
            },
            icon: Icon(Icons.refresh, color: Colors.blue),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.purple))
                : _cartItems.isEmpty
                    ? _buildEmptyCart()
                    : _buildCartContent(),
          ),
          if (widget.showBottomNav)
            BottomNavBar(
              currentIndex: 2, // Orders tab
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

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              TestNotificationWidget(),
              SizedBox(height: 16),
              // Cart items
              ...List.generate(_cartItems.length,
                  (index) => _buildCartItem(_cartItems[index], index)),
              SizedBox(height: 16),
              // ENHANCED: Delivery options with location picker
              _buildDeliveryOptionsWithLocation(),
              SizedBox(height: 16),
              // Special instructions
              _buildSpecialInstructions(),
              SizedBox(height: 16),
              // Schedule order
              _buildScheduleOrder(),
              SizedBox(height: 16),
              // Payment method
              _buildPaymentMethod(),
              SizedBox(height: 16),
              // Order summary
              _buildOrderSummary(),
              SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
        // Place order button (updated)
        _buildPlaceOrderButton(),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey.shade400),
          SizedBox(height: 20),
          Text('Your cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Add some delicious items to get started!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: Icon(Icons.restaurant_menu, color: Colors.white),
            label: Text('Browse Meals', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Safe cart item display
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    // Safe data extraction
    final foodName = item['foodName']?.toString() ?? 'Unknown Food';
    final shopName = item['shopName']?.toString() ?? 'Unknown Shop';
    final variation = item['variation']?.toString() ?? 'Regular';
    final foodImage = item['foodImage']?.toString() ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Food image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: foodImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: foodImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.fastfood)),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.fastfood)),
              ),
              SizedBox(width: 12),
              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(foodName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('$variation • $shopName',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('Rs. ${price.toStringAsFixed(2)} each',
                        style: TextStyle(
                            color: Colors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                onPressed: () => _removeCartItem(index),
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Quantity controls and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _updateCartItemQuantity(index, -1),
                      icon: Icon(Icons.remove, color: Colors.red, size: 18),
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$quantity',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    IconButton(
                      onPressed: () => _updateCartItemQuantity(index, 1),
                      icon: Icon(Icons.add, color: Colors.green, size: 18),
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              // Item total
              Text('Rs. ${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.purple)),
            ],
          ),
          SizedBox(height: 8),
          // Item-specific instructions
          TextField(
            decoration: InputDecoration(
              hintText: 'Special instructions for this item...',
              hintStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: TextStyle(fontSize: 12),
            maxLines: 2,
            onChanged: (value) async {
              _cartItems[index]['specialInstructions'] = value;
              await CartService.updateCartItems(_cartItems);
            },
          ),
        ],
      ),
    );
  }

  // ... (Keep all your other build methods - they should work fine now)

  Widget _buildSpecialInstructions() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Special Instructions for Order',
        hintText: 'Any specific requests for your order...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(Icons.note_add),
      ),
      maxLines: 2,
      onChanged: (value) => setState(() => _specialInstructions = value),
    );
  }

  Widget _buildScheduleOrder() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Order',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(_scheduledTime == null
                    ? 'Order now'
                    : 'Scheduled for ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'),
              ),
              TextButton.icon(
                onPressed: _selectScheduleTime,
                icon: Icon(Icons.schedule, size: 16),
                label: Text('Change', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: _paymentMethods
                .map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method, style: TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _paymentMethod = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final deliveryFee = _deliveryOption == 'Delivery' ? 100.0 : 0.0;
    final serviceFee = _totalCartValue * 0.05;
    final totalAmount = _totalCartValue + deliveryFee + serviceFee;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          _buildSummaryRow(
              'Subtotal ($_totalCartItems items)', _totalCartValue),
          if (_deliveryOption == 'Delivery')
            _buildSummaryRow('Delivery Fee', deliveryFee),
          _buildSummaryRow('Service Fee (5%)', serviceFee),
          Divider(),
          _buildSummaryRow('Total', totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              )),
          Text('Rs. ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.purple : Colors.black87,
              )),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    final totalAmount = _calculateTotalAmount();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
              Text('Total: Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_getUniqueShopCount()} restaurants',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrderWithBackend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Text('Place Orders',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Add the missing delivery options method
  Widget _buildDeliveryOptionsWithLocation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery Option',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Delivery', style: TextStyle(fontSize: 14)),
                  subtitle:
                      Text('To your location', style: TextStyle(fontSize: 12)),
                  value: 'Delivery',
                  groupValue: _deliveryOption,
                  onChanged: (value) =>
                      setState(() => _deliveryOption = value!),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Pickup', style: TextStyle(fontSize: 14)),
                  subtitle:
                      Text('From restaurant', style: TextStyle(fontSize: 12)),
                  value: 'Pickup',
                  groupValue: _deliveryOption,
                  onChanged: (value) =>
                      setState(() => _deliveryOption = value!),
                  dense: true,
                ),
              ),
            ],
          ),
          if (_deliveryOption == 'Delivery') ...[
            SizedBox(height: 12),
            // ENHANCED: Location picker button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationDisplayText.isNotEmpty
                              ? _locationDisplayText
                              : _deliveryAddress.isNotEmpty
                                  ? _deliveryAddress
                                  : 'Select delivery location',
                          style: TextStyle(
                            fontSize: 14,
                            color: (_locationDisplayText.isNotEmpty ||
                                    _deliveryAddress.isNotEmpty)
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectDeliveryLocation,
                        child: Text(
                          (_locationDisplayText.isNotEmpty ||
                                  _deliveryAddress.isNotEmpty)
                              ? 'Change'
                              : 'Select',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                  if (_deliveryLocation != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'GPS: ${_deliveryLocation!.latitude.toStringAsFixed(4)}, ${_deliveryLocation!.longitude.toStringAsFixed(4)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 8),
            // Fallback text input for address (backup option)
            ExpansionTile(
              title: Text('Or enter address manually',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Delivery Address',
                    hintText: 'Enter your delivery address...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.edit_location),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      setState(() => _deliveryAddress = value),
                  controller: TextEditingController(text: _deliveryAddress),
                ),
              ],
            ),
          ], // Add this button temporarily to your orders page
        ],
      ),
    );
  }
}
