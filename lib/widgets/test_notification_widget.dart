// FILE: lib/widgets/test_notification_widget.dart
// Add this widget to any page for testing notifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/order_notification_service.dart';
import '../Provider/userProvider.dart';
import '../Provider/OrderProvider.dart';

class TestNotificationWidget extends StatefulWidget {
  const TestNotificationWidget({Key? key}) : super(key: key);

  @override
  State<TestNotificationWidget> createState() => _TestNotificationWidgetState();
}

class _TestNotificationWidgetState extends State<TestNotificationWidget> {
  bool _isTestingNotifications = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  void _loadFCMToken() {
    setState(() {
      _fcmToken = NotificationService.getCurrentToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Notification Testing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // FCM Token Display
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FCM Token Status:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  _fcmToken != null ? '✅ Token Available' : '❌ No Token',
                  style: TextStyle(
                    color: _fcmToken != null ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                if (_fcmToken != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Token: ${_fcmToken!.substring(0, 50)}...',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16),

          // Test Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Test Basic Notification
              ElevatedButton.icon(
                onPressed: userProvider.currentUser != null &&
                        !_isTestingNotifications
                    ? () => _sendTestNotification(userProvider.currentUser!.id)
                    : null,
                icon: Icon(Icons.notifications, size: 16),
                label: Text('Test Basic', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              // Test Order Notification
              ElevatedButton.icon(
                onPressed: userProvider.currentUser != null &&
                        !_isTestingNotifications
                    ? () =>
                        _sendTestOrderNotification(userProvider.currentUser!.id)
                    : null,
                icon: Icon(Icons.restaurant, size: 16),
                label: Text('Test Order', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              // Refresh Token
              ElevatedButton.icon(
                onPressed: _refreshToken,
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Refresh', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              // Fix Stores Button
              ElevatedButton.icon(
                onPressed: !_isTestingNotifications
                    ? () => _fixAllStores(orderProvider)
                    : null,
                icon: Icon(Icons.build, size: 16),
                label: Text('Fix Stores', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),

          if (_isTestingNotifications) ...[
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Testing...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],

          SizedBox(height: 12),
          Text(
            'Note: Notifications require user to be logged in and Cloud Functions to be deployed.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(String userId) async {
    setState(() => _isTestingNotifications = true);

    try {
      final success = await OrderNotificationService.sendTestNotification(
        userId,
        'Hello from Eato! 🍕 This is a test notification to verify your notification system is working correctly.',
      );

      _showResultSnackBar(
        success ? '✅ Test notification sent!' : '❌ Failed to send notification',
        success ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showResultSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isTestingNotifications = false);
    }
  }

  Future<void> _sendTestOrderNotification(String userId) async {
    setState(() => _isTestingNotifications = true);

    try {
      // Create a fake order notification
      await OrderNotificationService.sendOrderStatusUpdate(
        orderId: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
        customerId: userId,
        newStatus: 'confirmed',
        storeName: 'Test Restaurant',
        estimatedTime: '15-20 minutes',
      );

      _showResultSnackBar('✅ Test order notification sent!', Colors.green);
    } catch (e) {
      _showResultSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isTestingNotifications = false);
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isTestingNotifications = true);

    try {
      // Re-initialize notification service
      await NotificationService.initialize();
      _loadFCMToken();
      _showResultSnackBar('✅ Token refreshed!', Colors.green);
    } catch (e) {
      _showResultSnackBar('❌ Error refreshing token: $e', Colors.red);
    } finally {
      setState(() => _isTestingNotifications = false);
    }
  }

  Future<void> _fixAllStores(OrderProvider orderProvider) async {
    setState(() => _isTestingNotifications = true);

    try {
      await orderProvider.fixAllStoresOwnerUid();
      _showResultSnackBar(
          '✅ All stores fixed! Notifications should work now.', Colors.green);
    } catch (e) {
      _showResultSnackBar('❌ Error fixing stores: $e', Colors.red);
    } finally {
      setState(() => _isTestingNotifications = false);
    }
  }

  void _showResultSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
