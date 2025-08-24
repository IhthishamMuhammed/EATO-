import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/widgets/CustomerOrderCard.dart'; // Import the new card
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
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
      itemBuilder: (context, index) => CustomerOrderCard(
        order: orders[index],
        canCancel: _canCancelOrder(orders[index]),
        onViewDetails: () => _showOrderDetailsDialog(orders[index]),
        onCancel: () => _showCancelOrderDialog(orders[index]),
      ),
    );
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

  // Customer can only cancel BEFORE provider confirms (only pending orders)
  bool _canCancelOrder(CustomerOrder order) {
    return order.status == OrderStatus.pending; // Only pending, NOT confirmed
  }

  Future<void> _showCancelOrderDialog(CustomerOrder order) async {
    // Show different messages based on order status
    String dialogContent;
    bool canCancel = _canCancelOrder(order);

    if (canCancel) {
      dialogContent =
          'Are you sure you want to cancel this order? This action cannot be undone.';
    } else {
      // Inform customer why they can't cancel
      switch (order.status) {
        case OrderStatus.confirmed:
          dialogContent =
              'This order has already been confirmed by the restaurant and cannot be cancelled. Please contact the restaurant directly if needed.';
          break;
        case OrderStatus.preparing:
          dialogContent =
              'This order is already being prepared and cannot be cancelled. Please contact the restaurant directly if needed.';
          break;
        case OrderStatus.ready:
          dialogContent =
              'This order is ready for pickup/delivery and cannot be cancelled.';
          break;
        case OrderStatus.onTheWay:
          dialogContent = 'This order is on the way and cannot be cancelled.';
          break;
        default:
          dialogContent = 'This order cannot be cancelled at this stage.';
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(canCancel ? 'Cancel Order' : 'Cannot Cancel Order'),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(canCancel ? 'Keep Order' : 'OK'),
          ),
          if (canCancel)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  Text('Cancel Order', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );

    if (confirmed == true && canCancel) {
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
                            'Order #${_getDisplayOrderNumber(order)}',
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

  String _getDisplayOrderNumber(CustomerOrder order) {
    // If orderNumber exists and looks like a proper sequential number, use it
    if (order.orderNumber.isNotEmpty &&
        order.orderNumber.contains('-') &&
        order.orderNumber.length >= 11) {
      // YYYYMMDD-XXX format
      return order.orderNumber;
    }

    // Otherwise, use a cleaner version of the document ID
    return order.id.substring(0, 8).toUpperCase();
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
                      overflow: TextOverflow.ellipsis,
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
