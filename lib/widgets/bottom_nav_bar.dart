// FILE: lib/widgets/bottom_nav_bar.dart
// IMPROVED VERSION - Better alignment and modern UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
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

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  bool _isDisposed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main Navigation Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: widget.currentIndex == 0,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.store_rounded,
                label: 'Shops',
                isSelected: widget.currentIndex == 1,
                index: 1,
              ),
              const SizedBox(width: 70), // Space for cart button
              _buildNavItem(
                icon: Icons.timeline_rounded,
                label: 'Activity',
                isSelected: widget.currentIndex == 3,
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Account',
                isSelected: widget.currentIndex == 4,
                index: 4,
              ),
            ],
          ),

          // Floating Cart Button
          Positioned(
            top: -20,
            child: _buildSafeCartButton(context),
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
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (!_isDisposed && mounted) {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
          widget.onTap(index);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? EatoTheme.primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? EatoTheme.primaryColor
                          : EatoTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? EatoTheme.primaryColor
                          : EatoTheme.textSecondaryColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                  // Selection indicator dot
                  const SizedBox(height: 1),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 4 : 0,
                    height: isSelected ? 4 : 0,
                    decoration: BoxDecoration(
                      color: EatoTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSafeCartButton(BuildContext context) {
    if (_isDisposed) {
      return _buildFallbackCartButton();
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
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
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!_isDisposed && mounted) {
                  try {
                    cartProvider.refreshCartCount();
                  } catch (e) {
                    print('Cart refresh failed: $e');
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
    final isSelected = widget.currentIndex == 2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    EatoTheme.primaryColor.withOpacity(0.9),
                    EatoTheme.primaryColor,
                  ]
                : [
                    EatoTheme.primaryColor,
                    EatoTheme.primaryColor.withOpacity(0.8),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: EatoTheme.primaryColor.withOpacity(0.4),
              spreadRadius: isSelected ? 2 : 1,
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_cart_rounded,
                color: Colors.white,
                size: 28,
              ),

              // Cart count badge
              if (cartCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
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

              // Loading indicator
              if (isLoading)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
