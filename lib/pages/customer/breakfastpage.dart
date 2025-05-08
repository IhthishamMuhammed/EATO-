import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BreakfastMenuPage(),
    );
  }
}

class BreakfastMenuPage extends StatelessWidget {
  const BreakfastMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () {
                        print('Back button pressed');
                        // Navigate back logic here
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title
                    const SizedBox(height: 20),
                    const Text(
                      'Breakfast',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    // Search bar
                    const SizedBox(height: 20),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey.shade500),
                            const SizedBox(width: 10),
                            Text(
                              'Search by Category',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Menu items grid
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: const [
                          FoodCategoryItem(
                            title: 'Rice and Curry',
                            imagePath: 'assets/rice_curry.png',
                          ),
                          FoodCategoryItem(
                            title: 'String Hoppers',
                            imagePath: 'assets/string_hoppers.png',
                          ),
                          FoodCategoryItem(
                            title: 'Roti',
                            imagePath: 'assets/roti.png',
                          ),
                          FoodCategoryItem(
                            title: 'Egg Roti',
                            imagePath: 'assets/egg_roti.png',
                          ),
                          FoodCategoryItem(
                            title: 'Short Eats',
                            imagePath: 'assets/short_eats.png',
                          ),
                          FoodCategoryItem(
                            title: 'Hoppers',
                            imagePath: 'assets/hoppers.png',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar - same as previous code
            CustomBottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                print('Navigated to index: $index');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FoodCategoryItem extends StatelessWidget {
  final String title;
  final String imagePath;

  const FoodCategoryItem({
    Key? key,
    required this.title,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8D7F3), // Light pink color
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Food Image
          SizedBox(
            height: 100,
            width: 100,
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          // Food Category Name
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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