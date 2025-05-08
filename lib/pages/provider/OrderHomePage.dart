import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/pages/provider/RequestHome.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:intl/intl.dart';


// Order model
class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String foodName;
  final int quantity;
  final double price;
  final String imageUrl;
  final DateTime orderTime;
  final String deliveryLocation;
  final String contactNumber;
  final OrderStatus status;
  final bool isPastOrder;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.foodName,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.orderTime,
    required this.deliveryLocation,
    required this.contactNumber,
    required this.status,
    this.isPastOrder = false,
  });
}

enum OrderStatus { pending, ready, onTheWay, delivered, cancelled }

// OrderProvider
class OrderProvider with ChangeNotifier {
  List<Order> _presentOrders = [];
  List<Order> _pastOrders = [];
  bool _isLoading = false;
  bool _isPresentTab = true; // Flag to track which tab is selected
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<Order> get presentOrders => _filterOrders(_presentOrders);
  List<Order> get pastOrders => _filterOrders(_pastOrders);
  bool get isPresentTab => _isPresentTab;

  void toggleTab(bool isPresentTab) {
    _isPresentTab = isPresentTab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Order> _filterOrders(List<Order> orders) {
    if (_searchQuery.isEmpty) return orders;

    return orders.where((order) {
      return order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.foodName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.deliveryLocation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.id.contains(_searchQuery);
    }).toList();
  }

  // Fetch orders from backend (mocked for now)
  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(seconds: 1));

    // Mock present orders
    _presentOrders = [
      Order(
        id: '01',
        customerId: 'cust1',
        customerName: 'Mihail Ahamed',
        foodName: 'Rice and curry - Chicken',
        quantity: 5,
        price: 250,
        imageUrl: 'https://example.com/food1.jpg',
        orderTime: DateTime.now().subtract(Duration(minutes: 30)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
        status: OrderStatus.pending,
      ),
      Order(
        id: '02',
        customerId: 'cust2',
        customerName: 'Ishmika',
        foodName: 'Rice and curry - Chicken',
        quantity: 5,
        price: 250,
        imageUrl: 'https://example.com/food2.jpg',
        orderTime: DateTime.now().subtract(Duration(hours: 1, minutes: 15)),
        deliveryLocation: 'Banagowra Mawatha',
        contactNumber: '076*******',
        status: OrderStatus.ready,
      ),
      Order(
        id: '03',
        customerId: 'cust3',
        customerName: 'Rishmika',
        foodName: 'Rice and curry - Chicken',
        quantity: 5,
        price: 250,
        imageUrl: 'https://example.com/food3.jpg',
        orderTime: DateTime.now().subtract(Duration(hours: 1, minutes: 25)),
        deliveryLocation: 'Faculty',
        contactNumber: '071*******',
        status: OrderStatus.onTheWay,
      ),
      Order(
        id: '04',
        customerId: 'cust4',
        customerName: 'Vitana',
        foodName: 'Rice and curry - Chicken',
        quantity: 5,
        price: 250,
        imageUrl: 'https://example.com/food4.jpg',
        orderTime: DateTime.now().subtract(Duration(hours: 2)),
        deliveryLocation: 'Main Canteen',
        contactNumber: '070*******',
        status: OrderStatus.delivered,
      ),
    ];

    // Mock past orders
    _pastOrders = [
      Order(
        id: '05',
        customerId: 'cust5',
        customerName: 'Mihail Ahamed',
        foodName: 'Rice and curry - Chicken',
        quantity: 5,
        price: 250,
        imageUrl: 'https://example.com/food5.jpg',
        orderTime: DateTime.now().subtract(Duration(days: 1)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
        status: OrderStatus.delivered,
        isPastOrder: true,
      ),
      Order(
        id: '06',
        customerId: 'cust6',
        customerName: 'Mihail Ahamed',
        foodName: 'Rice and curry - Egg',
        quantity: 12,
        price: 200,
        imageUrl: 'https://example.com/food6.jpg',
        orderTime: DateTime.now().subtract(Duration(days: 1, hours: 2)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
        status: OrderStatus.delivered,
        isPastOrder: true,
      ),
      Order(
        id: '07',
        customerId: 'cust7',
        customerName: 'Mihail Ahamed',
        foodName: 'Rice and curry - Fish',
        quantity: 3,
        price: 300,
        imageUrl: 'https://example.com/food7.jpg',
        orderTime: DateTime.now().subtract(Duration(days: 2)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
        status: OrderStatus.delivered,
        isPastOrder: true,
      ),
      Order(
        id: '08',
        customerId: 'cust8',
        customerName: 'Mihail Ahamed',
        foodName: 'Rice and curry - Chicken',
        quantity: 5,
        price: 250,
        imageUrl: 'https://example.com/food8.jpg',
        orderTime: DateTime.now().subtract(Duration(days: 2, hours: 3)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
        status: OrderStatus.delivered,
        isPastOrder: true,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(milliseconds: 500));

    // Find and update the order
    final orderIndex = _presentOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      final currentOrder = _presentOrders[orderIndex];
      final updatedOrder = Order(
        id: currentOrder.id,
        customerId: currentOrder.customerId,
        customerName: currentOrder.customerName,
        foodName: currentOrder.foodName,
        quantity: currentOrder.quantity,
        price: currentOrder.price,
        imageUrl: currentOrder.imageUrl,
        orderTime: currentOrder.orderTime,
        deliveryLocation: currentOrder.deliveryLocation,
        contactNumber: currentOrder.contactNumber,
        status: newStatus,
      );

      // If the order is delivered or cancelled, move it to past orders
      if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
        _presentOrders.removeAt(orderIndex);
        _pastOrders.insert(0, Order(
          id: updatedOrder.id,
          customerId: updatedOrder.customerId,
          customerName: updatedOrder.customerName,
          foodName: updatedOrder.foodName,
          quantity: updatedOrder.quantity,
          price: updatedOrder.price,
          imageUrl: updatedOrder.imageUrl,
          orderTime: updatedOrder.orderTime,
          deliveryLocation: updatedOrder.deliveryLocation,
          contactNumber: updatedOrder.contactNumber,
          status: updatedOrder.status,
          isPastOrder: true,
        ));
      } else {
        _presentOrders[orderIndex] = updatedOrder;
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}

class OrderHomePage extends StatefulWidget {
  final CustomUser currentUser;

  const OrderHomePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _OrderHomePageState createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;  // Default to Orders tab
  final OrderProvider _orderProvider = OrderProvider();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _orderProvider.fetchOrders();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _orderProvider.toggleTab(_tabController.index == 0);
    });

    _searchController.addListener(() {
      _orderProvider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Orders (current page)
      // Already on the page
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
            builder: (context) => ProviderHomePage(currentUser: widget.currentUser),
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
            _currentIndex = 0; // Reset to Orders tab when returning
          });
        });
        break;
    }
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(
          order: order,
          orderProvider: _orderProvider,
        ),
      ),
    );
  }

  Future<void> _refreshOrders() async {
    await _orderProvider.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _orderProvider,
      child: Scaffold(
        appBar: AppBar(
          title: _showSearchBar
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Search orders...',
              prefixIcon: Icon(Icons.search, color: EatoTheme.textSecondaryColor),
              suffixIcon: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showSearchBar = false;
                    _searchController.clear();
                  });
                  _orderProvider.setSearchQuery('');
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
            icon: Icon(Icons.arrow_back, color: EatoTheme.textPrimaryColor),
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
              Tab(text: 'ACTIVE ORDERS'),
              Tab(text: 'COMPLETED ORDERS'),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            if (orderProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: EatoTheme.primaryColor),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Present Orders Tab
                RefreshIndicator(
                  onRefresh: _refreshOrders,
                  color: EatoTheme.primaryColor,
                  child: orderProvider.presentOrders.isEmpty
                      ? _buildEmptyOrdersView('No active orders')
                      : _buildPresentOrdersList(orderProvider),
                ),

                // Past Orders Tab
                RefreshIndicator(
                  onRefresh: _refreshOrders,
                  color: EatoTheme.primaryColor,
                  child: orderProvider.pastOrders.isEmpty
                      ? _buildEmptyOrdersView('No completed orders')
                      : _buildPastOrdersList(orderProvider),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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

  Widget _buildPresentOrdersList(OrderProvider orderProvider) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      itemCount: orderProvider.presentOrders.length,
      itemBuilder: (context, index) {
        final order = orderProvider.presentOrders[index];
        return _buildActiveOrderCard(order);
      },
    );
  }

  Widget _buildPastOrdersList(OrderProvider orderProvider) {
    // Group orders by date
    Map<String, List<Order>> groupedOrders = {};

    for (var order in orderProvider.pastOrders) {
      final dateKey = _formatDateForGrouping(order.orderTime);
      if (!groupedOrders.containsKey(dateKey)) {
        groupedOrders[dateKey] = [];
      }
      groupedOrders[dateKey]!.add(order);
    }

    // Sort dates from newest to oldest
    final sortedDates = groupedOrders.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.all(0),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final ordersForDate = groupedOrders[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              color: EatoTheme.primaryColor.withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                _formatDateHeader(dateKey),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: EatoTheme.primaryColor,
                ),
              ),
            ),

            // Orders for this date
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: ordersForDate.length,
              itemBuilder: (context, orderIndex) {
                return _buildPastOrderCard(ordersForDate[orderIndex]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveOrderCard(Order order) {
    Color statusColor;
    String statusText;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.ready:
        statusColor = Colors.blue;
        statusText = 'Ready';
        break;
      case OrderStatus.onTheWay:
        statusColor = Colors.purple;
        statusText = 'On the way';
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

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
                        'Order #${order.id}',
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: order.imageUrl.isNotEmpty
                          ? Image.network(
                        order.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fastfood,
                            color: Colors.grey[400],
                            size: 30,
                          );
                        },
                      )
                          : Icon(
                        Icons.fastfood,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer name
                        Text(
                          order.customerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),

                        // Food details
                        Text(
                          '${order.foodName} x ${order.quantity}',
                          style: TextStyle(
                            color: EatoTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 4),

                        // Location
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
                                order.deliveryLocation,
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
                      ],
                    ),
                  ),

                  // Price and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs.${order.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildPastOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Food image
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: order.imageUrl.isNotEmpty
                      ? Image.network(
                    order.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.fastfood,
                        color: Colors.grey[400],
                        size: 22,
                      );
                    },
                  )
                      : Icon(
                    Icons.fastfood,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.foodName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'x${order.quantity}',
                          style: TextStyle(
                            color: EatoTheme.textSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            order.customerName,
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
                  ],
                ),
              ),

              // Price
              Text(
                'Rs.${order.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatDateForGrouping(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateHeader(String dateKey) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final dateObj = DateTime.parse(dateKey);

    if (DateFormat('yyyy-MM-dd').format(now) == dateKey) {
      return 'Today';
    } else if (DateFormat('yyyy-MM-dd').format(yesterday) == dateKey) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(dateObj);
    }
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

// Order Details Page
class OrderDetailsPage extends StatefulWidget {
  final Order order;
  final OrderProvider orderProvider;

  const OrderDetailsPage({
    Key? key,
    required this.order,
    required this.orderProvider,
  }) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isPastOrder = widget.order.isPastOrder;

    return Scaffold(
      appBar: EatoTheme.appBar(
        context: context,
        title: 'Order #${widget.order.id}',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: widget.order.imageUrl.isNotEmpty
                                ? Image.network(
                              widget.order.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.grey[600],
                                );
                              },
                            )
                                : Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(width: 20),

                        // Order details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Details',
                                style: EatoTheme.labelLarge,
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.order.foodName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Quantity: ${widget.order.quantity}',
                                style: TextStyle(
                                  color: EatoTheme.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Total: Rs.${widget.order.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: EatoTheme.primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildOrderStatusChip(widget.order.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Customer info section
                Text(
                  'Customer Information',
                  style: EatoTheme.headingSmall,
                ),
                SizedBox(height: 16),
                _buildInfoTile(
                  icon: Icons.person_outline,
                  title: 'Name',
                  value: widget.order.customerName,
                ),
                SizedBox(height: 12),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: widget.order.contactNumber,
                ),
                SizedBox(height: 12),
                _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Location',
                  value: widget.order.deliveryLocation,
                ),
                SizedBox(height: 12),
                _buildInfoTile(
                  icon: Icons.access_time,
                  title: 'Order Time',
                  value: DateFormat('MMM d, yyyy • h:mm a').format(widget.order.orderTime),
                ),

                SizedBox(height: 32),

                // Order Status Actions for active orders
                if (!isPastOrder) ...[
                  Text(
                    'Order Status',
                    style: EatoTheme.headingSmall,
                  ),
                  SizedBox(height: 16),

                  // Status buttons
                  _buildStatusButton(
                    title: 'Order is ready',
                    icon: Icons.check_circle_outline,
                    color: EatoTheme.infoColor,
                    isActive: widget.order.status == OrderStatus.ready,
                    isDisabled: widget.order.status == OrderStatus.onTheWay ||
                        widget.order.status == OrderStatus.delivered ||
                        widget.order.status == OrderStatus.cancelled,
                    onTap: () => _updateOrderStatus(OrderStatus.ready),
                  ),
                  SizedBox(height: 12),

                  _buildStatusButton(
                    title: 'Order is on the way',
                    icon: Icons.directions_bike_outlined,
                    color: EatoTheme.primaryColor,
                    isActive: widget.order.status == OrderStatus.onTheWay,
                    isDisabled: widget.order.status == OrderStatus.pending ||
                        widget.order.status == OrderStatus.delivered ||
                        widget.order.status == OrderStatus.cancelled,
                    onTap: () => _updateOrderStatus(OrderStatus.onTheWay),
                  ),
                  SizedBox(height: 12),

                  _buildStatusButton(
                    title: 'Order delivered',
                    icon: Icons.check_outlined,
                    color: EatoTheme.successColor,
                    isActive: widget.order.status == OrderStatus.delivered,
                    isDisabled: widget.order.status == OrderStatus.pending ||
                        widget.order.status == OrderStatus.cancelled,
                    onTap: () => _updateOrderStatus(OrderStatus.delivered),
                  ),
                  SizedBox(height: 12),

                  _buildStatusButton(
                    title: 'Cancel order',
                    icon: Icons.cancel_outlined,
                    color: EatoTheme.errorColor,
                    isActive: widget.order.status == OrderStatus.cancelled,
                    isDisabled: widget.order.status == OrderStatus.delivered,
                    onTap: () => _showCancelConfirmation(),
                  ),
                ] else ...[
                  // Order completion status for past orders
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.order.status == OrderStatus.delivered
                                ? EatoTheme.successColor.withOpacity(0.1)
                                : EatoTheme.errorColor.withOpacity(0.1),
                          ),
                          child: Icon(
                            widget.order.status == OrderStatus.delivered
                                ? Icons.check
                                : Icons.cancel,
                            color: widget.order.status == OrderStatus.delivered
                                ? EatoTheme.successColor
                                : EatoTheme.errorColor,
                            size: 40,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          widget.order.status == OrderStatus.delivered
                              ? 'Order Completed'
                              : 'Order Cancelled',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.order.status == OrderStatus.delivered
                                ? EatoTheme.successColor
                                : EatoTheme.errorColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(widget.order.orderTime),
                          style: TextStyle(
                            color: EatoTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 32),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChip(OrderStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.ready:
        statusColor = Colors.blue;
        statusText = 'Ready';
        break;
      case OrderStatus.onTheWay:
        statusColor = Colors.purple;
        statusText = 'On the way';
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: EatoTheme.primaryColor,
            size: 24,
          ),
          SizedBox(width: 16),
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
                SizedBox(height: 4),
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

  Widget _buildStatusButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : (isActive ? null : onTap),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : color,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : EatoTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isActive)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                )
              else if (!isDisabled)
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateOrderStatus(OrderStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.orderProvider.updateOrderStatus(widget.order.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated'),
            backgroundColor: EatoTheme.successColor,
          ),
        );

        if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
          Navigator.pop(context); // Go back to orders list
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order?'),
        content: Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, Keep Order'),
            style: EatoTheme.textButtonStyle,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(OrderStatus.cancelled);
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