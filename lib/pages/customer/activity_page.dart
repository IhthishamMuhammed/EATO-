import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// ✅ Cart Service for order history
class CartService {
  static const String _orderHistoryKey = 'order_history';

  // Get order history
  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_orderHistoryKey) ?? [];

    return history
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }

  // Add order to history
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
}

class ActivityPage extends StatefulWidget {
  final bool showBottomNav;

  const ActivityPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orderHistory = [];
  List<Map<String, dynamic>> _currentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrderData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allOrders = await CartService.getOrderHistory();

      // Separate current orders from history
      final now = DateTime.now();
      _currentOrders = allOrders.where((order) {
        final orderDate = DateTime.parse(order['orderDate']);
        final daysDiff = now.difference(orderDate).inDays;
        final status = order['status'] as String;

        // Current orders are recent orders that are still active
        return daysDiff <= 7 &&
            (status == 'Pending' ||
                status == 'Confirmed' ||
                status == 'Preparing' ||
                status == 'Out for Delivery');
      }).toList();

      _orderHistory = allOrders;

      // Generate some sample activity if no real orders exist
      if (_orderHistory.isEmpty) {
        await _generateSampleOrders();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading order data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate sample orders for demo purposes
  Future<void> _generateSampleOrders() async {
    final sampleOrders = [
      {
        'orderId': 'ORD001',
        'shopNames': ['Spice Garden', 'Rice Bowl'],
        'items': ['Chicken Curry', 'Rice and Curry', 'Kottu Roti'],
        'totalAmount': 1250.0,
        'status': 'Delivered',
        'orderDate':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'deliveryOption': 'Delivery',
        'paymentMethod': 'Cash on Delivery',
        'itemCount': 3,
      },
      {
        'orderId': 'ORD002',
        'shopNames': ['Local Eats'],
        'items': ['String Hoppers', 'Sambol'],
        'totalAmount': 450.0,
        'status': 'Preparing',
        'orderDate':
            DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'deliveryOption': 'Pickup',
        'paymentMethod': 'Card Payment',
        'itemCount': 2,
      },
      {
        'orderId': 'ORD003',
        'shopNames': ['Quick Bites'],
        'items': ['Fish Bun', 'Tea'],
        'totalAmount': 120.0,
        'status': 'Delivered',
        'orderDate':
            DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        'deliveryOption': 'Pickup',
        'paymentMethod': 'Mobile Wallet',
        'itemCount': 2,
      },
    ];

    for (var order in sampleOrders) {
      await CartService.addOrderToHistory(order);
    }

    // Reload data
    final allOrders = await CartService.getOrderHistory();
    final now = DateTime.now();

    _currentOrders = allOrders.where((order) {
      final orderDate = DateTime.parse(order['orderDate']);
      final daysDiff = now.difference(orderDate).inDays;
      final status = order['status'] as String;

      return daysDiff <= 7 &&
          (status == 'Pending' ||
              status == 'Confirmed' ||
              status == 'Preparing' ||
              status == 'Out for Delivery');
    }).toList();

    _orderHistory = allOrders;
  }

  // ✅ Handle bottom nav taps
  void _onBottomNavTap(int index) {
    if (index == 3) {
      // Activity tab - stay here
      return;
    } else {
      // Other tabs - navigate
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/subscribed');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/orders');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/account');
          break;
      }
    }
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
            Icon(Icons.timeline, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text('Activity',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.purple,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions, size: 16),
                  SizedBox(width: 4),
                  Text('Current'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 16),
                  SizedBox(width: 4),
                  Text('History'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.purple))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCurrentOrdersTab(),
                      _buildOrderHistoryTab(),
                    ],
                  ),
          ),
          if (widget.showBottomNav)
            BottomNavBar(
              currentIndex: 3, // Activity tab
              onTap: _onBottomNavTap,
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentOrdersTab() {
    if (_currentOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey.shade400),
            SizedBox(height: 20),
            Text('No Current Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your active orders will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              icon: Icon(Icons.restaurant_menu, color: Colors.white),
              label: Text('Order Now', style: TextStyle(color: Colors.white)),
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

    return RefreshIndicator(
      onRefresh: _loadOrderData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _currentOrders.length,
        itemBuilder: (context, index) {
          return _buildCurrentOrderCard(_currentOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderHistoryTab() {
    if (_orderHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 20),
            Text('No Order History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your past orders will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _orderHistory.length,
        itemBuilder: (context, index) {
          return _buildOrderHistoryCard(_orderHistory[index]);
        },
      ),
    );
  }

  Widget _buildCurrentOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final orderDate = DateTime.parse(order['orderDate']);
    final timeAgo = _getTimeAgo(orderDate);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['orderId'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Shop names
          Text(
            'From: ${(order['shopNames'] as List).join(', ')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.purple,
            ),
          ),

          SizedBox(height: 8),

          // Items
          Text(
            'Items: ${(order['items'] as List).join(', ')}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 12),

          // Order details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs. ${order['totalAmount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${order['itemCount']} items • $timeAgo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (status == 'Preparing' || status == 'Confirmed')
                    ElevatedButton(
                      onPressed: () => _showOrderTracking(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Track Order',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showOrderDetails(order),
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),

          // Progress indicator for active orders
          if (status != 'Delivered' && status != 'Cancelled')
            Column(
              children: [
                SizedBox(height: 16),
                _buildOrderProgress(status),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final orderDate = DateTime.parse(order['orderDate']);
    final formattedDate =
        '${orderDate.day}/${orderDate.month}/${orderDate.year}';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['orderId'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'From: ${(order['shopNames'] as List).join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '${order['itemCount']} items • Rs. ${order['totalAmount'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                if (status == 'Delivered')
                  TextButton(
                    onPressed: () => _reorderItems(order),
                    child: Text(
                      'Reorder',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProgress(String status) {
    final steps = [
      'Pending',
      'Confirmed',
      'Preparing',
      'Out for Delivery',
      'Delivered'
    ];
    final currentIndex = steps.indexOf(status);

    return Column(
      children: [
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.purple : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.purple, width: 2)
                          : null,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isActive ? Colors.purple : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((step) {
            return Expanded(
              child: Text(
                step,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Preparing':
        return Colors.purple;
      case 'Out for Delivery':
        return Colors.indigo;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime orderDate) {
    final now = DateTime.now();
    final difference = now.difference(orderDate);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showOrderTracking(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order Tracking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildOrderProgress(order['status']),
            SizedBox(height: 20),
            Text(
              'Estimated delivery: 25-30 minutes',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Order ID: ${order['orderId']}'),
            SizedBox(height: 8),
            Text('Restaurants: ${(order['shopNames'] as List).join(', ')}'),
            SizedBox(height: 8),
            Text('Items: ${(order['items'] as List).join(', ')}'),
            SizedBox(height: 8),
            Text('Total: Rs. ${order['totalAmount'].toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text('Payment: ${order['paymentMethod']}'),
            SizedBox(height: 8),
            Text('Delivery: ${order['deliveryOption']}'),
            SizedBox(height: 8),
            Text('Status: ${order['status']}'),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reorderItems(order);
                    },
                    child: Text('Reorder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reorderItems(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reorder functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
