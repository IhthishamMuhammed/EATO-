// File: lib/pages/provider/RequestHome.dart
// Modified version without bottom navigation bar

import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderCard.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class RequestHome extends StatefulWidget {
  final CustomUser currentUser;

  const RequestHome({Key? key, required this.currentUser}) : super(key: key);

  @override
  _RequestHomeState createState() => _RequestHomeState();
}

class _RequestHomeState extends State<RequestHome> with WidgetsBindingObserver {
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Real-time update management
  Timer? _refreshTimer;
  bool _isInitialized = false;

  // Loading states for individual requests
  final Set<String> _processingRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    _searchController.dispose();
    _stopRealTimeUpdates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume updates when app comes to foreground
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _refreshRequests();
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

        // Start real-time listeners for requests
        orderProvider.listenToStoreOrderRequests(storeId);

        // Setup periodic refresh for reliability
        _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
          if (mounted) _refreshRequests();
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

  Future<void> _refreshRequests() async {
    if (!mounted) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (storeProvider.userStore != null) {
      // Refresh listeners to ensure latest data
      orderProvider.listenToStoreOrderRequests(storeProvider.userStore!.id);
    }
  }

  // Request handling methods - THIS IS WHERE REQUESTS BECOME ORDERS
  Future<void> _acceptRequest(OrderRequest request) async {
    setState(() => _processingRequests.add(request.id));

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Accept the request - this moves it from requests to orders
      await orderProvider.acceptOrderRequest(request.id, request.orderId);

      _showSuccessSnackBar(
          'Order request accepted! Check Orders tab to manage it.');

      // Optional: Auto-navigate to Orders tab to show the new order
      _showNavigateToOrdersDialog();
    } catch (e) {
      _showErrorSnackBar('Failed to accept request: $e');
    } finally {
      setState(() => _processingRequests.remove(request.id));
    }
  }

  Future<void> _declineRequest(OrderRequest request) async {
    final reason = await _showDeclineReasonDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() => _processingRequests.add(request.id));

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.rejectOrderRequest(
          request.id, request.orderId, reason);

      _showSuccessSnackBar('Order request declined');
    } catch (e) {
      _showErrorSnackBar('Failed to decline request: $e');
    } finally {
      setState(() => _processingRequests.remove(request.id));
    }
  }

  Future<String?> _showDeclineReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: EatoTheme.textButtonStyle,
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

  void _showNavigateToOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request Accepted!'),
        content: Text(
            'The order is now available in your Orders tab. Would you like to go there now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Stay Here'),
            style: EatoTheme.textButtonStyle,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Note: Navigation will be handled by the main navigation wrapper
            },
            style: EatoTheme.primaryButtonStyle,
            child: Text('Go to Orders'),
          ),
        ],
      ),
    );
  }

  List<OrderRequest> _filterRequests(List<OrderRequest> requests) {
    if (_searchQuery.isEmpty) return requests;

    return requests.where((request) {
      return request.customerName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          request.orderId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _viewRequestDetails(OrderRequest request, CustomerOrder? order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRequestDetailsSheet(request, order),
    );
  }

  Widget _buildRequestDetailsSheet(OrderRequest request, CustomerOrder? order) {
    return Container(
      padding: EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Request Details', style: EatoTheme.headingMedium),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          if (order != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: OrderCard(
                  order: order,
                  actionButtons: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Accept this request to add it to your Orders.',
                          style: TextStyle(
                            color: EatoTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _processingRequests.contains(request.id)
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            _declineRequest(request);
                                          },
                                icon: Icon(Icons.close),
                                label: Text('Decline'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EatoTheme.errorColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _processingRequests.contains(request.id)
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            _acceptRequest(request);
                                          },
                                icon: _processingRequests.contains(request.id)
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.check),
                                label: Text(
                                    _processingRequests.contains(request.id)
                                        ? 'Processing...'
                                        : 'Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EatoTheme.successColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: EatoTheme.primaryColor),
                    SizedBox(height: 16),
                    Text('Loading order details...'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: EatoTheme.successColor,
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
              : _buildRequestsContent(orderProvider),
        );
      },
    );
  }

  Widget _buildNoStoreView() {
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Please set up your store first',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(OrderProvider orderProvider) {
    final filteredRequests = _filterRequests(orderProvider.orderRequests);

    return AppBar(
      title: _showSearchBar
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: EatoTheme.inputDecoration(
                hintText: 'Search requests...',
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
          IconButton(
            icon: Icon(Icons.refresh, color: EatoTheme.textPrimaryColor),
            onPressed: _refreshRequests,
          ),
          // Show notification badge for requests
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
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
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
    );
  }

  Widget _buildRequestsContent(OrderProvider orderProvider) {
    final filteredRequests = _filterRequests(orderProvider.orderRequests);

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      color: EatoTheme.primaryColor,
      child: filteredRequests.isEmpty
          ? _buildEmptyRequestsView()
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return FutureBuilder<CustomerOrder?>(
                  future: orderProvider.getOrderById(request.orderId),
                  builder: (context, snapshot) {
                    final order = snapshot.data;
                    final isProcessing =
                        _processingRequests.contains(request.id);

                    return OrderRequestCard(
                      request: request,
                      order: order,
                      isLoading: isProcessing,
                      onAccept: () => _acceptRequest(request),
                      onDecline: () => _declineRequest(request),
                      onViewDetails: () => _viewRequestDetails(request, order),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyRequestsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_outlined, size: 64, color: Colors.grey[400]),
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
            'New order requests will appear here.\nAccept requests to move them to Orders.',
            style: TextStyle(color: EatoTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _refreshRequests,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: EatoTheme.outlinedButtonStyle,
          ),
        ],
      ),
    );
  }
}

// OrderRequestCard widget - you'll need to create this or use existing OrderCard
class OrderRequestCard extends StatelessWidget {
  final OrderRequest request;
  final CustomerOrder? order;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onViewDetails;

  const OrderRequestCard({
    Key? key,
    required this.request,
    this.order,
    this.isLoading = false,
    required this.onAccept,
    required this.onDecline,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EatoTheme.primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EatoTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: EatoTheme.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Order Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'From: ${request.customerName}',
                        style: TextStyle(
                          color: EatoTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EatoTheme.warningColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (order != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Order summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: Rs.${order!.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '${order!.items.length} items',
                        style: EatoTheme.bodyMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewDetails,
                          child: Text('View Details'),
                          style: EatoTheme.outlinedButtonStyle,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onDecline,
                          icon: Icon(Icons.close, size: 16),
                          label: Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EatoTheme.errorColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onAccept,
                          icon: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.check, size: 16),
                          label: Text(isLoading ? 'Processing...' : 'Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EatoTheme.successColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: EatoTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
