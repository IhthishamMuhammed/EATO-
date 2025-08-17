// FILE: lib/services/order_notification_service.dart
// Modern Firebase implementation with Cloud Functions approach

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'dart:async';

class OrderNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Your Firebase project ID
  static const String _projectId = 'food-delivery-around-faculty';

  /// Send notification when order is placed
  static Future<void> sendOrderPlacedNotification({
    required String orderId,
    required String customerId,
    required String providerId,
    required String customerName,
    required String storeName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Notify provider
      await _sendToUser(
        userId: providerId,
        title: '📋 New Order Received!',
        body:
            'New order from $customerName - ₹${totalAmount.toStringAsFixed(2)}',
        data: {
          'type': 'new_order',
          'order_id': orderId,
          'customer_name': customerName,
        },
      );

      print('✅ Order placed notifications sent successfully');
    } catch (e) {
      print('❌ Error sending order placed notifications: $e');
    }
  }

  /// Send notification when order status changes
  static Future<void> sendOrderStatusUpdate({
    required String orderId,
    required String customerId,
    required String newStatus,
    required String storeName,
    String? estimatedTime,
  }) async {
    try {
      String title = '';
      String body = '';

      switch (newStatus.toLowerCase()) {
        case 'confirmed':
          title = '✅ Order Confirmed';
          body = '$storeName confirmed your order';
          break;
        case 'preparing':
          title = '👨‍🍳 Order Being Prepared';
          body = '$storeName is preparing your delicious meal';
          if (estimatedTime != null) {
            body += ' • Ready in $estimatedTime';
          }
          break;
        case 'ready':
          title = '🍽️ Order Ready!';
          body = 'Your order from $storeName is ready for pickup/delivery';
          break;
        case 'ontheway':
          title = '🛵 Out for Delivery';
          body = 'Your order is on the way! Get ready to enjoy your meal';
          break;
        case 'delivered':
          title = '🎉 Order Delivered!';
          body = 'Enjoy your meal from $storeName! Don\'t forget to rate us';
          break;
        case 'cancelled':
          title = '❌ Order Cancelled';
          body = 'Your order from $storeName has been cancelled';
          break;
        default:
          title = '📱 Order Update';
          body = 'Your order status has been updated';
      }

      await _sendToUser(
        userId: customerId,
        title: title,
        body: body,
        data: {
          'type': 'order_update',
          'order_id': orderId,
          'status': newStatus,
        },
      );

      print('✅ Order status update notification sent: $newStatus');
    } catch (e) {
      print('❌ Error sending order status update: $e');
    }
  }

  /// Send payment confirmation notification
  static Future<void> sendPaymentConfirmation({
    required String orderId,
    required String customerId,
    required double amount,
    required String paymentMethod,
    required String storeName,
  }) async {
    try {
      await _sendToUser(
        userId: customerId,
        title: '💳 Payment Successful',
        body:
            'Payment of ₹${amount.toStringAsFixed(2)} confirmed for your $storeName order',
        data: {
          'type': 'payment_success',
          'order_id': orderId,
          'amount': amount.toString(),
        },
      );

      print('✅ Payment confirmation notification sent');
    } catch (e) {
      print('❌ Error sending payment confirmation: $e');
    }
  }

  /// Send promotional notifications
  static Future<void> sendPromotionalNotification({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      int successCount = 0;
      for (String userId in userIds) {
        // Check user's notification preferences
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final prefs =
              userData['notificationPreferences'] as Map<String, dynamic>?;

          // Skip if user disabled promotional notifications
          if (prefs != null && prefs['promotions'] == false) {
            continue;
          }
        }

        final success = await _sendToUser(
          userId: userId,
          title: title,
          body: body,
          data: {
            'type': 'promotion',
            'imageUrl': imageUrl,
            ...?data,
          },
        );

        if (success) successCount++;
      }

      print(
          '✅ Promotional notifications sent to $successCount/${userIds.length} users');
    } catch (e) {
      print('❌ Error sending promotional notifications: $e');
    }
  }

  /// Send notification for new restaurant
  static Future<void> sendNewRestaurantNotification({
    required List<String> userIds,
    required String restaurantName,
    required String description,
    String? imageUrl,
  }) async {
    try {
      int successCount = 0;
      for (String userId in userIds) {
        // Check user's notification preferences
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final prefs =
              userData['notificationPreferences'] as Map<String, dynamic>?;

          // Skip if user disabled new restaurant notifications
          if (prefs != null && prefs['newRestaurants'] == false) {
            continue;
          }
        }

        final success = await _sendToUser(
          userId: userId,
          title: '🍽️ New Restaurant Available!',
          body: 'Check out $restaurantName - $description',
          data: {
            'type': 'new_restaurant',
            'restaurant_name': restaurantName,
            'imageUrl': imageUrl,
          },
        );

        if (success) successCount++;
      }

      print(
          '✅ New restaurant notifications sent to $successCount/${userIds.length} users');
    } catch (e) {
      print('❌ Error sending new restaurant notifications: $e');
    }
  }

  // ✅ FIXED: Private method using Firestore document approach
  static Future<bool> _sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ User document not found: $userId');
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ No FCM token found for user: $userId');
        return false;
      }

      // ✅ FIXED: Use Cloud Function approach
      return await _createNotificationDocument(
        token: fcmToken,
        title: title,
        body: body,
        data: data ?? {},
      );
    } catch (e) {
      print('❌ Error sending notification to user $userId: $e');
      return false;
    }
  }

  // ✅ FIXED: Create notification document for Cloud Function to process
  // ✅ ENHANCED: Configurable TTL
  static Future<bool> _createNotificationDocument({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    Duration ttlDuration = const Duration(days: 7), // Default 7 days
  }) async {
    try {
      await _firestore.collection('notifications_to_send').add({
        'token': token,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,

        // ✅ Configurable TTL
        'ttl': DateTime.now().add(ttlDuration),

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
          '✅ Notification document created with ${ttlDuration.inDays} day TTL');
      return true;
    } catch (e) {
      print('❌ Error creating notification document: $e');
      return false;
    }
  }

  /// Check TTL configuration status
  static Future<void> checkTTLStatus() async {
    try {
      // Create a test document to verify TTL
      final testDoc = await _firestore.collection('notifications_to_send').add({
        'test': true,
        'ttl': DateTime.now().add(Duration(minutes: 1)), // 1 minute for testing
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ TTL test document created: ${testDoc.id}');
      print('📅 Should be deleted automatically after 1 minute');

      // Check if document exists after 2 minutes
      Timer(Duration(minutes: 2), () async {
        final doc = await testDoc.get();
        if (doc.exists) {
          print(
              '⚠️ TTL might not be configured correctly - document still exists');
        } else {
          print('✅ TTL working correctly - document auto-deleted');
        }
      });
    } catch (e) {
      print('❌ Error testing TTL: $e');
    }
  }

  // ✅ FIXED: Simple notification for testing
  // ✅ UPDATED: Test notification with TTL
  static Future<bool> sendTestNotification(
      String userId, String message) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) return false;

      // Create notification document for Cloud Function
      await _firestore.collection('notifications_to_send').add({
        'token': fcmToken,
        'title': '🔔 Test Notification',
        'body': message,
        'data': {'type': 'test'},
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,

        // ✅ ADD TTL: Auto-delete after 7 days
        'ttl': DateTime.now().add(Duration(days: 7)),

        'android': {
          'channel_id': 'eato_notifications',
          'color': '#6A1B9A',
          'priority': 'high',
          'sound': 'default',
        },
        'ios': {
          'sound': 'default',
          'badge': 1,
        },
      });

      print('✅ Test notification with TTL queued successfully');
      return true;
    } catch (e) {
      print('❌ Error sending test notification: $e');
      return false;
    }
  }

  // ✅ BONUS: Method to check notification status
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
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  // ✅ BONUS: Method to mark notifications as processed
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
      print('❌ Error marking notification as processed: $e');
    }
  }
}
