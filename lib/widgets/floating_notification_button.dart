import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/services/notification_helper.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'dart:async';

class FloatingNotificationButton extends StatefulWidget {
  const FloatingNotificationButton({Key? key}) : super(key: key);

  @override
  State<FloatingNotificationButton> createState() =>
      _FloatingNotificationButtonState();
}

class _FloatingNotificationButtonState
    extends State<FloatingNotificationButton> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifications = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;

  // Track recently deleted/updated notifications to filter them from stream
  final Set<String> _recentlyDeletedIds = {};
  final Set<String> _recentlyMarkedReadIds = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupNotificationStream();
  }

  @override
  void dispose() {
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
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  void _setupNotificationStream() {
    _notificationSubscription =
        NotificationHelper.getNotificationStream().listen((notifications) {
      if (mounted) {
        print('📡 Stream received ${notifications.length} notifications');

        // Filter out recently deleted notifications from stream data
        List<Map<String, dynamic>> filteredNotifications = notifications
            .where((n) => !_recentlyDeletedIds.contains(n['id']))
            .toList();

        // Apply recent "mark as read" updates to stream data
        for (var notification in filteredNotifications) {
          if (_recentlyMarkedReadIds.contains(notification['id'])) {
            notification['isRead'] = true;
          }
        }

        print(
            '📡 After filtering: ${filteredNotifications.length} notifications');

        setState(() {
          _notifications = _sortNotifications(filteredNotifications);
          _unreadNotifications =
              _notifications.where((n) => !n['isRead']).length;
        });
      }
    }, onError: (error) {
      print('❌ Stream error: $error');
    });
  }

  // Sort notifications: unread first, then by timestamp
  List<Map<String, dynamic>> _sortNotifications(
      List<Map<String, dynamic>> notifications) {
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

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationSheet(),
    );
  }

  // IMPROVED delete notification - prevents stream override
  void _deleteNotificationImmediately(String notificationId) async {
    if (!mounted) return;

    print('🗑️ Deleting notification immediately: $notificationId');

    // Add to recently deleted set to filter from stream
    _recentlyDeletedIds.add(notificationId);

    // PAUSE the stream subscription to prevent it from overriding our UI
    _notificationSubscription?.pause();
    print('⏸️ Stream paused for delete operation');

    // Update UI INSTANTLY
    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
      _unreadNotifications = _notifications.where((n) => !n['isRead']).length;
    });

    try {
      // Delete from Firebase
      await NotificationHelper.deleteNotification(notificationId);
      print('✅ Firebase delete completed');

      // Wait for Firebase to propagate the change
      await Future.delayed(Duration(milliseconds: 1000));

      if (mounted) {
        // RESUME the stream subscription
        _notificationSubscription?.resume();
        print('▶️ Stream resumed after delete');

        // Clear from recently deleted after a delay to ensure stream sync
        Future.delayed(Duration(milliseconds: 2000), () {
          _recentlyDeletedIds.remove(notificationId);
          print('🧹 Cleared $notificationId from recently deleted filter');
        });
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      if (mounted) {
        // Remove from recently deleted on error
        _recentlyDeletedIds.remove(notificationId);
        // Resume stream even on error
        _notificationSubscription?.resume();
        _loadNotifications(); // Reload on error
      }
    }
  }

  // IMPROVED mark as read - prevents stream override
  void _markAsReadImmediately(String notificationId) async {
    if (!mounted) return;

    print('📖 Marking notification as read immediately: $notificationId');

    // PAUSE the stream subscription to prevent it from overriding our UI
    _notificationSubscription?.pause();
    print('⏸️ Stream paused for mark read operation');

    // Update UI INSTANTLY
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (_notifications[i]['id'] == notificationId) {
          // Create new map to ensure UI updates
          _notifications[i] = Map<String, dynamic>.from(_notifications[i]);
          _notifications[i]['isRead'] = true;
          break;
        }
      }
      // Re-sort notifications (read ones move down)
      _notifications = _sortNotifications(_notifications);
      _unreadNotifications = _notifications.where((n) => !n['isRead']).length;
    });

    try {
      // Update Firebase
      await NotificationHelper.markNotificationAsRead(notificationId);
      print('✅ Firebase mark read completed');

      // Wait for Firebase to propagate the change
      await Future.delayed(Duration(milliseconds: 800));

      if (mounted) {
        // RESUME the stream subscription
        _notificationSubscription?.resume();
        print('▶️ Stream resumed after mark read');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      if (mounted) {
        // Resume stream even on error
        _notificationSubscription?.resume();
        _loadNotifications(); // Reload on error
      }
    }
  }

  void _deleteAllNotifications() async {
    if (_notifications.isEmpty) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete All Notifications'),
          content: Text(
              'Are you sure you want to delete all notifications? This action cannot be undone.'),
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
        );
      },
    );

    if (confirm == true) {
      // PAUSE the stream subscription
      _notificationSubscription?.pause();
      print('⏸️ Stream paused for delete all operation');

      // Store notifications for background deletion
      final notificationsToDelete =
          List<Map<String, dynamic>>.from(_notifications);

      // Update UI IMMEDIATELY - clear everything
      setState(() {
        _notifications.clear();
        _unreadNotifications = 0;
      });

      try {
        // Delete from Firebase in background
        await Future.wait(notificationsToDelete
            .map((notification) =>
                NotificationHelper.deleteNotification(notification['id']))
            .toList());

        print('✅ All notifications deleted from Firebase');

        // Wait for Firebase to propagate
        await Future.delayed(Duration(milliseconds: 1500));

        if (mounted) {
          // RESUME the stream subscription
          _notificationSubscription?.resume();
          print('▶️ Stream resumed after delete all');
        }
      } catch (e) {
        print('❌ Error deleting all notifications: $e');
        if (mounted) {
          // Resume stream even on error
          _notificationSubscription?.resume();
          _loadNotifications(); // Reload on error
        }
      }
    }
  }

  void _markAllAsRead() async {
    if (_notifications.isEmpty) return;

    // PAUSE the stream subscription
    _notificationSubscription?.pause();
    print('⏸️ Stream paused for mark all read operation');

    // Update UI IMMEDIATELY
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i]['isRead']) {
          // Create new map to trigger UI update
          _notifications[i] = Map<String, dynamic>.from(_notifications[i]);
          _notifications[i]['isRead'] = true;
        }
      }
      _notifications = _sortNotifications(_notifications);
      _unreadNotifications = 0;
    });

    try {
      // Update Firebase in background
      await NotificationHelper.markAllNotificationsAsRead();
      print('✅ All notifications marked as read in Firebase');

      // Wait for Firebase to propagate
      await Future.delayed(Duration(milliseconds: 800));

      if (mounted) {
        // RESUME the stream subscription
        _notificationSubscription?.resume();
        print('▶️ Stream resumed after mark all read');
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
      if (mounted) {
        // Resume stream even on error
        _notificationSubscription?.resume();
        _loadNotifications(); // Reload on error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Stack(
        children: [
          FloatingActionButton(
            heroTag: "notification_fab",
            onPressed: _showNotifications,
            backgroundColor: EatoTheme.primaryColor,
            child: Icon(
              Icons.notifications,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (_unreadNotifications > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: BoxConstraints(
                  minWidth: 15,
                  minHeight: 15,
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
      ),
    );
  }

  // Rest of your build methods remain the same...
  Widget _buildNotificationSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.notifications, color: EatoTheme.primaryColor),
                SizedBox(width: 8),
                Text('Notifications', style: EatoTheme.headingMedium),
                if (_unreadNotifications > 0) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Spacer(),
                // Action buttons
                if (_notifications.isNotEmpty) ...[
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'mark_all_read') {
                        _markAllAsRead();
                      } else if (value == 'delete_all') {
                        _deleteAllNotifications();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (_unreadNotifications > 0)
                        PopupMenuItem<String>(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(Icons.done_all,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Mark all as read'),
                            ],
                          ),
                        ),
                      PopupMenuItem<String>(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete all'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Notifications list
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: ClampingScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      if (index >= _notifications.length) {
                        return SizedBox.shrink();
                      }
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: EatoTheme.headingSmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as Timestamp?;
    final notificationId = notification['id'];

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Dismissible(
        key: Key('notification_${notificationId}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Delete Notification'),
                content:
                    Text('Are you sure you want to delete this notification?'),
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
              );
            },
          );
        },
        onDismissed: (direction) {
          _deleteNotificationImmediately(notificationId);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification['color'].withOpacity(0.1),
            child: Icon(
              notification['icon'],
              color: notification['color'],
              size: 20,
            ),
          ),
          title: Text(
            notification['title'],
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification['message']),
              if (timestamp != null) ...[
                SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                onPressed: () {
                  // Show confirmation dialog first
                  showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete Notification'),
                        content: Text(
                            'Are you sure you want to delete this notification?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                              // Delete immediately after confirmation
                              _deleteNotificationImmediately(notificationId);
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            if (!isRead) {
              print('Notification tapped, marking as read: $notificationId');
              _markAsReadImmediately(notificationId);
            }
          },
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
