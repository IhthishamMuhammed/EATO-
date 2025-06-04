import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ✅ Subscription Service
class SubscriptionService {
  static const String _subscriptionsKey = 'subscribed_shops';

  static Future<void> subscribeToShop(Map<String, dynamic> shop) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

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
      shop['subscribedAt'] = DateTime.now().toIso8601String();
      decodedSubscriptions.add(shop);

      List<String> encodedSubscriptions =
          decodedSubscriptions.map((item) => json.encode(item)).toList();
      await prefs.setStringList(_subscriptionsKey, encodedSubscriptions);
    }
  }

  static Future<void> unsubscribeFromShop(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    List<Map<String, dynamic>> decodedSubscriptions = subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();

    decodedSubscriptions.removeWhere((shop) => shop['shopId'] == shopId);

    List<String> encodedSubscriptions =
        decodedSubscriptions.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_subscriptionsKey, encodedSubscriptions);
  }

  static Future<bool> isSubscribed(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    List<Map<String, dynamic>> decodedSubscriptions = subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();

    return decodedSubscriptions.any((shop) => shop['shopId'] == shopId);
  }

  static Future<List<Map<String, dynamic>>> getSubscribedShops() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];

    return subscriptions
        .map((item) => Map<String, dynamic>.from(json.decode(item)))
        .toList();
  }

  static Future<void> clearAllSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionsKey);
  }
}

class SubscribedPage extends StatefulWidget {
  final bool showBottomNav;

  const SubscribedPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<SubscribedPage> createState() => _SubscribedPageState();
}

class _SubscribedPageState extends State<SubscribedPage> {
  List<Map<String, dynamic>> _subscribedShops = [];
  bool _isLoading = true;
  String _sortBy = 'Recent'; // Recent, Name, Rating

  @override
  void initState() {
    super.initState();
    _loadSubscribedShops();
  }

  Future<void> _loadSubscribedShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shops = await SubscriptionService.getSubscribedShops();
      setState(() {
        _subscribedShops = shops;
        _isLoading = false;
      });
      _sortShops();
    } catch (e) {
      print('Error loading subscribed shops: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortShops() {
    switch (_sortBy) {
      case 'Name':
        _subscribedShops.sort(
            (a, b) => (a['shopName'] ?? '').compareTo(b['shopName'] ?? ''));
        break;
      case 'Rating':
        _subscribedShops.sort((a, b) =>
            (b['shopRating'] ?? 0.0).compareTo(a['shopRating'] ?? 0.0));
        break;
      case 'Recent':
      default:
        _subscribedShops.sort((a, b) {
          final aDate = DateTime.parse(
              a['subscribedAt'] ?? DateTime.now().toIso8601String());
          final bDate = DateTime.parse(
              b['subscribedAt'] ?? DateTime.now().toIso8601String());
          return bDate.compareTo(aDate); // Most recent first
        });
        break;
    }
    setState(() {});
  }

  Future<void> _unsubscribeFromShop(Map<String, dynamic> shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsubscribe'),
        content: Text(
            'Are you sure you want to unsubscribe from ${shop['shopName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Unsubscribe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SubscriptionService.unsubscribeFromShop(shop['shopId']);
        await _loadSubscribedShops(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unsubscribed from ${shop['shopName']}'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unsubscribe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllSubscriptions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Subscriptions'),
        content: Text('Are you sure you want to unsubscribe from all shops?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SubscriptionService.clearAllSubscriptions();
        await _loadSubscribedShops(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All subscriptions cleared'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear subscriptions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewShopMenu(Map<String, dynamic> shop) {
    // Navigate to shop menu or category page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shop menu for ${shop['shopName']} coming soon!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  String _getTimeAgo(String subscribedAt) {
    final subscribedDate = DateTime.parse(subscribedAt);
    final now = DateTime.now();
    final difference = now.difference(subscribedDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  // ✅ Handle bottom nav taps
  void _onBottomNavTap(int index) {
    if (index == 1) {
      // Subscribed tab - stay here
      return;
    } else {
      // Other tabs - navigate
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/orders');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/activity');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/account');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text('My Subscriptions',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
            if (_subscribedShops.isNotEmpty) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_subscribedShops.length}',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          if (_subscribedShops.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.sort, color: Colors.grey[600]),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
                _sortShops();
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'Recent', child: Text('Sort by Recent')),
                PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
                PopupMenuItem(value: 'Rating', child: Text('Sort by Rating')),
              ],
            ),
            IconButton(
              onPressed: _clearAllSubscriptions,
              icon: Icon(Icons.clear_all, color: Colors.red),
              tooltip: 'Clear All',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.purple))
                : _subscribedShops.isEmpty
                    ? _buildEmptyState()
                    : _buildSubscriptionsList(),
          ),
          if (widget.showBottomNav)
            BottomNavBar(
              currentIndex: 1, // Subscribed tab
              onTap: _onBottomNavTap,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Subscriptions Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Subscribe to your favorite restaurants to get updates and easy access to their menus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: Icon(Icons.restaurant_menu, color: Colors.white),
            label: Text('Browse Restaurants',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return RefreshIndicator(
      onRefresh: _loadSubscribedShops,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _subscribedShops.length,
        itemBuilder: (context, index) {
          return _buildSubscriptionCard(_subscribedShops[index]);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> shop) {
    final subscribedAt =
        shop['subscribedAt'] ?? DateTime.now().toIso8601String();
    final timeAgo = _getTimeAgo(subscribedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shop header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Shop image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      shop['shopImage'] != null && shop['shopImage'].isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: shop['shopImage'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.purple),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.store, size: 30),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.store, size: 30),
                            ),
                ),

                const SizedBox(width: 16),

                // Shop details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop['shopName'] ?? 'Shop',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Subscribed badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite,
                                    size: 12, color: Colors.purple),
                                SizedBox(width: 4),
                                Text(
                                  'Subscribed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Shop stats
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${(shop['shopRating'] ?? 0.0).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${(shop['distance'] ?? 0.0).toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${shop['deliveryTime'] ?? 30} min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Subscribed $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewShopMenu(shop),
                    icon: Icon(Icons.restaurant_menu,
                        size: 16, color: Colors.white),
                    label: Text('View Menu',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _unsubscribeFromShop(shop),
                  icon: Icon(Icons.unsubscribe, size: 16, color: Colors.red),
                  label:
                      Text('Unsubscribe', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
