// File: lib/pages/customer/activity_page.dart (Enhanced with store contact visibility)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/widgets/OrderProgressIndicator.dart';
import 'package:eato/EatoComponents.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  final bool showBottomNav;

  const ActivityPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeOrders();
  }

  Future<void> _initializeOrders() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (userProvider.currentUser != null) {
        // Start listening to customer orders
        orderProvider.listenToCustomerOrders(userProvider.currentUser!.id);
        _isInitialized = true;
      } else {
        throw Exception('User not logged in');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      appBar: EatoComponents.appBar(
        context: context,
        title: 'Order Activity',
        titleIcon: Icons.history,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All Orders'),
          ],
          labelColor: EatoTheme.primaryColor,
          unselectedLabelColor: EatoTheme.textSecondaryColor,
          indicatorColor: EatoTheme.primaryColor,
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 3,
              onTap: (index) {
                if (index != 3) {
                  Navigator.pushReplacementNamed(
                      context, _getRouteForIndex(index));
                }
              },
            )
          : null,
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
            'Loading your orders...',
            style: TextStyle(color: EatoTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          SizedBox(height: 16),
          Text(
            'Failed to load orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(color: EatoTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          EatoComponents.primaryButton(
            text: 'Retry',
            onPressed: () {
              setState(() {
                _isInitialized = false;
              });
              _initializeOrders();
            },
            width: 120,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final allOrders = orderProvider.customerOrders;

        if (allOrders.isEmpty) {
          return EatoComponents.emptyState(
            message:
                'No orders found\nStart ordering to see your order history!',
            icon: Icons.receipt_long,
            actionText: 'Browse Restaurants',
            onActionPressed: () => Navigator.pushNamed(context, '/home'),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersList(_getActiveOrders(allOrders)),
            _buildOrdersList(_getCompletedOrders(allOrders)),
            _buildOrdersList(allOrders),
          ],
        );
      },
    );
  }

  Widget _buildOrdersList(List<CustomerOrder> orders) {
    if (orders.isEmpty) {
      return EatoComponents.emptyState(
        message: 'No orders in this category',
        icon: Icons.inbox,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
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
          // Order Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant, color: EatoTheme.primaryColor),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: EatoTheme.textPrimaryColor,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // ✅ FIXED: Prevent overflow
                      ),
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: TextStyle(
                          color: EatoTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OrderStatusWidget(
                      status: order.status,
                      showAnimation: _isActiveStatus(order.status),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: EatoTheme.primaryColor,
                        fontSize:
                            14, // ✅ FIXED: Slightly smaller to prevent overflow
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order Items Summary
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                // ✅ FIXED: Better item list with overflow handling
                ...order.items.take(2).map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x ',
                            style: TextStyle(
                              fontSize: 12,
                              color: EatoTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.foodName,
                              style: TextStyle(
                                fontSize: 12,
                                color: EatoTheme.textSecondaryColor,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // ✅ FIXED: Prevent overflow
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 2)
                  Text(
                    '+${order.items.length - 2} more items',
                    style: TextStyle(
                      fontSize: 12,
                      color: EatoTheme.primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Store Contact Information
          _buildStoreContactSection(order),

          // Order Actions - ✅ FIXED: Better spacing and layout
          _buildOrderActions(order),
        ],
      ),
    );
  }

  Widget _buildStoreContactSection(CustomerOrder order) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  'Loading restaurant contact...',
                  style: TextStyle(
                      fontSize: 12, color: EatoTheme.textSecondaryColor),
                ),
              ],
            ),
          );
        }

        final storeData = snapshot.data!.data() as Map<String, dynamic>?;
        final contact = storeData?['contact']?.toString() ?? '';

        if (contact.isEmpty) {
          return SizedBox(); // Don't show anything if no contact
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            // ✅ FIXED: Use EatoTheme purple instead of blue
            color: EatoTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EatoTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.phone, color: EatoTheme.primaryColor, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Contact',
                      style: TextStyle(
                        fontSize: 12,
                        color: EatoTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // ✅ FIXED: Better text wrapping and overflow handling
                    Text(
                      contact,
                      style: TextStyle(
                        fontSize: 14,
                        color: EatoTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // ✅ FIXED: More compact call button
              SizedBox(
                width: 60,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _callStore(contact, order.storeName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EatoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(60, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call, size: 14),
                      SizedBox(width: 2),
                      Text('Call', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderActions(CustomerOrder order) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EatoTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // ✅ FIXED: Date/time in separate row to prevent overflow
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: EatoTheme.textSecondaryColor),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: EatoTheme.textSecondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Prevent overflow
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // ✅ FIXED: Action buttons in separate row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_canCancelOrder(order)) ...[
                TextButton(
                  onPressed: () => _showCancelOrderDialog(order),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(60, 32),
                  ),
                ),
                SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: () => _showOrderDetailsDialog(order),
                child: Text(
                  'View Details',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EatoTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(80, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
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
        _showSnackBar('Phone number copied: $phoneNumber', Colors.blue);
      }
    } catch (e) {
      print('Error launching phone call: $e');
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      _showSnackBar('Phone number copied: $phoneNumber', Colors.blue);
    }
  }

  // ===================================
  // ORDER MANAGEMENT
  // ===================================

  List<CustomerOrder> _getActiveOrders(List<CustomerOrder> orders) {
    return orders
        .where((order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.onTheWay)
        .toList();
  }

  List<CustomerOrder> _getCompletedOrders(List<CustomerOrder> orders) {
    return orders
        .where((order) =>
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.rejected)
        .toList();
  }

  bool _isActiveStatus(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready ||
        status == OrderStatus.onTheWay;
  }

  bool _canCancelOrder(CustomerOrder order) {
    return order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed;
  }

  Future<void> _showCancelOrderDialog(CustomerOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order'),
        content: Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.cancelOrder(order.id, 'Cancelled by customer');
        _showSnackBar('Order cancelled successfully', Colors.orange);
      } catch (e) {
        _showSnackBar('Failed to cancel order', Colors.red);
      }
    }
  }

  void _showOrderDetailsDialog(CustomerOrder order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EatoTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Order #${order.id.substring(0, 8)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: EatoTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            OrderStatusWidget(
                              status: order.status,
                              showAnimation: _isActiveStatus(order.status),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Restaurant Info with Contact
                      _buildDetailSection(
                        title: 'Restaurant Information',
                        child: _buildRestaurantInfoWithContact(order),
                      ),

                      SizedBox(height: 16),

                      // Order Items
                      _buildDetailSection(
                        title: 'Order Items',
                        child: Column(
                          children: order.items
                              .map((item) => Container(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: EatoTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.foodName,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              if (item.variation != null)
                                                Text(
                                                  item.variation!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: EatoTheme
                                                        .textSecondaryColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}x',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: EatoTheme.textSecondaryColor,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: EatoTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Order Summary
                      _buildDetailSection(
                        title: 'Order Summary',
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', order.subtotal),
                            if (order.deliveryFee > 0)
                              _buildSummaryRow(
                                  'Delivery Fee', order.deliveryFee),
                            _buildSummaryRow('Service Fee', order.serviceFee),
                            Divider(),
                            _buildSummaryRow('Total Amount', order.totalAmount,
                                isTotal: true),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Delivery Information
                      if (order.deliveryOption == 'Delivery')
                        _buildDetailSection(
                          title: 'Delivery Information',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: EatoTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order.displayAddress,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.payment,
                                      size: 16, color: EatoTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Text(
                                    order.paymentMethod,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Special Instructions
                      if (order.specialInstructions != null &&
                          order.specialInstructions!.isNotEmpty)
                        _buildDetailSection(
                          title: 'Special Instructions',
                          child: Text(
                            order.specialInstructions!,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ),

                      SizedBox(height: 16),

                      // Order Timeline
                      _buildDetailSection(
                        title: 'Order Timeline',
                        child: Column(
                          children: [
                            _buildTimelineItem(
                              'Order Placed',
                              order.orderTime,
                              true,
                            ),
                            if (order.confirmedTime != null)
                              _buildTimelineItem(
                                'Order Confirmed',
                                order.confirmedTime!,
                                true,
                              ),
                            if (order.readyTime != null)
                              _buildTimelineItem(
                                'Order Ready',
                                order.readyTime!,
                                true,
                              ),
                            if (order.deliveredTime != null)
                              _buildTimelineItem(
                                order.status == OrderStatus.delivered
                                    ? 'Order Delivered'
                                    : 'Order Completed',
                                order.deliveredTime!,
                                true,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoWithContact(CustomerOrder order) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .get(),
      builder: (context, snapshot) {
        final contact = snapshot.hasData
            ? (snapshot.data!.data() as Map<String, dynamic>?)
                ?.let((data) => data['contact']?.toString())
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, size: 16, color: EatoTheme.primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.storeName,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (contact != null && contact.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: EatoTheme.primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contact,
                      style: TextStyle(fontSize: 14),
                      overflow:
                          TextOverflow.ellipsis, // ✅ FIXED: Prevent overflow
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _callStore(contact, order.storeName),
                      icon: Icon(Icons.call, size: 14),
                      label: Text('Call', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EatoTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(70, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: EatoTheme.primaryColor),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading contact...',
                    style: TextStyle(
                        fontSize: 12, color: EatoTheme.textSecondaryColor),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetailSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: EatoTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EatoTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ],
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
              color: isTotal
                  ? EatoTheme.textPrimaryColor
                  : EatoTheme.textSecondaryColor,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color:
                  isTotal ? EatoTheme.primaryColor : EatoTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime time, bool isCompleted) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : EatoTheme.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? Colors.green.shade700
                        : EatoTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(time),
                  style: TextStyle(
                    fontSize: 12,
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================
  // HELPER METHODS
  // ===================================

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/subscribed';
      case 2:
        return '/orders';
      case 4:
        return '/account';
      default:
        return '/home';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Extension to add null-aware let function
extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) operation) {
    final value = this;
    return value != null ? operation(value) : null;
  }
}
