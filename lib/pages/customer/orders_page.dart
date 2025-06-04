import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ✅ Same Cart Service (should be in a separate file)
class CartService {
  static const String _cartKey = 'cart_items';
  static const String _orderHistoryKey = 'order_history';

  // Get all cart items
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList(_cartKey) ?? [];

    return cartItems
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }

  // Update cart items
  static Future<void> updateCartItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedItems = items.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_cartKey, encodedItems);
  }

  // Clear cart
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  // Add order to history (for activity page)
  static Future<void> addOrderToHistory(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_orderHistoryKey) ?? [];

    history.insert(0, json.encode(order)); // Add to beginning

    // Keep only last 50 orders
    if (history.length > 50) {
      history = history.take(50).toList();
    }

    await prefs.setStringList(_orderHistoryKey, history);
  }

  // Get order history (for activity page)
  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_orderHistoryKey) ?? [];

    return history
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }
}

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
  String _deliveryAddress = '';

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

  // ✅ Load real cart items from storage
  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await CartService.getCartItems();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
      _updateCartTotals();
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCartTotals() {
    _totalCartItems =
        _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
    _totalCartValue = _cartItems.fold(
        0.0, (sum, item) => sum + (item['totalPrice'] as double));
  }

  // ✅ Update cart item quantity and save to storage
  Future<void> _updateCartItemQuantity(int index, int change) async {
    setState(() {
      _cartItems[index]['quantity'] += change;

      if (_cartItems[index]['quantity'] <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['totalPrice'] =
            _cartItems[index]['quantity'] * _cartItems[index]['price'];
      }
      _updateCartTotals();
    });

    // Save to storage
    await CartService.updateCartItems(_cartItems);
  }

  // ✅ Remove item from cart and save to storage
  Future<void> _removeCartItem(int index) async {
    setState(() {
      _cartItems.removeAt(index);
      _updateCartTotals();
    });

    // Save to storage
    await CartService.updateCartItems(_cartItems);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item removed from cart'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ Clear entire cart
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

  // ✅ Schedule order time
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

  // ✅ Send order requests to restaurants
  Future<void> _sendOrderRequests() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Your cart is empty'),
            backgroundColor: Colors.orange),
      );
      return;
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
            Text('Sending order requests to restaurants...'),
          ],
        ),
      ),
    );

    try {
      // Group orders by shop
      Map<String, List<Map<String, dynamic>>> ordersByShop = {};
      for (var item in _cartItems) {
        final shopId = item['shopId'];
        if (!ordersByShop.containsKey(shopId)) {
          ordersByShop[shopId] = [];
        }
        ordersByShop[shopId]!.add(item);
      }

      // Simulate sending orders
      await Future.delayed(Duration(seconds: 2));

      Navigator.pop(context); // Close loading dialog

      // Add to order history for activity page
      await _addToOrderHistory();

      // Clear cart
      await CartService.clearCart();

      // Show success dialog
      _showOrderSuccessDialog(ordersByShop.keys.length);

      // Refresh cart
      await _loadCartItems();
    } catch (e) {
      Navigator.pop(context);
      _showOrderFailureDialog();
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
                    'You are about to send order requests to ${_getUniqueShopCount()} restaurants.'),
                SizedBox(height: 8),
                Text('Total Amount: Rs. ${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Payment: $_paymentMethod'),
                Text(
                    '${_deliveryOption == 'Delivery' ? 'Delivery' : 'Pickup'}'),
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
    return _cartItems.map((item) => item['shopId']).toSet().length;
  }

  void _showOrderSuccessDialog(int shopCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text('Order Requests Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅ Sent to $shopCount restaurants'),
            SizedBox(height: 8),
            Text(
                'You will receive notifications when restaurants respond to your order requests.'),
            SizedBox(height: 8),
            Text('Check the Activity tab for order updates.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Great!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOrderFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red, size: 48),
        title: Text('Order Failed'),
        content: Text('Failed to send order requests. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToOrderHistory() async {
    final newOrder = {
      'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
      'shopNames': _cartItems.map((item) => item['shopName']).toSet().toList(),
      'items': _cartItems.map((item) => item['foodName']).toList(),
      'totalAmount': _calculateTotalAmount(),
      'status': 'Pending',
      'orderDate': DateTime.now().toIso8601String(),
      'deliveryOption': _deliveryOption,
      'paymentMethod': _paymentMethod,
      'specialInstructions': _specialInstructions,
      'scheduledTime': _scheduledTime?.toIso8601String(),
      'itemCount': _totalCartItems,
    };

    await CartService.addOrderToHistory(newOrder);
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

  // ✅ Cart content with full functionality
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

              SizedBox(height: 16),

              // Delivery options
              _buildDeliveryOptions(),

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

        // Send order button
        _buildSendOrderButton(),
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

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
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
                child: item['foodImage'] != null && item['foodImage'].isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item['foodImage'],
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
                    Text(item['foodName'],
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                        '${item['variation'] ?? 'Traditional'} • ${item['shopName']}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('Rs. ${item['price'].toStringAsFixed(2)} each',
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
                      child: Text('${item['quantity']}',
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
              Text('Rs. ${item['totalPrice'].toStringAsFixed(2)}',
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

  Widget _buildDeliveryOptions() {
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
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Enter your delivery address...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.location_on),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _deliveryAddress = value),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildSendOrderButton() {
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
              onPressed: _sendOrderRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Text('Send Order Requests',
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
}
