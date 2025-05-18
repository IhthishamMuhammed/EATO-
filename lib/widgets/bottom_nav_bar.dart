import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
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
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: currentIndex == 2 ? Colors.purpleAccent : Colors.purple,
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.shopping_cart, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
