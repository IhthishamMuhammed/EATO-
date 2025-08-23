// FILE: lib/services/order_notification_service.dart
// Fixed version that matches your OrderProvider method calls

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/services/notification_helper.dart';

class OrderNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===================================================================
  // 🔔 METHODS CALLED BY YOUR ORDERPROVIDER
  // ===================================================================

  /// ✅ Method called by OrderProvider.placeOrdersWithNotifications()
  static Future<bool> sendOrderPlacedNotification({
    required String orderId,
    required String customerId,
    required String providerId,
    required String customerName,
    required String storeName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      print('🍕 [OrderNotificationService] Sending order placed notifications');
      print('   Order ID: $orderId');
      print('   Customer: $customerId');
      print('   Provider: $providerId');
      print('   Store: $storeName');

      // Step 1: Create notifications in Firestore for UI display
      await NotificationHelper.createOrderNotification(
        orderId: orderId,
        customerId: customerId,
        providerId: providerId,
        status: 'placed',
        customerName: customerName,
        storeName: storeName,
        totalAmount: totalAmount,
      );

      // Step 2: Send push notifications

      // Customer notification
      bool customerPushSent = await _sendPushNotification(
        userId: customerId,
        title: '📋 Order Placed Successfully',
        body:
            'Your order from $storeName has been placed and is being processed',
        data: {
          'type': 'order_update',
          'orderId': orderId,
          'status': 'placed',
          'storeName': storeName,
        },
      );

      // Provider notification
      bool providerPushSent = await _sendPushNotification(
        userId: providerId,
        title: '🔔 New Order Received!',
        body:
            'New order from $customerName - ₹${totalAmount.toStringAsFixed(2)}',
        data: {
          'type': 'new_order',
          'orderId': orderId,
          'customerName': customerName,
          'totalAmount': totalAmount.toString(),
        },
      );

      print('✅ [OrderNotificationService] Order placed notifications complete');
      print(
          '   Customer push: $customerPushSent, Provider push: $providerPushSent');
      return true;
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error sending order placed notification: $e');
      return false;
    }
  }

  /// ✅ Method called by OrderProvider.updateOrderStatusWithNotifications()
  static Future<bool> sendOrderStatusUpdate({
    required String orderId,
    required String customerId,
    required String newStatus,
    required String storeName,
    String? estimatedTime,
    String? providerId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      print(
          '🔄 [OrderNotificationService] Sending order status update: $newStatus');
      print('   Order ID: $orderId');
      print('   Customer: $customerId');
      print('   Store: $storeName');

      // Step 1: Create notification in Firestore for UI display
      await NotificationHelper.createOrderNotification(
        orderId: orderId,
        customerId: customerId,
        providerId: providerId ?? '',
        status: newStatus,
        customerName: customerName ?? 'Customer',
        storeName: storeName,
        totalAmount: totalAmount,
        estimatedTime: estimatedTime,
      );

      // Step 2: Send push notification
      String title = _getNotificationTitle(newStatus);
      String body = _getNotificationBody(newStatus, storeName, estimatedTime);

      bool pushSent = await _sendPushNotification(
        userId: customerId,
        title: title,
        body: body,
        data: {
          'type': 'order_update',
          'orderId': orderId,
          'status': newStatus,
          'storeName': storeName,
        },
      );

      print(
          '✅ [OrderNotificationService] Order status update complete - Push: $pushSent');
      return true;
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error sending order status update: $e');
      return false;
    }
  }

  /// ✅ Method called by OrderProvider.sendPaymentConfirmation()
  static Future<bool> sendPaymentConfirmation({
    required String orderId,
    required String customerId,
    required double amount,
    required String paymentMethod,
    required String storeName,
  }) async {
    try {
      print('💳 [OrderNotificationService] Sending payment confirmation');

      // Step 1: Create notification in Firestore for UI display
      await NotificationHelper.createGeneralNotification(
        userId: customerId,
        title: '✅ Payment Confirmed',
        message:
            'Payment of ₹${amount.toStringAsFixed(2)} confirmed for your order from $storeName',
        type: 'payment_success',
        data: {
          'orderId': orderId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'storeName': storeName,
        },
      );

      // Step 2: Send push notification
      bool pushSent = await _sendPushNotification(
        userId: customerId,
        title: '✅ Payment Confirmed',
        body:
            'Payment of ₹${amount.toStringAsFixed(2)} confirmed for your order from $storeName',
        data: {
          'type': 'payment_success',
          'orderId': orderId,
          'amount': amount.toString(),
        },
      );

      print(
          '✅ [OrderNotificationService] Payment confirmation complete - Push: $pushSent');
      return pushSent;
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error sending payment confirmation: $e');
      return false;
    }
  }

  /// ✅ Method called by OrderProvider.sendPromotionToCustomers()
  static Future<int> sendPromotionalNotification({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      print(
          '🎉 [OrderNotificationService] Sending promotional notification to ${userIds.length} users');

      int successCount = 0;
      for (String userId in userIds) {
        // Step 1: Create notification in Firestore for UI display
        await NotificationHelper.createGeneralNotification(
          userId: userId,
          title: title,
          message: body,
          type: 'promotion',
          data: {
            'imageUrl': imageUrl,
          },
        );

        // Step 2: Send push notification
        bool pushSent = await _sendPushNotification(
          userId: userId,
          title: title,
          body: body,
          data: {
            'type': 'promotion',
            'imageUrl': imageUrl ?? '',
          },
        );

        if (pushSent) successCount++;
      }

      print(
          '✅ [OrderNotificationService] Promotional notifications sent: $successCount/${userIds.length}');
      return successCount;
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error sending promotional notification: $e');
      return 0;
    }
  }

  /// ✅ Method called by OrderProvider.notifyAboutNewRestaurant()
  static Future<int> sendNewRestaurantNotification({
    required List<String> userIds,
    required String restaurantName,
    required String description,
    String? imageUrl,
  }) async {
    try {
      print(
          '🏪 [OrderNotificationService] Sending new restaurant notification to ${userIds.length} users');

      int successCount = 0;
      for (String userId in userIds) {
        // Step 1: Create notification in Firestore for UI display
        await NotificationHelper.createGeneralNotification(
          userId: userId,
          title: '🎉 New Restaurant: $restaurantName',
          message: description,
          type: 'new_restaurant',
          data: {
            'restaurantName': restaurantName,
            'imageUrl': imageUrl,
          },
        );

        // Step 2: Send push notification
        bool pushSent = await _sendPushNotification(
          userId: userId,
          title: '🎉 New Restaurant: $restaurantName',
          body: description,
          data: {
            'type': 'new_restaurant',
            'restaurantName': restaurantName,
            'imageUrl': imageUrl ?? '',
          },
        );

        if (pushSent) successCount++;
      }

      print(
          '✅ [OrderNotificationService] New restaurant notifications sent: $successCount/${userIds.length}');
      return successCount;
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error sending new restaurant notification: $e');
      return 0;
    }
  }

  // ===================================================================
  // 🧪 TESTING METHODS (keep existing ones)
  // ===================================================================

  /// Send test notification (existing method)
  static Future<bool> sendTestNotification(
    String userId,
    String message,
  ) async {
    try {
      print(
          '🧪 [OrderNotificationService] Sending test notification to: $userId');

      // Step 1: Create notification in Firestore for UI display
      await NotificationHelper.createGeneralNotification(
        userId: userId,
        title: '🧪 Test Notification',
        message: message,
        type: 'test',
        data: {'isTest': true},
      );

      // Step 2: Send push notification
      bool pushSent = await _sendPushNotification(
        userId: userId,
        title: '🧪 Test Notification',
        body: message,
        data: {'type': 'test'},
      );

      print(
          '✅ [OrderNotificationService] Test notification complete - Push: $pushSent');
      return pushSent;
    } catch (e) {
      print('❌ [OrderNotificationService] Error sending test notification: $e');
      return false;
    }
  }

  // ===================================================================
  // 🚀 PUSH NOTIFICATION SENDING (via Cloud Functions)
  // ===================================================================

  /// Send push notification via Cloud Function
  static Future<bool> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ [OrderNotificationService] User document not found: $userId');
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print(
            '⚠️ [OrderNotificationService] No FCM token found for user: $userId');
        return false;
      }

      print(
          '📤 [OrderNotificationService] Sending push notification via Cloud Function');

      // Create notification document for Cloud Function to process
      await _firestore.collection('notifications_to_send').add({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,

        // TTL: Auto-delete after 7 days
        'ttl': DateTime.now().add(Duration(days: 7)),

        'android': {
          'channel_id': data['type'] == 'order_update'
              ? 'order_updates'
              : 'eato_notifications',
          'color': '#6A1B9A',
          'priority': 'high',
          'sound': 'default',
        },
        'ios': {
          'sound': 'default',
          'badge': 1,
        },
      });

      print(
          '✅ [OrderNotificationService] Push notification queued for Cloud Function');
      return true;
    } catch (e) {
      print('❌ [OrderNotificationService] Error sending push notification: $e');
      return false;
    }
  }

  // ===================================================================
  // 🎨 HELPER METHODS
  // ===================================================================

  /// Get notification title based on order status
  static String _getNotificationTitle(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return '📋 Order Placed Successfully';
      case 'confirmed':
        return '✅ Order Confirmed';
      case 'preparing':
        return '👨‍🍳 Order Being Prepared';
      case 'ready':
        return '🍽️ Order Ready!';
      case 'delivered':
        return '🎉 Order Delivered!';
      case 'cancelled':
        return '❌ Order Cancelled';
      default:
        return '📦 Order Update';
    }
  }

  /// Get notification body based on order status
  static String _getNotificationBody(
      String status, String storeName, String? estimatedTime) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Your order from $storeName has been placed and is being processed';
      case 'confirmed':
        return '$storeName has confirmed your order and will start preparing it soon';
      case 'preparing':
        String body = '$storeName is now preparing your delicious meal';
        if (estimatedTime != null) {
          body += ' • Ready in $estimatedTime';
        }
        return body;
      case 'ready':
        return 'Your order from $storeName is ready for pickup/delivery';
      case 'delivered':
        return 'Enjoy your meal from $storeName! Please rate your experience';
      case 'cancelled':
        return 'Your order from $storeName has been cancelled';
      default:
        return 'Your order from $storeName has been updated';
    }
  }

  // ===================================================================
  // 🔧 ADMIN & DEBUGGING METHODS
  // ===================================================================

  /// Get pending notifications (for debugging)
  static Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications_to_send')
          .where('processed', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error getting pending notifications: $e');
      return [];
    }
  }

  /// Mark notification as processed (for debugging)
  static Future<void> markNotificationAsProcessed(String notificationId) async {
    try {
      await _firestore
          .collection('notifications_to_send')
          .doc(notificationId)
          .update({
        'processed': true,
        'processedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error marking notification as processed: $e');
    }
  }

  /// Send notification to specific user (general purpose)
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Step 1: Create notification in Firestore for UI display
      await NotificationHelper.createGeneralNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        data: data,
      );

      // Step 2: Send push notification
      bool pushSent = await _sendPushNotification(
        userId: userId,
        title: title,
        body: message,
        data: {
          'type': type,
          ...data ?? {},
        },
      );

      return pushSent;
    } catch (e) {
      print(
          '❌ [OrderNotificationService] Error sending notification to user: $e');
      return false;
    }
  }
}
