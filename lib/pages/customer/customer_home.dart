import 'package:eato/pages/customer/meal_category_page.dart';
import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/customer/account_page.dart';
import 'package:eato/pages/customer/activity_page.dart';
import 'package:eato/pages/customer/orders_page.dart';
import 'package:eato/pages/customer/subscribed_page.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with SingleTickerProviderStateMixin {
  // Current selected tab index
  int _currentIndex = 0;
  late AnimationController _animationController;

  // URLs for meal images - using placeholder images initially
  final Map<String, String> _mealImageUrls = {
    'BREAKFAST':
        'https://images.unsplash.com/photo-1533089860892-a9b9ac6cd6b4?q=80&w=600',
    'LUNCH':
        'https://images.unsplash.com/photo-1547592180-85f173990888?q=80&w=600',
    'DINNER':
        'https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=600',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Try to load image URLs from Firebase if available
    _loadImageUrls();
  }

  Future<void> _loadImageUrls() async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Try to get URLs from Firebase Storage
      final breakfastRef = storage.ref().child('meals/breakfast.jpg');
      final lunchRef = storage.ref().child('meals/lunch.jpg');
      final dinnerRef = storage.ref().child('meals/dinner.jpg');

      final breakfastUrl = await breakfastRef.getDownloadURL();
      final lunchUrl = await lunchRef.getDownloadURL();
      final dinnerUrl = await dinnerRef.getDownloadURL();

      // Update the map with actual Firebase URLs
      if (mounted) {
        setState(() {
          _mealImageUrls['BREAKFAST'] = breakfastUrl;
          _mealImageUrls['LUNCH'] = lunchUrl;
          _mealImageUrls['DINNER'] = dinnerUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If any error occurs, we'll use the fallback URLs
      print('Error loading image URLs from Firebase: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to handle tab change
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Navigate to meal type page
  void _navigateToMealPage(BuildContext context, String mealType) {
    Navigator.push(
      context,
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
    // Use a switch to determine which page to show based on current index
    Widget currentPage;

    switch (_currentIndex) {
      case 0:
        currentPage = _buildHomePage(context);
        break;
      case 1:
        currentPage = const SubscribedPage(showBottomNav: false);
        break;
      case 2:
        currentPage = const OrdersPage(showBottomNav: false);
        break;
      case 3:
        currentPage = const ActivityPage(showBottomNav: false);
        break;
      case 4:
        currentPage = const AccountPage(showBottomNav: false);
        break;
      default:
        currentPage = _buildHomePage(context);
    }

    return Scaffold(
      // Removed the AppBar
      body: currentPage,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  // Build the main home page with meal options
  Widget _buildHomePage(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30), // Increased top padding

                  // Welcome Text with Animation
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              'WELCOME',
                              style: TextStyle(
                                fontSize: 38, // Increased font size
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                                letterSpacing: 2.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'Select your meal option',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.purple.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Breakfast Button - Enhanced design
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.2, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                      )),
                      child: _buildEnhancedMealButton(
                        title: 'BREAKFAST',
                        imageUrl: _mealImageUrls['BREAKFAST']!,
                        onTap: () => _navigateToMealPage(context, 'Breakfast'),
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lunch Button - Enhanced design
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.2, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                      )),
                      child: _buildEnhancedMealButton(
                        title: 'LUNCH',
                        imageUrl: _mealImageUrls['LUNCH']!,
                        onTap: () => _navigateToMealPage(context, 'Lunch'),
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dinner Button - Enhanced design
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.2, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                      )),
                      child: _buildEnhancedMealButton(
                        title: 'DINNER',
                        imageUrl: _mealImageUrls['DINNER']!,
                        onTap: () => _navigateToMealPage(context, 'Dinner'),
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ));
  }

  // Enhanced meal button with beautiful design using standard network images
  Widget _buildEnhancedMealButton({
    required String title,
    required String imageUrl,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image with overlay
              Hero(
                tag: 'meal_$title',
                child: _isLoading
                    ? _buildLoadingPlaceholder(color)
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingPlaceholder(color);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildErrorPlaceholder(title, color);
                        },
                      ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Decorative elements
              Positioned(
                top: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    _getIconForMeal(title),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Title label
              Align(
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 36, // Increased font size from 24 to 36
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    shadows: [
                      // Added text shadow for better visibility
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading placeholder widget
  Widget _buildLoadingPlaceholder(Color color) {
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: 2,
        ),
      ),
    );
  }

  // Error placeholder widget
  Widget _buildErrorPlaceholder(String title, Color color) {
    return Container(
      color: color.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForMeal(title),
            size: 40,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get icon for each meal type
  IconData _getIconForMeal(String mealType) {
    switch (mealType.toUpperCase()) {
      case 'BREAKFAST':
        return Icons.coffee;
      case 'LUNCH':
        return Icons.restaurant;
      case 'DINNER':
        return Icons.dinner_dining;
      default:
        return Icons.food_bank;
    }
  }
}
