// FILE: lib/pages/customer/shops_page.dart
// Updated to use separate card widgets with swipeable tabs

import 'package:eato/EatoComponents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/widgets/shop_card.dart';
import 'package:eato/widgets/subscribed_shop_card.dart';
import 'package:eato/services/firebase_subscription_service.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/customer/shop_menu_modal.dart';
import 'package:eato/pages/theme/eato_theme.dart';

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
  List<Store> _filteredShops = [];
  List<Map<String, dynamic>> _subscribedShops = [];
  bool _isLoading = true;
  String? _error;
  Map<String, bool> _subscriptionStatus = {};
  bool _isDisposed = false;

  // Add this variable at the top of your class
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _loadData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose(); // Don't forget to dispose
    super.dispose();
  }

  void _onTabChanged() {
    if (_isDisposed) return;

    // Add haptic feedback for better UX
    HapticFeedback.selectionClick();

    if (_tabController.index == 1) {
      // Refresh subscribed shops when switching to subscribed tab
      _loadSubscribedShops();
    }
  }

  Future<void> _loadData() async {
    if (_isDisposed) return;
    if (mounted && !_isDisposed) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      await Future.wait([
        _loadAllShops(),
        _loadSubscribedShops(),
      ]);
    } catch (e) {
      print('❌ [ShopsPage] Error loading data: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _error = 'Failed to load shops: $e';
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllShops() async {
    if (_isDisposed) return;
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
      if (mounted && !_isDisposed) {
        setState(() {
          _allShops = shops;
          _filteredShops = List.from(shops);
        });
      }

      // Load subscription status for all shops
      await _loadSubscriptionStatus();

      print('✅ [ShopsPage] Loaded ${shops.length} shops');
    } catch (e) {
      print('❌ [ShopsPage] Error loading all shops: $e');
      throw e;
    }
  }

  Future<void> _loadSubscribedShops() async {
    if (_isDisposed) return;
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      if (mounted && !_isDisposed) {
        setState(() {
          _subscribedShops = [];
        });
        return;
      }
    }

    try {
      print('🔄 [ShopsPage] Loading subscribed shops...');

      final subscribedShops =
          await FirebaseSubscriptionService.getSubscribedShops();
      if (mounted && !_isDisposed) {
        setState(() {
          _subscribedShops = subscribedShops;
        });

        print(
            '✅ [ShopsPage] Loaded ${subscribedShops.length} subscribed shops');
      }
    } catch (e) {
      print('❌ [ShopsPage] Error loading subscribed shops: $e');
      setState(() {
        _subscribedShops = [];
      });
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    if (_isDisposed) return;
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      return;
    }

    try {
      Map<String, bool> status = {};
      for (var shop in _allShops) {
        status[shop.id] =
            await FirebaseSubscriptionService.isSubscribed(shop.id);
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _subscriptionStatus = status;
        });
      }
    } catch (e) {
      print('❌ [ShopsPage] Error loading subscription status: $e');
    }
  }

  Future<void> _toggleSubscription(Store shop) async {
    if (_isDisposed) return;
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      _showAuthRequiredDialog();
      return;
    }

    final isCurrentlySubscribed = _subscriptionStatus[shop.id] ?? false;

    try {
      if (isCurrentlySubscribed) {
        await FirebaseSubscriptionService.unsubscribeFromShop(shop.id);
        if (mounted && !_isDisposed) {
          setState(() {
            _subscriptionStatus[shop.id] = false;
          });
        }
        await _loadSubscribedShops();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.unsubscribe, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Unsubscribed from ${shop.name}'),
                ],
              ),
              backgroundColor: EatoTheme.warningColor,
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
          'distance': 2.5,
          'deliveryTime': 30,
        };

        await FirebaseSubscriptionService.subscribeToShop(shop.id, shopData);
        if (mounted && !_isDisposed) {
          setState(() {
            _subscriptionStatus[shop.id] = true;
          });
        }
        await _loadSubscribedShops();

        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Subscribed to ${shop.name}'),
                ],
              ),
              backgroundColor: EatoTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ShopsPage] Error toggling subscription: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAuthRequiredDialog() {
    if (_isDisposed) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: EatoTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please log in to subscribe to restaurants and get updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _viewShopMenu(Store shop) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ShopMenuModal(
          shopId: shop.id,
          shopName: shop.name,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load menu: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _unsubscribeFromShop(Store shop) async {
    if (_isDisposed) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.unsubscribe, color: EatoTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Unsubscribe'),
          ],
        ),
        content:
            Text('Are you sure you want to unsubscribe from ${shop.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.warningColor),
            child: const Text('Unsubscribe',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseSubscriptionService.unsubscribeFromShop(shop.id);
        await _loadSubscribedShops();

        if (mounted) {
          if (mounted && !_isDisposed) {
            setState(() {
              _subscriptionStatus[shop.id] = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Unsubscribed from ${shop.name}'),
                ],
              ),
              backgroundColor: EatoTheme.warningColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unsubscribe: $e'),
              backgroundColor: EatoTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  DeliveryMode _parseDeliveryMode(Map<String, dynamic> shopData) {
    if (shopData.containsKey('deliveryMode')) {
      final mode = shopData['deliveryMode'] as String?;
      switch (mode?.toLowerCase()) {
        case 'pickup':
          return DeliveryMode.pickup;
        case 'delivery':
          return DeliveryMode.delivery;
        case 'both':
          return DeliveryMode.both;
        default:
          return DeliveryMode.pickup;
      }
    }

    final isPickup = shopData['isPickup'] as bool? ?? true;
    return isPickup ? DeliveryMode.pickup : DeliveryMode.delivery;
  }

  void _onBottomNavTap(int index) {
    if (index == 1 || _isDisposed) {
      return;
    }
    if (_showSearchBar) {
      setState(() {
        _showSearchBar = false;
        _searchController.clear();
        _filteredShops = List.from(_allShops);
      });
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
      appBar: _showSearchBar
          ? AppBar(
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: EatoTheme.textSecondaryColor),
                ),
                style: EatoTheme.bodyMedium,
                onChanged: (value) {
                  _performSearch(value);
                },
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              actions: [
                IconButton(
                  icon: Icon(Icons.close, color: EatoTheme.textSecondaryColor),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = false;
                      _searchController.clear();
                      _filteredShops = List.from(_allShops);
                    });
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: EatoTheme.primaryColor,
                labelColor: EatoTheme.primaryColor,
                unselectedLabelColor: EatoTheme.textSecondaryColor,
                labelStyle:
                    EatoTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3.0,
                splashFactory: InkRipple.splashFactory,
                tabs: const [
                  Tab(text: 'All Shops'),
                  Tab(text: 'Subscribed'),
                ],
              ),
            )
          : EatoComponents.appBar(
              context: context,
              title: 'Shops',
              titleIcon: Icons.store,
              actions: [
                IconButton(
                  onPressed: () => setState(() => _showSearchBar = true),
                  icon: Icon(Icons.search, color: EatoTheme.textSecondaryColor),
                  tooltip: 'Search Shops',
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: EatoTheme.primaryColor,
                labelColor: EatoTheme.primaryColor,
                unselectedLabelColor: EatoTheme.textSecondaryColor,
                labelStyle:
                    EatoTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3.0,
                splashFactory: InkRipple.splashFactory,
                tabs: const [
                  Tab(text: 'All Shops'),
                  Tab(text: 'Subscribed'),
                ],
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: EatoTheme.primaryColor))
                : _error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        physics:
                            const BouncingScrollPhysics(), // Enable smooth swiping
                        children: [
                          _buildAllShopsTab(),
                          _buildSubscribedShopsTab(),
                        ],
                      ),
          ),
          if (widget.showBottomNav)
            BottomNavBar(
              currentIndex: 1,
              onTap: _onBottomNavTap,
            ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    print('🔍 Searching for: "$query"');
    print('📊 All shops count: ${_allShops.length}');

    setState(() {
      if (query.isEmpty) {
        _filteredShops = List.from(_allShops);
        print('✅ Reset to all shops: ${_filteredShops.length}');
      } else {
        _filteredShops = _allShops
            .where((shop) =>
                shop.name.toLowerCase().contains(query.toLowerCase()) ||
                (shop.location?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
        print('🎯 Filtered shops: ${_filteredShops.length}');

        // Debug: Print shop names being checked
        for (var shop in _allShops.take(3)) {
          print('   Checking: ${shop.name} | ${shop.location}');
        }
      }
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: EatoTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: EatoTheme.headingMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Try Again', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllShopsTab() {
    final shopsToShow =
        _searchController.text.isEmpty ? _allShops : _filteredShops;

    print('🏪 Building shops tab:');
    print('   Search text: "${_searchController.text}"');
    print('   All shops: ${_allShops.length}');
    print('   Filtered shops: ${_filteredShops.length}');
    print('   Showing: ${shopsToShow.length}');
    if (shopsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined,
                size: 64, color: EatoTheme.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No Shops Available'
                  : 'No shops found',
              style: EatoTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Check back later for new restaurants'
                  : 'Try a different search term',
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllShops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shopsToShow.length,
        itemBuilder: (context, index) {
          final shop = shopsToShow[index];
          final isSubscribed = _subscriptionStatus[shop.id] ?? false;

          return ShopCard(
            shop: shop,
            isSubscribed: isSubscribed,
            showSubscribeButton: true,
            onSubscriptionToggle: () => _toggleSubscription(shop),
            onViewMenu: () => _viewShopMenu(shop),
          );
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
            Icon(Icons.login, size: 64, color: EatoTheme.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              'Login Required',
              style: EatoTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in to view your subscriptions',
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Login', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: EatoTheme.primaryColor),
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
            Icon(Icons.favorite_border,
                size: 64, color: EatoTheme.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              'No Subscriptions Yet',
              style: EatoTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Subscribe to restaurants in the "All Shops" tab to see them here',
                textAlign: TextAlign.center,
                style: EatoTheme.bodyMedium.copyWith(
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.store, color: Colors.white),
              label: const Text('Browse Shops',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: EatoTheme.primaryColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscribedShops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subscribedShops.length,
        itemBuilder: (context, index) {
          final shopData = _subscribedShops[index];
          final shop = Store(
            id: shopData['shopId'] ?? '',
            name: shopData['shopName'] ?? 'Unknown Shop',
            contact: shopData['shopContact'] ?? '',
            deliveryMode: _parseDeliveryMode(shopData),
            imageUrl: shopData['shopImage'] ?? '',
            foods: [],
            ownerUid: '',
            isActive: true,
            isAvailable: true,
            location: shopData['shopLocation'],
            rating: (shopData['shopRating'] ?? 0.0).toDouble(),
          );

          return SubscribedShopCard(
            shop: shop,
            shopData: shopData,
            onViewMenu: () => _viewShopMenu(shop),
            onUnsubscribe: () => _unsubscribeFromShop(shop),
          );
        },
      ),
    );
  }
}
