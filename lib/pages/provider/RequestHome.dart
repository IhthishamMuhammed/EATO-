import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/pages/provider/OrderHomePage.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Model classes for requests
class OrderRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String foodName;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime requestTime;
  final String deliveryLocation;
  final String contactNumber;
  final bool isCancellationRequest;

  OrderRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.foodName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.requestTime,
    required this.deliveryLocation,
    required this.contactNumber,
    this.isCancellationRequest = false,
  });
}

class RequestProvider with ChangeNotifier {
  List<OrderRequest> _newRequests = [];
  List<OrderRequest> _cancellationRequests = [];
  bool _isLoading = false;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<OrderRequest> get newRequests => _filterRequests(_newRequests);
  List<OrderRequest> get cancellationRequests => _filterRequests(_cancellationRequests);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<OrderRequest> _filterRequests(List<OrderRequest> requests) {
    if (_searchQuery.isEmpty) return requests;

    return requests.where((request) {
      return request.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.foodName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.deliveryLocation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.id.contains(_searchQuery);
    }).toList();
  }

  // Mock data loading
  Future<void> fetchRequests() async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(seconds: 1));

    // Mock data for new orders
    _newRequests = [
      OrderRequest(
        id: '1',
        customerId: 'cust1',
        customerName: 'Mihail Ahamed',
        foodName: 'Rice and curry - Egg',
        price: 250,
        quantity: 2,
        imageUrl: 'https://example.com/food1.jpg',
        requestTime: DateTime.now().subtract(Duration(minutes: 15)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
      ),
      OrderRequest(
        id: '2',
        customerId: 'cust2',
        customerName: 'Mohammed M.I.',
        foodName: 'Rice and curry - Chicken',
        price: 300,
        quantity: 1,
        imageUrl: 'https://example.com/food2.jpg',
        requestTime: DateTime.now().subtract(Duration(minutes: 10)),
        deliveryLocation: 'Banagowra Mawatha',
        contactNumber: '076*******',
      ),
    ];

    // Mock data for cancellation requests
    _cancellationRequests = [
      OrderRequest(
        id: '3',
        customerId: 'cust3',
        customerName: 'Mihail Ajamied',
        foodName: 'Rice and curry - Egg',
        price: 250,
        quantity: 1,
        imageUrl: 'https://example.com/food3.jpg',
        requestTime: DateTime.now().subtract(Duration(minutes: 30)),
        deliveryLocation: 'Faculty Gate',
        contactNumber: '077*******',
        isCancellationRequest: true,
      ),
      OrderRequest(
        id: '4',
        customerId: 'cust4',
        customerName: 'Mohammed M.I.',
        foodName: 'Rice and curry - Chicken',
        price: 300,
        quantity: 3,
        imageUrl: 'https://example.com/food4.jpg',
        requestTime: DateTime.now().subtract(Duration(minutes: 25)),
        deliveryLocation: 'Main Canteen',
        contactNumber: '076*******',
        isCancellationRequest: true,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Accept a new order request
  Future<void> acceptRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(milliseconds: 500));

    // Remove the request from the list
    _newRequests.removeWhere((request) => request.id == requestId);

    _isLoading = false;
    notifyListeners();
  }

  // Decline a new order request
  Future<void> declineRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(milliseconds: 500));

    // Remove the request from the list
    _newRequests.removeWhere((request) => request.id == requestId);

    _isLoading = false;
    notifyListeners();
  }

  // Accept a cancellation request
  Future<void> acceptCancellation(String requestId) async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(milliseconds: 500));

    // Remove the request from the list
    _cancellationRequests.removeWhere((request) => request.id == requestId);

    _isLoading = false;
    notifyListeners();
  }

  // Decline a cancellation request
  Future<void> declineCancellation(String requestId) async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(Duration(milliseconds: 500));

    // Remove the request from the list
    _cancellationRequests.removeWhere((request) => request.id == requestId);

    _isLoading = false;
    notifyListeners();
  }
}

class RequestHome extends StatefulWidget {
  final CustomUser currentUser;

  const RequestHome({Key? key, required this.currentUser}) : super(key: key);

  @override
  _RequestHomeState createState() => _RequestHomeState();
}

class _RequestHomeState extends State<RequestHome> with SingleTickerProviderStateMixin {
  int _currentIndex = 1; // Default to Requests tab
  final RequestProvider _requestProvider = RequestProvider();
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestProvider.fetchRequests();

    _searchController.addListener(() {
      _requestProvider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            builder: (context) => OrderHomePage(currentUser: widget.currentUser),
          ),
        );
        break;
      case 1: // Requests - current page
      // Already on this page
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
            _currentIndex = 1; // Reset to Requests tab when returning
          });
        });
        break;
    }
  }

  void _viewRequestDetails(OrderRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRequestDetails(request),
    );
  }

  Widget _buildRequestDetails(OrderRequest request) {
    return Container(
      padding: EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.isCancellationRequest ? 'Cancellation Request' : 'New Order Request',
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
                  request.contactNumber,
                  style: TextStyle(
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Request type badge
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: request.isCancellationRequest
                    ? EatoTheme.errorColor.withOpacity(0.1)
                    : EatoTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: request.isCancellationRequest
                      ? EatoTheme.errorColor
                      : EatoTheme.successColor,
                ),
              ),
              child: Text(
                request.isCancellationRequest
                    ? 'Order Cancellation Request'
                    : 'New Order Request',
                style: TextStyle(
                  color: request.isCancellationRequest
                      ? EatoTheme.errorColor
                      : EatoTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),

          // Order details
          Text(
            'Request Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Food item
          Row(
            children: [
              // Food image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: request.imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    request.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.fastfood,
                        color: Colors.grey[400],
                        size: 30,
                      );
                    },
                  ),
                )
                    : Icon(
                  Icons.fastfood,
                  color: Colors.grey[400],
                  size: 30,
                ),
              ),
              SizedBox(width: 16),

              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.foodName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quantity: ${request.quantity}',
                      style: TextStyle(
                        color: EatoTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                'Rs.${request.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: EatoTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Location',
                      style: TextStyle(
                        color: EatoTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      request.deliveryLocation,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Request time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.access_time,
                color: EatoTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Time',
                      style: TextStyle(
                        color: EatoTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(request.requestTime),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Spacer(),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (request.isCancellationRequest) {
                      _requestProvider.declineCancellation(request.id);
                    } else {
                      _requestProvider.declineRequest(request.id);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Request declined'),
                        backgroundColor: EatoTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.close),
                  label: Text('Decline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EatoTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (request.isCancellationRequest) {
                      _requestProvider.acceptCancellation(request.id);
                    } else {
                      _requestProvider.acceptRequest(request.id);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Request accepted'),
                        backgroundColor: EatoTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.check),
                  label: Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EatoTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _requestProvider,
      child: Scaffold(
        appBar: AppBar(
          title: _showSearchBar
              ? TextField(
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
                  _requestProvider.setSearchQuery('');
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
                onPressed: () => _requestProvider.fetchRequests(),
              ),
          ],
        ),
        body: Consumer<RequestProvider>(
          builder: (context, requestProvider, _) {
            if (requestProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: EatoTheme.primaryColor),
              );
            }

            // Check if both request lists are empty
            final bool isEmpty = requestProvider.newRequests.isEmpty &&
                requestProvider.cancellationRequests.isEmpty;

            if (isEmpty) {
              return _buildEmptyRequestsView();
            }

            return RefreshIndicator(
              onRefresh: () => requestProvider.fetchRequests(),
              color: EatoTheme.primaryColor,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Orders Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: EatoTheme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'New Order Requests',
                              style: EatoTheme.headingSmall,
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: EatoTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${requestProvider.newRequests.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // New Order Requests
                      requestProvider.newRequests.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24.0,
                          horizontal: 16.0,
                        ),
                        child: Center(
                          child: Text(
                            'No new order requests',
                            style: TextStyle(color: EatoTheme.textSecondaryColor),
                          ),
                        ),
                      )
                          : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: requestProvider.newRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(
                            requestProvider.newRequests[index],
                            requestProvider,
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Cancel Order Requests Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              color: EatoTheme.errorColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cancellation Requests',
                              style: EatoTheme.headingSmall,
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: EatoTheme.errorColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${requestProvider.cancellationRequests.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // Cancel Order Requests
                      requestProvider.cancellationRequests.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24.0,
                          horizontal: 16.0,
                        ),
                        child: Center(
                          child: Text(
                            'No cancellation requests',
                            style: TextStyle(color: EatoTheme.textSecondaryColor),
                          ),
                        ),
                      )
                          : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: requestProvider.cancellationRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(
                            requestProvider.cancellationRequests[index],
                            requestProvider,
                          );
                        },
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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
            'No Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EatoTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New requests will appear here',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _requestProvider.fetchRequests(),
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: EatoTheme.outlinedButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(OrderRequest request, RequestProvider provider) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: request.isCancellationRequest
                ? EatoTheme.errorColor.withOpacity(0.3)
                : EatoTheme.successColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Request header
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: request.isCancellationRequest
                    ? EatoTheme.errorColor.withOpacity(0.05)
                    : EatoTheme.successColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    request.isCancellationRequest
                        ? 'Cancellation Request'
                        : 'New Order Request',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: request.isCancellationRequest
                          ? EatoTheme.errorColor
                          : EatoTheme.successColor,
                    ),
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
                      child: request.imageUrl.isNotEmpty
                          ? Image.network(
                        request.imageUrl,
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

                  // Order details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer name
                        Text(
                          request.customerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),

                        // Food details
                        Text(
                          '${request.foodName} x ${request.quantity}',
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
                                request.deliveryLocation,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs.${request.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total: ${(request.price * request.quantity).toStringAsFixed(0)}',
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

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewRequestDetails(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EatoTheme.primaryColor,
                        side: BorderSide(color: EatoTheme.primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('View details'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (request.isCancellationRequest) {
                          provider.acceptCancellation(request.id);
                        } else {
                          provider.acceptRequest(request.id);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Request accepted'),
                            backgroundColor: EatoTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: request.isCancellationRequest
                            ? EatoTheme.errorColor
                            : EatoTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        request.isCancellationRequest ? 'Accept cancel' : 'Accept',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
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