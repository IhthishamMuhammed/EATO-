// File: lib/pages/provider/OrderHomePage.dart
// Fixed version with responsive design to prevent overflow on different devices

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderCard.dart';
import 'package:eato/widgets/OrderProgressIndicator.dart';
import 'package:eato/pages/theme/eato_theme.dart';
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

  // Track updating status per order ID instead of globally
  final Set<String> _updatingOrderIds = {};

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

  // Order status update with notifications
  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    setState(() => _updatingOrderIds.add(orderId));

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

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
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
  }

  // Helper method to get estimated time based on status
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
      final query = _searchQuery.toLowerCase();

      // Search in customer name
      if (order.customerName.toLowerCase().contains(query)) return true;

      // Search in order ID
      if (order.id.toLowerCase().contains(query)) return true;

      // Search in food items
      if (order.items
          .any((item) => item.foodName.toLowerCase().contains(query)))
        return true;

      // Search in customer phone (if available)
      if (order.customerPhone.toLowerCase().contains(query)) return true;

      // Search in delivery address
      if (order.deliveryAddress.toLowerCase().contains(query)) return true;

      // Search in delivery option (delivery/pickup)
      if (order.deliveryOption.toLowerCase().contains(query)) return true;

      return false;
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
          appBar: _buildAppBar(orderProvider),
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
                style: EatoTheme.getResponsiveHeadingSmall(context)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: EatoTheme.getHorizontalPadding(context),
              ),
              child: Text(
                'Please set up your store first',
                style: EatoTheme.getResponsiveBodyMedium(context)
                    .copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(OrderProvider orderProvider) {
    return AppBar(
      title: _showSearchBar
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: EatoTheme.inputDecoration(
                // ✅ FIXED: Responsive search hint based on screen size
                hintText: EatoTheme.isSmallScreen(context)
                    ? 'Search orders...'
                    : 'Search orders, customers, items...',
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
                context: context,
              ),
              style: EatoTheme.getResponsiveBodyMedium(context),
            )
          : Text(
              'Orders',
              style: EatoTheme.getResponsiveHeadingSmall(context).copyWith(
                color: EatoTheme.textPrimaryColor,
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
        if (!_showSearchBar) ...[
          IconButton(
            icon: Icon(Icons.search, color: EatoTheme.textPrimaryColor),
            onPressed: () => setState(() => _showSearchBar = true),
          ),
          // Clear completed orders button - only show if on completed tab and has completed orders
          if (_tabController.index == 2 &&
              orderProvider.completedOrders.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: EatoTheme.textPrimaryColor),
              onPressed: () => _showClearCompletedDialog(),
            ),
        ],
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: EatoTheme.primaryColor,
        labelColor: EatoTheme.primaryColor,
        unselectedLabelColor: EatoTheme.textSecondaryColor,
        labelStyle: EatoTheme.getResponsiveBodyMedium(context).copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: EatoTheme.getResponsiveBodyMedium(context),
        tabs: [
          _buildTabWithCount('PENDING', orderProvider.pendingOrders.length),
          _buildTabWithCount('ACTIVE', orderProvider.activeOrders.length),
          _buildTabWithCount('COMPLETED', orderProvider.completedOrders.length),
        ],
      ),
    );
  }

  void _showClearCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Completed Orders?',
            style: EatoTheme.getResponsiveHeadingSmall(context)),
        content: Text(
          'This will remove all completed orders from your view. This action cannot be undone.',
          style: EatoTheme.getResponsiveBodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: EatoTheme.textButtonStyle,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCompletedOrders();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCompletedOrders() async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);

      if (storeProvider.userStore != null) {
        final completedOrders = orderProvider.completedOrders;

        // Delete completed orders from Firestore
        final batch = FirebaseFirestore.instance.batch();

        for (final order in completedOrders) {
          batch.delete(
              FirebaseFirestore.instance.collection('orders').doc(order.id));
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${completedOrders.length} completed orders cleared'),
              backgroundColor: EatoTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear orders: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ FIXED: Responsive tab with count that prevents overflow
  Widget _buildTabWithCount(String title, int count) {
    return Tab(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use abbreviated titles on very small screens
          final displayTitle = EatoTheme.isSmallScreen(context)
              ? _getAbbreviatedTitle(title)
              : title;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: EatoTheme.isSmallScreen(context) ? 4 : 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: EatoTheme.isSmallScreen(context) ? 4 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: EatoTheme.isSmallScreen(context) ? 10 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Helper to get abbreviated tab titles for small screens
  String _getAbbreviatedTitle(String title) {
    switch (title) {
      case 'PENDING':
        return 'PEND';
      case 'ACTIVE':
        return 'ACTV';
      case 'COMPLETED':
        return 'DONE';
      default:
        return title;
    }
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
      padding: EdgeInsets.symmetric(
        vertical: EatoTheme.getVerticalPadding(context),
        horizontal: EatoTheme.getHorizontalPadding(context),
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: EdgeInsets.only(bottom: EatoTheme.getCardSpacing(context)),
          child: OrderCard(
            order: order,
            onTap: () => _viewOrderDetails(order),
            showProgress: true,
            isProviderView:
                true, // Enable provider view to show customer contact
          ),
        );
      },
    );
  }

  // ✅ FIXED: Responsive action buttons that prevent overflow
  Widget? _buildOrderActionButtons(CustomerOrder order) {
    if (_isOrderCompleted(order.status)) return null;

    return Container(
      padding: EdgeInsets.all(EatoTheme.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Existing buttons
          Expanded(
            child: EatoTheme.buildResponsiveButtonRow(
              buttons: [
                _buildQuickStatusButton(order),
                OutlinedButton(
                  onPressed: () => _viewOrderDetails(order),
                  child: Text(
                    EatoTheme.isSmallScreen(context)
                        ? 'Details'
                        : 'View Details',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: EatoTheme.getResponsiveOutlinedButtonStyle(context),
                ),
              ],
            ),
          ),
          // Add compact action buttons here
          if (order.customerPhone.isNotEmpty) ...[
            SizedBox(width: 8),
            // Add your compact call button here
          ],
          if (order.deliveryOption == 'Delivery' &&
              order.deliveryAddress.isNotEmpty) ...[
            SizedBox(width: 6),
            // Add your compact directions button here
          ],
        ],
      ),
    );
  }

  // ✅ FIXED: Responsive status button with dynamic text
  Widget _buildQuickStatusButton(CustomerOrder order) {
    String buttonText;
    String shortButtonText; // For small screens
    IconData buttonIcon;
    Color buttonColor;
    OrderStatus nextStatus;

    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        buttonText = 'Start Preparing';
        shortButtonText = 'Start';
        buttonIcon = Icons.restaurant;
        buttonColor = EatoTheme.primaryColor;
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        buttonText = 'Mark Ready';
        shortButtonText = 'Ready';
        buttonIcon = Icons.check_circle_outline;
        buttonColor = EatoTheme.infoColor;
        nextStatus = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        if (order.deliveryOption == 'Pickup') {
          buttonText = 'Mark Picked Up';
          shortButtonText = 'Picked Up';
          buttonIcon = Icons.check;
          buttonColor = EatoTheme.successColor;
          nextStatus = OrderStatus.delivered;
        } else {
          buttonText = 'Out for Delivery';
          shortButtonText = 'Deliver';
          buttonIcon = Icons.directions_bike;
          buttonColor = Colors.indigo;
          nextStatus = OrderStatus.onTheWay;
        }
        break;
      case OrderStatus.onTheWay:
        buttonText = 'Mark Delivered';
        shortButtonText = 'Delivered';
        buttonIcon = Icons.check;
        buttonColor = EatoTheme.successColor;
        nextStatus = OrderStatus.delivered;
        break;
      default:
        return SizedBox.shrink();
    }

    // Check if THIS specific order is updating
    final isThisOrderUpdating = _updatingOrderIds.contains(order.id);

    // Choose text based on screen size and updating state
    final displayText = isThisOrderUpdating
        ? 'Updating...'
        : (EatoTheme.isSmallScreen(context) ? shortButtonText : buttonText);

    return ElevatedButton.icon(
      onPressed: isThisOrderUpdating
          ? null
          : () => _updateOrderStatus(order.id, nextStatus),
      icon: isThisOrderUpdating
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(buttonIcon, size: 16),
      label: Text(
        displayText,
        overflow: TextOverflow.ellipsis,
      ),
      style: EatoTheme.getResponsivePrimaryButtonStyle(context).copyWith(
        backgroundColor: MaterialStateProperty.all(buttonColor),
      ),
    );
  }

  Widget _buildEmptyOrdersView(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: EatoTheme.getHorizontalPadding(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: EatoTheme.isMobile(context) ? 48 : 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: EatoTheme.getResponsiveHeadingSmall(context).copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: EatoTheme.getResponsiveBodyMedium(context).copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isOrderCompleted(OrderStatus status) {
    return status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.rejected;
  }
}

// ✅ FIXED: Responsive Order Details Page
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
  // Track updating status for this specific order only
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
            padding: EdgeInsets.all(EatoTheme.getHorizontalPadding(context)),
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
                    padding:
                        EdgeInsets.all(EatoTheme.getHorizontalPadding(context)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Order Status',
                                style: EatoTheme.getResponsiveHeadingSmall(
                                    context),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                  isProviderView: true,
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
      padding: EdgeInsets.all(EatoTheme.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update Order Status',
              style: EatoTheme.getResponsiveHeadingSmall(context)),
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
        label: Text(
          _isUpdatingStatus ? 'Updating...' : title,
          style: EatoTheme.getResponsiveBodyMedium(context).copyWith(
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: EatoTheme.getResponsivePrimaryButtonStyle(context).copyWith(
          backgroundColor: MaterialStateProperty.all(color),
        ),
      ),
    );
  }

  // Update status method with proper loading state management
  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
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
        title: Text('Cancel Order?',
            style: EatoTheme.getResponsiveHeadingSmall(context)),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: EatoTheme.getResponsiveBodyMedium(context),
        ),
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
