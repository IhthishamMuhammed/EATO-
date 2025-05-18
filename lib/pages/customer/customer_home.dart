import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/customer/meal_pages.dart';
import 'package:eato/pages/customer/account_page.dart';
import 'package:eato/pages/customer/activity_page.dart'; // Import actual ActivityPage
import 'package:eato/pages/customer/orders_page.dart'; // Import actual OrdersPage
import 'package:eato/pages/customer/subscribed_page.dart'; // Import actual SubscribedPage

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  // Current selected tab index
  int _currentIndex = 0;

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
              title: const Text('Home'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'WELCOME',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Select your meal option',
              style: TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Breakfast Button - Updated to match the second image
            _buildMealButtonWithImage(
              title: 'BREAKFAST',
              imagePath: 'assets/breakfast.jpg',
              onTap: () => _navigateToMealPage(context, 'Breakfast'),
            ),
            const SizedBox(height: 20),

            // Lunch Button - Updated to match the second image
            _buildMealButtonWithImage(
              title: 'LUNCH',
              imagePath: 'assets/lunch.jpg',
              onTap: () => _navigateToMealPage(context, 'Lunch'),
            ),
            const SizedBox(height: 20),

            // Dinner Button - Updated to match the second image
            _buildMealButtonWithImage(
              title: 'DINNER',
              imagePath: 'assets/dinner.jpg',
              onTap: () => _navigateToMealPage(context, 'Dinner'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // New method for meal buttons that look like the ones in image 2
  Widget _buildMealButtonWithImage({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            // Title Text
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the MealButton class but it's not being used now
class MealButton extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const MealButton({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              // Background Image
              Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              // Overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              // Title Text
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black,
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
}
