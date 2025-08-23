// FILE: lib/EatoComponents.dart
// Enhanced with new reusable components found across multiple pages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/pages/theme/eato_theme.dart';

/// EatoComponents provides reusable UI elements to maintain consistency across the app.
class EatoComponents {
  // ✅ EXISTING: Primary button with gradient background
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double width = double.infinity,
    double height = 50,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading
                ? LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : EatoTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: EatoTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: App Bar component (used across all pages)
  static AppBar appBar({
    required BuildContext context,
    required String title,
    IconData? titleIcon,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool centerTitle = true,
    Widget? leading,
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: centerTitle,
      leading: leading ??
          (Navigator.canPop(context)
              ? IconButton(
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_ios,
                      color: EatoTheme.textPrimaryColor),
                )
              : null),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleIcon != null) ...[
            Icon(titleIcon, color: EatoTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: EatoTheme.headingMedium.copyWith(
              color: EatoTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  // ✅ NEW: Loading Screen component (used in multiple places)
  static Widget loadingScreen({
    String message = 'Loading...',
    IconData icon = Icons.restaurant,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: EatoTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: EatoTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(EatoTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Meal Button component (used in Home page)
  static Widget mealButton({
    required String title,
    required String imageUrl,
    required Color color,
    required VoidCallback onTap,
    double height = 140,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(25),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: height,
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
                // Optimized image loading
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: color.withOpacity(0.2),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: color.withOpacity(0.3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getMealIcon(title),
                          size: 40,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

                // Icon decoration
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
                      _getMealIcon(title),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Title
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: EatoTheme.headingMedium.copyWith(
                      fontSize: 36,
                      color: color,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Shop Card component (used in shops page and meal pages)
  static Widget shopCard({
    required String shopName,
    required String shopImage,
    required double rating,
    required String location,
    String? deliveryTime,
    String? distance,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Shop image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: shopImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.store, color: Colors.grey.shade400),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.store, color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Shop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: EatoTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating row
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: EatoTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (deliveryTime != null) ...[
                          Icon(Icons.access_time,
                              color: EatoTheme.textSecondaryColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            deliveryTime,
                            style: EatoTheme.bodySmall.copyWith(
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: EatoTheme.textSecondaryColor, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: EatoTheme.bodySmall.copyWith(
                              color: EatoTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Food Card component (used in shop menus and meal pages)
  static Widget foodCard({
    required String name,
    required String imageUrl,
    required double price,
    required VoidCallback onTap,
    String? description,
    Map<String, double>? portionPrices,
    bool isAvailable = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Food image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.fastfood, color: Colors.grey.shade400),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.fastfood, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: EatoTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAvailable
                              ? EatoTheme.textPrimaryColor
                              : EatoTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: EatoTheme.bodySmall.copyWith(
                            color: EatoTheme.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Price section
                      if (portionPrices != null && portionPrices.isNotEmpty)
                        Text(
                          'From Rs. ${portionPrices.values.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}',
                          style: EatoTheme.labelMedium.copyWith(
                            color: EatoTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          'Rs. ${price.toStringAsFixed(0)}',
                          style: EatoTheme.labelMedium.copyWith(
                            color: EatoTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),

                // Action button
                if (isAvailable)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EatoTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: EatoTheme.primaryColor,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unavailable',
                      style: EatoTheme.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Add to Cart Modal (replaces direct adding)
  static Future<void> showAddToCartModal({
    required BuildContext context,
    required String foodName,
    required String foodImage,
    required double basePrice,
    required Map<String, double> portionPrices,
    required Function(String portion, int quantity, String? instructions)
        onAddToCart,
    String? description,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddToCartModal(
        foodName: foodName,
        foodImage: foodImage,
        basePrice: basePrice,
        portionPrices: portionPrices,
        onAddToCart: onAddToCart,
        description: description,
      ),
    );
  }

  // ✅ NEW: Tab Bar component (used in multiple pages)
  static Widget customTabBar({
    required List<String> tabs,
    required String selectedTab,
    required Function(String) onTabSelected,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isSelected = tab == selectedTab;
          return GestureDetector(
            onTap: () => onTabSelected(tab),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? EatoTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected
                        ? EatoTheme.primaryColor
                        : EatoTheme.textLightColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✅ EXISTING: Empty state component
  static Widget emptyState({
    required String message,
    IconData icon = Icons.search_off,
    VoidCallback? onActionPressed,
    String? actionText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: EatoTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 24),
              primaryButton(
                text: actionText,
                onPressed: onActionPressed,
                height: 40,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Helper methods
  static IconData _getMealIcon(String mealType) {
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

// ✅ NEW: Add to Cart Modal Widget
class _AddToCartModal extends StatefulWidget {
  final String foodName;
  final String foodImage;
  final double basePrice;
  final Map<String, double> portionPrices;
  final Function(String portion, int quantity, String? instructions)
      onAddToCart;
  final String? description;

  const _AddToCartModal({
    required this.foodName,
    required this.foodImage,
    required this.basePrice,
    required this.portionPrices,
    required this.onAddToCart,
    this.description,
  });

  @override
  State<_AddToCartModal> createState() => _AddToCartModalState();
}

class _AddToCartModalState extends State<_AddToCartModal> {
  String _selectedPortion = '';
  int _quantity = 1;
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default portion
    if (widget.portionPrices.isNotEmpty) {
      _selectedPortion = widget.portionPrices.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPrice =
        widget.portionPrices[_selectedPortion] ?? widget.basePrice;
    final totalPrice = selectedPrice * _quantity;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food image and name
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.foodImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.fastfood,
                                color: Colors.grey.shade400),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.fastfood,
                                color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.foodName,
                              style: EatoTheme.headingSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.description != null) ...[
                              SizedBox(height: 4),
                              Text(
                                widget.description!,
                                style: EatoTheme.bodySmall.copyWith(
                                  color: EatoTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Portion selection
                  if (widget.portionPrices.isNotEmpty) ...[
                    Text(
                      'Choose Portion Size',
                      style: EatoTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...widget.portionPrices.entries.map((entry) {
                      final isSelected = entry.key == _selectedPortion;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPortion = entry.key),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? EatoTheme.primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? EatoTheme.primaryColor.withOpacity(0.05)
                                : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: EatoTheme.bodyLarge.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? EatoTheme.primaryColor
                                      : EatoTheme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                'Rs. ${entry.value.toStringAsFixed(0)}',
                                style: EatoTheme.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: EatoTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 24),
                  ],

                  // Quantity selection
                  Text(
                    'Quantity',
                    style: EatoTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            _quantity.toString(),
                            style: EatoTheme.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onTap: () => setState(() => _quantity++),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Special instructions
                  Text(
                    'Special Instructions (Optional)',
                    style: EatoTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      hintText: 'Add any special requests...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          // Bottom section with price and add button
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price',
                      style: EatoTheme.labelLarge,
                    ),
                    Text(
                      'Rs. ${totalPrice.toStringAsFixed(0)}',
                      style: EatoTheme.headingSmall.copyWith(
                        color: EatoTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                EatoComponents.primaryButton(
                  text: 'Add to Cart',
                  onPressed: () {
                    widget.onAddToCart(
                      _selectedPortion,
                      _quantity,
                      _instructionsController.text.trim().isEmpty
                          ? null
                          : _instructionsController.text.trim(),
                    );
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.foodName} added to cart!'),
                        backgroundColor: EatoTheme.primaryColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Icon(
          icon,
          color: EatoTheme.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }
}
