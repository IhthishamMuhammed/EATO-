import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/services/notification_helper.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'dart:async';

class EnhancedFloatingNotificationButton extends StatefulWidget {
  const EnhancedFloatingNotificationButton({Key? key}) : super(key: key);

  @override
  State<EnhancedFloatingNotificationButton> createState() =>
      _EnhancedFloatingNotificationButtonState();
}

class _EnhancedFloatingNotificationButtonState
    extends State<EnhancedFloatingNotificationButton>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifications = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;

  // Animation controllers for enhanced UX
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Removed filtering - always show in arrival order

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadNotifications();
    _setupNotificationStream();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationHelper.getUserNotifications();
      final unreadCount = await NotificationHelper.getUnreadNotificationCount();

      if (mounted) {
        setState(() {
          _notifications = _sortNotifications(notifications);
          _unreadNotifications = unreadCount;
        });

        // Pulse animation for new notifications
        if (unreadCount > 0) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  void _setupNotificationStream() {
    _notificationSubscription =
        NotificationHelper.getNotificationStream().listen((notifications) {
      if (mounted) {
        final previousUnread = _unreadNotifications;
        setState(() {
          _notifications = _sortNotifications(notifications);
          _unreadNotifications =
              notifications.where((n) => !n['isRead']).length;
        });

        // Trigger pulse animation for new notifications
        if (_unreadNotifications > previousUnread) {
          _pulseController.repeat(reverse: true);
        } else if (_unreadNotifications == 0) {
          _pulseController.stop();
        }
      }
    }, onError: (error) {
      print('Stream error: $error');
    });
  }

  List<Map<String, dynamic>> _sortNotifications(
      List<Map<String, dynamic>> notifications) {
    // Always sort by arrival time - latest first, with unread notifications prioritized
    notifications.sort((a, b) {
      // First, sort by read status (unread first)
      final aIsRead = a['isRead'] as bool;
      final bIsRead = b['isRead'] as bool;
      if (!aIsRead && bIsRead) return -1;
      if (aIsRead && !bIsRead) return 1;

      // Then sort by timestamp (newest first)
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });

    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _unreadNotifications > 0 ? _pulseAnimation.value : 1.0,
            child: FloatingActionButton(
              onPressed: _showNotificationPanel,
              backgroundColor: EatoTheme.primaryColor,
              child: _buildNotificationIcon(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Icon(
          Icons.notifications,
          color: Colors.white,
          size: 24,
        ),
        if (_unreadNotifications > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel() {
    _slideController.forward();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEnhancedNotificationSheet(),
    ).then((_) {
      _slideController.reverse();
    });
  }

  Widget _buildEnhancedNotificationSheet() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSheetHeader(),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),

          // Header with statistics
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EatoTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications,
                  color: EatoTheme.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: EatoTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatChip('${_notifications.length}', 'Total'),
                        SizedBox(width: 8),
                        if (_unreadNotifications > 0)
                          _buildStatChip('$_unreadNotifications', 'Unread',
                              isHighlighted: true),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick actions menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: _handleQuickAction,
                itemBuilder: (BuildContext context) => [
                  if (_unreadNotifications > 0)
                    PopupMenuItem<String>(
                      value: 'mark_all_read',
                      child: _buildMenuOption(
                          Icons.done_all, 'Mark all as read', Colors.green),
                    ),
                  PopupMenuItem<String>(
                    value: 'delete_all',
                    child: _buildMenuOption(
                        Icons.delete, 'Delete all', Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String count, String label,
      {bool isHighlighted = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isHighlighted ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: Colors.red.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red : EatoTheme.primaryColor,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Text(title),
      ],
    );
  }

  // Remove filter tabs and action bar methods since they're no longer needed

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildEnhancedNotificationItem(notification, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You'll see notifications here when they arrive",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNotificationItem(
      Map<String, dynamic> notification, int index) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as Timestamp?;
    final notificationId = notification['id'];
    final type = notification['type'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key('notification_${notificationId}_$index'),
        direction: DismissDirection.endToStart,
        background: _buildDismissBackground(),
        confirmDismiss: (direction) => _confirmDeleteNotification(notification),
        onDismissed: (direction) => _deleteNotification(notificationId),
        child: GestureDetector(
          onTap: () => _markNotificationAsRead(notificationId, isRead),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isRead ? Colors.white : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
                width: 1,
              ),
              boxShadow: isRead
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with animation
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notification['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification['icon'],
                      color: notification['color'],
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: EatoTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification['message'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Footer with timestamp and type
                        Row(
                          children: [
                            _buildTypeChip(type),
                            Spacer(),
                            if (timestamp != null)
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
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
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatType(type),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getTypeColor(type),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 24),
          SizedBox(width: 8),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getTypeColor(String type) {
    switch (type) {
      case 'order_placed':
      case 'new_order':
        return Colors.blue;
      case 'order_confirmed':
      case 'order_delivered':
        return Colors.green;
      case 'order_cancelled':
      case 'payment_failed':
        return Colors.red;
      case 'promotion':
      case 'discount':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatType(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Action handlers
  void _handleQuickAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'delete_all':
        _deleteAllNotifications();
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _unreadNotifications = 0;
    });
    _pulseController.stop();

    try {
      await NotificationHelper.markAllNotificationsAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Delete All Notifications'),
        content: Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _notifications.clear();
        _unreadNotifications = 0;
      });
      _pulseController.stop();

      try {
        // Background deletion
        await Future.wait(_notifications
            .map((n) => NotificationHelper.deleteNotification(n['id'])));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All notifications deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error deleting all notifications: $e');
      }
    }
  }

  Future<bool?> _confirmDeleteNotification(Map<String, dynamic> notification) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
      _unreadNotifications = _notifications.where((n) => !n['isRead']).length;
    });

    NotificationHelper.deleteNotification(notificationId).catchError((e) {
      print('Error deleting notification: $e');
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  void _markNotificationAsRead(String notificationId, bool isCurrentlyRead) {
    if (isCurrentlyRead) return;

    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        _unreadNotifications--;
      }
    });

    if (_unreadNotifications == 0) {
      _pulseController.stop();
    }

    NotificationHelper.markNotificationAsRead(notificationId).catchError((e) {
      print('Error marking notification as read: $e');
    });
  }
}
