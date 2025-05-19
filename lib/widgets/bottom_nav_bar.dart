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
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main row with navigation items
          Row(
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
              // Empty space for the center button
              const SizedBox(width: 65),
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

          // Center floating button
          Positioned(
            top: -20,
            child: _buildOrdersButton(),
          ),

          // Selection indicator lines
          _buildSelectionIndicator(context),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    // Skip if center button is selected
    if (currentIndex == 2) {
      return const SizedBox.shrink();
    }

    // Calculate position based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;

    // Adjust positions for each tab (manually tuned)
    double leftPosition;
    switch (currentIndex) {
      case 0: // Home
        leftPosition = itemWidth * 0.5 - 15;
        break;
      case 1: // Subscribed
        leftPosition = itemWidth * 1.5 - 15;
        break;
      case 3: // Activity
        leftPosition = itemWidth * 3.5 - 15;
        break;
      case 4: // Account
        leftPosition = itemWidth * 4.5 - 15;
        break;
      default:
        leftPosition = 0;
    }

    return Positioned(
      bottom: 0,
      left: leftPosition,
      child: Container(
        height: 4,
        width: 30,
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required int index,
  }) {
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.purple : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.purple : Colors.grey,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersButton() {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 65, // Increased size
        height: 65, // Increased size
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: currentIndex == 2 ? Colors.purpleAccent : Colors.purple,
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 30, // Increased icon size
              ),

              // Cart item count badge - optional
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
}
