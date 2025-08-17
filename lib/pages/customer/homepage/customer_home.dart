import 'package:eato/pages/customer/Orders_Page.dart';
import 'package:eato/pages/customer/homepage/meal_category_page.dart';
import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/customer/account_page.dart';
import 'package:eato/pages/customer/activity_page.dart';
import 'package:eato/pages/customer/shops_page.dart';
import 'package:eato/EatoComponents.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Provider/FoodProvider.dart';

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

  final Map<String, String> _mealImageUrls = {
    'BREAKFAST':
        'https://images.unsplash.com/photo-1533089860892-a9b9ac6cd6b4?q=80&w=600',
    'LUNCH':
        'https://images.unsplash.com/photo-1547592180-85f173990888?q=80&w=600',
    'DINNER':
        'https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=600',
  };

  bool _isLoading = false;
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

      if (mounted && !_isDisposed) {
        _loadFirebaseImagesInBackground();
      }
    } catch (e) {
      print("⚠️ Background initialization failed: $e");
      if (mounted && !_isDisposed) {
        setState(() {
          _userLoading = false;
        });
      }
    }
  }

  Future<void> _loadFirebaseImagesInBackground() async {
    if (_isDisposed) return;

    try {
      final storage = FirebaseStorage.instance;

      final futures = [
        storage
            .ref()
            .child('meals/breakfast.jpg')
            .getDownloadURL()
            .catchError((_) => _mealImageUrls['BREAKFAST']!),
        storage
            .ref()
            .child('meals/lunch.jpg')
            .getDownloadURL()
            .catchError((_) => _mealImageUrls['LUNCH']!),
        storage
            .ref()
            .child('meals/dinner.jpg')
            .getDownloadURL()
            .catchError((_) => _mealImageUrls['DINNER']!),
      ];

      final urls = await Future.wait(futures);

      if (mounted && !_isDisposed) {
        setState(() {
          _mealImageUrls['BREAKFAST'] = urls[0];
          _mealImageUrls['LUNCH'] = urls[1];
          _mealImageUrls['DINNER'] = urls[2];
        });
        print("✅ Firebase images loaded successfully");
      }
    } catch (e) {
      print('Firebase images failed, using fallbacks: $e');
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Handle search
            },
          ),
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

                // Meal Time Cards
                Column(
                  children: [
                    _buildMealTimeCard(
                      'BREAKFAST',
                      'Start your day right',
                      _mealImageUrls['BREAKFAST']!,
                      () => _navigateToMealPage('Breakfast'),
                    ),
                    const SizedBox(height: 16),
                    _buildMealTimeCard(
                      'LUNCH',
                      'Fuel your afternoon',
                      _mealImageUrls['LUNCH']!,
                      () => _navigateToMealPage('Lunch'),
                    ),
                    const SizedBox(height: 16),
                    _buildMealTimeCard(
                      'DINNER',
                      'End your day deliciously',
                      _mealImageUrls['DINNER']!,
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

  Widget _buildMealTimeCard(
    String title,
    String subtitle,
    String imageUrl,
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
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: EatoTheme.primaryColor.withOpacity(0.1),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 48),
                      ),
                    );
                  },
                ),
              ),
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
