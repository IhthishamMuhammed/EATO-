// File: lib/pages/customer/ActivityPage.dart (Updated with backend integration)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/widgets/OrderProgressIndicator.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  final bool showBottomNav;

  const ActivityPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize order provider and start listening to customer orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderProvider();
    });
  }

  void _initializeOrderProvider() async {
    if (_isInitialized) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      // Start listening to customer orders for real-time updates
      orderProvider.listenToCustomerOrders(userProvider.currentUser!.id);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Stop listening when leaving the page
    Provider.of<OrderProvider>(context, listen: false).stopListening();
    super.dispose();
  }

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

  Future<void> _refreshOrders() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      // Re-initialize listener
      orderProvider.listenToCustomerOrders(userProvider.currentUser!.id);
    }
  }

  void _viewOrderDetails(CustomerOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOrderDetailsPage(order: order),
      ),
    );
  }

  void _trackOrder(CustomerOrder order) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildOrderTrackingModal(order),
    );
  }

  Widget _buildOrderTrackingModal(CustomerOrder order) {
    return Container(
      padding: EdgeInsets.all(20),
      height: 400,
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Tracking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Order info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EatoTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'From ${order.storeName}',
                        style: TextStyle(
                          color: EatoTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                OrderStatusWidget(
                  status: order.status,
                  showAnimation: _isActiveStatus(order.status),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Progress indicator
          Expanded(
            child: OrderProgressIndicator(
              currentStatus: order.status,
              isVertical: true,
            ),
          ),

          SizedBox(height: 20),

          // Estimated time
          if (_isActiveStatus(order.status)) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Text(
                    _getEstimatedTime(order.status),
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Contact store button
          if (_isActiveStatus(order.status))
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement contact store functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Contact store feature coming soon!')),
                  );
                },
                icon: Icon(Icons.phone),
                label: Text('Contact Store'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EatoTheme.primaryColor,
                  side: BorderSide(color: EatoTheme.primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isActiveStatus(OrderStatus status) {
    return status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready ||
        status == OrderStatus.onTheWay;
  }

  String _getEstimatedTime(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Preparing your order • 15-20 min';
      case OrderStatus.preparing:
        return 'Almost ready • 10-15 min';
      case OrderStatus.ready:
        return 'Ready for pickup/delivery';
      case OrderStatus.onTheWay:
        return 'On the way • 5-10 min';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, UserProvider>(
      builder: (context, orderProvider, userProvider, _) {
        if (userProvider.currentUser == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Activity'),
              backgroundColor: Colors.white,
              elevation: 1,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('Please login to view your orders',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        // Separate current orders from history
        final allOrders = orderProvider.customerOrders;
        final currentOrders = allOrders.where((order) {
          return order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed ||
              order.status == OrderStatus.preparing ||
              order.status == OrderStatus.ready ||
              order.status == OrderStatus.onTheWay;
        }).toList();

        final orderHistory = allOrders.where((order) {
          return order.status == OrderStatus.delivered ||
              order.status == OrderStatus.cancelled ||
              order.status == OrderStatus.rejected;
        }).toList();

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
                if (currentOrders.isNotEmpty) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentOrders.length} active',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.purple),
                onPressed: _refreshOrders,
              ),
            ],
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
                      if (currentOrders.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${currentOrders.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                child: orderProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.purple))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCurrentOrdersTab(currentOrders),
                          _buildOrderHistoryTab(orderHistory),
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
      },
    );
  }

  Widget _buildCurrentOrdersTab(List<CustomerOrder> currentOrders) {
    if (currentOrders.isEmpty) {
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
      onRefresh: _refreshOrders,
      color: Colors.purple,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: currentOrders.length,
        itemBuilder: (context, index) {
          return _buildCurrentOrderCard(currentOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderHistoryTab(List<CustomerOrder> orderHistory) {
    if (orderHistory.isEmpty) {
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
      onRefresh: _refreshOrders,
      color: Colors.purple,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: orderHistory.length,
        itemBuilder: (context, index) {
          return _buildOrderHistoryCard(orderHistory[index]);
        },
      ),
    );
  }

  Widget _buildCurrentOrderCard(CustomerOrder order) {
    final timeAgo = _getTimeAgo(order.orderTime);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _getStatusColor(order.status).withOpacity(0.3)),
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
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'From ${order.storeName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: EatoTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                OrderStatusWidget(
                  status: order.status,
                  showAnimation: _isActiveStatus(order.status),
                ),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items summary
                Text(
                  'Items: ${order.items.map((item) => '${item.foodName} x${item.quantity}').join(', ')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 12),

                // Order info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${order.items.length} items • $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_isActiveStatus(order.status))
                          ElevatedButton(
                            onPressed: () => _trackOrder(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Track Order',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _viewOrderDetails(order),
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),

                // Progress indicator for active orders
                if (_isActiveStatus(order.status)) ...[
                  SizedBox(height: 16),
                  OrderProgressIndicator(currentStatus: order.status),
                ],

                // Delivery info
                if (order.deliveryOption == 'Delivery') ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Delivery to: ${order.deliveryAddress}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryCard(CustomerOrder order) {
    final formattedDate = DateFormat('MMM d, yyyy').format(order.orderTime);

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
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
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
              'From: ${order.storeName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '${order.items.length} items • Rs. ${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrderStatusWidget(status: order.status),
                if (order.status == OrderStatus.delivered)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reorder functionality coming soon!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return EatoTheme.infoColor;
      case OrderStatus.onTheWay:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Colors.red;
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
}

// ===================================
// CUSTOMER ORDER DETAILS PAGE
// ===================================

class CustomerOrderDetailsPage extends StatelessWidget {
  final CustomerOrder order;

  const CustomerOrderDetailsPage({Key? key, required this.order})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Status',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        OrderStatusWidget(status: order.status),
                      ],
                    ),
                    SizedBox(height: 20),
                    OrderProgressIndicator(currentStatus: order.status),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Store info
            Text(
              'Restaurant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: EatoTheme.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.restaurant, color: EatoTheme.primaryColor),
                ),
                title: Text(order.storeName),
                subtitle: Text(
                    'Order placed on ${DateFormat('MMM d, yyyy • h:mm a').format(order.orderTime)}'),
              ),
            ),

            SizedBox(height: 24),

            // Order items
            Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: order.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: item.foodImage.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.foodImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.fastfood,
                                              color: Colors.grey[400]);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.fastfood,
                                      color: Colors.grey[400]),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.foodName,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (item.variation != null)
                                    Text(
                                      item.variation!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('x${item.quantity}'),
                                Text(
                                  'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (index < order.items.length - 1) ...[
                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: 12),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Delivery info
            Text(
              'Delivery Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Method', order.deliveryOption),
                    if (order.deliveryOption == 'Delivery')
                      _buildInfoRow('Address', order.deliveryAddress),
                    _buildInfoRow('Payment', order.paymentMethod),
                    if (order.specialInstructions != null &&
                        order.specialInstructions!.isNotEmpty)
                      _buildInfoRow('Instructions', order.specialInstructions!),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Order summary
            Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', order.subtotal),
                    if (order.deliveryFee > 0)
                      _buildSummaryRow('Delivery Fee', order.deliveryFee),
                    _buildSummaryRow('Service Fee', order.serviceFee),
                    Divider(),
                    _buildSummaryRow('Total', order.totalAmount, isTotal: true),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Action button
            if (order.status == OrderStatus.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement cancel order functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Cancel order functionality coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel Order'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? EatoTheme.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
