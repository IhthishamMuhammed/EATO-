// File: lib/pages/provider/RequestHome.dart (Updated with backend integration)

import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/pages/provider/OrderHomePage.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RequestHome extends StatefulWidget {
  final CustomUser currentUser;

  const RequestHome({Key? key, required this.currentUser}) : super(key: key);

  @override
  _RequestHomeState createState() => _RequestHomeState();
}

class _RequestHomeState extends State<RequestHome> {
  int _currentIndex = 1; // Default to Requests tab
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Initialize the order provider and start listening to requests
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

    // Start listening to order requests for this store
    if (storeProvider.userStore != null) {
      orderProvider.listenToStoreOrderRequests(storeProvider.userStore!.id);
    }
  }

  @override
  void dispose() {
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
      case 0: // Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderHomePage(currentUser: widget.currentUser),
          ),
        );
        break;
      case 1: // Requests - current page
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
            _currentIndex = 1; // Reset to Requests tab when returning
          });
        });
        break;
    }
  }

  List<OrderRequest> _filterRequests(List<OrderRequest> requests) {
    if (_searchQuery.isEmpty) return requests;

    return requests.where((request) {
      return request.customerName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          request.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.storeName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _viewRequestDetails(OrderRequest request, CustomerOrder? order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRequestDetails(request, order),
    );
  }

  Widget _buildRequestDetails(OrderRequest request, CustomerOrder? order) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        return Container(
          padding: EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Order Request',
                    style: EatoTheme.headingMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: EatoTheme.textPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Customer info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: EatoTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: EatoTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      request.customerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Order #${request.orderId.substring(0, 8)}',
                      style: TextStyle(
                        color: EatoTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Request info badge
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EatoTheme.primaryColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: EatoTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        _formatTimeAgo(request.requestTime),
                        style: TextStyle(
                          color: EatoTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Order details (if available)
              if (order != null) ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Order items
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Items (${order.items.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: EatoTheme.primaryColor,
                                  ),
                                ),
                                SizedBox(height: 12),
                                ...order.items
                                    .map((item) => Padding(
                                          padding: EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              // Food image
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: item.foodImage.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        child: Image.network(
                                                          item.foodImage,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Icon(
                                                              Icons.fastfood,
                                                              color: Colors
                                                                  .grey[400],
                                                              size: 20,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.fastfood,
                                                        color: Colors.grey[400],
                                                        size: 20,
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
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: EatoTheme
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Delivery information
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow(Icons.delivery_dining,
                                    'Delivery Method', order.deliveryOption),
                                if (order.deliveryOption == 'Delivery')
                                  _buildDetailRow(
                                      Icons.location_on,
                                      'Delivery Address',
                                      order.deliveryAddress),
                                _buildDetailRow(Icons.payment, 'Payment Method',
                                    order.paymentMethod),
                                if (order.specialInstructions != null &&
                                    order.specialInstructions!.isNotEmpty)
                                  _buildDetailRow(
                                      Icons.note,
                                      'Special Instructions',
                                      order.specialInstructions!),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Total amount
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildPriceRow('Subtotal', order.subtotal),
                                if (order.deliveryFee > 0)
                                  _buildPriceRow(
                                      'Delivery Fee', order.deliveryFee),
                                _buildPriceRow('Service Fee', order.serviceFee),
                                Divider(),
                                _buildPriceRow(
                                    'Total Amount', order.totalAmount,
                                    isTotal: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: EatoTheme.primaryColor),
                        SizedBox(height: 16),
                        Text('Loading order details...'),
                      ],
                    ),
                  ),
                ),
              ],

              // Action buttons
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: orderProvider.isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _rejectRequest(request, orderProvider);
                              },
                        icon: Icon(Icons.close),
                        label: Text('Decline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EatoTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: orderProvider.isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _acceptRequest(request, orderProvider);
                              },
                        icon: Icon(Icons.check),
                        label: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EatoTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
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

  void _acceptRequest(OrderRequest request, OrderProvider orderProvider) async {
    try {
      await orderProvider.acceptOrderRequest(request.id, request.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order request accepted successfully'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _rejectRequest(OrderRequest request, OrderProvider orderProvider) async {
    // Show reason dialog
    final reason = await _showRejectReasonDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await orderProvider.rejectOrderRequest(
          request.id, request.orderId, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order request declined'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for declining this order:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g., Out of ingredients, Too busy, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, StoreProvider>(
      builder: (context, orderProvider, storeProvider, _) {
        if (storeProvider.userStore == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Requests'),
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

        final filteredRequests = _filterRequests(orderProvider.orderRequests);

        return Scaffold(
          appBar: AppBar(
            title: _showSearchBar
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: EatoTheme.inputDecoration(
                      hintText: 'Search requests...',
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
                    'Requests',
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
              if (!_showSearchBar) ...[
                IconButton(
                  icon: Icon(Icons.search, color: EatoTheme.textPrimaryColor),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = true;
                    });
                  },
                ),
                // Badge showing request count
                if (filteredRequests.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_active,
                              color: EatoTheme.primaryColor),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: EatoTheme.errorColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${filteredRequests.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
          body: orderProvider.isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: EatoTheme.primaryColor),
                )
              : RefreshIndicator(
                  onRefresh: () async => _initializeOrderProvider(),
                  color: EatoTheme.primaryColor,
                  child: filteredRequests.isEmpty
                      ? _buildEmptyRequestsView()
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = filteredRequests[index];
                            return _buildRequestCard(request, orderProvider);
                          },
                        ),
                ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildEmptyRequestsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No New Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EatoTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New order requests will appear here',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _initializeOrderProvider(),
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: EatoTheme.outlinedButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(OrderRequest request, OrderProvider orderProvider) {
    return FutureBuilder<CustomerOrder?>(
      future: orderProvider.getOrderById(request.orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EatoTheme.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Request header
                Container(
                  padding: EdgeInsets.all(12),
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
                          Icon(Icons.new_releases,
                              color: EatoTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'New Order Request',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: EatoTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatTimeAgo(request.requestTime),
                        style: TextStyle(
                          color: EatoTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Request details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Customer info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                EatoTheme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: EatoTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.customerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Order #${request.orderId.substring(0, 8)}',
                                  style: TextStyle(
                                    color: EatoTheme.textSecondaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              'PENDING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Order summary (if available)
                      if (order != null) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${order.items.length} items',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: EatoTheme.primaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.delivery_dining,
                                      size: 16,
                                      color: EatoTheme.textSecondaryColor),
                                  SizedBox(width: 4),
                                  Text(
                                    order.deliveryOption,
                                    style: TextStyle(
                                      color: EatoTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.payment,
                                      size: 16,
                                      color: EatoTheme.textSecondaryColor),
                                  SizedBox(width: 4),
                                  Text(
                                    order.paymentMethod,
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
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: EatoTheme.primaryColor,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading order details...',
                                style: TextStyle(
                                  color: EatoTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: orderProvider.isLoading
                                  ? null
                                  : () {
                                      _viewRequestDetails(request, order);
                                    },
                              icon: Icon(Icons.visibility, size: 16),
                              label: Text('View Details'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: EatoTheme.primaryColor,
                                side: BorderSide(color: EatoTheme.primaryColor),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: orderProvider.isLoading
                                  ? null
                                  : () {
                                      _acceptRequest(request, orderProvider);
                                    },
                              icon: Icon(Icons.check, size: 16),
                              label: Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EatoTheme.successColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(time);
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
