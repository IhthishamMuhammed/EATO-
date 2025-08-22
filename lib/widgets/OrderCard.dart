import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/EatoComponents.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final VoidCallback? onTap;
  final Widget? actionButtons;
  final bool showProgress;
  final bool isProviderView;

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.actionButtons,
    this.showProgress = false,
    this.isProviderView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: 16, vertical: 6), // Reduced vertical margin
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Order header
            _buildOrderHeader(),

            // Order details
            Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info with call button
                  _buildCustomerInfo(context),
                  SizedBox(height: 12), // Reduced spacing

                  // Order items
                  _buildOrderItems(),
                  SizedBox(height: 8), // Reduced spacing

                  // Special instructions
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    _buildSpecialInstructions(),
                    SizedBox(height: 8), // Reduced spacing
                  ],

                  // Total amount
                  _buildTotalAmount(),
                ],
              ),
            ),

            // Action buttons or progress indicator
            if (actionButtons != null) actionButtons!,
            if (showProgress && actionButtons == null)
              _buildViewDetailsAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
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
                size: 14, // Smaller icon
                color: EatoTheme.primaryColor,
              ),
              SizedBox(width: 6),
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: EatoTheme.primaryColor,
                  fontSize: 13, // Smaller text
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14, // Smaller icon
                color: EatoTheme.textSecondaryColor,
              ),
              SizedBox(width: 4),
              Text(
                _formatTime(order.orderTime),
                style: TextStyle(
                  color: EatoTheme.textSecondaryColor,
                  fontSize: 11, // Smaller text
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: EatoTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: EatoTheme.primaryColor,
            size: 18,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.customerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (order.customerPhone.isNotEmpty)
                Text(
                  order.customerPhone,
                  style: TextStyle(
                    color: EatoTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        // Call button for provider view
        if (isProviderView && order.customerPhone.isNotEmpty) ...[
          InkWell(
            onTap: () =>
                _callCustomer(context, order.customerPhone, order.customerName),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: EatoTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        // Location button for delivery orders
        if (order.deliveryOption == 'Delivery') ...[
          InkWell(
            onTap: () => _openDirections(context, order.deliveryAddress),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.navigation,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        _buildStatusWidget(),
      ],
    );
  }

  Widget _buildStatusWidget() {
    // Don't show "On the Way" status for pickup orders
    OrderStatus displayStatus = order.status;
    if (order.deliveryOption == 'Pickup' &&
        order.status == OrderStatus.onTheWay) {
      displayStatus = OrderStatus.ready;
    }

    return OrderStatusWidget(status: displayStatus);
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: EatoTheme.textPrimaryColor,
            fontSize: 13, // Smaller text
          ),
        ),
        SizedBox(height: 6),
        ...order.items
            .map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 2), // Reduced spacing
                  child: Row(
                    children: [
                      Text(
                        '• ${item.foodName}',
                        style: TextStyle(fontSize: 13), // Smaller text
                      ),
                      if (item.variation != null)
                        Text(
                          ' (${item.variation})',
                          style: TextStyle(
                            color: EatoTheme.textSecondaryColor,
                            fontSize: 12, // Smaller text
                          ),
                        ),
                      Spacer(),
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: EatoTheme.primaryColor,
                          fontSize: 13, // Smaller text
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildSpecialInstructions() {
    return Container(
      padding: EdgeInsets.all(6), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.note, size: 14, color: Colors.amber[700]), // Smaller icon
          SizedBox(width: 6),
          Expanded(
            child: Text(
              order.specialInstructions!,
              style: TextStyle(
                color: Colors.amber[700],
                fontSize: 11, // Smaller text
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Amount',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14, // Smaller text
          ),
        ),
        Text(
          'Rs. ${order.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16, // Smaller text
            color: EatoTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildViewDetailsAction() {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
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
              fontSize: 13, // Smaller text
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 12, // Smaller icon
            color: EatoTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Future<void> _openDirections(BuildContext context, String address) async {
    try {
      final Uri mapsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}');

      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri);
      } else {
        await Clipboard.setData(ClipboardData(text: address));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address copied: $address'),
            backgroundColor: EatoTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: address));
    }
  }

  Future<void> _callCustomer(
      BuildContext context, String phoneNumber, String customerName) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number copied: $phoneNumber'),
            backgroundColor: EatoTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number copied: $phoneNumber'),
          backgroundColor: EatoTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Specialized widget for order requests
class OrderRequestCard extends StatelessWidget {
  final OrderRequest request;
  final CustomerOrder? order;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onViewDetails;
  final bool isLoading;

  const OrderRequestCard({
    Key? key,
    required this.request,
    this.order,
    this.onAccept,
    this.onDecline,
    this.onViewDetails,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            color: EatoTheme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Request header
            _buildRequestHeader(),

            // Request details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Customer info
                  _buildCustomerInfo(),
                  SizedBox(height: 16),

                  // Order summary
                  if (order != null)
                    _buildOrderSummary()
                  else
                    _buildLoadingOrderSummary(),

                  SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestHeader() {
    return Container(
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
              Icon(Icons.new_releases, color: EatoTheme.primaryColor, size: 20),
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
    );
  }

  Widget _buildCustomerInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: EatoTheme.primaryColor.withOpacity(0.1),
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
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order!.items.length} items',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Rs. ${order!.totalAmount.toStringAsFixed(0)}',
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
                  size: 16, color: EatoTheme.textSecondaryColor),
              SizedBox(width: 4),
              Text(
                order!.deliveryOption,
                style: TextStyle(
                  color: EatoTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.payment,
                  size: 16, color: EatoTheme.textSecondaryColor),
              SizedBox(width: 4),
              Text(
                order!.paymentMethod,
                style: TextStyle(
                  color: EatoTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrderSummary() {
    return Container(
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onViewDetails,
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
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
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
}
