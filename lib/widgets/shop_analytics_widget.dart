// File: lib/widgets/shop_analytics_widget.dart

import 'package:flutter/material.dart';
import 'package:eato/services/firebase_subscription_service.dart';

class ShopAnalyticsWidget extends StatefulWidget {
  final String shopId;
  final bool showDetailed;
  final EdgeInsets? padding;

  const ShopAnalyticsWidget({
    Key? key,
    required this.shopId,
    this.showDetailed = false,
    this.padding,
  }) : super(key: key);

  @override
  State<ShopAnalyticsWidget> createState() => _ShopAnalyticsWidgetState();
}

class _ShopAnalyticsWidgetState extends State<ShopAnalyticsWidget> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics =
          await FirebaseSubscriptionService.getShopAnalytics(widget.shopId);

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [ShopAnalyticsWidget] Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load analytics';
          _isLoading = false;
        });
      }
    }
  }

  String _getSubscriberText(int count) {
    if (count == 0) return 'No subscribers yet';
    if (count == 1) return '1 subscriber';
    if (count < 1000) return '$count subscribers';
    if (count < 1000000)
      return '${(count / 1000).toStringAsFixed(1)}K subscribers';
    return '${(count / 1000000).toStringAsFixed(1)}M subscribers';
  }

  Color _getSubscriberColor(int count) {
    if (count == 0) return Colors.grey;
    if (count < 10) return Colors.orange;
    if (count < 50) return Colors.blue;
    if (count < 100) return Colors.green;
    return Colors.purple;
  }

  IconData _getSubscriberIcon(int count) {
    if (count == 0) return Icons.people_outline;
    if (count < 10) return Icons.people;
    if (count < 50) return Icons.groups;
    return Icons.groups_rounded;
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showDetailed) {
      return _buildDetailedAnalytics();
    } else {
      return _buildCompactAnalytics();
    }
  }

  Widget _buildCompactAnalytics() {
    return Container(
      padding: widget.padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : Row(
                  children: [
                    // Subscriber count
                    Expanded(
                      child: _buildMetricCard(
                        icon: _getSubscriberIcon(
                            _analytics['subscriberCount'] ?? 0),
                        iconColor: _getSubscriberColor(
                            _analytics['subscriberCount'] ?? 0),
                        title: 'Subscribers',
                        value: _getSubscriberText(
                            _analytics['subscriberCount'] ?? 0),
                        isCompact: true,
                      ),
                    ),

                    SizedBox(width: 16),

                    // Rating
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.star,
                        iconColor: _getRatingColor(_analytics['rating'] ?? 0.0),
                        title: 'Rating',
                        value:
                            '${(_analytics['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                        isCompact: true,
                      ),
                    ),

                    SizedBox(width: 12),

                    // Refresh button
                    IconButton(
                      onPressed: _loadAnalytics,
                      icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
    );
  }

  Widget _buildDetailedAnalytics() {
    return Container(
      padding: widget.padding ?? EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                'Shop Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              if (!_isLoading)
                IconButton(
                  onPressed: _loadAnalytics,
                  icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                  tooltip: 'Refresh Analytics',
                ),
            ],
          ),

          SizedBox(height: 16),

          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else ...[
            // Shop name
            Text(
              _analytics['shopName'] ?? 'Your Shop',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 20),

            // Metrics row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon:
                        _getSubscriberIcon(_analytics['subscriberCount'] ?? 0),
                    iconColor:
                        _getSubscriberColor(_analytics['subscriberCount'] ?? 0),
                    title: 'Total Subscribers',
                    value: '${_analytics['subscriberCount'] ?? 0}',
                    subtitle:
                        _getSubscriberText(_analytics['subscriberCount'] ?? 0),
                    isCompact: false,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.star,
                    iconColor: _getRatingColor(_analytics['rating'] ?? 0.0),
                    title: 'Shop Rating',
                    value:
                        '${(_analytics['rating'] ?? 0.0).toStringAsFixed(1)}',
                    subtitle:
                        _getRatingDescription(_analytics['rating'] ?? 0.0),
                    isCompact: false,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Insights
            _buildInsights(),

            SizedBox(height: 16),

            // Last updated
            Text(
              'Last updated: ${_formatTime(_analytics['lastUpdated'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: isCompact ? 20 : 24),
              if (!isCompact) ...[
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isCompact) ...[
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 16 : 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          if (subtitle != null && !isCompact) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final subscriberCount = _analytics['subscriberCount'] ?? 0;
    final rating = _analytics['rating'] ?? 0.0;

    List<Map<String, dynamic>> insights = [];

    // Subscriber insights
    if (subscriberCount == 0) {
      insights.add({
        'icon': Icons.lightbulb_outline,
        'color': Colors.blue,
        'title': 'Get your first subscribers',
        'description':
            'Add attractive photos and descriptions to your menu items to attract customers.',
      });
    } else if (subscriberCount < 10) {
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.green,
        'title': 'Growing subscriber base',
        'description':
            'You\'re building momentum! Keep adding quality food items and maintain good service.',
      });
    } else if (subscriberCount >= 50) {
      insights.add({
        'icon': Icons.celebration,
        'color': Colors.purple,
        'title': 'Popular restaurant!',
        'description':
            'Great job! Your restaurant is attracting many subscribers. Keep up the excellent work!',
      });
    }

    // Rating insights
    if (rating < 3.0 && rating > 0) {
      insights.add({
        'icon': Icons.warning_amber,
        'color': Colors.orange,
        'title': 'Improve service quality',
        'description':
            'Focus on food quality, delivery time, and customer service to boost your rating.',
      });
    } else if (rating >= 4.5) {
      insights.add({
        'icon': Icons.star,
        'color': Colors.amber,
        'title': 'Excellent rating!',
        'description':
            'Your customers love your service! This high rating will attract more subscribers.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.info_outline,
        'color': Colors.grey,
        'title': 'Keep improving',
        'description':
            'Continue providing great food and service to grow your subscriber base.',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        ...insights.map((insight) => _buildInsightCard(insight)).toList(),
      ],
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            insight['icon'],
            color: insight['color'],
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  insight['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 12),
            Text(
              'Loading analytics...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(height: 12),
            Text(
              _error ?? 'Failed to load analytics',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Average';
    if (rating > 0) return 'Needs Improvement';
    return 'No ratings yet';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${time.day}/${time.month}/${time.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// ===============================================
// REAL-TIME ANALYTICS WIDGET (with Stream)
// ===============================================

class RealTimeShopAnalytics extends StatelessWidget {
  final String shopId;
  final bool showDetailed;

  const RealTimeShopAnalytics({
    Key? key,
    required this.shopId,
    this.showDetailed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirebaseSubscriptionService.getShopAnalyticsStream(shopId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(height: 8),
                Text('Error loading real-time analytics'),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild
                    (context as Element).markNeedsBuild();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: Colors.purple),
            ),
          );
        }

        final analytics = snapshot.data!;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Live Analytics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLiveMetric(
                      'Subscribers',
                      '${analytics['subscriberCount'] ?? 0}',
                      Icons.people,
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildLiveMetric(
                      'Rating',
                      '${(analytics['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMetric(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
