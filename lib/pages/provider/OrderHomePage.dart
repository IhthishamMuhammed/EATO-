// File: lib/pages/provider/OrderHomePage.dart
// Fixed version using notification methods with customer contact display

import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderCard.dart';
import 'package:eato/widgets/OrderProgressIndicator.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/EatoComponents.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class OrderHomePage extends StatefulWidget {
  final CustomUser currentUser;

  const OrderHomePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _OrderHomePageState createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  String _searchQuery = '';

  // Real-time update management
  Timer? _refreshTimer;
  bool _isInitialized = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 3, vsync: this);

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });

    // Initialize real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRealTimeUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    _stopRealTimeUpdates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume updates when app comes to foreground
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _refreshOrders();
    }
  }

  // Real-time updates initialization
  Future<void> _initializeRealTimeUpdates() async {
    if (_isInitialized) return;

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Ensure store data is available
      if (storeProvider.userStore == null) {
        await storeProvider.fetchUserStore(widget.currentUser);
      }

      if (storeProvider.userStore != null) {
        final storeId = storeProvider.userStore!.id;

        // Stop any existing listeners
        _stopRealTimeUpdates();

        // Start real-time listeners
        orderProvider.listenToStoreOrders(storeId);

        // Setup periodic refresh for reliability
        _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
          if (mounted) _refreshOrders();
        });

        _isInitialized = true;
      }
    } catch (e) {
      _showErrorSnackBar('Failed to initialize: $e');
    }
  }

  void _stopRealTimeUpdates() {
    _refreshTimer?.cancel();

    // Only stop listeners if context is still valid
    try {
      if (mounted) {
        Provider.of<OrderProvider>(context, listen: false).stopListening();
      }
    } catch (e) {
      // Context might be disposed, ignore
    }
  }

  Future<void> _refreshOrders() async {
    if (!mounted) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (storeProvider.userStore != null) {
      // Refresh listeners to ensure latest data
      orderProvider.listenToStoreOrders(storeProvider.userStore!.id);
    }
  }

  // ✅ FIXED: Order status update with notifications
  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // ✅ USE THE NOTIFICATION METHOD INSTEAD
      await orderProvider.updateOrderStatusWithNotifications(
        orderId: orderId,
        newStatus: newStatus,
        estimatedTime: _getEstimatedTime(newStatus),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  // ✅ NEW: Helper method to get estimated time based on status
  String? _getEstimatedTime(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return '20-30 mins';
      case OrderStatus.ready:
        return '5 mins';
      case OrderStatus.onTheWay:
        return '15-25 mins';
      default:
        return null;
    }
  }

  void _viewOrderDetails(CustomerOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(
          order: order,
          currentUser: widget.currentUser,
          onStatusUpdate: _updateOrderStatus,
        ),
      ),
    );
  }

  List<CustomerOrder> _filterOrders(List<CustomerOrder> orders) {
    if (_searchQuery.isEmpty) return orders;

    return orders.where((order) {
      return order.customerName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.items.any((item) =>
              item.foodName.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, StoreProvider>(
      builder: (context, orderProvider, storeProvider, _) {
        if (storeProvider.userStore == null) {
          return _buildNoStoreView();
        }

        return Scaffold(
          appBar: _buildAppBar(),
          body: orderProvider.isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: EatoTheme.primaryColor))
              : _buildOrdersContent(orderProvider),
        );
      },
    );
  }

  Widget _buildNoStoreView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No Store Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Please set up your store first',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _showSearchBar
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: EatoTheme.inputDecoration(
                hintText: 'Search orders...',
                prefixIcon:
                    Icon(Icons.search, color: EatoTheme.textSecondaryColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = false;
                      _searchController.clear();
                    });
                  },
                ),
              ),
              style: EatoTheme.bodyMedium,
            )
          : Text(
              'Orders',
              style: TextStyle(
                color: EatoTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: _showSearchBar ? false : true,
      leadingWidth: _showSearchBar ? 0 : null,
      leading: _showSearchBar
          ? null
          : (Navigator.canPop(context)
              ? IconButton(
                  icon:
                      Icon(Icons.arrow_back, color: EatoTheme.textPrimaryColor),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      actions: [
        if (!_showSearchBar)
          IconButton(
            icon: Icon(Icons.search, color: EatoTheme.textPrimaryColor),
            onPressed: () => setState(() => _showSearchBar = true),
          ),
        if (!_showSearchBar)
          IconButton(
            icon: Icon(Icons.refresh, color: EatoTheme.textPrimaryColor),
            onPressed: _refreshOrders,
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: EatoTheme.primaryColor,
        labelColor: EatoTheme.primaryColor,
        unselectedLabelColor: EatoTheme.textSecondaryColor,
        tabs: [
          Tab(text: 'PENDING'),
          Tab(text: 'ACTIVE'),
          Tab(text: 'COMPLETED'),
        ],
      ),
    );
  }

  Widget _buildOrdersContent(OrderProvider orderProvider) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Pending Orders Tab
        RefreshIndicator(
          onRefresh: _refreshOrders,
          color: EatoTheme.primaryColor,
          child: _buildOrdersList(
            _filterOrders(orderProvider.pendingOrders),
            'No pending orders',
            'Accepted requests will appear here as pending orders',
          ),
        ),

        // Active Orders Tab
        RefreshIndicator(
          onRefresh: _refreshOrders,
          color: EatoTheme.primaryColor,
          child: _buildOrdersList(
            _filterOrders(orderProvider.activeOrders),
            'No active orders',
            'Orders being prepared or delivered will appear here',
          ),
        ),

        // Completed Orders Tab
        RefreshIndicator(
          onRefresh: _refreshOrders,
          color: EatoTheme.primaryColor,
          child: _buildOrdersList(
            _filterOrders(orderProvider.completedOrders),
            'No completed orders',
            'Delivered and cancelled orders will appear here',
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(
      List<CustomerOrder> orders, String emptyTitle, String emptySubtitle) {
    if (orders.isEmpty) {
      return _buildEmptyOrdersView(emptyTitle, emptySubtitle);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onTap: () => _viewOrderDetails(order),
          showProgress: true,
          isProviderView:
              true, // ✅ Enable provider view to show customer contact
          actionButtons: _buildOrderActionButtons(order),
        );
      },
    );
  }

  Widget? _buildOrderActionButtons(CustomerOrder order) {
    if (_isOrderCompleted(order.status)) return null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatusButton(order),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _viewOrderDetails(order),
              child: Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EatoTheme.primaryColor,
                side: BorderSide(color: EatoTheme.primaryColor),
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusButton(CustomerOrder order) {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    OrderStatus nextStatus;

    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        buttonText = 'Start Preparing';
        buttonIcon = Icons.restaurant;
        buttonColor = EatoTheme.primaryColor;
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        buttonText = 'Mark Ready';
        buttonIcon = Icons.check_circle_outline;
        buttonColor = EatoTheme.infoColor;
        nextStatus = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        // For pickup orders, skip "On the Way" and go directly to "Delivered"
        if (order.deliveryOption == 'Pickup') {
          buttonText = 'Mark Picked Up';
          buttonIcon = Icons.check;
          buttonColor = EatoTheme.successColor;
          nextStatus = OrderStatus.delivered;
        } else {
          // For delivery orders, go to "On the Way"
          buttonText = 'Out for Delivery';
          buttonIcon = Icons.directions_bike;
          buttonColor = Colors.indigo;
          nextStatus = OrderStatus.onTheWay;
        }
        break;
      case OrderStatus.onTheWay:
        buttonText = 'Mark Delivered';
        buttonIcon = Icons.check;
        buttonColor = EatoTheme.successColor;
        nextStatus = OrderStatus.delivered;
        break;
      default:
        return SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: _isUpdatingStatus
          ? null
          : () => _updateOrderStatus(order.id, nextStatus),
      icon: _isUpdatingStatus
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(buttonIcon, size: 16),
      label: Text(_isUpdatingStatus ? 'Updating...' : buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersView(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EatoTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: EatoTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isOrderCompleted(OrderStatus status) {
    return status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.rejected;
  }
}

// ✅ FIXED: Order Details Page for Orders with customer contact
class OrderDetailsPage extends StatefulWidget {
  final CustomerOrder order;
  final CustomUser currentUser;
  final Function(String orderId, OrderStatus newStatus)? onStatusUpdate;

  const OrderDetailsPage({
    Key? key,
    required this.order,
    required this.currentUser,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        // Get real-time order updates
        final currentOrder = orderProvider.providerOrders
                .where((o) => o.id == widget.order.id)
                .isNotEmpty
            ? orderProvider.providerOrders
                .firstWhere((o) => o.id == widget.order.id)
            : widget.order;

        return Scaffold(
          appBar: EatoTheme.appBar(
            context: context,
            title: 'Order #${currentOrder.id.substring(0, 8)}',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                            Text('Order Status', style: EatoTheme.labelLarge),
                            OrderStatusWidget(status: currentOrder.status),
                          ],
                        ),
                        SizedBox(height: 20),
                        OrderProgressIndicator(
                            currentStatus: currentOrder.status),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Order details using reusable card with provider view
                OrderCard(
                  order: currentOrder,
                  isProviderView:
                      true, // ✅ Enable provider view for customer contact
                  actionButtons: _buildStatusActions(currentOrder),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildStatusActions(CustomerOrder order) {
    if (_isOrderCompleted(order.status)) return null;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update Order Status', style: EatoTheme.headingSmall),
          SizedBox(height: 16),

          // Status action buttons based on current status
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed)
            _buildStatusButton(
              title: 'Start Preparing',
              icon: Icons.restaurant,
              color: EatoTheme.primaryColor,
              onTap: () => _updateStatus(OrderStatus.preparing),
            ),

          if (order.status == OrderStatus.preparing)
            _buildStatusButton(
              title: 'Mark as Ready',
              icon: Icons.check_circle_outline,
              color: EatoTheme.infoColor,
              onTap: () => _updateStatus(OrderStatus.ready),
            ),

          if (order.status == OrderStatus.ready &&
              order.deliveryOption == 'Delivery')
            _buildStatusButton(
              title: 'Out for Delivery',
              icon: Icons.directions_bike,
              color: Colors.indigo,
              onTap: () => _updateStatus(OrderStatus.onTheWay),
            ),

          if (order.status == OrderStatus.ready ||
              order.status == OrderStatus.onTheWay)
            _buildStatusButton(
              title: order.deliveryOption == 'Pickup'
                  ? 'Mark as Picked Up'
                  : 'Mark as Delivered',
              icon: Icons.check,
              color: EatoTheme.successColor,
              onTap: () => _updateStatus(OrderStatus.delivered),
            ),

          // Cancel button for non-completed orders
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            Column(
              children: [
                SizedBox(height: 12),
                _buildStatusButton(
                  title: 'Cancel Order',
                  icon: Icons.cancel_outlined,
                  color: EatoTheme.errorColor,
                  onTap: () => _showCancelConfirmation(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _isUpdatingStatus ? null : onTap,
        icon: _isUpdatingStatus
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(_isUpdatingStatus ? 'Updating...' : title,
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Update status method using notification method
  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
      // ✅ USE NOTIFICATION METHOD DIRECTLY
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatusWithNotifications(
        orderId: widget.order.id,
        newStatus: newStatus,
        estimatedTime: _getEstimatedTime(newStatus),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (newStatus == OrderStatus.delivered ||
            newStatus == OrderStatus.cancelled) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  // ✅ NEW: Helper method to get estimated time
  String? _getEstimatedTime(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return '20-30 mins';
      case OrderStatus.ready:
        return '5 mins';
      case OrderStatus.onTheWay:
        return '15-25 mins';
      default:
        return null;
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order?'),
        content: Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, Keep Order'),
            style: EatoTheme.textButtonStyle,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(OrderStatus.cancelled);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  bool _isOrderCompleted(OrderStatus status) {
    return status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.rejected;
  }
}
