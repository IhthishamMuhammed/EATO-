import 'package:flutter/material.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class CompactFoodSummaryCard extends StatefulWidget {
  final List<OrderRequest> requests;
  final List<CustomerOrder> orders;

  const CompactFoodSummaryCard({
    Key? key,
    required this.requests,
    required this.orders,
  }) : super(key: key);

  @override
  State<CompactFoodSummaryCard> createState() => _CompactFoodSummaryCardState();
}

class _CompactFoodSummaryCardState extends State<CompactFoodSummaryCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final foodSummary = _calculateFoodSummary();

    if (foodSummary.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EatoTheme.primaryColor.withOpacity(0.05),
              EatoTheme.primaryColor.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 🎯 COMPACT HEADER (Always visible)
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: EatoTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.summarize,
                        color: EatoTheme.primaryColor,
                        size: 16,
                      ),
                    ),

                    SizedBox(width: 12),

                    // Title & stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Food Summary',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: EatoTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              _buildQuickStat('${foodSummary.length}', 'Items'),
                              SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 12,
                                color: EatoTheme.textSecondaryColor
                                    .withOpacity(0.3),
                              ),
                              SizedBox(width: 8),
                              _buildQuickStat(
                                  '${_getTotalItemsCount()}', 'Qty'),
                              SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 12,
                                color: EatoTheme.textSecondaryColor
                                    .withOpacity(0.3),
                              ),
                              SizedBox(width: 8),
                              _buildQuickStat(
                                  '${widget.orders.length}', 'Orders'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expand/Collapse indicator
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: EatoTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 📋 EXPANDABLE DETAILED LIST
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: _expandAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: EatoTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Food Item',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: EatoTheme.textPrimaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: EatoTheme.textPrimaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Orders',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: EatoTheme.textPrimaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 12, color: Colors.grey[300]),

                      // Food items (compact version)
                      ...foodSummary.entries.map((entry) {
                        final foodName = entry.key;
                        final data = entry.value;
                        final totalQuantity = data['quantity'] as int;
                        final orderCount = data['orderCount'] as int;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              // Food name (more compact)
                              Expanded(
                                flex: 3,
                                child: Text(
                                  foodName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: EatoTheme.textPrimaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Total quantity
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        EatoTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$totalQuantity',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: EatoTheme.primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),

                              // Order count
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: orderCount > 1
                                        ? EatoTheme.warningColor
                                            .withOpacity(0.1)
                                        : EatoTheme.successColor
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$orderCount',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: orderCount > 1
                                          ? EatoTheme.warningColor
                                          : EatoTheme.successColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: EatoTheme.primaryColor,
          ),
        ),
        SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Map<String, Map<String, dynamic>> _calculateFoodSummary() {
    Map<String, Map<String, dynamic>> summary = {};

    for (var order in widget.orders) {
      for (var item in order.items) {
        final key = item.foodName;

        if (summary.containsKey(key)) {
          summary[key]!['quantity'] =
              (summary[key]!['quantity'] as int) + item.quantity;
          summary[key]!['orderCount'] =
              (summary[key]!['orderCount'] as int) + 1;

          // Add variations
          if (item.variation != null && item.variation!.isNotEmpty) {
            (summary[key]!['variations'] as Set<String>).add(item.variation!);
          }
        } else {
          summary[key] = {
            'quantity': item.quantity,
            'orderCount': 1,
            'variations': item.variation != null && item.variation!.isNotEmpty
                ? <String>{item.variation!}
                : <String>{},
          };
        }
      }
    }

    // Sort by quantity (descending)
    var sortedEntries = summary.entries.toList()
      ..sort((a, b) =>
          (b.value['quantity'] as int).compareTo(a.value['quantity'] as int));

    return Map.fromEntries(sortedEntries);
  }

  int _getTotalItemsCount() {
    return widget.orders.fold(
        0,
        (total, order) =>
            total + order.items.fold(0, (sum, item) => sum + item.quantity));
  }
}
