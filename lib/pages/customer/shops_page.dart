import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/services/firebase_subscription_service.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/customer/shop_menu_modal.dart';

class ShopsPage extends StatefulWidget {
  final bool showBottomNav;

  const ShopsPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Store> _allShops = [];
  List<Map<String, dynamic>> _subscribedShops = [];
  bool _isLoading = true;
  String? _error;
  Map<String, bool> _subscriptionStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      // Refresh subscribed shops when switching to subscribed tab
      _loadSubscribedShops();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadAllShops(),
        _loadSubscribedShops(),
      ]);
    } catch (e) {
      print('❌ [ShopsPage] Error loading data: $e');
      setState(() {
        _error = 'Failed to load shops: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllShops() async {
    try {
      print('🔄 [ShopsPage] Loading all shops...');

      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('isActive', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Store> shops = [];
      for (var doc in shopsSnapshot.docs) {
        try {
          final store = Store.fromFirestore(doc);
          shops.add(store);
        } catch (e) {
          print('⚠️ [ShopsPage] Error parsing shop ${doc.id}: $e');
          continue;
        }
      }

      // Sort shops by rating (highest first)
      shops.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));

      setState(() {
        _allShops = shops;
      });

      // Load subscription status for all shops
      await _loadSubscriptionStatus();

      print('✅ [ShopsPage] Loaded ${shops.length} shops');
    } catch (e) {
      print('❌ [ShopsPage] Error loading all shops: $e');
      throw e;
    }
  }

  Future<void> _loadSubscribedShops() async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      setState(() {
        _subscribedShops = [];
      });
      return;
    }

    try {
      print('🔄 [ShopsPage] Loading subscribed shops...');

      final subscribedShops =
          await FirebaseSubscriptionService.getSubscribedShops();

      setState(() {
        _subscribedShops = subscribedShops;
      });

      print('✅ [ShopsPage] Loaded ${subscribedShops.length} subscribed shops');
    } catch (e) {
      print('❌ [ShopsPage] Error loading subscribed shops: $e');
      setState(() {
        _subscribedShops = [];
      });
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      return;
    }

    try {
      Map<String, bool> status = {};
      for (var shop in _allShops) {
        status[shop.id] =
            await FirebaseSubscriptionService.isSubscribed(shop.id);
      }

      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
        });
      }
    } catch (e) {
      print('❌ [ShopsPage] Error loading subscription status: $e');
    }
  }

  Future<void> _toggleSubscription(Store shop) async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      _showAuthRequiredDialog();
      return;
    }

    final isCurrentlySubscribed = _subscriptionStatus[shop.id] ?? false;

    try {
      if (isCurrentlySubscribed) {
        await FirebaseSubscriptionService.unsubscribeFromShop(shop.id);

        setState(() {
          _subscriptionStatus[shop.id] = false;
        });

        // Refresh subscribed shops list
        await _loadSubscribedShops();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.unsubscribe, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Unsubscribed from ${shop.name}'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final shopData = {
          'shopName': shop.name,
          'shopImage': shop.imageUrl,
          'shopRating': shop.rating ?? 0.0,
          'shopContact': shop.contact,
          'shopLocation': shop.location ?? 'Location not specified',
          'isPickup': shop.isPickup,
          'distance': 2.5, // Mock distance
          'deliveryTime': 30, // Mock time
        };

        await FirebaseSubscriptionService.subscribeToShop(shop.id, shopData);

        setState(() {
          _subscriptionStatus[shop.id] = true;
        });

        // Refresh subscribed shops list
        await _loadSubscribedShops();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Subscribed to ${shop.name}'),
                ],
              ),
              backgroundColor: Colors.purple,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ShopsPage] Error toggling subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to update subscription: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.purple),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: Text(
          'Please log in to subscribe to restaurants and get updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewShopMenu(Store shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopMenuModal(
        shopId: shop.id,
        shopName: shop.name,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      // Already on shops page
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/cart');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/activity');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/account');
        break;
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
            Icon(Icons.store, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text(
              'Shops',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'All Shops'),
            Tab(text: 'Subscribed'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.purple))
                : _error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllShopsTab(),
                          _buildSubscribedShopsTab(),
                        ],
                      ),
          ),
          if (widget.showBottomNav)
            BottomNavBar(
              currentIndex: 1, // Shops tab
              onTap: _onBottomNavTap,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text('Try Again', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllShopsTab() {
    if (_allShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Shops Available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new restaurants',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllShops,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _allShops.length,
        itemBuilder: (context, index) {
          final shop = _allShops[index];
          final isSubscribed = _subscriptionStatus[shop.id] ?? false;
          return _buildShopCard(shop, isSubscribed, true);
        },
      ),
    );
  }

  Widget _buildSubscribedShopsTab() {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Login Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please log in to view your subscriptions',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: Icon(Icons.login, color: Colors.white),
              label: Text('Login', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      );
    }

    if (_subscribedShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Subscriptions Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Subscribe to restaurants in the "All Shops" tab to see them here',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: Icon(Icons.store, color: Colors.white),
              label:
                  Text('Browse Shops', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscribedShops,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _subscribedShops.length,
        itemBuilder: (context, index) {
          final shopData = _subscribedShops[index];
          final shop = Store(
            id: shopData['shopId'] ?? '',
            name: shopData['shopName'] ?? 'Unknown Shop',
            contact: shopData['shopContact'] ?? '',
            deliveryMode: (shopData['isPickup'] ?? true)
                ? DeliveryMode.pickup
                : DeliveryMode.delivery,
            imageUrl: shopData['shopImage'] ?? '',
            foods: [],
            ownerUid: '',
            isActive: true,
            isAvailable: true,
            location: shopData['shopLocation'],
            rating: (shopData['shopRating'] ?? 0.0).toDouble(),
          );
          return _buildSubscribedShopCard(shop, shopData);
        },
      ),
    );
  }

  Widget _buildShopCard(
      Store shop, bool isSubscribed, bool showSubscribeButton) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed
              ? Colors.purple.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Shop image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: shop.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: shop.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.store, size: 30),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(Icons.store, size: 30),
                        ),
                ),

                SizedBox(width: 16),

                // Shop details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (showSubscribeButton)
                            GestureDetector(
                              onTap: () => _toggleSubscription(shop),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSubscribed
                                      ? Colors.purple.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSubscribed
                                        ? Colors.purple
                                        : Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSubscribed
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 14,
                                      color: isSubscribed
                                          ? Colors.purple
                                          : Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      isSubscribed ? 'Subscribed' : 'Subscribe',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSubscribed
                                            ? Colors.purple
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Shop stats
                      Row(
                        children: [
                          if ((shop.rating ?? 0) > 0) ...[
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '${(shop.rating ?? 0.0).toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 16),
                          ],
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.location ?? 'Location not specified',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: shop.isPickup ? Colors.green : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  shop.isPickup
                                      ? Icons.store
                                      : Icons.delivery_dining,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  shop.isPickup ? 'Pickup' : 'Delivery',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewShopMenu(shop),
                icon:
                    Icon(Icons.restaurant_menu, size: 16, color: Colors.white),
                label: Text('View Menu', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribedShopCard(Store shop, Map<String, dynamic> shopData) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Shop image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: shop.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: shop.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.store, size: 30),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(Icons.store, size: 30),
                        ),
                ),

                SizedBox(width: 16),

                // Shop details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: TextStyle(
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

                      SizedBox(height: 8),

                      // Shop stats
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '${(shop.rating ?? 0.0).toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.people, size: 16, color: Colors.purple),
                          SizedBox(width: 4),
                          Text(
                            '${shopData['subscriberCount'] ?? 0} subscribers',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.location ?? 'Location not specified',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Subscribed ${_getTimeAgo(shopData['subscribedAt'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _unsubscribeFromShop(shop),
                  icon: Icon(Icons.unsubscribe, size: 16, color: Colors.orange),
                  label: Text('Unsubscribe',
                      style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange),
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

  Future<void> _unsubscribeFromShop(Store shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.unsubscribe, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unsubscribe'),
          ],
        ),
        content:
            Text('Are you sure you want to unsubscribe from ${shop.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Unsubscribe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseSubscriptionService.unsubscribeFromShop(shop.id);
        await _loadSubscribedShops(); // Refresh the list

        if (mounted) {
          setState(() {
            _subscriptionStatus[shop.id] = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Unsubscribed from ${shop.name}'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unsubscribe: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _getTimeAgo(String? subscribedAt) {
    if (subscribedAt == null) return 'recently';

    try {
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
    } catch (e) {
      return 'recently';
    }
  }
}
