// FILE: lib/pages/customer/Activity_Page.dart
// FIXED VERSION - Proper navigation handling for embedded mode

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/widgets/OrderProgressIndicator.dart';
import 'package:eato/EatoComponents.dart';
import 'package:eato/pages/theme/eato_theme.dart';
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

  // ✅ FIX: Store provider references to avoid disposal issues
  OrderProvider? _orderProvider;
  UserProvider? _userProvider;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDataInBackground();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ FIX: Store provider references early to avoid disposal issues
    if (!_isDisposed) {
      _orderProvider = Provider.of<OrderProvider>(context, listen: false);
      _userProvider = Provider.of<UserProvider>(context, listen: false);
    }
  }

  Future<void> _initializeDataInBackground() async {
    if (_isInitialized || _isDisposed) return;

    try {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      await _ensureUserDataLoaded();

      if (_userProvider?.currentUser != null && !_isDisposed) {
        _orderProvider?.listenToCustomerOrders(_userProvider!.currentUser!.id);
        _isInitialized = true;
        print(
            "✅ Activity page initialized for user: ${_userProvider!.currentUser!.name}");
      } else {
        throw Exception("User not authenticated");
      }
    } catch (e) {
      print("⚠️ Activity page initialization failed: $e");
      if (mounted && !_isDisposed) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _ensureUserDataLoaded() async {
    if (_userProvider?.currentUser == null && !_isDisposed) {
      final User? authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        await _userProvider?.fetchUser(authUser.uid);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();

    // ✅ FIX: Safely stop listening without accessing Provider.of()
    try {
      _orderProvider?.stopListening();
    } catch (e) {
      print("⚠️ Error stopping order listener: $e");
    }

    super.dispose();
  }

  // ✅ FIX: Proper navigation handling - don't pop back to CustomerHomePage
  void _onBottomNavTap(int index) {
    if (index == 3 || !mounted || _isDisposed)
      return; // Already on Activity tab

    if (widget.showBottomNav) {
      // Standalone mode: Use named routes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/shops');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/orders');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/account');
              break;
          }
        }
      });
    } else {
      // ✅ FIX: In embedded mode, do nothing - let CustomerHomePage handle it
      // Don't pop or navigate - the tab switching is handled by the parent
      print(
          "🔄 Activity page embedded mode - ignoring navigation to index $index");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 3,
              onTap: _onBottomNavTap,
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Icon(
            Icons.timeline,
            color: EatoTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Activity',
            style: EatoTheme.headingMedium.copyWith(
              color: EatoTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _refreshData,
          icon: Icon(
            Icons.refresh,
            color: EatoTheme.textSecondaryColor,
          ),
          tooltip: 'Refresh',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: EatoTheme.primaryColor,
        labelColor: EatoTheme.primaryColor,
        unselectedLabelColor: EatoTheme.textSecondaryColor,
        labelStyle: EatoTheme.labelLarge,
        tabs: const [
          Tab(text: 'Active Orders'),
          Tab(text: 'Order History'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorState();
    }

    return Consumer2<UserProvider, OrderProvider>(
      builder: (context, userProvider, orderProvider, child) {
        final user = userProvider.currentUser;

        if (user == null) {
          return _buildLoginRequiredState();
        }

        if (_isLoading && orderProvider.customerOrders.isEmpty) {
          return _buildLoadingState();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildActiveOrdersTab(orderProvider),
            _buildOrderHistoryTab(orderProvider),
          ],
        );
      },
    );
  }

  Widget _buildLoginRequiredState() {
    return EatoComponents.emptyState(
      message: "Please login to view your orders",
      icon: Icons.person_outline,
      actionText: "Go to Login",
      onActionPressed: () =>
          Navigator.pushReplacementNamed(context, '/role_selection'),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(EatoTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your activity...',
            style: EatoTheme.bodyMedium.copyWith(
              color: EatoTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return EatoComponents.emptyState(
      message: "Something went wrong. Please try again.",
      icon: Icons.error_outline,
      actionText: "Retry",
      onActionPressed: () {
        if (mounted && !_isDisposed) {
          setState(() {
            _error = null;
            _isInitialized = false;
          });
          _initializeDataInBackground();
        }
      },
    );
  }

  Widget _buildActiveOrdersTab(OrderProvider orderProvider) {
    final activeOrders = orderProvider.customerOrders
        .where((order) =>
            order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled &&
            order.status != OrderStatus.rejected)
        .toList();

    if (activeOrders.isEmpty) {
      return EatoComponents.emptyState(
        message: "No active orders",
        icon: Icons.shopping_cart_outlined,
        actionText: "Start Shopping",
        onActionPressed: () {
          if (widget.showBottomNav) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // ✅ FIX: In embedded mode, don't pop - let parent handle tab switching
            print(
                "🔄 Activity page: Start Shopping - staying in embedded mode");
          }
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: EatoTheme.primaryColor,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(activeOrders[index], isActive: true);
        },
      ),
    );
  }

  Widget _buildOrderHistoryTab(OrderProvider orderProvider) {
    final completedOrders = orderProvider.customerOrders
        .where((order) =>
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.rejected)
        .toList();

    if (completedOrders.isEmpty) {
      return EatoComponents.emptyState(
        message: "No completed orders yet",
        icon: Icons.history,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: EatoTheme.primaryColor,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: completedOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(completedOrders[index], isActive: false);
        },
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName,
                        style: EatoTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: EatoTheme.bodySmall.copyWith(
                          color: EatoTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  OrderStatusWidget(
                    status: order.status,
                    showAnimation: isActive,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isActive) ...[
                OrderProgressIndicator(currentStatus: order.status),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EatoTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EatoTheme.primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items (${order.items.length})',
                      style: EatoTheme.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: EatoTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items
                        .take(2)
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.foodName}',
                                      style: EatoTheme.bodySmall.copyWith(
                                        color: EatoTheme.textSecondaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                    style: EatoTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: EatoTheme.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    if (order.items.length > 2) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${order.items.length - 2} more items',
                        style: EatoTheme.bodySmall.copyWith(
                          color: EatoTheme.primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: EatoTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatOrderTime(order.orderTime),
                            style: EatoTheme.bodySmall.copyWith(
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            order.deliveryOption == 'Delivery'
                                ? Icons.delivery_dining
                                : Icons.store,
                            size: 16,
                            color: EatoTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.deliveryOption,
                            style: EatoTheme.bodySmall.copyWith(
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: EatoTheme.bodySmall.copyWith(
                          color: EatoTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                        style: EatoTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isActive && _shouldShowActionButton(order.status)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: EatoComponents.primaryButton(
                    text: _getActionButtonText(order.status),
                    onPressed: () => _handleOrderAction(order),
                    height: 40,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatOrderTime(DateTime orderTime) {
    final now = DateTime.now();
    final difference = now.difference(orderTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(orderTime);
    }
  }

  bool _shouldShowActionButton(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.ready;
  }

  String _getActionButtonText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Track Order';
      case OrderStatus.confirmed:
        return 'Track Order';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.onTheWay:
        return 'Track Delivery';
      default:
        return 'View Details';
    }
  }

  void _handleOrderAction(CustomerOrder order) {
    _viewOrderDetails(order);
  }

  void _viewOrderDetails(CustomerOrder order) {
    if (mounted && !_isDisposed) {
      Navigator.pushNamed(
        context,
        '/order_details',
        arguments: {'order': order},
      );
    }
  }

  Future<void> _refreshData() async {
    if (_isDisposed) return;

    try {
      await _ensureUserDataLoaded();

      if (_userProvider?.currentUser != null && !_isDisposed) {
        _orderProvider?.listenToCustomerOrders(_userProvider!.currentUser!.id);
      }
    } catch (e) {
      print("⚠️ Error refreshing activity data: $e");
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data'),
            backgroundColor: EatoTheme.errorColor,
          ),
        );
      }
    }
  }
}
