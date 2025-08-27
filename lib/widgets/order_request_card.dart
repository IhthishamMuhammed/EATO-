import 'package:flutter/material.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/pages/theme/eato_theme.dart';

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


  String _getPaymentIcon(String paymentMethod) {
    if (paymentMethod.toLowerCase().contains('cash')) {
      return '💵';
    } else if (paymentMethod.toLowerCase().contains('card')) {
      return '💳';
    }
    return '💰';
  }

  Color _getPaymentColor(String paymentMethod) {
    if (paymentMethod.toLowerCase().contains('cash')) {
      return Colors.green;
    } else if (paymentMethod.toLowerCase().contains('card')) {
      return Colors.blue;
    }
    return EatoTheme.primaryColor;
  }

  String _getDeliveryIcon(String deliveryOption) {
    if (deliveryOption.toLowerCase().contains('delivery')) {
      return '🚗';
    } else if (deliveryOption.toLowerCase().contains('pickup')) {
      return '🏪';
    }
    return '📦';
  }

  Color _getDeliveryColor(String deliveryOption) {
    if (deliveryOption.toLowerCase().contains('delivery')) {
      return Colors.orange;
    } else if (deliveryOption.toLowerCase().contains('pickup')) {
      return EatoTheme.primaryColor;
    }
    return EatoTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: order != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row - Customer & Status
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EatoTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
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
                              order!.customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (order!.customerPhone.isNotEmpty)
                              Text(
                                order!.customerPhone,
                                style: TextStyle(
                                  color: EatoTheme.textSecondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: EatoTheme.warningColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NEW REQUEST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Essential Info Row
                  Row(
                    children: [
                      // Delivery Type
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getDeliveryColor(order!.deliveryOption)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getDeliveryColor(order!.deliveryOption)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getDeliveryIcon(order!.deliveryOption),
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  order!.deliveryOption,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: _getDeliveryColor(
                                        order!.deliveryOption),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Payment Method
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getPaymentColor(order!.paymentMethod)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getPaymentColor(order!.paymentMethod)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getPaymentIcon(order!.paymentMethod),
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  order!.paymentMethod
                                      .replaceAll(' Payment', '')
                                      .replaceAll('on Delivery', ''),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color:
                                        _getPaymentColor(order!.paymentMethod),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Total Amount
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: EatoTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Rs. ${order!.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: EatoTheme.primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Order Summary
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: EatoTheme.textSecondaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${order!.items.length} item${order!.items.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: EatoTheme.textSecondaryColor,
                          ),
                        ),
                        Spacer(),
                        Text(
                          order!.items
                                  .take(2)
                                  .map((item) => item.foodName)
                                  .join(', ') +
                              (order!.items.length > 2 ? '...' : ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: EatoTheme.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Action Buttons

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onDecline,
                          child: Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EatoTheme.errorColor,
                            foregroundColor: Colors.white,

                            padding: EdgeInsets.symmetric(vertical: 10),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onAccept,
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EatoTheme.successColor,
                            foregroundColor: Colors.white,

                            padding: EdgeInsets.symmetric(vertical: 10),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),


                  SizedBox(height: 8),

                  // View Details Button

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onViewDetails,

                      child: Text('View Full Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EatoTheme.primaryColor,
                        side: BorderSide(color: EatoTheme.primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 8),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )

          : Padding(
              padding: const EdgeInsets.all(16.0),

              child: Center(
                child: CircularProgressIndicator(color: EatoTheme.primaryColor),
              ),
            ),


    );
  }
}
