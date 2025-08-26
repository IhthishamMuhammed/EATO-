// FILE: lib/services/shop_analytics_service.dart
// Service to efficiently load shop analytics data (subscriber count + food items)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/services/firebase_subscription_service.dart';

class ShopAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get complete shop analytics including subscriber count and food items count
  static Future<Map<String, dynamic>> getShopAnalytics(String shopId) async {
    try {
      // Run both queries concurrently for better performance
      final futures = await Future.wait([
        FirebaseSubscriptionService.getShopSubscriberCount(shopId),
        _getShopFoodItemsCount(shopId),
      ]);

      return {
        'subscriberCount': futures[0] as int,
        'totalFoodItems': futures[1] as int,
      };
    } catch (e) {
      print('❌ [ShopAnalyticsService] Error getting analytics for $shopId: $e');
      return {
        'subscriberCount': 0,
        'totalFoodItems': 0,
      };
    }
  }

  /// Get food items count for a shop
  static Future<int> _getShopFoodItemsCount(String shopId) async {
    try {
      final foodsSnapshot = await _firestore
          .collection('stores')
          .doc(shopId)
          .collection('foods')
          .where('isAvailable', isEqualTo: true)
          .get();

      return foodsSnapshot.docs.length;
    } catch (e) {
      print(
          '❌ [ShopAnalyticsService] Error getting food count for $shopId: $e');
      return 0;
    }
  }

  /// Batch load analytics for multiple shops (more efficient)
  static Future<Map<String, Map<String, dynamic>>> batchLoadShopAnalytics(
      List<String> shopIds) async {
    Map<String, Map<String, dynamic>> results = {};

    try {
      // Create batches for concurrent processing
      final List<Future<void>> futures = shopIds.map((shopId) async {
        final analytics = await getShopAnalytics(shopId);
        results[shopId] = analytics;
      }).toList();

      // Wait for all analytics to load
      await Future.wait(futures);

      print(
          '✅ [ShopAnalyticsService] Loaded analytics for ${shopIds.length} shops');
      return results;
    } catch (e) {
      print('❌ [ShopAnalyticsService] Error in batch loading: $e');
      return results;
    }
  }

  /// Get real-time stream of shop analytics
  static Stream<Map<String, dynamic>> getShopAnalyticsStream(String shopId) {
    return Stream.periodic(Duration(seconds: 30)).asyncMap((_) async {
      return await getShopAnalytics(shopId);
    });
  }

  /// Update shop food count when foods are added/removed (call this from food operations)
  static Future<void> updateShopFoodCount(String shopId) async {
    try {
      final foodCount = await _getShopFoodItemsCount(shopId);

      // You can optionally store this in a separate analytics collection
      // for faster retrieval if needed
      await _firestore.collection('shopAnalytics').doc(shopId).set({
        'totalFoodItems': foodCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ [ShopAnalyticsService] Error updating food count: $e');
    }
  }
}
