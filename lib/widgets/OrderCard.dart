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
  final bool
      isProviderView; // New parameter to show customer contact for providers

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.actionButtons,
    this.showProgress = false,
    this.isProviderView = false, // Default to customer view
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info (enhanced for provider view)
                  _buildCustomerInfo(context),
                  SizedBox(height: 16),

                  // Customer contact card (only for provider view)
                  if (isProviderView && order.customerPhone.isNotEmpty) ...[
                    _buildCustomerContactCard(context),
                    SizedBox(height: 16),
                  ],

                  // Order items
                  _buildOrderItems(),
                  SizedBox(height: 12),

                  // Delivery info
                  if (order.deliveryOption == 'Delivery') ...[
                    _buildDeliveryInfo(),
                    SizedBox(height: 8),
                  ],

                  // Special instructions
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    _buildSpecialInstructions(),
                    SizedBox(height: 12),
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
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: EatoTheme.primaryColor.withOpacity(0.1),
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
              // Show phone for provider view or just show it always as in original
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
        // Call button for provider view
        if (isProviderView && order.customerPhone.isNotEmpty) ...[
          InkWell(
            onTap: () =>
                _callCustomer(context, order.customerPhone, order.customerName),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: EatoTheme.primaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        OrderStatusWidget(status: order.status),
      ],
    );
  }

  // Customer contact card for provider view
  Widget _buildCustomerContactCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EatoTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EatoTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: EatoTheme.primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Contact',
                  style: TextStyle(
                    fontSize: 12,
                    color: EatoTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  order.customerPhone,
                  style: TextStyle(
                    fontSize: 14,
                    color: EatoTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _callCustomer(
                  context, order.customerPhone, order.customerName),
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size(60, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Icon(Icons.call, size: 16),
            ),
          ),
        ],
      ),
    );
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
          ),
        ),
        SizedBox(height: 8),
        ...order.items
            .map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('• ${item.foodName}'),
                      if (item.variation != null)
                        Text(' (${item.variation})',
                            style:
                                TextStyle(color: EatoTheme.textSecondaryColor)),
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
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Row(
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
    );
  }

  Widget _buildSpecialInstructions() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
    );
  }

  Widget _buildViewDetailsAction() {
    return Container(
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
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  // Call functionality for provider view
  Future<void> _callCustomer(
      BuildContext context, String phoneNumber, String customerName) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Fallback: Copy to clipboard
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
      print('Error launching phone call: $e');
      // Fallback: Copy to clipboard
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
