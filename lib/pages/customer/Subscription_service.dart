import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SubscriptionService {
  static const String _subscriptionsKey = 'subscribed_shops';

  // Add shop to subscriptions
  static Future<void> subscribeToShop(Map<String, dynamic> shop) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    // Check if already subscribed
    bool alreadySubscribed = false;
    List<Map<String, dynamic>> decodedSubscriptions = subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();

    for (var subscription in decodedSubscriptions) {
      if (subscription['shopId'] == shop['shopId']) {
        alreadySubscribed = true;
        break;
      }
    }

    if (!alreadySubscribed) {
      // Add subscription with timestamp
      shop['subscribedAt'] = DateTime.now().toIso8601String();
      decodedSubscriptions.add(shop);

      List<String> encodedSubscriptions =
          decodedSubscriptions.map((item) => json.encode(item)).toList();
      await prefs.setStringList(_subscriptionsKey, encodedSubscriptions);
    }
  }

  // Remove shop from subscriptions
  static Future<void> unsubscribeFromShop(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    List<Map<String, dynamic>> decodedSubscriptions = subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();

    // Remove the shop
    decodedSubscriptions.removeWhere((shop) => shop['shopId'] == shopId);

    List<String> encodedSubscriptions =
        decodedSubscriptions.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_subscriptionsKey, encodedSubscriptions);
  }

  // Check if shop is subscribed
  static Future<bool> isSubscribed(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    List<Map<String, dynamic>> decodedSubscriptions = subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();

    return decodedSubscriptions.any((shop) => shop['shopId'] == shopId);
  }

  // Get all subscribed shops
  static Future<List<Map<String, dynamic>>> getSubscribedShops() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    return subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }

  // Get subscription count
  static Future<int> getSubscriptionCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];
    return subscriptions.length;
  }

  // Clear all subscriptions
  static Future<void> clearAllSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionsKey);
  }
}
