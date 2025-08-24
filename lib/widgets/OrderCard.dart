import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/pages/theme/eato_theme.dart';
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Order header with status
            _buildOrderHeader(),

            // Main content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order items - highlighted
                  _buildOrderItems(),
                  SizedBox(height: 8),

                  // Special instructions (if any)
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    _buildSpecialInstructions(),
                    SizedBox(height: 8),
                  ],

                  // Total amount
                  _buildTotalAmount(),
                ],
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EatoTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 16,
            color: EatoTheme.primaryColor,
          ),
          SizedBox(width: 6),
          Text(
            'Order #${order.id.substring(0, 8)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: EatoTheme.primaryColor,
              fontSize: 13,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '• ${_formatTime(order.orderTime)}',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          Spacer(),
          _buildStatusWidget(),
        ],
      ),
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
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EatoTheme.primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EatoTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 16,
                color: EatoTheme.primaryColor,
              ),
              SizedBox(width: 6),
              Text(
                'Items (${order.items.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: EatoTheme.primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...order.items
              .map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: EatoTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.foodName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.variation != null)
                          Text(
                            '(${item.variation}) ',
                            style: TextStyle(
                              color: EatoTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: EatoTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: EatoTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.note_outlined, size: 14, color: Colors.amber[700]),
          SizedBox(width: 6),
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
            fontSize: 13,
          ),
        ),
        Text(
          'Rs. ${order.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: EatoTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    if (actionButtons != null) {
      return actionButtons!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Main action buttons
          if (showProgress) ...[
            Row(
              children: [
                // Mark Ready button
                Expanded(
                  child: _buildCustomButton(
                    text: 'Mark Ready',
                    onPressed: onTap,
                    icon: Icons.check_circle_outline,
                    backgroundColor: EatoTheme.primaryColor,
                    textColor: Colors.white,
                    height: 40,
                  ),
                ),
                SizedBox(width: 8),
                // View Details button
                Expanded(
                  child: _buildCustomButton(
                    text: 'View Details',
                    onPressed: onTap,
                    icon: Icons.visibility_outlined,
                    backgroundColor: Colors.transparent,
                    textColor: EatoTheme.primaryColor,
                    borderColor: EatoTheme.primaryColor,
                    height: 40,
                  ),
                ),

                // Add compact action buttons even when showProgress is true
                if (isProviderView) ...[
                  SizedBox(width: 8),

                  // Call button - show if phone number exists
                  if (order.customerPhone.isNotEmpty)
                    _buildCompactActionButton(
                      context: context,
                      icon: Icons.phone,
                      onPressed: () => _callCustomer(
                          context, order.customerPhone, order.customerName),
                      color: Colors.green,
                    ),

                  // Spacing between buttons if both exist
                  if (order.customerPhone.isNotEmpty &&
                      order.deliveryOption == 'Delivery' &&
                      order.deliveryAddress.isNotEmpty)
                    SizedBox(width: 6),

                  // Directions button - show only for delivery orders with address
                  if (order.deliveryOption == 'Delivery' &&
                      order.deliveryAddress.isNotEmpty)
                    _buildCompactActionButton(
                      context: context,
                      icon: Icons.directions,
                      onPressed: () =>
                          _openDirections(context, order.deliveryAddress),
                      color: Colors.blue,
                    ),
                ],
              ],
            ),
          ] else ...[
            // Bottom row with View Details and action buttons
            Row(
              children: [
                // View Details button
                Expanded(
                  child: _buildCustomButton(
                    text: 'View Details',
                    onPressed: onTap,
                    icon: Icons.visibility_outlined,
                    backgroundColor: Colors.transparent,
                    textColor: EatoTheme.primaryColor,
                    borderColor: EatoTheme.primaryColor,
                    height: 40,
                  ),
                ),

                // Compact action buttons for provider view
                if (isProviderView) ...[
                  SizedBox(width: 8),

                  // Call button - show if phone number exists
                  if (order.customerPhone.isNotEmpty)
                    _buildCompactActionButton(
                      context: context,
                      icon: Icons.phone,
                      onPressed: () => _callCustomer(
                          context, order.customerPhone, order.customerName),
                      color: Colors.green,
                    ),

                  // Spacing between buttons if both exist
                  if (order.customerPhone.isNotEmpty &&
                      order.deliveryOption == 'Delivery' &&
                      order.deliveryAddress.isNotEmpty)
                    SizedBox(width: 6),

                  // Directions button - show only for delivery orders with address
                  if (order.deliveryOption == 'Delivery' &&
                      order.deliveryAddress.isNotEmpty)
                    _buildCompactActionButton(
                      context: context,
                      icon: Icons.directions,
                      onPressed: () =>
                          _openDirections(context, order.deliveryAddress),
                      color: Colors.blue,
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Compact round action button
  Widget _buildCompactActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 32,
      height: 32,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  // Custom button builder
  Widget _buildCustomButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    Color? borderColor,
    double height = 36,
  }) {
    return Container(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: backgroundColor == Colors.transparent ? 0 : 2,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
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
