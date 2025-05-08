import 'package:flutter/material.dart';

void main() {
  runApp(const CustomerHomePage());
}

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MealSelectionPage(),
    );
  }
}

class MealSelectionPage extends StatelessWidget {
  const MealSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
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
                    onTap: () {
                      print('Breakfast selected');
                    },
                  ),
                  const SizedBox(height: 20),
                  // Lunch Button
                  MealButton(
                    title: 'LUNCH',
                    imagePath: 'assets/lunch.jpg',
                    onTap: () {
                      print('Lunch selected');
                    },
                  ),
                  const SizedBox(height: 20),
                  // Dinner Button
                  MealButton(
                    title: 'DINNER',
                    imagePath: 'assets/dinner.jpg',
                    onTap: () {
                      print('Dinner selected');
                    },
                  ),
                ],
              ),
            ),
          ),
          // Bottom Navigation Bar
          CustomBottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              print('Navigated to index: $index');
            },
          ),
        ],
      ),
    );
  }
}

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

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: currentIndex == 0,
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.favorite,
            label: 'Subscribed',
            isSelected: currentIndex == 1,
            index: 1,
          ),
          _buildOrdersButton(),
          _buildNavItem(
            icon: Icons.chat_bubble,
            label: 'Activity',
            isSelected: currentIndex == 3,
            index: 3,
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Account',
            isSelected: currentIndex == 4,
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: isSelected ? Colors.purple : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.purple : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.purple,
      ),
      child: const Center(
        child: Icon(Icons.shopping_cart, color: Colors.white, size: 26),
      ),
    );
  }
}