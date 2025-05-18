import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:eato/pages/customer/meal_pages.dart';
import 'package:eato/pages/customer/account_page.dart';

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

    // Handle navigation to appropriate screen based on index
    if (index != 0) {
      // Navigate to the appropriate screen based on index
      // This is handled by the BottomNavBar widget itself now
    }
  }

  // Navigate to meal type page
  void _navigateToMealPage(BuildContext context, String mealType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPage(mealType: mealType),
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
        currentPage = const SubscribedPage();
        break;
      case 2:
        currentPage = const OrdersPage();
        break;
      case 3:
        currentPage = const ActivityPage();
        break;
      case 4:
        currentPage = const AccountPage();
        break;
      default:
        currentPage = _buildHomePage(context);
    }

    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  // Build the main home page with meal options
  Widget _buildHomePage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'WELCOME',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select your meal option',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            // Breakfast Button
            MealButton(
              title: 'BREAKFAST',
              imagePath: 'assets/breakfast.jpg',
              onTap: () => _navigateToMealPage(context, 'Breakfast'),
            ),
            const SizedBox(height: 20),
            // Lunch Button
            MealButton(
              title: 'LUNCH',
              imagePath: 'assets/lunch.jpg',
              onTap: () => _navigateToMealPage(context, 'Lunch'),
            ),
            const SizedBox(height: 20),
            // Dinner Button
            MealButton(
              title: 'DINNER',
              imagePath: 'assets/dinner.jpg',
              onTap: () => _navigateToMealPage(context, 'Dinner'),
            ),
          ],
        ),
      ),
    );
  }
}

// Meal Button widget
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

// Placeholder pages for the bottom navigation tabs
class SubscribedPage extends StatelessWidget {
  const SubscribedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 80,
              color: Colors.purple.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Subscriptions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your subscribed food providers will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart,
              size: 80,
              color: Colors.purple.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your orders will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityPage extends StatelessWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble,
              size: 80,
              color: Colors.purple.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your recent activity and notifications will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
