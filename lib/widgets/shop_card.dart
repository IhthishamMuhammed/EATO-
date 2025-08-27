

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class ShopCard extends StatelessWidget {
  final Store shop;
  final bool isSubscribed;
  final bool showSubscribeButton;
  final VoidCallback onSubscriptionToggle;
  final VoidCallback onViewMenu;
  final int? subscriberCount; // NEW: Add subscriber count
  final int? totalFoodItems; // NEW: Add total food items

  const ShopCard({
    Key? key,
    required this.shop,
    required this.isSubscribed,
    required this.showSubscribeButton,
    required this.onSubscriptionToggle,
    required this.onViewMenu,
    this.subscriberCount, // NEW: Optional subscriber count
    this.totalFoodItems, // NEW: Optional total food items
  }) : super(key: key);

  String _getDeliveryModeText(Store shop) {
    switch (shop.deliveryMode) {
      case DeliveryMode.pickup:
        return 'Pickup';
      case DeliveryMode.delivery:
        return 'Delivery';
      case DeliveryMode.both:
        return 'Both';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubscribed
              ? EatoTheme.primaryColor.withOpacity(0.4)

              : Colors.black.withOpacity(0.15),

          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(

            color: Colors.black.withOpacity(0.1),

            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(

            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Shop image with enhanced styling

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: shop.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: shop.imageUrl,

                            width: 70,
                            height: 70,

                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[300],
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: EatoTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.store,

                                size: 35,

                                color: EatoTheme.primaryColor,
                              ),
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: EatoTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 35,
                              color: EatoTheme.primaryColor,
                            ),
                          ),
                  ),
                ),


                const SizedBox(width: 16),

                // Shop details with enhanced layout

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: TextStyle(

                                fontSize: 17,
                                fontWeight: FontWeight.w700,

                                color: EatoTheme.textPrimaryColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Subscribe/Subscribed button - only show if showSubscribeButton is true
                          if (showSubscribeButton)
                            GestureDetector(
                              onTap: onSubscriptionToggle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(

                                    horizontal: 10, vertical: 4),

                                decoration: BoxDecoration(
                                  gradient: isSubscribed
                                      ? LinearGradient(
                                          colors: [
                                            EatoTheme.primaryColor
                                                .withOpacity(0.1),
                                            EatoTheme.primaryColor
                                                .withOpacity(0.05),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.withOpacity(0.1),
                                            Colors.grey.withOpacity(0.05),
                                          ],
                                        ),

                                  borderRadius: BorderRadius.circular(12),

                                  border: Border.all(
                                    color: isSubscribed
                                        ? EatoTheme.primaryColor
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSubscribed
                                          ? Icons.favorite
                                          : Icons.favorite_border,

                                      size: 14,

                                      color: isSubscribed
                                          ? EatoTheme.primaryColor
                                          : Colors.grey.shade600,
                                    ),

                                    const SizedBox(width: 4),
                                    Text(
                                      isSubscribed ? 'Subscribed' : 'Subscribe',
                                      style: TextStyle(
                                        fontSize: 11,

                                        fontWeight: FontWeight.w600,
                                        color: isSubscribed
                                            ? EatoTheme.primaryColor
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),


                      const SizedBox(height: 6),

                      // Stats row with rating, subscriber count, and food items

                      Row(
                        children: [
                          // Rating badge
                          if ((shop.rating ?? 0) > 0) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star,
                                      size: 14, color: Colors.amber.shade600),
                                  SizedBox(width: 2),
                                  Text(
                                    '${(shop.rating ?? 0.0).toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],


                          // Subscriber count badge
                          if (subscriberCount != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EatoTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people,
                                      size: 14,
                                      color: EatoTheme.primaryColor
                                          .withOpacity(0.8)),
                                  SizedBox(width: 2),
                                  Text(
                                    '$subscriberCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: EatoTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Food items count badge
                          if (totalFoodItems != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EatoTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restaurant_menu,
                                      size: 14,
                                      color: EatoTheme.successColor
                                          .withOpacity(0.8)),
                                  SizedBox(width: 2),
                                  Text(
                                    '$totalFoodItems items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: EatoTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                        ],
                      ),

                      const SizedBox(height: 6),


                      // Delivery mode badge

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(

                                horizontal: 10, vertical: 4),

                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: shop.isPickup
                                    ? [
                                        EatoTheme.successColor,
                                        EatoTheme.successColor.withOpacity(0.8)
                                      ]
                                    : [
                                        EatoTheme.infoColor,
                                        EatoTheme.infoColor.withOpacity(0.8)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: (shop.isPickup
                                          ? EatoTheme.successColor
                                          : EatoTheme.infoColor)
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(

                                  _getDeliveryModeIcon(shop
                                      .deliveryMode), // ✅ Handles all three modes
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                // Fixed code

                                Text(
                                  _getDeliveryModeText(
                                      shop), // ✅ This will show Pickup/Delivery/Both correctly
                                  style: TextStyle(

                                    fontSize: 10,

                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
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

          // Replace the bottom Container with this:
          Container(
            padding: const EdgeInsets.fromLTRB(
                16, 8, 16, 12), // Increased top and bottom padding
            child: SizedBox(
              width: double.infinity,
              height: 50, // Increased from 36 to 40

              child: ElevatedButton(
                onPressed: onViewMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EatoTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: EatoTheme.primaryColor.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Icon(Icons.restaurant_menu, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'View Menu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Colors.white,

                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeliveryModeIcon(DeliveryMode mode) {
    switch (mode) {
      case DeliveryMode.pickup:
        return Icons.store;
      case DeliveryMode.delivery:
        return Icons.delivery_dining;
      case DeliveryMode.both:
        return Icons.compare_arrows; // or Icons.local_shipping
    }
  }
}
