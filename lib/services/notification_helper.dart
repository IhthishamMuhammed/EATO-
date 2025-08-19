// FILE: lib/services/notification_helper.dart
// Complete NotificationHelper service that works with your existing notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===================================================================
  // 🔔 NOTIFICATION UI DATA MANAGEMENT (for customer_home.dart)
  // ===================================================================

  /// Get all notifications for the current user from Firestore
  static Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('⚠️ [NotificationHelper] No authenticated user');
        return [];
      }

      print('🔔 [NotificationHelper] Fetching notifications for user: $userId');

      final notificationsSnapshot = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> notifications = [];

      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        notifications.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'general',
          'isRead': data['isRead'] ?? false,
          'timestamp': data['timestamp'],
          'data': data['data'] ?? {},
          'icon': _getNotificationIcon(data['type']),
          'color': _getNotificationColor(data['type']),
        });
      }

      print(
          '✅ [NotificationHelper] Found ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      print('❌ [NotificationHelper] Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final unreadSnapshot = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final count = unreadSnapshot.docs.length;
      print('🔢 [NotificationHelper] Unread count: $count');
      return count;
    } catch (e) {
      print('❌ [NotificationHelper] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      print(
          '✅ [NotificationHelper] Marking notification as read: $notificationId');

      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      print('✅ [NotificationHelper] Successfully marked as read');
    } catch (e) {
      print('❌ [NotificationHelper] Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      print(
          '📝 [NotificationHelper] Marking all notifications as read for user: $userId');

      final unreadNotifications = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadNotifications.docs.isEmpty) {
        print('ℹ️ [NotificationHelper] No unread notifications found');
        return;
      }

      final batch = _firestore.batch();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print(
          '✅ [NotificationHelper] Marked ${unreadNotifications.docs.length} notifications as read');
    } catch (e) {
      print(
          '❌ [NotificationHelper] Error marking all notifications as read: $e');
    }
  }

  /// Listen to real-time notification updates
  static Stream<List<Map<String, dynamic>>> getNotificationStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('⚠️ [NotificationHelper] No user for notification stream');
      return Stream.value([]);
    }

    print(
        '🔄 [NotificationHelper] Setting up notification stream for user: $userId');

    return _firestore
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      print(
          '📡 [NotificationHelper] Stream update: ${snapshot.docs.length} notifications');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'general',
          'isRead': data['isRead'] ?? false,
          'timestamp': data['timestamp'],
          'data': data['data'] ?? {},
          'icon': _getNotificationIcon(data['type']),
          'color': _getNotificationColor(data['type']),
        };
      }).toList();
    });
  }

  // ===================================================================
  // 🏗️ NOTIFICATION CREATION (integrates with existing push service)
  // ===================================================================

  /// Create a new notification in Firestore (for display in UI)
  static Future<void> createNotificationInFirestore({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print(
          '💾 [NotificationHelper] Creating notification in Firestore for user: $userId');
      print('   Title: $title');
      print('   Type: $type');

      // Save to user_notifications collection (for UI display)
      final notificationRef =
          await _firestore.collection('user_notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
          '✅ [NotificationHelper] Created notification in Firestore: ${notificationRef.id}');
    } catch (e) {
      print(
          '❌ [NotificationHelper] Error creating notification in Firestore: $e');
    }
  }

  /// Create order notification (combines Firestore + your existing push service)
  static Future<void> createOrderNotification({
    required String orderId,
    required String customerId,
    required String providerId,
    required String status,
    required String customerName,
    required String storeName,
    double? totalAmount,
    String? estimatedTime,
  }) async {
    try {
      print(
          '🍕 [NotificationHelper] Creating order notification for status: $status');

      String customerTitle = '';
      String customerMessage = '';
      String providerTitle = '';
      String providerMessage = '';

      switch (status.toLowerCase()) {
        case 'placed':
          customerTitle = '📋 Order Placed Successfully';
          customerMessage =
              'Your order from $storeName has been placed and is being processed';
          providerTitle = '🔔 New Order Received!';
          providerMessage = 'New order from $customerName';
          if (totalAmount != null) {
            providerMessage += ' - ₹${totalAmount.toStringAsFixed(2)}';
          }
          break;

        case 'confirmed':
          customerTitle = '✅ Order Confirmed';
          customerMessage =
              '$storeName has confirmed your order and will start preparing it soon';
          break;

        case 'preparing':
          customerTitle = '👨‍🍳 Order Being Prepared';
          customerMessage = '$storeName is now preparing your delicious meal';
          if (estimatedTime != null) {
            customerMessage += ' • Ready in $estimatedTime';
          }
          break;

        case 'ready':
          customerTitle = '🍽️ Order Ready!';
          customerMessage =
              'Your order from $storeName is ready for pickup/delivery';
          break;

        case 'delivered':
          customerTitle = '🎉 Order Delivered!';
          customerMessage =
              'Enjoy your meal from $storeName! Please rate your experience';
          break;

        case 'cancelled':
          customerTitle = '❌ Order Cancelled';
          customerMessage = 'Your order from $storeName has been cancelled';
          break;

        default:
          customerTitle = '📦 Order Update';
          customerMessage = 'Your order from $storeName has been updated';
      }

      // Create notification for customer
      if (customerTitle.isNotEmpty) {
        await createNotificationInFirestore(
          userId: customerId,
          title: customerTitle,
          message: customerMessage,
          type: 'order_${status.toLowerCase()}',
          data: {
            'orderId': orderId,
            'storeName': storeName,
            'status': status,
            'totalAmount': totalAmount,
            'estimatedTime': estimatedTime,
          },
        );
      }

      // Create notification for provider (for new orders)
      if (status.toLowerCase() == 'placed' && providerTitle.isNotEmpty) {
        await createNotificationInFirestore(
          userId: providerId,
          title: providerTitle,
          message: providerMessage,
          type: 'new_order',
          data: {
            'orderId': orderId,
            'customerName': customerName,
            'totalAmount': totalAmount,
          },
        );
      }

      print('✅ [NotificationHelper] Order notifications created successfully');
    } catch (e) {
      print('❌ [NotificationHelper] Error creating order notification: $e');
    }
  }

  /// Create general notification (for promotions, announcements, etc.)
  static Future<void> createGeneralNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    await createNotificationInFirestore(
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
    );
  }

  // ===================================================================
  // 🎨 UTILITY METHODS (for UI styling)
  // ===================================================================

  /// Get notification icon based on type
  static IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'order_placed':
        return Icons.receipt_long;
      case 'order_confirmed':
        return Icons.check_circle;
      case 'order_preparing':
        return Icons.restaurant;
      case 'order_ready':
        return Icons.notifications_active;
      case 'order_delivered':
        return Icons.delivery_dining;
      case 'order_cancelled':
        return Icons.cancel;
      case 'new_order':
        return Icons.add_shopping_cart;
      case 'payment_success':
        return Icons.payment;
      case 'payment_failed':
        return Icons.error;
      case 'promotion':
      case 'discount':
        return Icons.local_offer;
      case 'new_restaurant':
        return Icons.store;
      case 'review_request':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color based on type
  static Color _getNotificationColor(String? type) {
    switch (type) {
      case 'order_placed':
        return Colors.blue;
      case 'order_confirmed':
        return Colors.green;
      case 'order_preparing':
        return Colors.orange;
      case 'order_ready':
        return Colors.purple;
      case 'order_delivered':
        return Colors.green.shade700;
      case 'order_cancelled':
        return Colors.red;
      case 'new_order':
        return Colors.indigo;
      case 'payment_success':
        return Colors.green;
      case 'payment_failed':
        return Colors.red;
      case 'promotion':
      case 'discount':
        return Colors.purple;
      case 'new_restaurant':
        return Colors.teal;
      case 'review_request':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // ===================================================================
  // 🧹 CLEANUP METHODS
  // ===================================================================

  /// Delete old notifications (call this periodically)
  static Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final oldNotifications = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isLessThan: cutoffTimestamp)
          .get();

      if (oldNotifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
          '🧹 [NotificationHelper] Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('❌ [NotificationHelper] Error cleaning up notifications: $e');
    }
  }

  /// Delete specific notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .delete();
      print('🗑️ [NotificationHelper] Deleted notification: $notificationId');
    } catch (e) {
      print('❌ [NotificationHelper] Error deleting notification: $e');
    }
  }
}
