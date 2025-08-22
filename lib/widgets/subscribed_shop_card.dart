// FILE: lib/widgets/subscribed_shop_card.dart
// Compact subscribed shop card widget using EatoTheme

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

  String _getTimeAgo(String? subscribedAt) {
    if (subscribedAt == null) return 'recently';

    try {
      final subscribedDate = DateTime.parse(subscribedAt);
      final now = DateTime.now();
      final difference = now.difference(subscribedDate);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EatoTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Shop image - smaller
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: shop.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: shop.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.store, size: 25),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.store, size: 25),
                        ),
                ),

                const SizedBox(width: 12),

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
                              style: EatoTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          // Compact subscribed badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: EatoTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: EatoTheme.primaryColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite,
                                    size: 10, color: EatoTheme.primaryColor),
                                const SizedBox(width: 2),
                                Text(
                                  'Subscribed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: EatoTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Compact shop stats
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${(shop.rating ?? 0.0).toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const Spacer(),
                          Text(
                            _getTimeAgo(shopData['subscribedAt']),
                            style: TextStyle(
                              fontSize: 12,
                              color: EatoTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 12, color: EatoTheme.textSecondaryColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              shop.location ?? 'Location not specified',
                              style: TextStyle(
                                fontSize: 12,
                                color: EatoTheme.textSecondaryColor,
                              ),
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

          // Compact action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            decoration: BoxDecoration(
              color: EatoTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
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
                    child: Text(
                      'View Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
