// FILE: lib/widgets/shop_card.dart
// Enhanced shop card widget with better UI and larger elements

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

  const ShopCard({
    Key? key,
    required this.shop,
    required this.isSubscribed,
    required this.showSubscribeButton,
    required this.onSubscriptionToggle,
    required this.onViewMenu,
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
              : Colors.black.withOpacity(0.15), // Black shade outline
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Darker shadow
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
            padding: const EdgeInsets.all(16), // Increased from 12
            child: Row(
              children: [
                // Larger shop image with enhanced styling
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
                            width: 70, // Increased from 50
                            height: 70, // Increased from 50
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
                                size: 35, // Increased from 25
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

                const SizedBox(width: 16), // Increased from 12

                // Shop details with larger text
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
                                fontSize: 17, // Increased from 15
                                fontWeight: FontWeight.w700, // Bolder
                                color: EatoTheme.textPrimaryColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (showSubscribeButton)
                            GestureDetector(
                              onTap: onSubscriptionToggle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4), // Increased padding
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
                                  borderRadius:
                                      BorderRadius.circular(12), // More rounded
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
                                      size: 14, // Increased from 12
                                      color: isSubscribed
                                          ? EatoTheme.primaryColor
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(
                                        width: 4), // Increased from 2
                                    Text(
                                      isSubscribed ? 'Subscribed' : 'Subscribe',
                                      style: TextStyle(
                                        fontSize: 11, // Increased from 10
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

                      const SizedBox(height: 6), // Increased from 4

                      // Enhanced shop stats row with better spacing
                      Row(
                        children: [
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
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, // Increased from 12
                                    color: EatoTheme.primaryColor
                                        .withOpacity(0.7)),
                                const SizedBox(width: 4), // Increased from 2
                                Expanded(
                                  child: Text(
                                    shop.location ?? 'Location not specified',
                                    style: TextStyle(
                                      fontSize: 12, // Increased from 11
                                      color: EatoTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Delivery mode badge in separate row for better visibility
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4), // Increased padding
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
                                  shop.isPickup
                                      ? Icons.store
                                      : Icons.delivery_dining,
                                  size: 12, // Increased from 10
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4), // Increased from 2
                                Text(
                                  _getDeliveryModeText(shop),
                                  style: TextStyle(
                                    fontSize: 10, // Increased from 9
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

          // Compact View Menu button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 36, // Increased from 28
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
                    Icon(Icons.restaurant_menu, size: 16), // Increased from 14
                    SizedBox(width: 6), // Increased from 4
                    Text(
                      'View Menu',
                      style: TextStyle(
                        fontSize: 14, // Increased from 11
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3, // Increased for better readability
                        color: Colors.white, // Explicitly set white color
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
}
