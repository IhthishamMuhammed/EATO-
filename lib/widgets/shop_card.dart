// FILE: lib/widgets/shop_card.dart
// Compact shop card widget using EatoTheme

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed
              ? EatoTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
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
                // Smaller shop image
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: EatoTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          if (showSubscribeButton)
                            GestureDetector(
                              onTap: onSubscriptionToggle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSubscribed
                                      ? EatoTheme.primaryColor.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSubscribed
                                        ? EatoTheme.primaryColor
                                        : Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSubscribed
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 12,
                                      color: isSubscribed
                                          ? EatoTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      isSubscribed ? 'Subscribed' : 'Subscribe',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSubscribed
                                            ? EatoTheme.primaryColor
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Compact shop stats and location in one row
                      Row(
                        children: [
                          if ((shop.rating ?? 0) > 0) ...[
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${(shop.rating ?? 0.0).toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.location_on,
                              size: 12, color: EatoTheme.textSecondaryColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              shop.location ?? 'Location not specified',
                              style: TextStyle(
                                fontSize: 11,
                                color: EatoTheme.textSecondaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Delivery mode badge on same row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: shop.isPickup
                                  ? EatoTheme.successColor
                                  : EatoTheme.infoColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  shop.isPickup
                                      ? Icons.store
                                      : Icons.delivery_dining,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _getDeliveryModeText(shop),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
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

          // Compact action button
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            decoration: BoxDecoration(
              color: EatoTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
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
          ),
        ],
      ),
    );
  }
}
