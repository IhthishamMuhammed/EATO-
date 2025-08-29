import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:intl/intl.dart';

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
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _buildRequestHeader(),
            if (order != null) ...[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderItems(),
                    SizedBox(height: 8),
                    if (order!.specialInstructions != null &&
                        order!.specialInstructions!.isNotEmpty) ...[
                      _buildSpecialInstructions(),
                      SizedBox(height: 8),
                    ],
                    _buildTotalAmount(),
                  ],
                ),
              ),
              _buildRequestActions(),
            ] else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child:
                      CircularProgressIndicator(color: EatoTheme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EatoTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active,
              size: 16, color: EatoTheme.warningColor),
          SizedBox(width: 6),
          Text(
            'New Request ${_getDisplayOrderNumber()}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: EatoTheme.warningColor,
              fontSize: 13,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '• ${_formatTime(request.requestTime)}',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          Spacer(),
          _buildNewRequestBadge(),
        ],
      ),
    );
  }

  Widget _buildNewRequestBadge() {
    return Container(
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
    );
  }

  Widget _buildOrderItems() {
    if (order == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EatoTheme.warningColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EatoTheme.warningColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu,
                  size: 16, color: EatoTheme.warningColor),
              SizedBox(width: 6),
              Text(
                'Items (${order!.items.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: EatoTheme.warningColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...order!.items
              .map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: EatoTheme.warningColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.foodName,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
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
                            color: EatoTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: EatoTheme.warningColor,
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
    if (order == null) return SizedBox.shrink();

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
              order!.specialInstructions!,
              style: TextStyle(color: Colors.amber[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount() {
    if (order == null) return SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Amount',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Text(
          'Rs. ${order!.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: EatoTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestActions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Builder(
        builder: (buttonContext) => Row(
          children: [
            Expanded(
              child: _buildCustomButton(
                text: 'Decline',
                onPressed: isLoading ? null : onDecline,
                icon: Icons.close,
                backgroundColor: EatoTheme.errorColor,
                textColor: Colors.white,
                height: 40,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildCustomButton(
                text: isLoading ? 'Processing...' : 'Accept',
                onPressed: isLoading ? null : onAccept,
                icon: isLoading ? null : Icons.check,
                backgroundColor: EatoTheme.successColor,
                textColor: Colors.white,
                height: 40,
                isLoading: isLoading,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildCustomButton(
                text: 'View Details',
                onPressed: () {
                  if (order != null) _showRequestDetails(buttonContext);
                },
                icon: Icons.visibility_outlined,
                backgroundColor: Colors.transparent,
                textColor: EatoTheme.primaryColor,
                borderColor: EatoTheme.primaryColor,
                height: 40,
              ),
            ),
            if (order != null && order!.customerPhone.isNotEmpty) ...[
              SizedBox(width: 8),
              _buildCompactActionButton(
                icon: Icons.phone,
                onPressed: () =>
                    _callCustomer(order!.customerPhone, order!.customerName),
                color: Colors.green,
              ),
            ],
            if (order != null &&
                order!.deliveryOption == 'Delivery' &&
                order!.deliveryAddress.isNotEmpty) ...[
              SizedBox(width: 6),
              _buildCompactActionButton(
                icon: Icons.directions,
                onPressed: () => _openDirections(order!.deliveryAddress),
                color: Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // NEW METHOD: Show complete request details in modal
  void _showRequestDetails(BuildContext context) {
    if (order == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (sheetContext, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Request Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: EatoTheme.warningColor,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(modalContext),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // COMPLETE REQUEST DETAILS CONTENT
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Information Section
                      _buildDetailSection(
                        'Order Information',
                        Icons.receipt_long,
                        Column(
                          children: [
                            _buildDetailRow(
                                'Request ID', _getDisplayOrderNumber()),
                            _buildDetailRow(
                                'Request Time',
                                DateFormat('MMM dd, yyyy • h:mm a')
                                    .format(request.requestTime)),
                            _buildDetailRow('Status', 'PENDING REQUEST'),
                            _buildDetailRow('Store', order!.storeName),
                            _buildDetailRow(
                                'Delivery Method', order!.deliveryOption),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Customer Information
                      _buildDetailSection(
                        'Customer Information',
                        Icons.person,
                        Column(
                          children: [
                            _buildDetailRow('Name', order!.customerName),
                            if (order!.customerPhone.isNotEmpty) ...[
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildDetailRow(
                                          'Phone', order!.customerPhone)),
                                  IconButton(
                                    icon:
                                        Icon(Icons.phone, color: Colors.green),
                                    onPressed: () => _callCustomer(
                                        order!.customerPhone,
                                        order!.customerName),
                                  ),
                                ],
                              ),
                            ],
                            _buildDetailRow(
                                'Payment Method', order!.paymentMethod),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Complete Order Items
                      _buildDetailSection(
                        'Order Items (${order!.items.length})',
                        Icons.restaurant_menu,
                        Column(
                          children: order!.items
                              .map((item) => Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        // Food Image placeholder
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: EatoTheme.warningColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.fastfood,
                                            color: EatoTheme.warningColor,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.foodName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (item.variation != null) ...[
                                                SizedBox(height: 4),
                                                Text(
                                                  'Variation: ${item.variation}',
                                                  style: TextStyle(
                                                    color: EatoTheme
                                                        .textSecondaryColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                              if (item.specialInstructions !=
                                                      null &&
                                                  item.specialInstructions!
                                                      .isNotEmpty) ...[
                                                SizedBox(height: 4),
                                                Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Note: ${item.specialInstructions}',
                                                    style: TextStyle(
                                                      color: Colors.amber[700],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Rs. ${item.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: EatoTheme
                                                          .textSecondaryColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    ' × ${item.quantity}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Text(
                                                    'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: EatoTheme
                                                          .warningColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Order Summary
                      _buildDetailSection(
                        'Order Summary',
                        Icons.receipt,
                        Column(
                          children: [
                            _buildSummaryRow('Subtotal', order!.subtotal),
                            if (order!.deliveryFee > 0)
                              _buildSummaryRow(
                                  'Delivery Fee', order!.deliveryFee),
                            if (order!.serviceFee > 0)
                              _buildSummaryRow(
                                  'Service Fee', order!.serviceFee),
                            Divider(height: 24),
                            _buildSummaryRow('Total Amount', order!.totalAmount,
                                isTotal: true),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Delivery Information
                      if (order!.deliveryOption == 'Delivery') ...[
                        _buildDetailSection(
                          'Delivery Information',
                          Icons.location_on,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildDetailRow(
                                          'Address', order!.deliveryAddress)),
                                  if (order!.deliveryAddress.isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.directions,
                                          color: Colors.blue),
                                      onPressed: () => _openDirections(
                                          order!.deliveryAddress),
                                    ),
                                ],
                              ),
                              if (order!.scheduledTime != null)
                                _buildDetailRow(
                                    'Scheduled Time',
                                    DateFormat('MMM dd, yyyy • h:mm a')
                                        .format(order!.scheduledTime!)),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Special Instructions
                      if (order!.specialInstructions != null &&
                          order!.specialInstructions!.isNotEmpty) ...[
                        _buildDetailSection(
                          'Special Instructions',
                          Icons.note_outlined,
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Text(
                              order!.specialInstructions!,
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Action Buttons at the bottom
                      _buildDetailSection(
                        'Request Actions',
                        Icons.pending_actions,
                        Column(
                          children: [
                            // Accept Button
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 12),
                              child: ElevatedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(modalContext);
                                        onAccept();
                                      },
                                icon: isLoading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.check),
                                label: Text(isLoading
                                    ? 'Processing...'
                                    : 'Accept Request'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EatoTheme.successColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            // Decline Button
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 12),
                              child: OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(modalContext);
                                        onDecline();
                                      },
                                icon: Icon(Icons.close),
                                label: Text('Decline Request'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: EatoTheme.errorColor,
                                  side: BorderSide(color: EatoTheme.errorColor),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            // Contact & Directions row
                            if (order!.customerPhone.isNotEmpty ||
                                (order!.deliveryOption == 'Delivery' &&
                                    order!.deliveryAddress.isNotEmpty)) ...[
                              Row(
                                children: [
                                  if (order!.customerPhone.isNotEmpty)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _callCustomer(
                                            order!.customerPhone,
                                            order!.customerName),
                                        icon: Icon(Icons.phone),
                                        label: Text('Call Customer'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green,
                                          side: BorderSide(color: Colors.green),
                                        ),
                                      ),
                                    ),
                                  if (order!.customerPhone.isNotEmpty &&
                                      order!.deliveryOption == 'Delivery' &&
                                      order!.deliveryAddress.isNotEmpty)
                                    SizedBox(width: 12),
                                  if (order!.deliveryOption == 'Delivery' &&
                                      order!.deliveryAddress.isNotEmpty)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openDirections(
                                            order!.deliveryAddress),
                                        icon: Icon(Icons.directions),
                                        label: Text('Get Directions'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          side: BorderSide(color: Colors.blue),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: EatoTheme.warningColor, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: EatoTheme.warningColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: EatoTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
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
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : EatoTheme.textSecondaryColor,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? EatoTheme.warningColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    Color? borderColor,
    double height = 36,
    bool isLoading = false,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: backgroundColor == Colors.transparent ? 0 : 2,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: textColor),
              ),
              SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, size: 16),
              SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
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
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  String _getDisplayOrderNumber() {
    // Use the order's orderNumber if available and not empty
    if (order != null && order!.orderNumber.isNotEmpty) {
      // If orderNumber is different from the order ID, use it directly
      if (order!.orderNumber != order!.id) {
        return order!.orderNumber;
      }
      // If orderNumber is just numbers (timestamp fallback), format it nicely
      if (RegExp(r'^\d+$').hasMatch(order!.orderNumber)) {
        return '#${order!.orderNumber}';
      }
      return order!.orderNumber;
    }

    // Final fallback to truncated request ID
    return '#${request.id.substring(0, 8).toUpperCase()}';
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Future<void> _openDirections(String address) async {
    try {
      final Uri mapsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}');
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri);
      } else {
        await Clipboard.setData(ClipboardData(text: address));
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: address));
    }
  }

  Future<void> _callCustomer(String phoneNumber, String customerName) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await Clipboard.setData(ClipboardData(text: phoneNumber));
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
    }
  }
}
