// FILE: lib/pages/customer/homepage/customer_home.dart
// Clean Customer Home Page with separated notification functionality

import 'package:eato/pages/customer/Orders_Page.dart';
import 'package:eato/pages/customer/homepage/meal_category_page.dart';
import 'package:eato/services/order_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/customer/account_page.dart';
import 'package:eato/pages/customer/activity_page.dart';
import 'package:eato/pages/customer/shops_page.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/widgets/notification_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  // ✅ PREVENT USERPROVIDER REBUILDS: Store user state locally
  bool _userLoaded = false;
  bool _userLoading = false;

  // ✅ ROBUST IMAGE LOADING: Multiple fallback URLs for each meal
  final Map<String, List<String>> _mealImageOptions = {
    'BREAKFAST': [
      'https://images.unsplash.com/photo-1551218808-94e220e084d2?q=80&w=600',
      'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://cdn.pixabay.com/photo/2017/05/07/08/56/pancakes-2291908_960_720.jpg',
    ],
    'LUNCH': [
      'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://cdn.pixabay.com/photo/2017/12/09/08/18/pizza-3007395_960_720.jpg',
    ],
    'DINNER': [
      'https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=600',
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=600',
      'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://cdn.pixabay.com/photo/2016/12/26/17/28/spaghetti-1932466_960_720.jpg',
    ],
  };

  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print("🚀 CustomerHomePage: initState called");

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initializeAppInBackground();
    _animationController.forward();
  }

  Future<void> _initializeAppInBackground() async {
    if (_isDisposed) return;

    try {
      // ✅ FIXED: Load user once and store state locally
      final User? authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null &&
          mounted &&
          !_isDisposed &&
          !_userLoaded &&
          !_userLoading) {
        setState(() {
          _userLoading = true;
        });

        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Only fetch if user is not already loaded
        if (userProvider.currentUser == null ||
            userProvider.currentUser!.id != authUser.uid) {
          print("📥 Fetching user data for the first time...");
          await userProvider.fetchUser(authUser.uid);
        }

        if (mounted && !_isDisposed) {
          setState(() {
            _userLoaded = true;
            _userLoading = false;
          });
          print("✅ User loaded and state saved locally");
        }
      }

      print("✅ Using direct image URLs with fallbacks");
    } catch (e) {
      print("⚠️ Background initialization failed: $e");
      if (mounted && !_isDisposed) {
        setState(() {
          _userLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    print("🗑️ CustomerHomePage: dispose called");
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    print(
        "🔄 Tab tapped: $index (current: $_currentIndex, disposed: $_isDisposed, mounted: $mounted)");

    if (index == _currentIndex) {
      print("   → Same tab, ignoring");
      return;
    }

    if (_isDisposed || !mounted) {
      print("   → Widget disposed or unmounted, ignoring");
      return;
    }

    print("✅ Switching from tab $_currentIndex to $index");

    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToMealPage(String mealType) {
    if (_isDisposed) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealCategoryPage(
          mealTime: mealType,
          showBottomNav: false,
        ),
      ),
    );
  }

  // ===================================================================
  // 🏗️ BUILD METHODS
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print(
        "🏗️ CustomerHomePage: build called (currentIndex: $_currentIndex, userLoaded: $_userLoaded, userLoading: $_userLoading)");

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildBody() {
    // ✅ FIXED: Use local state instead of Consumer to prevent rebuilds
    if (_userLoading) {
      print("⏳ Showing loading indicator...");
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(EatoTheme.primaryColor),
        ),
      );
    }

    if (!_userLoaded) {
      print("❌ User not loaded, showing login message");
      return const Center(
        child: Text('Please log in to continue'),
      );
    }

    print("✅ Rendering IndexedStack with index $_currentIndex");

    // ✅ STABLE: IndexedStack with no Consumer to prevent rebuilds
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeContent(), // 0: Home
        const ShopsPage(showBottomNav: false), // 1: Shops
        const OrdersPage(showBottomNav: false), // 2: Orders
        const ActivityPage(showBottomNav: false), // 3: Activity
        const AccountPage(showBottomNav: false), // 4: Account
      ],
    );
  }

  Widget _buildHomeContent() {
    print("🏠 Building home content widget");
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.restaurant, color: EatoTheme.primaryColor, size: 32),
            const SizedBox(width: 8),
            Text(
              'EATO',
              style: EatoTheme.headingLarge.copyWith(
                color: EatoTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          // 🔔 Clean notification widget integration
          NotificationWidget(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section - Use Provider here only, not at top level
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.currentUser;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello ${user?.name ?? 'Guest'} 👋',
                          style: EatoTheme.headingMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What would you like to eat today?',
                          style: EatoTheme.bodyMedium.copyWith(
                            color: EatoTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Quick Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        'Order Now',
                        Icons.restaurant,
                        EatoTheme.primaryColor,
                        () {
                          print("🎯 Order Now button pressed");
                          _onTabTapped(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Track Order',
                        Icons.delivery_dining,
                        Colors.orange,
                        () {
                          print("🎯 Track Order button pressed");
                          _onTabTapped(3);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Meal Categories Section
                Text(
                  'Explore by Meal Time',
                  style: EatoTheme.headingSmall,
                ),
                const SizedBox(height: 16),

                // ✅ ROBUST MEAL TIME CARDS: With fallback image loading
                Column(
                  children: [
                    _buildMealTimeCard(
                      'BREAKFAST',
                      'Start your day right',
                      _mealImageOptions['BREAKFAST']!,
                      () => _navigateToMealPage('Breakfast'),
                    ),
                    const SizedBox(height: 16),
                    _buildMealTimeCard(
                      'LUNCH',
                      'Fuel your afternoon',
                      _mealImageOptions['LUNCH']!,
                      () => _navigateToMealPage('Lunch'),
                    ),
                    const SizedBox(height: 16),
                    _buildMealTimeCard(
                      'DINNER',
                      'End your day deliciously',
                      _mealImageOptions['DINNER']!,
                      () => _navigateToMealPage('Dinner'),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: EatoTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ROBUST MEAL TIME CARD: With multiple fallback URLs
  Widget _buildMealTimeCard(
    String title,
    String subtitle,
    List<String> imageUrls,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // ✅ ROBUST IMAGE: Using fallback widget
              Positioned.fill(
                child: _ImageWithFallbacks(
                  imageUrls: imageUrls,
                  fit: BoxFit.cover,
                  loadingWidget: Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          EatoTheme.primaryColor.withOpacity(0.3),
                          EatoTheme.primaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 32,
                            color: EatoTheme.primaryColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: EatoTheme.bodySmall.copyWith(
                              color: EatoTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Text content
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EatoTheme.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: EatoTheme.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ HELPER WIDGET: Image widget that tries multiple URLs automatically
class _ImageWithFallbacks extends StatefulWidget {
  final List<String> imageUrls;
  final BoxFit fit;
  final Widget loadingWidget;
  final Widget errorWidget;

  const _ImageWithFallbacks({
    required this.imageUrls,
    required this.fit,
    required this.loadingWidget,
    required this.errorWidget,
  });

  @override
  _ImageWithFallbacksState createState() => _ImageWithFallbacksState();
}

class _ImageWithFallbacksState extends State<_ImageWithFallbacks> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _currentIndex >= widget.imageUrls.length) {
      return widget.errorWidget;
    }

    if (_isLoading) {
      return Stack(
        children: [
          widget.loadingWidget,
          _buildCurrentImage(),
        ],
      );
    }

    return _buildCurrentImage();
  }

  Widget _buildCurrentImage() {
    if (_currentIndex >= widget.imageUrls.length) {
      return widget.errorWidget;
    }

    return Image.network(
      widget.imageUrls[_currentIndex],
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image loaded successfully
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          });
          return child;
        }
        // Still loading, show nothing (loading widget is shown from parent Stack)
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        print(
            '❌ [HomePage] Image failed to load: ${widget.imageUrls[_currentIndex]} - Error: $error');

        // Try next image URL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (_currentIndex < widget.imageUrls.length - 1) {
              // Try next image
              print(
                  '🔄 [HomePage] Trying next image URL: ${widget.imageUrls[_currentIndex + 1]}');
              setState(() {
                _currentIndex++;
                _isLoading = true;
              });
            } else {
              // All images failed, show error widget
              print(
                  '💥 [HomePage] All ${widget.imageUrls.length} image URLs failed, showing error widget');
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          }
        });

        return const SizedBox.shrink();
      },
    );
  }
}
