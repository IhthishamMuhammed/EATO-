import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/widgets/OrderStatusWidget.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/EatoComponents.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerOrderCard extends StatelessWidget {
  final CustomerOrder order;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;
  final bool canCancel;

  const CustomerOrderCard({
    Key? key,
    required this.order,
    this.onViewDetails,
    this.onCancel,
    this.canCancel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EatoTheme.primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EatoTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section - Restaurant info with order number
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: EatoTheme.primaryColor.withOpacity(0.03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
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
                        order.storeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: EatoTheme.textPrimaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Order #${_getDisplayOrderNumber()}',
                        style: TextStyle(
                          color: EatoTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OrderStatusWidget(
                      status: order.status,
                      showAnimation: _isActiveStatus(order.status),
                    ),
                    SizedBox(height: 2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: EatoTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Section - Items and details
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order items in a more compact layout
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_outlined,
                              size: 14, color: EatoTheme.primaryColor),
                          SizedBox(width: 4),
                          Text(
                            '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: EatoTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                          Spacer(),
                          Text(
                            DateFormat('MMM dd • hh:mm a')
                                .format(order.orderTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      // Items list with minimal spacing
                      ...order.items.take(2).map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color:
                                        EatoTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: EatoTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.foodName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: EatoTheme.textSecondaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (order.items.length > 2)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            '+${order.items.length - 2} more items',
                            style: TextStyle(
                              fontSize: 11,
                              color: EatoTheme.primaryColor,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Contact and action row combined
                Row(
                  children: [
                    // Contact info (if available)
                    Expanded(
                      child: _buildCompactContactSection(),
                    ),
                    SizedBox(width: 8),
                    // Action buttons
                    _buildActionButtons(context),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12),
        ],
      ),
    );
  }

  String _getDisplayOrderNumber() {
    if (order.orderNumber.isNotEmpty &&
        order.orderNumber.contains('-') &&
        order.orderNumber.length >= 11) {
      return order.orderNumber;
    }
    return order.id.substring(0, 8).toUpperCase();
  }

  bool _isActiveStatus(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready ||
        status == OrderStatus.onTheWay;
  }

  Widget _buildCompactContactSection() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 32,
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: EatoTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 10,
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final storeData = snapshot.data!.data() as Map<String, dynamic>?;
        final contact = storeData?['contact']?.toString() ?? '';

        if (contact.isEmpty) {
          return SizedBox(height: 32);
        }

        return GestureDetector(
          onTap: () => _callStore(context, contact, order.storeName),
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: EatoTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EatoTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone, color: EatoTheme.primaryColor, size: 14),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    contact,
                    style: TextStyle(
                      fontSize: 11,
                      color: EatoTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canCancel) ...[
          Container(
            height: 32,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade300),
                padding: EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size(60, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
          SizedBox(width: 6),
        ] else if (order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.onTheWay) ...[
          Container(
            height: 32,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
                padding: EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size(70, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Can\'t Cancel',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
          SizedBox(width: 6),
        ],
        Container(
          height: 32,
          child: ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size(80, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, size: 12),
                SizedBox(width: 4),
                Text(
                  'Details',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _callStore(
      BuildContext context, String phoneNumber, String storeName) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number copied: $phoneNumber'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error launching phone call: $e');
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number copied: $phoneNumber'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
