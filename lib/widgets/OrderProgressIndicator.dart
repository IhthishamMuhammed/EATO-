// FILE: lib/widgets/OrderProgressIndicator.dart
// FIXED VERSION - Complete and working implementation

import 'package:flutter/material.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class OrderProgressIndicator extends StatelessWidget {
  final OrderStatus currentStatus;
  final bool isVertical;

  const OrderProgressIndicator({
    Key? key,
    required this.currentStatus,
    this.isVertical = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
    ];

    final currentIndex = steps.indexOf(currentStatus);

    if (isVertical) {
      return _buildVerticalProgress(steps, currentIndex);
    } else {
      return _buildHorizontalProgress(steps, currentIndex);
    }
  }

  Widget _buildHorizontalProgress(List<OrderStatus> steps, int currentIndex) {
    return Column(
      children: [
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          isActive ? EatoTheme.primaryColor : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: EatoTheme.primaryColor, width: 2)
                          : null,
                    ),
                    child: isActive
                        ? Icon(Icons.check, size: 8, color: Colors.white)
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isActive
                            ? EatoTheme.primaryColor
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((step) {
            return Expanded(
              child: Text(
                _getStepLabel(step),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVerticalProgress(List<OrderStatus> steps, int currentIndex) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isActive ? EatoTheme.primaryColor : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: EatoTheme.primaryColor, width: 2)
                        : null,
                  ),
                  child: isActive
                      ? Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStepLabel(step),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isActive ? EatoTheme.primaryColor : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (index < steps.length - 1)
              Container(
                margin: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                width: 2,
                height: 20,
                color: isActive ? EatoTheme.primaryColor : Colors.grey[300],
              ),
          ],
        );
      }).toList(),
    );
  }

  String _getStepLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Ordered';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return '';
    }
  }
}
