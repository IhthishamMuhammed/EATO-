// FILE: lib/services/notification_service.dart
// Replace your existing notification_service.dart with this enhanced version

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Enhanced background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📱 Background message received: ${message.notification?.title}");

  // You can add custom logic here for background processing
  if (message.data.containsKey('order_id')) {
    print("🔔 Order update notification: ${message.data['order_id']}");
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _currentToken;
  static bool _isInitialized = false;

  // ✅ Enhanced initialization
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      await _initializeLocalNotifications();
      await _requestPermissions();
      await _setupMessageHandlers();
      await _initializeTokenManagement();

      _isInitialized = true;
      print("✅ NotificationService initialized successfully");
    } catch (e) {
      print("❌ NotificationService initialization failed: $e");
    }
  }

  // ✅ Initialize local notifications with channels
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ Create notification channels
    await _createNotificationChannels();
  }

  // ✅ Create notification channels for different types
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'eato_notifications',
        'Eato Notifications',
        description: 'General notifications from Eato app',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications about your order status',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      AndroidNotificationChannel(
        'promotions',
        'Promotions & Offers',
        description: 'Special offers and promotional notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // ✅ Request permissions
  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    print("🔐 Permission granted: ${settings.authorizationStatus}");
  }

  // ✅ Setup message handlers
  static Future<void> _setupMessageHandlers() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📱 Foreground message: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // Background/terminated app - user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 App opened from notification: ${message.notification?.title}");
      _handleNotificationClick(message);
    });

    // Check if app was opened from terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print(
          "🚀 App launched from notification: ${initialMessage.notification?.title}");
      _handleNotificationClick(initialMessage);
    }
  }

  // ✅ Enhanced token management
  static Future<void> _initializeTokenManagement() async {
    try {
      // Get current token
      _currentToken = await _messaging.getToken();
      print("🔑 FCM Token: $_currentToken");

      // Save token to user profile if user is logged in
      if (_auth.currentUser != null && _currentToken != null) {
        await _saveTokenToUserProfile(_currentToken!);
      }

      // Listen for token updates
      _messaging.onTokenRefresh.listen((newToken) {
        print("🔄 Token refreshed: $newToken");
        _currentToken = newToken;
        if (_auth.currentUser != null) {
          _saveTokenToUserProfile(newToken);
        }
      });
    } catch (e) {
      print("❌ Token management setup failed: $e");
    }
  }

  // ✅ Save FCM token to user profile
  static Future<void> _saveTokenToUserProfile(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ Token saved to user profile");
    } catch (e) {
      print("❌ Failed to save token: $e");
    }
  }

  // ✅ Enhanced local notification display
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Determine notification channel based on message type
    String channelId = 'eato_notifications';
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'order_update':
          channelId = 'order_updates';
          break;
        case 'promotion':
          channelId = 'promotions';
          break;
      }
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'eato_notifications', // channel ID
      'Eato Notifications', // channel name
      channelDescription: 'General notifications from Eato app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Color(0xFF6A1B9A),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: _createPayload(data),
    );
  }

  // ✅ Get notification actions based on message type
  static List<AndroidNotificationAction>? _getNotificationActions(
      Map<String, dynamic> data) {
    if (data['type'] == 'order_update') {
      return [
        const AndroidNotificationAction(
          'view_order',
          'View Order',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'track_order',
          'Track',
          showsUserInterface: true,
        ),
      ];
    }
    return null;
  }

  // ✅ Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print("🔔 Notification tapped: ${response.payload}");

    if (response.actionId != null) {
      print("🔔 Action tapped: ${response.actionId}");
      // Handle action button taps
      _handleNotificationAction(response.actionId!, response.payload);
    } else {
      // Handle notification body tap
      _handleNotificationBody(response.payload);
    }
  }

  // ✅ Handle notification click from Firebase message
  static void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;

    // Navigate based on notification type
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'order_update':
          _navigateToOrderDetails(data['order_id']);
          break;
        case 'promotion':
          _navigateToPromotions();
          break;
        case 'new_food':
          _navigateToFoodMenu(data['shop_id']);
          break;
        default:
          _navigateToHome();
      }
    }
  }

  // ✅ Public methods for sending notifications

  // Save token when user logs in
  static Future<void> saveUserToken(String userId) async {
    if (_currentToken != null) {
      await _saveTokenToUserProfile(_currentToken!);
    }
  }

  // Remove token when user logs out
  static Future<void> removeUserToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'tokenRemovedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("❌ Failed to remove token: $e");
    }
  }

  // Get current FCM token
  static String? getCurrentToken() => _currentToken;

  // ✅ Helper methods
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'order_updates':
        return 'Order Updates';
      case 'promotions':
        return 'Promotions & Offers';
      default:
        return 'Eato Notifications';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'order_updates':
        return 'Notifications about your order status';
      case 'promotions':
        return 'Special offers and promotional notifications';
      default:
        return 'General notifications from Eato app';
    }
  }

  static String _createPayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  static void _handleNotificationAction(String actionId, String? payload) {
    // Handle action button taps
    print("🔔 Handling action: $actionId with payload: $payload");
    // Implement navigation logic based on action
  }

  static void _handleNotificationBody(String? payload) {
    // Handle notification body tap
    print("🔔 Handling body tap with payload: $payload");
    // Implement navigation logic
  }

  // Navigation methods (implement based on your app structure)
  static void _navigateToOrderDetails(String? orderId) {
    print("🧭 Navigate to order: $orderId");
    // Add navigation logic here
  }

  static void _navigateToPromotions() {
    print("🧭 Navigate to promotions");
    // Add navigation logic here
  }

  static void _navigateToFoodMenu(String? shopId) {
    print("🧭 Navigate to food menu: $shopId");
    // Add navigation logic here
  }

  static void _navigateToHome() {
    print("🧭 Navigate to home");
    // Add navigation logic here
  }
}
