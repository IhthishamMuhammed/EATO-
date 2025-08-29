import 'package:eato/EatoComponents.dart';
import 'package:eato/widgets/store_availability_fab.dart';
import 'package:eato/widgets/compact_food_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderCard.dart';
import 'package:eato/widgets/order_request_card.dart';
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

  // Cache for order data to avoid repeated async calls
  final Map<String, CustomerOrder> _orderCache = {};

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

      // Clear cache to force refresh
      _orderCache.clear();
      setState(() {});
    }
  }

  // Pre-load order data for summary widgets
  Future<void> _loadOrderData(
      List<OrderRequest> requests, OrderProvider orderProvider) async {
    for (var request in requests) {
      if (!_orderCache.containsKey(request.orderId)) {
        try {
          final order = await orderProvider.getOrderById(request.orderId);
          if (order != null) {
            _orderCache[request.orderId] = order;
          }
        } catch (e) {
          // Skip if order not found
          continue;
        }
      }
    }

    if (mounted) {
      setState(() {}); // Refresh UI with cached data
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
    } catch (e) {
      _showErrorSnackBar('Failed to accept request: $e');
    } finally {
      setState(() => _processingRequests.remove(request.id));
    }
  }

  Future<void> _declineRequest(OrderRequest request) async {
    // Show confirmation dialog before declining
    final confirmed = await _showDeclineConfirmationDialog();
    if (!confirmed) return;

    setState(() => _processingRequests.add(request.id));

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      // Use a default reason since meal providers don't need to specify
      await orderProvider.rejectOrderRequest(
          request.id, request.orderId, 'Declined by restaurant');

      _showSuccessSnackBar('Order request declined');
    } catch (e) {
      _showErrorSnackBar('Failed to decline request: $e');
    } finally {
      setState(() => _processingRequests.remove(request.id));
    }
  }

  Future<bool> _showDeclineConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Decline Order Request'),
        content: Text(
          'Are you sure you want to decline this order request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
            style: EatoTheme.textButtonStyle,
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Decline'),
          ),
        ],
      ),
    );
    return result ?? false;
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

        final filteredRequests = _filterRequests(orderProvider.orderRequests);

        // Pre-load order data for summary widgets
        if (filteredRequests.isNotEmpty &&
            _orderCache.length < filteredRequests.length) {
          _loadOrderData(filteredRequests, orderProvider);
        }

        // Get cached orders for widgets
        final cachedOrders = _orderCache.values.toList();

        return Scaffold(
          appBar: _buildAppBar(orderProvider),
          body: Stack(
            children: [
              // Main content with food summary widgets
              Column(
                children: [
                  // Food Summary Card (expandable detailed view)
                  if (filteredRequests.isNotEmpty)
                    CompactFoodSummaryCard(
                      requests: filteredRequests,
                      orders: cachedOrders,
                    ),

                  // Requests List
                  Expanded(
                    child: orderProvider.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: EatoTheme.primaryColor))
                        : _buildRequestsContent(orderProvider),
                  ),
                ],
              ),

              // Floating availability button
              StoreAvailabilityFAB(
                storeId: storeProvider.userStore!.id,
              ),
            ],
          ),
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

  // Add this import at the top of your file
  // import 'package:eato/EatoComponents.dart';

  AppBar _buildAppBar(OrderProvider orderProvider) {
    if (_showSearchBar) {
      // Custom search AppBar when search is active
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: EatoTheme.inputDecoration(
            hintText: 'Search requests...',
            prefixIcon: Icon(Icons.search, color: EatoTheme.textSecondaryColor),
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
          style: EatoTheme.bodyMedium,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 0,
        leading: null,
        actions: [],
      );
    }

    // Use ProfilePage style AppBar when not searching
    return EatoComponents.appBar(
      context: context,
      title: 'Requests',
      titleIcon: Icons.inbox,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: EatoTheme.textPrimaryColor),
          onPressed: () => setState(() => _showSearchBar = true),
        ),
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

                // Use cached order if available, otherwise show loading
                final cachedOrder = _orderCache[request.orderId];

                return FutureBuilder<CustomerOrder?>(
                  future: cachedOrder != null
                      ? Future.value(cachedOrder)
                      : orderProvider.getOrderById(request.orderId),
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
