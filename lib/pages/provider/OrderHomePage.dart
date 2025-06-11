// File: lib/pages/provider/OrderHomePage.dart (Updated with backend integration)

import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/widgets/OrderProgressIndicator.dart';
import 'package:eato/pages/provider/RequestHome.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class OrderHomePage extends StatefulWidget {
  final CustomUser currentUser;

  const OrderHomePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _OrderHomePageState createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Initialize the order provider and start listening to orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderProvider();
    });
  }

  void _initializeOrderProvider() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Make sure we have the store data
    if (storeProvider.userStore == null) {
      await storeProvider.fetchUserStore(widget.currentUser);
    }

    // Start listening to orders for this store
    if (storeProvider.userStore != null) {
      orderProvider.listenToStoreOrders(storeProvider.userStore!.id);
      orderProvider.listenToStoreOrderRequests(storeProvider.userStore!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    // Stop listening when leaving the page
    Provider.of<OrderProvider>(context, listen: false).stopListening();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Orders (current page)
        break;
      case 1: // Requests
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestHome(currentUser: widget.currentUser),
          ),
        );
        break;
      case 2: // Menu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProviderHomePage(currentUser: widget.currentUser),
          ),
        );
        break;
      case 3: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(currentUser: widget.currentUser),
          ),
        ).then((_) {
          setState(() {
            _currentIndex = 0;
          });
        });
        break;
    }
  }

  void _viewOrderDetails(CustomerOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(
          order: order,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  Future<void> _refreshOrders() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (storeProvider.userStore != null) {
      // Re-initialize listeners
      orderProvider.listenToStoreOrders(storeProvider.userStore!.id);
      orderProvider.listenToStoreOrderRequests(storeProvider.userStore!.id);
    }
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, StoreProvider>(
      builder: (context, orderProvider, storeProvider, _) {
        if (storeProvider.userStore == null) {
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Text('Please set up your store first',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: _showSearchBar
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: EatoTheme.inputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: Icon(Icons.search,
                          color: EatoTheme.textSecondaryColor),
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
                        icon: Icon(Icons.arrow_back,
                            color: EatoTheme.textPrimaryColor),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null),
            actions: [
              if (!_showSearchBar)
                IconButton(
                  icon: Icon(Icons.search, color: EatoTheme.textPrimaryColor),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = true;
                    });
                  },
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
          ),
          body: orderProvider.isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: EatoTheme.primaryColor),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending Orders Tab
                    RefreshIndicator(
                      onRefresh: _refreshOrders,
                      color: EatoTheme.primaryColor,
                      child: _buildOrdersList(
                        _filterOrders(orderProvider.pendingOrders),
                        'No pending orders',
                      ),
                    ),

                    // Active Orders Tab
                    RefreshIndicator(
                      onRefresh: _refreshOrders,
                      color: EatoTheme.primaryColor,
                      child: _buildOrdersList(
                        _filterOrders(orderProvider.activeOrders),
                        'No active orders',
                      ),
                    ),

                    // Completed Orders Tab
                    RefreshIndicator(
                      onRefresh: _refreshOrders,
                      color: EatoTheme.primaryColor,
                      child: _buildOrdersList(
                        _filterOrders(orderProvider.completedOrders),
                        'No completed orders',
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildOrdersList(List<CustomerOrder> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return _buildEmptyOrdersView(emptyMessage);
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildEmptyOrdersView(String message) {
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
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EatoTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Orders will appear here when customers place them',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Order header with ID and time
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: EatoTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 16,
                        color: EatoTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: EatoTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: EatoTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatTime(order.orderTime),
                        style: TextStyle(
                          color: EatoTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                  // Customer info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            EatoTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: EatoTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              order.customerPhone,
                              style: TextStyle(
                                color: EatoTheme.textSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OrderStatusWidget(status: order.status),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Order items
                  Text(
                    'Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: EatoTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...order.items
                      .map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text('• ${item.foodName}'),
                                Spacer(),
                                Text(
                                  'x${item.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: EatoTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),

                  SizedBox(height: 12),

                  // Delivery info
                  if (order.deliveryOption == 'Delivery') ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: EatoTheme.textSecondaryColor,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              color: EatoTheme.textSecondaryColor,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],

                  // Special instructions
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.amber[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.specialInstructions!,
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Total amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rs. ${order.totalAmount.toStringAsFixed(2)}',
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

            // Actions
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      color: EatoTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: EatoTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      selectedItemColor: EatoTheme.primaryColor,
      unselectedItemColor: EatoTheme.textLightColor,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_outlined),
          activeIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ===================================
// ORDER DETAILS PAGE (Updated)
// ===================================

class OrderDetailsPage extends StatefulWidget {
  final CustomerOrder order;
  final CustomUser currentUser;

  const OrderDetailsPage({
    Key? key,
    required this.order,
    required this.currentUser,
  }) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        // Find the current order in the provider's list (for real-time updates)
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
          body: Stack(
            children: [
              SingleChildScrollView(
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
                                Text(
                                  'Order Status',
                                  style: EatoTheme.labelLarge,
                                ),
                                OrderStatusWidget(
                                  status: currentOrder.status,
                                  showAnimation:
                                      _isStatusActive(currentOrder.status),
                                ),
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

                    // Customer info
                    _buildSectionTitle('Customer Information'),
                    SizedBox(height: 16),
                    _buildInfoCard([
                      _buildInfoRow(
                          Icons.person, 'Name', currentOrder.customerName),
                      _buildInfoRow(
                          Icons.phone, 'Phone', currentOrder.customerPhone),
                      if (currentOrder.deliveryOption == 'Delivery')
                        _buildInfoRow(Icons.location_on, 'Address',
                            currentOrder.deliveryAddress),
                      _buildInfoRow(
                          Icons.access_time,
                          'Order Time',
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(currentOrder.orderTime)),
                      if (currentOrder.scheduledTime != null)
                        _buildInfoRow(
                            Icons.schedule,
                            'Scheduled Time',
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(currentOrder.scheduledTime!)),
                    ]),

                    SizedBox(height: 24),

                    // Order items
                    _buildSectionTitle('Order Items'),
                    SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ...currentOrder.items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      // Item image
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.grey[200],
                                        ),
                                        child: item.foodImage.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  item.foodImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(
                                                      Icons.fastfood,
                                                      color: Colors.grey[400],
                                                      size: 25,
                                                    );
                                                  },
                                                ),
                                              )
                                            : Icon(
                                                Icons.fastfood,
                                                color: Colors.grey[400],
                                                size: 25,
                                              ),
                                      ),
                                      SizedBox(width: 12),

                                      // Item details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.foodName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (item.variation != null)
                                              Text(
                                                item.variation!,
                                                style: TextStyle(
                                                  color: EatoTheme
                                                      .textSecondaryColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (item.specialInstructions !=
                                                    null &&
                                                item.specialInstructions!
                                                    .isNotEmpty)
                                              Container(
                                                margin: EdgeInsets.only(top: 4),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Note: ${item.specialInstructions}',
                                                  style: TextStyle(
                                                    color: Colors.amber[700],
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Quantity and price
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'x${item.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: EatoTheme.primaryColor,
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (index <
                                      currentOrder.items.length - 1) ...[
                                    SizedBox(height: 12),
                                    Divider(height: 1),
                                    SizedBox(height: 12),
                                  ],
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Order summary
                    _buildSectionTitle('Order Summary'),
                    SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', currentOrder.subtotal),
                            if (currentOrder.deliveryFee > 0)
                              _buildSummaryRow(
                                  'Delivery Fee', currentOrder.deliveryFee),
                            _buildSummaryRow(
                                'Service Fee', currentOrder.serviceFee),
                            Divider(),
                            _buildSummaryRow('Total', currentOrder.totalAmount,
                                isTotal: true),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.payment,
                                    size: 16,
                                    color: EatoTheme.textSecondaryColor),
                                SizedBox(width: 8),
                                Text(
                                  currentOrder.paymentMethod,
                                  style: TextStyle(
                                    color: EatoTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Order actions (if not completed)
                    if (!_isOrderCompleted(currentOrder.status))
                      _buildOrderActions(currentOrder, orderProvider),

                    SizedBox(height: 32),
                  ],
                ),
              ),

              // Loading overlay
              if (orderProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isStatusActive(OrderStatus status) {
    return status == OrderStatus.preparing || status == OrderStatus.onTheWay;
  }

  bool _isOrderCompleted(OrderStatus status) {
    return status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.rejected;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: EatoTheme.headingSmall,
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: EatoTheme.primaryColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: EatoTheme.bodyMedium,
                ),
              ],
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

  Widget _buildOrderActions(CustomerOrder order, OrderProvider orderProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Order Status',
              style: EatoTheme.headingSmall,
            ),
            SizedBox(height: 16),

            // Status action buttons based on current status
            if (order.status == OrderStatus.pending ||
                order.status == OrderStatus.confirmed)
              _buildStatusButton(
                title: 'Start Preparing',
                icon: Icons.restaurant,
                color: EatoTheme.primaryColor,
                onTap: () =>
                    _updateStatus(OrderStatus.preparing, orderProvider),
              ),

            if (order.status == OrderStatus.preparing)
              _buildStatusButton(
                title: 'Mark as Ready',
                icon: Icons.check_circle_outline,
                color: EatoTheme.infoColor,
                onTap: () => _updateStatus(OrderStatus.ready, orderProvider),
              ),

            if (order.status == OrderStatus.ready &&
                order.deliveryOption == 'Delivery')
              _buildStatusButton(
                title: 'Out for Delivery',
                icon: Icons.directions_bike,
                color: Colors.indigo,
                onTap: () => _updateStatus(OrderStatus.onTheWay, orderProvider),
              ),

            if (order.status == OrderStatus.ready ||
                order.status == OrderStatus.onTheWay)
              _buildStatusButton(
                title: 'Mark as Delivered',
                icon: Icons.check,
                color: EatoTheme.successColor,
                onTap: () =>
                    _updateStatus(OrderStatus.delivered, orderProvider),
              ),

            // Cancel button (only for non-delivered orders)
            if (order.status != OrderStatus.delivered &&
                order.status != OrderStatus.cancelled)
              Column(
                children: [
                  SizedBox(height: 12),
                  _buildStatusButton(
                    title: 'Cancel Order',
                    icon: Icons.cancel_outlined,
                    color: EatoTheme.errorColor,
                    onTap: () => _showCancelConfirmation(orderProvider),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: TextStyle(color: Colors.white)),
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

  void _updateStatus(OrderStatus newStatus, OrderProvider orderProvider) async {
    try {
      await orderProvider.updateOrderStatus(widget.order.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: EatoTheme.successColor,
          ),
        );

        // Go back if order is delivered or cancelled
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
          ),
        );
      }
    }
  }

  void _showCancelConfirmation(OrderProvider orderProvider) {
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
              _updateStatus(OrderStatus.cancelled, orderProvider);
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
}
