// File: lib/widgets/bottom_nav_bar.dart (Updated to work with backend integration)

import 'package:flutter/material.dart';
import 'package:eato/services/CartService.dart'; // Import the updated CartService

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload cart count when widget updates
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      // Use the updated CartService method
      final cartItems = await CartService.getCartItems();
      int totalCount = 0;

      for (var item in cartItems) {
        totalCount += item['quantity'] as int;
      }

      if (mounted) {
        setState(() {
          _cartCount = totalCount;
        });
      }
    } catch (e) {
      print('Error loading cart count in bottom nav: $e');
      // Set to 0 on error to prevent UI issues
      if (mounted) {
        setState(() {
          _cartCount = 0;
        });
      }
    }
  }

  // Public method to refresh cart count from outside
  void refreshCartCount() {
    _loadCartCount();
  }

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
                isSelected: widget.currentIndex == 0,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.favorite,
                label: 'shops',
                isSelected: widget.currentIndex == 1,
                index: 1,
              ),
              // Empty space for the center button
              const SizedBox(width: 65),
              _buildNavItem(
                icon: Icons.timeline,
                label: 'Activity',
                isSelected: widget.currentIndex == 3,
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Account',
                isSelected: widget.currentIndex == 4,
                index: 4,
              ),
            ],
          ),

          // Center floating cart button with real count
          Positioned(
            top: -20,
            child: _buildCartButton(),
          ),

          // Selection indicator lines
          _buildSelectionIndicator(context),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    // Skip if center button is selected
    if (widget.currentIndex == 2) {
      return const SizedBox.shrink();
    }

    // Calculate position based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;

    // Adjust positions for each tab (manually tuned)
    double leftPosition;
    switch (widget.currentIndex) {
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
      onTap: () => widget.onTap(index),
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

  Widget _buildCartButton() {
    return GestureDetector(
      onTap: () {
        widget.onTap(2);
        // Refresh cart count after navigation
        Future.delayed(Duration(milliseconds: 500), () {
          _loadCartCount();
        });
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.currentIndex == 2 ? Colors.purpleAccent : Colors.purple,
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
                size: 30,
              ),

              // Real cart count badge
              if (_cartCount > 0)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        _cartCount > 99 ? '99+' : '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
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

// ===============================================
// Enhanced Bottom Nav Bar with Cart Refresh
// ===============================================

/// Enhanced version that can be used to automatically refresh cart count
/// when cart items change throughout the app
class EnhancedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const EnhancedBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedBottomNavBar> createState() => _EnhancedBottomNavBarState();
}

class _EnhancedBottomNavBarState extends State<EnhancedBottomNavBar>
    with WidgetsBindingObserver {
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCartCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh cart count when app resumes
    if (state == AppLifecycleState.resumed) {
      _loadCartCount();
    }
  }

  @override
  void didUpdateWidget(EnhancedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload cart count when widget updates
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      final cartItems = await CartService.getCartItems();
      int totalCount = 0;

      for (var item in cartItems) {
        totalCount += item['quantity'] as int;
      }

      if (mounted) {
        setState(() {
          _cartCount = totalCount;
        });
      }
    } catch (e) {
      print('Error loading cart count in enhanced bottom nav: $e');
      if (mounted) {
        setState(() {
          _cartCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
    );
  }
}

// ===============================================
// Global Cart State Notifier (Optional)
// ===============================================

/// A simple notifier that can be used to update cart count globally
class CartCountNotifier extends ChangeNotifier {
  int _cartCount = 0;

  int get cartCount => _cartCount;

  Future<void> updateCartCount() async {
    try {
      final cartItems = await CartService.getCartItems();
      int totalCount = 0;

      for (var item in cartItems) {
        totalCount += item['quantity'] as int;
      }

      _cartCount = totalCount;
      notifyListeners();
    } catch (e) {
      print('Error updating cart count: $e');
      _cartCount = 0;
      notifyListeners();
    }
  }

  void clearCount() {
    _cartCount = 0;
    notifyListeners();
  }
}
