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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
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
                Icon(Icons.notifications_active,
                    color: EatoTheme.primaryColor, size: 16),
                SizedBox(width: 6),
                Text(
                  'New Order Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: EatoTheme.primaryColor,
                    fontSize: 13,
                  ),
                ),
                Spacer(),
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order items list
                  Container(
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
                              'Items (${order!.items.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: EatoTheme.primaryColor,
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
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: EatoTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                        SizedBox(height: 8),
                        Divider(height: 16),
                        Row(
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
                              'Rs. ${order!.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: EatoTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Accept/Decline buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onDecline,
                          child: Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EatoTheme.errorColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
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
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // View Details button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      child: Text('View Details'),
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
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: CircularProgressIndicator(color: EatoTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
