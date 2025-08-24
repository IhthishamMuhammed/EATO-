import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/pages/provider/OrderHomePage.dart';
import 'package:eato/pages/provider/RequestHome.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
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
  bool _isDataInitialized = false;
  bool _isTransitioning = false;

  String? _storeId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Animation controller for smooth transitions
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

    // Initialize data immediately, not in post frame callback
    _initializeProviderData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeProviderData() async {
    if (_isDataInitialized) return;

    try {
      print('🔧 [ProviderMainNavigation] Initializing provider data...');

      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Ensure store data is available
      if (storeProvider.userStore == null) {
        print('📦 [ProviderMainNavigation] Fetching user store...');
        await storeProvider.fetchUserStore(widget.currentUser);
      }

      if (storeProvider.userStore != null) {
        final storeId = storeProvider.userStore!.id;
        _storeId = storeId; // ADD THIS LINE - Set the _storeId variable
        print('🏪 [ProviderMainNavigation] Store ID: $storeId');

        // Rest of your existing code...
        orderProvider.listenToStoreOrders(storeId);
        orderProvider.listenToStoreOrderRequests(storeId);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isDataInitialized = true;
            });
            print('✅ [ProviderMainNavigation] Data initialization complete');
          }
        });
      } else {
        print('❌ [ProviderMainNavigation] No store found for user');
      }
    } catch (e) {
      print('❌ [ProviderMainNavigation] Error initializing provider data: $e');
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex || _isTransitioning) return;

    setState(() {
      _isTransitioning = true;
    });

    // Smooth transition with fade effect
    _animationController.forward().then((_) {
      setState(() {
        _currentIndex = index;
      });

      // Smooth page transition
      _pageController
          .animateToPage(
        index,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      )
          .then((_) {
        _animationController.reverse().then((_) {
          setState(() {
            _isTransitioning = false;
          });
        });
      });
    });
  }

  void _onPageChanged(int index) {
    if (!_isTransitioning) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: BouncingScrollPhysics(), // Enable smooth swiping
            children: [
              // Orders Page (Index 0)
              _buildOrdersPage(),

              // Requests Page (Index 1)
              _buildRequestsPage(),

              // Menu/Provider Home Page (Index 2)
              _buildMenuPage(),

              // Profile Page (Index 3)
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
      stream: FirebaseFirestore.instance
          .collection('order_requests')
          .where('storeId', isEqualTo: _storeId!)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final requestCount = snapshot.data?.docs.length ?? 0;

        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            selectedItemColor: EatoTheme.primaryColor,
            unselectedItemColor: EatoTheme.textLightColor,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            iconSize: 24,
            mouseCursor: SystemMouseCursors.click,
            items: [
              BottomNavigationBarItem(
                icon: _buildTabIcon(Icons.receipt_outlined, 0),
                activeIcon: _buildTabIcon(Icons.receipt, 0),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _buildRequestsTabIcon(requestCount, false, 1),
                activeIcon: _buildRequestsTabIcon(requestCount, true, 1),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: _buildTabIcon(Icons.restaurant_menu_outlined, 2),
                activeIcon: _buildTabIcon(Icons.restaurant_menu, 2),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: _buildTabIcon(Icons.person_outline, 3),
                activeIcon: _buildTabIcon(Icons.person, 3),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 4 : 0),
      decoration: BoxDecoration(
        color: isSelected
            ? EatoTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: isSelected ? EatoTheme.primaryColor : EatoTheme.textLightColor,
      ),
    );
  }

  Widget _buildRequestsTabIcon(int requestCount, bool isActive, int index) {
    final isSelected = _currentIndex == index;

    // ✅ DEBUG: Print each time the badge is rebuilt
    print(
        '🎯 [ProviderMainNavigation] Building badge with count: $requestCount');

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 4 : 0),
      decoration: BoxDecoration(
        color: isSelected
            ? EatoTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            isActive ? Icons.notifications : Icons.notifications_outlined,
            color:
                isSelected ? EatoTheme.primaryColor : EatoTheme.textLightColor,
          ),
          if (requestCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: AnimatedScale(
                scale: 1.0, // ✅ FIXED: Always show when count > 0
                duration: Duration(milliseconds: 300), // Longer animation
                curve: Curves.elasticOut, // Bouncy animation
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: EatoTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                    // ✅ ENHANCED: Add subtle shadow to make badge more visible
                    boxShadow: [
                      BoxShadow(
                        color: EatoTheme.errorColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    requestCount > 99 ? '99+' : '$requestCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
