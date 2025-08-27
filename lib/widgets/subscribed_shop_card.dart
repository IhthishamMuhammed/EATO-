// FILE: lib/widgets/subscribed_shop_card.dart
// Modified to match ShopCard size and fix button visibility

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class SubscribedShopCard extends StatelessWidget {
  final Store shop;
  final Map<String, dynamic> shopData;
  final VoidCallback onViewMenu;
  final VoidCallback onUnsubscribe;

  const SubscribedShopCard({
    Key? key,
    required this.shop,
    required this.shopData,
    required this.onViewMenu,
    required this.onUnsubscribe,
  }) : super(key: key);

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
          color: EatoTheme.primaryColor.withOpacity(0.4),
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
                // Shop image - same size as ShopCard
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

                // Shop details
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
                          // Subscribed badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  EatoTheme.primaryColor.withOpacity(0.1),
                                  EatoTheme.primaryColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EatoTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 14,
                                  color: EatoTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Subscribed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: EatoTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Stats row WITHOUT rating and time
                      Row(
                        children: [
                          Icon(Icons.people,
                              size: 14, color: EatoTheme.primaryColor),
                          const SizedBox(width: 2),
                          Text(
                            '${shopData['subscriberCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: EatoTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.restaurant_menu,
                              size: 14, color: EatoTheme.successColor),
                          const SizedBox(width: 2),
                          Text(
                            '${shopData['totalFoodItems'] ?? 0}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: EatoTheme.successColor,
                            ),
                          ),
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
                                  shop.isPickup
                                      ? Icons.store
                                      : Icons.delivery_dining,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shop.isPickup ? 'Pickup' : 'Delivery',
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

          // Action buttons - View Menu and Unsubscribe
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            decoration: BoxDecoration(
              color: EatoTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewMenu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EatoTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'View Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Compact unsubscribe button
                SizedBox(
                  width: 36,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onUnsubscribe,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: EatoTheme.warningColor, width: 1),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Icon(
                      Icons.unsubscribe,
                      size: 16,
                      color: EatoTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
