import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/customer/meal_pages.dart';
import 'package:eato/pages/customer/account_page.dart';
import 'package:eato/pages/customer/activity_page.dart';
import 'package:eato/pages/customer/orders_page.dart';
import 'package:eato/pages/customer/subscribed_page.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
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
        builder: (context) => MealPage(
          mealType: mealType,
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
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text(
                'Home',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            )
          : null,
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

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
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Select your meal option',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.purple.shade600,
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
                    imagePath: 'assets/images/breakfast.jpg',
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
                    imagePath: 'assets/images/lunch.jpg',
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
                    imagePath: 'assets/images/logo.jpg',
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
    );
  }

  // Enhanced meal button with beautiful design
  Widget _buildEnhancedMealButton({
    required String title,
    required String imagePath,
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
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
