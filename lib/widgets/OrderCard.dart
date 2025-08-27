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

  // ADD THESE - This is what's missing in your original
  final Function(String orderId, OrderStatus newStatus)? onStatusUpdate;
  final bool isUpdating;

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.actionButtons,
    this.showProgress = false,
    this.isProviderView = false,
    // These are the key additions:
    this.onStatusUpdate,
    this.isUpdating = false,
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
            _buildOrderHeader(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderItems(),
                  SizedBox(height: 8),
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    _buildSpecialInstructions(),
                    SizedBox(height: 8),
                  ],
                  _buildTotalAmount(),
                ],
              ),
            ),
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
          Icon(Icons.receipt_outlined, size: 16, color: EatoTheme.primaryColor),
          SizedBox(width: 6),
          Text(
            'Order ${_getDisplayOrderNumber()}',
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
              Icon(Icons.restaurant_menu,
                  size: 16, color: EatoTheme.primaryColor),
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
              style: TextStyle(color: Colors.amber[700], fontSize: 12),
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
          if (showProgress) ...[
            Row(
              children: [
                // THE FIX: Proper update button
                Expanded(child: _buildUpdateButton()),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCustomButton(
                    text: 'View Details',
                    onPressed: () => _showOrderDetails(context),
                    icon: Icons.visibility_outlined,
                    backgroundColor: Colors.transparent,
                    textColor: EatoTheme.primaryColor,
                    borderColor: EatoTheme.primaryColor,
                    height: 40,
                  ),
                ),
                if (isProviderView) ...[
                  SizedBox(width: 8),
                  if (order.customerPhone.isNotEmpty)
                    _buildCompactActionButton(
                      context: context,
                      icon: Icons.phone,
                      onPressed: () => _callCustomer(
                          context, order.customerPhone, order.customerName),
                      color: Colors.green,
                    ),
                  if (order.customerPhone.isNotEmpty &&
                      order.deliveryOption == 'Delivery' &&
                      order.deliveryAddress.isNotEmpty)
                    SizedBox(width: 6),
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
            Row(
              children: [
                Expanded(
                  child: _buildCustomButton(
                    text: 'View Details',
                    onPressed: () => _showOrderDetails(context),
                    icon: Icons.visibility_outlined,
                    backgroundColor: Colors.transparent,
                    textColor: EatoTheme.primaryColor,
                    borderColor: EatoTheme.primaryColor,
                    height: 40,
                  ),
                ),
                if (isProviderView) ...[
                  SizedBox(width: 8),
                  if (order.customerPhone.isNotEmpty)
                    _buildCompactActionButton(
                      context: context,
                      icon: Icons.phone,
                      onPressed: () => _callCustomer(
                          context, order.customerPhone, order.customerName),
                      color: Colors.green,
                    ),
                  if (order.customerPhone.isNotEmpty &&
                      order.deliveryOption == 'Delivery' &&
                      order.deliveryAddress.isNotEmpty)
                    SizedBox(width: 6),
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

  // THE MAIN FIX: Proper update button that actually works
  Widget _buildUpdateButton() {
    if (_isOrderCompleted(order.status)) {
      return SizedBox.shrink();
    }

    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    OrderStatus? nextStatus;

    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        buttonText = 'Start Preparing';
        buttonIcon = Icons.restaurant;
        buttonColor = EatoTheme.primaryColor;
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        buttonText = 'Mark Ready';
        buttonIcon = Icons.check_circle_outline;
        buttonColor = EatoTheme.infoColor;
        nextStatus = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        if (order.deliveryOption == 'Pickup') {
          buttonText = 'Mark Picked Up';
          buttonIcon = Icons.check;
          buttonColor = EatoTheme.successColor;
          nextStatus = OrderStatus.delivered;
        } else {
          buttonText = 'Out for Delivery';
          buttonIcon = Icons.directions_bike;
          buttonColor = Colors.indigo;
          nextStatus = OrderStatus.onTheWay;
        }
        break;
      case OrderStatus.onTheWay:
        buttonText = 'Mark Delivered';
        buttonIcon = Icons.check;
        buttonColor = EatoTheme.successColor;
        nextStatus = OrderStatus.delivered;
        break;
      default:
        return SizedBox.shrink();
    }

    return _buildCustomButton(
      text: isUpdating ? 'Updating...' : buttonText,
      onPressed: isUpdating || nextStatus == null
          ? null
          : () {
              print('🔥 OrderCard: Updating order ${order.id} to $nextStatus');
              onStatusUpdate?.call(order.id, nextStatus!);
            },
      icon: isUpdating ? null : buttonIcon,
      backgroundColor: buttonColor,
      textColor: Colors.white,
      height: 40,
      isLoading: isUpdating,
    );
  }

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
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  // FIXED: Show complete order details in modal
  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
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
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: EatoTheme.primaryColor,
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
              // COMPLETE ORDER DETAILS CONTENT
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header Section
                      _buildDetailSection(
                        'Order Information',
                        Icons.receipt_long,
                        Column(
                          children: [
                            _buildDetailRow(
                                'Order ID', _getDisplayOrderNumber()),
                            _buildDetailRow(
                                'Order Time',
                                DateFormat('MMM dd, yyyy • h:mm a')
                                    .format(order.orderTime)),
                            _buildDetailRow(
                                'Status',
                                order.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase()),
                            _buildDetailRow('Store', order.storeName),
                            _buildDetailRow(
                                'Delivery Method', order.deliveryOption),
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
                            _buildDetailRow('Name', order.customerName),
                            if (order.customerPhone.isNotEmpty) ...[
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildDetailRow(
                                          'Phone', order.customerPhone)),
                                  if (isProviderView)
                                    IconButton(
                                      icon: Icon(Icons.phone,
                                          color: Colors.green),
                                      onPressed: () => _callCustomer(
                                          modalContext,
                                          order.customerPhone,
                                          order.customerName),
                                    ),
                                ],
                              ),
                            ],
                            _buildDetailRow(
                                'Payment Method', order.paymentMethod),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Complete Order Items
                      _buildDetailSection(
                        'Order Items (${order.items.length})',
                        Icons.restaurant_menu,
                        Column(
                          children: order.items
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
                                            color: EatoTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.fastfood,
                                            color: EatoTheme.primaryColor,
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
                                                          .primaryColor,
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
                            _buildSummaryRow('Subtotal', order.subtotal),
                            if (order.deliveryFee > 0)
                              _buildSummaryRow(
                                  'Delivery Fee', order.deliveryFee),
                            if (order.serviceFee > 0)
                              _buildSummaryRow('Service Fee', order.serviceFee),
                            Divider(height: 24),
                            _buildSummaryRow('Total Amount', order.totalAmount,
                                isTotal: true),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Delivery Information
                      if (order.deliveryOption == 'Delivery') ...[
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
                                          'Address', order.deliveryAddress)),
                                  if (isProviderView &&
                                      order.deliveryAddress.isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.directions,
                                          color: Colors.blue),
                                      onPressed: () => _openDirections(
                                          modalContext, order.deliveryAddress),
                                    ),
                                ],
                              ),
                              if (order.scheduledTime != null)
                                _buildDetailRow(
                                    'Scheduled Time',
                                    DateFormat('MMM dd, yyyy • h:mm a')
                                        .format(order.scheduledTime!)),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Special Instructions
                      if (order.specialInstructions != null &&
                          order.specialInstructions!.isNotEmpty) ...[
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
                              order.specialInstructions!,
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Order Timeline
                      _buildDetailSection(
                        'Order Timeline',
                        Icons.timeline,
                        Column(
                          children: [
                            _buildTimelineItem(
                                'Order Placed', order.orderTime, true),
                            if (order.confirmedTime != null)
                              _buildTimelineItem('Order Confirmed',
                                  order.confirmedTime!, true),
                            if (order.readyTime != null)
                              _buildTimelineItem(
                                  'Order Ready', order.readyTime!, true),
                            if (order.deliveredTime != null)
                              _buildTimelineItem(
                                order.deliveryOption == "Pickup"
                                    ? "Order Picked Up"
                                    : "Order Delivered",
                                order.deliveredTime!,
                                true,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Action Buttons for Provider View
                      if (isProviderView &&
                          !_isOrderCompleted(order.status)) ...[
                        _buildDetailSection(
                          'Order Actions',
                          Icons.settings,
                          Column(
                            children: _getDetailActionButtons(modalContext),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
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
                Icon(icon, color: EatoTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: EatoTheme.primaryColor,
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
              color: isTotal ? EatoTheme.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime time, bool isCompleted) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
                  isCompleted ? EatoTheme.successColor : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('MMM dd • h:mm a').format(time),
                  style: TextStyle(
                    color: EatoTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getDetailActionButtons(BuildContext context) {
    List<Widget> buttons = [];

    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        buttons.add(_buildDetailActionButton(
          context,
          'Start Preparing',
          Icons.restaurant,
          EatoTheme.primaryColor,
          OrderStatus.preparing,
        ));
        break;
      case OrderStatus.preparing:
        buttons.add(_buildDetailActionButton(
          context,
          'Mark as Ready',
          Icons.check_circle_outline,
          Colors.blue,
          OrderStatus.ready,
        ));
        break;
      case OrderStatus.ready:
        if (order.deliveryOption == 'Pickup') {
          buttons.add(_buildDetailActionButton(
            context,
            'Mark as Picked Up',
            Icons.check,
            EatoTheme.successColor,
            OrderStatus.delivered,
          ));
        } else {
          buttons.add(_buildDetailActionButton(
            context,
            'Out for Delivery',
            Icons.directions_bike,
            Colors.indigo,
            OrderStatus.onTheWay,
          ));
        }
        break;
      case OrderStatus.onTheWay:
        buttons.add(_buildDetailActionButton(
          context,
          'Mark as Delivered',
          Icons.check,
          EatoTheme.successColor,
          OrderStatus.delivered,
        ));
        break;
      default:
        break;
    }

    // Add contact buttons
    if (order.customerPhone.isNotEmpty ||
        (order.deliveryOption == 'Delivery' &&
            order.deliveryAddress.isNotEmpty)) {
      buttons.add(SizedBox(height: 12));

      Row contactButtons = Row(
        children: [
          if (order.customerPhone.isNotEmpty)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callCustomer(
                    context, order.customerPhone, order.customerName),
                icon: Icon(Icons.phone),
                label: Text('Call Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (order.customerPhone.isNotEmpty &&
              order.deliveryOption == 'Delivery' &&
              order.deliveryAddress.isNotEmpty)
            SizedBox(width: 12),
          if (order.deliveryOption == 'Delivery' &&
              order.deliveryAddress.isNotEmpty)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openDirections(context, order.deliveryAddress),
                icon: Icon(Icons.directions),
                label: Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      );

      buttons.add(contactButtons);
    }

    return buttons;
  }

  Widget _buildDetailActionButton(BuildContext context, String title,
      IconData icon, Color color, OrderStatus status) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: isUpdating
            ? null
            : () {
                Navigator.pop(context); // Close modal first
                onStatusUpdate?.call(order.id, status);
              },
        icon: isUpdating
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(isUpdating ? 'Updating...' : title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
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

  String _getDisplayOrderNumber() {
    // First, try to use the orderNumber field
    if (order.orderNumber.isNotEmpty && order.orderNumber != order.id) {
      return order.orderNumber;
    }

    // If orderNumber is empty or same as ID, check if it's a timestamp fallback
    if (order.orderNumber.isNotEmpty) {
      // If it's a pure number (timestamp fallback), format it nicely
      if (RegExp(r'^\d+$').hasMatch(order.orderNumber)) {
        return '#${order.orderNumber}';
      }
      return order.orderNumber;
    }

    // Final fallback to truncated ID
    return '#${order.id.substring(0, 8).toUpperCase()}';
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  bool _isOrderCompleted(OrderStatus status) {
    return status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.rejected;
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
    }
  }
}
