import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../firebase_options.dart';
import '../services/notification_service.dart';
import '../Provider/userProvider.dart';

class AppInitializer {
  static bool _isInitialized = false;
  static bool _isInitializing =
      false; // ✅ FIX: Prevent concurrent initialization

  // ✅ FIX: Single initialization method - no userProvider parameter needed
  static Future<void> initialize() async {
    // ✅ FIX: Prevent multiple concurrent initializations
    if (_isInitialized || _isInitializing) {
      print('📱 App already initialized or initializing, skipping...');
      return;
    }

    _isInitializing = true;

    try {
      print('📱 Starting app initialization...');

      // Step 1: Initialize Firebase (critical)
      await _initializeFirebase();

      // Step 2: Initialize non-critical services in parallel
      await Future.wait([
        _initializeNotifications(),
        _initializeAppCheck(),
      ]);

      _isInitialized = true;
      _isInitializing = false;
      print('✅ App initialization completed successfully');
    } catch (e) {
      _isInitializing = false;
      print('❌ App initialization error: $e');
      // Don't throw - allow app to continue
    }
  }

  static Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow; // Firebase is critical
    }
  }

  static Future<void> _initializeNotifications() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService.initialize();
      print('✅ Notifications initialized');
    } catch (e) {
      print('❌ Notifications initialization failed: $e');
      // Don't throw - notifications are not critical
    }
  }

  static Future<void> _initializeAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
      print('✅ App Check initialized');
    } catch (e) {
      print('❌ App Check initialization failed: $e');
      // Don't throw - app check is not critical
    }
  }

  // ✅ FIX: Remove the auth listener setup from here
  // Auth listeners should be managed by the main app, not the initializer

  // ✅ NEW: Method to check if app is properly initialized
  static bool get isInitialized => _isInitialized;

  // ✅ NEW: Method to manually refresh user data (if needed by other parts of app)
  static Future<void> refreshUserData(UserProvider userProvider) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        print('🔄 Refreshing user data for: ${currentUser.uid}');
        await userProvider.fetchUser(currentUser.uid);
        print('✅ User data refreshed: ${userProvider.currentUser?.name}');
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }
}

// Background message handler (unchanged)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message received: ${message.notification?.title}');

  if (message.data.containsKey('order_id')) {
    print('📋 Order update notification: ${message.data['order_id']}');
  }
}
