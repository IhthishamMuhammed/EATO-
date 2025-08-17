// File: lib/services/firebase_subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/Model/Food&Store.dart';

class FirebaseSubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================================
  // CUSTOMER SUBSCRIPTION METHODS
  // ===============================================

  /// Subscribe to a shop
  static Future<void> subscribeToShop(
      String shopId, Map<String, dynamic> shopData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print(
          '🔔 [SubscriptionService] Subscribing user $userId to shop $shopId');

      // Use a batch to ensure atomic operations
      final batch = _firestore.batch();

      // 1. Add shop to user's subscriptions
      final userSubscriptionRef =
          _firestore.collection('subscriptions').doc(userId);

      batch.set(
          userSubscriptionRef,
          {
            'subscribedShops': FieldValue.arrayUnion([shopId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      // 2. Add user to shop's subscribers
      final shopSubscriberRef =
          _firestore.collection('shopSubscribers').doc(shopId);

      batch.set(
          shopSubscriberRef,
          {
            'subscribers': FieldValue.arrayUnion([userId]),
            'subscriberCount': FieldValue.increment(1),
            'shopData': shopData, // Store shop info for easy access
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      // Execute batch
      await batch.commit();

      print('✅ [SubscriptionService] Successfully subscribed to shop $shopId');
    } catch (e) {
      print('❌ [SubscriptionService] Error subscribing to shop: $e');
      throw Exception('Failed to subscribe to shop: $e');
    }
  }

  /// Unsubscribe from a shop
  static Future<void> unsubscribeFromShop(String shopId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print(
          '🔕 [SubscriptionService] Unsubscribing user $userId from shop $shopId');

      // Use a batch to ensure atomic operations
      final batch = _firestore.batch();

      // 1. Remove shop from user's subscriptions
      final userSubscriptionRef =
          _firestore.collection('subscriptions').doc(userId);

      batch.update(userSubscriptionRef, {
        'subscribedShops': FieldValue.arrayRemove([shopId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Remove user from shop's subscribers
      final shopSubscriberRef =
          _firestore.collection('shopSubscribers').doc(shopId);

      batch.update(shopSubscriberRef, {
        'subscribers': FieldValue.arrayRemove([userId]),
        'subscriberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Execute batch
      await batch.commit();

      print(
          '✅ [SubscriptionService] Successfully unsubscribed from shop $shopId');
    } catch (e) {
      print('❌ [SubscriptionService] Error unsubscribing from shop: $e');
      throw Exception('Failed to unsubscribe from shop: $e');
    }
  }

  /// Check if user is subscribed to a shop
  static Future<bool> isSubscribed(String shopId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc =
          await _firestore.collection('subscriptions').doc(userId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final subscribedShops = List<String>.from(data['subscribedShops'] ?? []);

      return subscribedShops.contains(shopId);
    } catch (e) {
      print('❌ [SubscriptionService] Error checking subscription: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserSubscriptions(
      String userId) async {
    try {
      print('📋 [SubscriptionService] Loading subscriptions for user: $userId');

      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> subscriptions = [];

      for (var doc in subscriptionsSnapshot.docs) {
        try {
          final data = doc.data();
          final shopId = data['shopId'] as String?;

          if (shopId != null) {
            // Get shop details
            final shopDoc =
                await _firestore.collection('stores').doc(shopId).get();

            if (shopDoc.exists) {
              final shopData = shopDoc.data()!;
              subscriptions.add({
                'subscriptionId': doc.id,
                'shopId': shopId,
                'shopName': shopData['name'] ?? 'Unknown Shop',
                'shopImage': shopData['imageUrl'] ?? '',
                'shopRating': shopData['rating'] ?? 4.0,
                'shopLocation':
                    shopData['location'] ?? 'Location not specified',
                'subscribedAt': data['subscribedAt'],
              });
            }
          }
        } catch (e) {
          print(
              '⚠️ [SubscriptionService] Error processing subscription ${doc.id}: $e');
        }
      }

      print(
          '✅ [SubscriptionService] Loaded ${subscriptions.length} subscriptions');
      return subscriptions;
    } catch (e) {
      print('❌ [SubscriptionService] Error loading subscriptions: $e');
      return [];
    }
  }

  // ✅ Subscribe to shop

  // ✅ Check if user is subscribed to shop
  static Future<bool> isSubscribedToShop(String userId, String shopId) async {
    try {
      final subscriptionSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return subscriptionSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ [SubscriptionService] Error checking subscription: $e');
      return false;
    }
  }

  /// Get user's subscribed shops with real-time updates
  static Stream<List<Map<String, dynamic>>> getSubscribedShopsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('subscriptions')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        if (!snapshot.exists) return [];

        final data = snapshot.data() as Map<String, dynamic>;
        final subscribedShopIds =
            List<String>.from(data['subscribedShops'] ?? []);

        if (subscribedShopIds.isEmpty) return [];

        // Get shop details for each subscribed shop
        List<Map<String, dynamic>> subscribedShops = [];

        for (String shopId in subscribedShopIds) {
          try {
            // Get shop data from stores collection
            final storeDoc =
                await _firestore.collection('stores').doc(shopId).get();

            if (storeDoc.exists) {
              final storeData = storeDoc.data() as Map<String, dynamic>;

              // Get subscriber count
              final subscriberDoc = await _firestore
                  .collection('shopSubscribers')
                  .doc(shopId)
                  .get();

              int subscriberCount = 0;
              if (subscriberDoc.exists) {
                subscriberCount = subscriberDoc.data()?['subscriberCount'] ?? 0;
              }

              subscribedShops.add({
                'shopId': shopId,
                'shopName': storeData['name'] ?? 'Unknown Shop',
                'shopImage': storeData['imageUrl'] ?? '',
                'shopRating': (storeData['rating'] ?? 0.0).toDouble(),
                'shopContact': storeData['contact'] ?? '',
                'shopLocation':
                    storeData['location'] ?? 'Location not specified',
                'isPickup': storeData['deliveryMode'] == 'pickup' ||
                    storeData['isPickup'] == true,
                'distance':
                    2.5, // Mock distance - replace with actual calculation
                'deliveryTime':
                    30, // Mock time - replace with actual calculation
                'subscriberCount': subscriberCount,
                'subscribedAt': DateTime.now()
                    .toIso8601String(), // You can store this in user doc if needed
              });
            }
          } catch (e) {
            print(
                '⚠️ [SubscriptionService] Error getting shop data for $shopId: $e');
            continue;
          }
        }

        return subscribedShops;
      } catch (e) {
        print('❌ [SubscriptionService] Error in subscription stream: $e');
        return [];
      }
    });
  }

  /// Get subscribed shops as a one-time fetch
  static Future<List<Map<String, dynamic>>> getSubscribedShops() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final doc =
          await _firestore.collection('subscriptions').doc(userId).get();

      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      final subscribedShopIds =
          List<String>.from(data['subscribedShops'] ?? []);

      if (subscribedShopIds.isEmpty) return [];

      // Get shop details for each subscribed shop
      List<Map<String, dynamic>> subscribedShops = [];

      for (String shopId in subscribedShopIds) {
        try {
          // Get shop data from stores collection
          final storeDoc =
              await _firestore.collection('stores').doc(shopId).get();

          if (storeDoc.exists) {
            final storeData = storeDoc.data() as Map<String, dynamic>;

            // Get subscriber count
            final subscriberDoc = await _firestore
                .collection('shopSubscribers')
                .doc(shopId)
                .get();

            int subscriberCount = 0;
            if (subscriberDoc.exists) {
              subscriberCount = subscriberDoc.data()?['subscriberCount'] ?? 0;
            }

            subscribedShops.add({
              'shopId': shopId,
              'shopName': storeData['name'] ?? 'Unknown Shop',
              'shopImage': storeData['imageUrl'] ?? '',
              'shopRating': (storeData['rating'] ?? 0.0).toDouble(),
              'shopContact': storeData['contact'] ?? '',
              'shopLocation': storeData['location'] ?? 'Location not specified',
              'isPickup': storeData['deliveryMode'] == 'pickup' ||
                  storeData['isPickup'] == true,
              'distance':
                  2.5, // Mock distance - replace with actual calculation
              'deliveryTime': 30, // Mock time - replace with actual calculation
              'subscriberCount': subscriberCount,
              'subscribedAt': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          print(
              '⚠️ [SubscriptionService] Error getting shop data for $shopId: $e');
          continue;
        }
      }

      return subscribedShops;
    } catch (e) {
      print('❌ [SubscriptionService] Error getting subscribed shops: $e');
      return [];
    }
  }

  /// Get subscription count for current user
  static Future<int> getSubscriptionCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final doc =
          await _firestore.collection('subscriptions').doc(userId).get();

      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>;
      final subscribedShops = List<String>.from(data['subscribedShops'] ?? []);

      return subscribedShops.length;
    } catch (e) {
      print('❌ [SubscriptionService] Error getting subscription count: $e');
      return 0;
    }
  }

  /// Clear all subscriptions for current user
  static Future<void> clearAllSubscriptions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print(
          '🗑️ [SubscriptionService] Clearing all subscriptions for user $userId');

      // Get current subscriptions
      final doc =
          await _firestore.collection('subscriptions').doc(userId).get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final subscribedShopIds =
          List<String>.from(data['subscribedShops'] ?? []);

      if (subscribedShopIds.isEmpty) return;

      // Use batch to remove user from all shop subscribers
      final batch = _firestore.batch();

      // Clear user's subscriptions
      batch.delete(_firestore.collection('subscriptions').doc(userId));

      // Remove user from each shop's subscribers
      for (String shopId in subscribedShopIds) {
        final shopSubscriberRef =
            _firestore.collection('shopSubscribers').doc(shopId);

        batch.update(shopSubscriberRef, {
          'subscribers': FieldValue.arrayRemove([userId]),
          'subscriberCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      print('✅ [SubscriptionService] Successfully cleared all subscriptions');
    } catch (e) {
      print('❌ [SubscriptionService] Error clearing subscriptions: $e');
      throw Exception('Failed to clear subscriptions: $e');
    }
  }

  // ===============================================
  // SHOP OWNER ANALYTICS METHODS
  // ===============================================

  /// Get subscriber count for a shop (for shop owners)
  static Future<int> getShopSubscriberCount(String shopId) async {
    try {
      final doc =
          await _firestore.collection('shopSubscribers').doc(shopId).get();

      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>;
      return data['subscriberCount'] ?? 0;
    } catch (e) {
      print('❌ [SubscriptionService] Error getting subscriber count: $e');
      return 0;
    }
  }

  /// Get real-time subscriber count stream for a shop
  static Stream<int> getShopSubscriberCountStream(String shopId) {
    return _firestore
        .collection('shopSubscribers')
        .doc(shopId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['subscriberCount'] ?? 0;
    });
  }

  /// Get shop analytics (subscriber count + rating)
  static Future<Map<String, dynamic>> getShopAnalytics(String shopId) async {
    try {
      // Get subscriber count
      final subscriberDoc =
          await _firestore.collection('shopSubscribers').doc(shopId).get();

      int subscriberCount = 0;
      if (subscriberDoc.exists) {
        subscriberCount = subscriberDoc.data()?['subscriberCount'] ?? 0;
      }

      // Get shop rating from stores collection
      final storeDoc = await _firestore.collection('stores').doc(shopId).get();

      double rating = 0.0;
      String shopName = 'Unknown Shop';
      if (storeDoc.exists) {
        final storeData = storeDoc.data() as Map<String, dynamic>;
        rating = (storeData['rating'] ?? 0.0).toDouble();
        shopName = storeData['name'] ?? 'Unknown Shop';
      }

      return {
        'shopId': shopId,
        'shopName': shopName,
        'subscriberCount': subscriberCount,
        'rating': rating,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [SubscriptionService] Error getting shop analytics: $e');
      return {
        'shopId': shopId,
        'shopName': 'Unknown Shop',
        'subscriberCount': 0,
        'rating': 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get real-time shop analytics stream
  static Stream<Map<String, dynamic>> getShopAnalyticsStream(String shopId) {
    return _firestore
        .collection('shopSubscribers')
        .doc(shopId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        int subscriberCount = 0;
        if (snapshot.exists) {
          subscriberCount = snapshot.data()?['subscriberCount'] ?? 0;
        }

        // Get shop rating from stores collection
        final storeDoc =
            await _firestore.collection('stores').doc(shopId).get();

        double rating = 0.0;
        String shopName = 'Unknown Shop';
        if (storeDoc.exists) {
          final storeData = storeDoc.data() as Map<String, dynamic>;
          rating = (storeData['rating'] ?? 0.0).toDouble();
          shopName = storeData['name'] ?? 'Unknown Shop';
        }

        return {
          'shopId': shopId,
          'shopName': shopName,
          'subscriberCount': subscriberCount,
          'rating': rating,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        print('❌ [SubscriptionService] Error in analytics stream: $e');
        return {
          'shopId': shopId,
          'shopName': 'Unknown Shop',
          'subscriberCount': 0,
          'rating': 0.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  // ===============================================
  // HELPER METHODS
  // ===============================================

  /// Check if current user is authenticated
  static bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Initialize subscription document for new users
  static Future<void> initializeUserSubscriptions(String userId) async {
    try {
      await _firestore.collection('subscriptions').doc(userId).set({
        'subscribedShops': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
          '✅ [SubscriptionService] Initialized subscriptions for user $userId');
    } catch (e) {
      print(
          '❌ [SubscriptionService] Error initializing user subscriptions: $e');
    }
  }

  /// Migrate from SharedPreferences to Firebase (one-time migration)
  static Future<void> migrateFromLocalStorage(
      List<Map<String, dynamic>> localSubscriptions) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print(
          '🔄 [SubscriptionService] Migrating ${localSubscriptions.length} subscriptions from local storage');

      final batch = _firestore.batch();

      List<String> shopIds = [];
      for (var subscription in localSubscriptions) {
        final shopId = subscription['shopId'] as String?;
        if (shopId != null) {
          shopIds.add(shopId);

          // Add to shop subscribers
          final shopSubscriberRef =
              _firestore.collection('shopSubscribers').doc(shopId);

          batch.set(
              shopSubscriberRef,
              {
                'subscribers': FieldValue.arrayUnion([userId]),
                'subscriberCount': FieldValue.increment(1),
                'shopData': subscription,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }
      }

      // Set user subscriptions
      if (shopIds.isNotEmpty) {
        final userSubscriptionRef =
            _firestore.collection('subscriptions').doc(userId);

        batch.set(userSubscriptionRef, {
          'subscribedShops': shopIds,
          'migratedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      print(
          '✅ [SubscriptionService] Successfully migrated subscriptions to Firebase');
    } catch (e) {
      print('❌ [SubscriptionService] Error migrating subscriptions: $e');
      throw Exception('Failed to migrate subscriptions: $e');
    }
  }
}
