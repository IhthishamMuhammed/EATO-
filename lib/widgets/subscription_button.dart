// File: lib/widgets/subscription_button.dart

import 'package:flutter/material.dart';
import 'package:eato/services/firebase_subscription_service.dart';

class SubscriptionButton extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic> shopData;
  final VoidCallback? onSubscriptionChanged;
  final ButtonStyle? style;
  final EdgeInsets? padding;
  final double? iconSize;
  final double? fontSize;
  final bool showSubscriberCount;
  final bool isCompact;

  const SubscriptionButton({
    Key? key,
    required this.shopId,
    required this.shopData,
    this.onSubscriptionChanged,
    this.style,
    this.padding,
    this.iconSize,
    this.fontSize,
    this.showSubscriberCount = false,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<SubscriptionButton> createState() => _SubscriptionButtonState();
}

class _SubscriptionButtonState extends State<SubscriptionButton>
    with SingleTickerProviderStateMixin {
  bool _isSubscribed = false;
  bool _isLoading = false;
  int _subscriberCount = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkSubscriptionStatus();
    if (widget.showSubscriberCount) {
      _loadSubscriberCount();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      return;
    }

    try {
      final isSubscribed =
          await FirebaseSubscriptionService.isSubscribed(widget.shopId);
      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
        });
      }
    } catch (e) {
      print('❌ [SubscriptionButton] Error checking subscription status: $e');
    }
  }

  Future<void> _loadSubscriberCount() async {
    try {
      final count = await FirebaseSubscriptionService.getShopSubscriberCount(
          widget.shopId);
      if (mounted) {
        setState(() {
          _subscriberCount = count;
        });
      }
    } catch (e) {
      print('❌ [SubscriptionButton] Error loading subscriber count: $e');
    }
  }

  Future<void> _toggleSubscription() async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      _showAuthRequiredDialog();
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Animate button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      if (_isSubscribed) {
        await FirebaseSubscriptionService.unsubscribeFromShop(widget.shopId);

        if (mounted) {
          setState(() {
            _isSubscribed = false;
            if (widget.showSubscriberCount && _subscriberCount > 0) {
              _subscriberCount--;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unsubscribed from ${widget.shopData['shopName'] ?? 'shop'}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await FirebaseSubscriptionService.subscribeToShop(
            widget.shopId, widget.shopData);

        if (mounted) {
          setState(() {
            _isSubscribed = true;
            if (widget.showSubscriberCount) {
              _subscriberCount++;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subscribed to ${widget.shopData['shopName'] ?? 'shop'}!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.purple,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Notify parent widget of subscription change
      widget.onSubscriptionChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to ${_isSubscribed ? 'unsubscribe' : 'subscribe'}: $e',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.purple),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: Text(
          'Please log in to subscribe to restaurants and get updates about their menu and offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactButton();
    } else {
      return _buildFullButton();
    }
  }

  Widget _buildCompactButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleSubscription,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isSubscribed ? Colors.purple : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSubscribed ? Colors.purple : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isSubscribed ? Colors.white : Colors.purple,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSubscribed ? Icons.favorite : Icons.favorite_border,
                        size: widget.iconSize ?? 16,
                        color: _isSubscribed ? Colors.white : Colors.purple,
                      ),
                      if (widget.showSubscriberCount) ...[
                        SizedBox(width: 4),
                        Text(
                          '$_subscriberCount',
                          style: TextStyle(
                            fontSize: widget.fontSize ?? 12,
                            fontWeight: FontWeight.w600,
                            color: _isSubscribed ? Colors.white : Colors.purple,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _toggleSubscription,
        icon: _isLoading
            ? SizedBox(
                width: widget.iconSize ?? 20,
                height: widget.iconSize ?? 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _isSubscribed ? Colors.white : Colors.purple,
                ),
              )
            : Icon(
                _isSubscribed ? Icons.favorite : Icons.favorite_border,
                size: widget.iconSize ?? 20,
                color: _isSubscribed ? Colors.white : Colors.purple,
              ),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSubscribed ? 'Subscribed' : 'Subscribe',
              style: TextStyle(
                fontSize: widget.fontSize ?? 14,
                fontWeight: FontWeight.w600,
                color: _isSubscribed ? Colors.white : Colors.purple,
              ),
            ),
            if (widget.showSubscriberCount)
              Text(
                '$_subscriberCount subscribers',
                style: TextStyle(
                  fontSize: (widget.fontSize ?? 14) - 2,
                  color: _isSubscribed
                      ? Colors.white.withOpacity(0.8)
                      : Colors.purple.withOpacity(0.7),
                ),
              ),
          ],
        ),
        style: widget.style ??
            ElevatedButton.styleFrom(
              backgroundColor: _isSubscribed ? Colors.purple : Colors.white,
              foregroundColor: _isSubscribed ? Colors.white : Colors.purple,
              side: BorderSide(
                color: Colors.purple,
                width: _isSubscribed ? 0 : 1.5,
              ),
              padding: widget.padding ??
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _isSubscribed ? 4 : 2,
            ),
      ),
    );
  }
}

// ===============================================
// SUBSCRIPTION FLOATING ACTION BUTTON
// ===============================================

class SubscriptionFAB extends StatelessWidget {
  final String shopId;
  final Map<String, dynamic> shopData;
  final VoidCallback? onSubscriptionChanged;

  const SubscriptionFAB({
    Key? key,
    required this.shopId,
    required this.shopData,
    this.onSubscriptionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SubscriptionButton(
      shopId: shopId,
      shopData: shopData,
      onSubscriptionChanged: onSubscriptionChanged,
      isCompact: true,
      showSubscriberCount: true,
      iconSize: 18,
      fontSize: 12,
    );
  }
}

// ===============================================
// SUBSCRIPTION STATUS INDICATOR
// ===============================================

class SubscriptionStatusIndicator extends StatefulWidget {
  final String shopId;
  final double size;
  final bool showCount;

  const SubscriptionStatusIndicator({
    Key? key,
    required this.shopId,
    this.size = 24,
    this.showCount = false,
  }) : super(key: key);

  @override
  State<SubscriptionStatusIndicator> createState() =>
      _SubscriptionStatusIndicatorState();
}

class _SubscriptionStatusIndicatorState
    extends State<SubscriptionStatusIndicator> {
  bool _isSubscribed = false;
  int _subscriberCount = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!FirebaseSubscriptionService.isUserAuthenticated()) {
      return;
    }

    try {
      final isSubscribed =
          await FirebaseSubscriptionService.isSubscribed(widget.shopId);

      int count = 0;
      if (widget.showCount) {
        count = await FirebaseSubscriptionService.getShopSubscriberCount(
            widget.shopId);
      }

      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
          _subscriberCount = count;
        });
      }
    } catch (e) {
      print('❌ [SubscriptionStatusIndicator] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSubscribed && !widget.showCount) {
      return SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSubscribed) ...[
          Icon(
            Icons.favorite,
            size: widget.size,
            color: Colors.purple,
          ),
          if (widget.showCount) SizedBox(width: 4),
        ],
        if (widget.showCount)
          Text(
            '$_subscriberCount',
            style: TextStyle(
              fontSize: widget.size * 0.6,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
      ],
    );
  }
}
