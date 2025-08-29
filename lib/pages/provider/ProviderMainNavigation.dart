// ProviderMainNavigation.dart - FIXED VERSION with Store Setup Navigation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/pages/auth/login.dart';
import 'package:eato/pages/provider/StoreSetupPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/pages/provider/OrderHomePage.dart';
import 'package:eato/pages/provider/RequestHome.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
// import 'package:eato/pages/provider/StoreSetupPage.dart'; // Add this import
import 'package:eato/pages/theme/eato_theme.dart';

class ProviderMainNavigation extends StatefulWidget {
  final CustomUser currentUser;
  final int initialIndex;

  const ProviderMainNavigation({
    Key? key,
    required this.currentUser,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _ProviderMainNavigationState createState() => _ProviderMainNavigationState();
}

class _ProviderMainNavigationState extends State<ProviderMainNavigation>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ FIX: Add proper loading states
  bool _isDataInitialized = false;
  bool _isInitializing = true;
  String? _initError;
  String? _storeId;
  bool _needsStoreSetup = false; // ✅ NEW: Track if store setup is needed

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // ✅ FIX: Initialize data immediately and wait
    _initializeProviderData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ FIX: Proper async initialization with store setup handling
  Future<void> _initializeProviderData() async {
    if (_isDataInitialized) return;

    try {
      print('🔧 [ProviderMainNavigation] Initializing provider data...');

      setState(() {
        _isInitializing = true;
        _initError = null;
        _needsStoreSetup = false;
      });

      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // ✅ STEP 1: Check if user has a store
      print('📦 [ProviderMainNavigation] Checking for user store...');
      await storeProvider.fetchUserStore(widget.currentUser);

      // ✅ STEP 2: Handle missing store case
      if (storeProvider.userStore == null) {
        print(
            '⚠️ [ProviderMainNavigation] No store found - redirecting to setup');

        if (mounted) {
          setState(() {
            _needsStoreSetup = true;
            _isInitializing = false;
            _isDataInitialized = false;
          });
        }
        return; // Exit early - don't proceed with order initialization
      }

      final storeId = storeProvider.userStore!.id;
      _storeId = storeId;

      print(
          '✅ [StoreProvider] Found store: $storeId (${storeProvider.userStore!.name})');

      // ✅ STEP 3: Initialize orders for this store
      await orderProvider.fetchOrdersForStore(storeId);
      print('📋 [OrderProvider] Orders initialized for store: $storeId');

      // ✅ STEP 4: Mark as initialized
      if (mounted) {
        setState(() {
          _isDataInitialized = true;
          _isInitializing = false;
          _initError = null;
          _needsStoreSetup = false;
        });
        print('✅ [ProviderMainNavigation] Data initialization complete');
      }
    } catch (e, stackTrace) {
      print('❌ [ProviderMainNavigation] Initialization failed: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isDataInitialized = false;
          _isInitializing = false;
          _initError = e.toString();
          _needsStoreSetup = false;
        });
      }
    }
  }

  // ✅ NEW: Navigate to store setup
  void _navigateToStoreSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreSetupPage(currentUser: widget.currentUser),
      ),
    ).then((_) {
      // Refresh data after returning from store setup
      _retryInitialization();
    });
  }

  // ✅ FIX: Retry initialization with better error handling
  void _retryInitialization() async {
    setState(() {
      _isDataInitialized = false;
      _isInitializing = true;
      _initError = null;
      _needsStoreSetup = false;
    });

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      await storeProvider.fetchUserStore(widget.currentUser);

      if (storeProvider.userStore == null) {
        // Show message and redirect to setup
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No store found. Please set up your store first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );

          setState(() {
            _needsStoreSetup = true;
            _isInitializing = false;
            _isDataInitialized = false;
          });
        }
        return;
      }

      // Continue with normal initialization
      _initializeProviderData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    if (!_isInitializing && _isDataInitialized) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW: Show store setup screen
    if (_needsStoreSetup) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Setup Your Store'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(role: 'mealprovider'),
                ),
              );
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 80,
                  color: EatoTheme.primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Welcome to Eato!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Let\'s set up your store to start receiving orders from customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _navigateToStoreSetup,
                  icon: Icon(Icons.add_business),
                  label: Text('Set Up My Store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EatoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _retryInitialization,
                  child: Text('I Already Have a Store'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: EatoTheme.primaryColor),
                    foregroundColor: EatoTheme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ FIX: Show loading screen while initializing
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(EatoTheme.primaryColor),
              ),
              SizedBox(height: 24),
              Text(
                'Setting up your store...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This won\'t take long',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ FIX: Show error screen with retry option
    if (_initError != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _retryInitialization,
                  icon: Icon(Icons.refresh),
                  label: Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EatoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: _navigateToStoreSetup,
                  child: Text('Set Up New Store Instead'),
                  style: TextButton.styleFrom(
                    foregroundColor: EatoTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ FIX: Only show main navigation when fully initialized
    if (!_isDataInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Initializing...'),
        ),
      );
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: BouncingScrollPhysics(),
            children: [
              _buildOrdersPage(),
              _buildRequestsPage(),
              _buildMenuPage(),
              _buildProfilePage(),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildOrdersPage() {
    return OrderHomePage(currentUser: widget.currentUser);
  }

  Widget _buildRequestsPage() {
    return RequestHome(currentUser: widget.currentUser);
  }

  Widget _buildMenuPage() {
    return ProviderHomePage(currentUser: widget.currentUser);
  }

  Widget _buildProfilePage() {
    return ProfilePage(currentUser: widget.currentUser);
  }

  Widget _buildBottomNavigationBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: _storeId != null
          ? FirebaseFirestore.instance
              .collection('order_requests')
              .where('storeId', isEqualTo: _storeId!)
              .where('status', isEqualTo: 'pending')
              .snapshots()
          : Stream.empty(),
      builder: (context, snapshot) {
        final requestCount = snapshot.data?.docs.length ?? 0;

        print(
            '🎯 [ProviderMainNavigation] Building badge with count: $requestCount');

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: EatoTheme.primaryColor,
            unselectedItemColor: Colors.grey[600],
            currentIndex: _currentIndex,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: requestCount > 0
                    ? Badge(
                        label: Text('$requestCount'),
                        child: Icon(Icons.notifications),
                      )
                    : Icon(Icons.notifications_none),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
