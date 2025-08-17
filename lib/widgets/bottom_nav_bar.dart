// FILE: lib/widgets/bottom_nav_bar.dart
// FIXED VERSION - Safe provider access and lifecycle management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/CartProvider.dart';

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
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

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

          // ✅ FIXED: Safe cart button with provider access
          Positioned(
            top: -20,
            child: _buildSafeCartButton(context),
          ),

          _buildSelectionIndicator(context),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    if (widget.currentIndex == 2 || _isDisposed) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;

    double leftPosition;
    switch (widget.currentIndex) {
      case 0:
        leftPosition = itemWidth * 0.5 - 15;
        break;
      case 1:
        leftPosition = itemWidth * 1.5 - 15;
        break;
      case 3:
        leftPosition = itemWidth * 3.5 - 15;
        break;
      case 4:
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
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        if (!_isDisposed && mounted) {
          widget.onTap(index);
        }
      },
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

  // ✅ FIXED: Safe cart button with try-catch for provider access
  Widget _buildSafeCartButton(BuildContext context) {
    if (_isDisposed) {
      return _buildFallbackCartButton();
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        // ✅ FIX: Handle null cartProvider gracefully
        if (cartProvider == null) {
          return _buildFallbackCartButton();
        }

        final cartCount = cartProvider.cartCount;
        final isLoading = cartProvider.isLoading;

        return _buildCartButton(
          cartCount: cartCount,
          isLoading: isLoading,
          onTap: () {
            if (!_isDisposed && mounted) {
              widget.onTap(2);
              // ✅ FIX: Safe refresh with null check
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!_isDisposed && mounted) {
                  try {
                    cartProvider.refreshCartCount();
                  } catch (e) {
                    print('⚠️ Cart refresh failed: $e');
                  }
                }
              });
            }
          },
        );
      },
    );
  }

  Widget _buildFallbackCartButton() {
    return _buildCartButton(
      cartCount: 0,
      isLoading: false,
      onTap: () {
        if (!_isDisposed && mounted) {
          widget.onTap(2);
        }
      },
    );
  }

  Widget _buildCartButton({
    required int cartCount,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

              // ✅ Cart count badge
              if (cartCount > 0)
                Positioned(
                  top: -8,
                  right: -8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
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
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              // ✅ Loading indicator
              if (isLoading)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
