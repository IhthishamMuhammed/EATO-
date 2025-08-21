// FILE: lib/widgets/notification_widget.dart
// Separate notification widget with all notification functionality

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/services/notification_helper.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'dart:async';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  // 🔔 NOTIFICATION STATE
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifications = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;

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

  @override
  Widget build(BuildContext context) {
    return buildNotificationIcon();
  }

  // ===================================================================
  // 🔔 NOTIFICATION FUNCTIONALITY
  // ===================================================================

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationHelper.getUserNotifications();
      final unreadCount = await NotificationHelper.getUnreadNotificationCount();

      if (mounted) {
        setState(() {
          _notifications = notifications;
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
        setState(() {
          _notifications = notifications;
          _unreadNotifications =
              notifications.where((n) => !n['isRead']).length;
        });
      }
    });
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationSheet(),
    );
  }

  // ===================================================================
  // 🗑️ DELETE NOTIFICATION FUNCTIONALITY
  // ===================================================================

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationHelper.deleteNotification(notificationId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    // Show confirmation dialog
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Notifications'),
        content: Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Clear All'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        // Delete all notifications for current user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final notificationsQuery = await FirebaseFirestore.instance
              .collection('user_notifications')
              .where('userId', isEqualTo: user.uid)
              .get();

          final batch = FirebaseFirestore.instance.batch();
          for (var doc in notificationsQuery.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();

          if (mounted) {
            Navigator.of(context).pop(); // Close notification sheet
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('All notifications cleared'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('Error clearing all notifications: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationHelper.markNotificationAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    await NotificationHelper.markAllNotificationsAsRead();
  }

  String _formatNotificationTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // ===================================================================
  // 🎨 UI WIDGETS
  // ===================================================================

  /// Main notification icon with badge - call this from your AppBar
  Widget buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: _showNotifications,
        ),
        if (_unreadNotifications > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadNotifications',
                style: const TextStyle(
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

  Widget _buildNotificationSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with responsive button layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title row
                Row(
                  children: [
                    Icon(Icons.notifications, color: EatoTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: EatoTheme.headingMedium,
                    ),
                    if (_unreadNotifications > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Action buttons row (only show if there are notifications or unread items)
                if (_notifications.isNotEmpty || _unreadNotifications > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_unreadNotifications > 0) ...[
                        TextButton.icon(
                          onPressed: _markAllAsRead,
                          icon: Icon(Icons.done_all, size: 16),
                          label: Text('Mark all read'),
                          style: TextButton.styleFrom(
                            foregroundColor: EatoTheme.primaryColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_notifications.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearAllNotifications,
                          icon: Icon(Icons.delete_sweep, size: 16),
                          label: Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
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
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
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
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: EatoTheme.headingSmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you about order updates and special offers',
            style: EatoTheme.bodySmall.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Dismissible(
        key: Key(notification['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmation();
        },
        onDismissed: (direction) {
          _deleteNotification(notification['id']);
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
            style: EatoTheme.bodyMedium.copyWith(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification['message'],
                style: EatoTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                _formatNotificationTime(timestamp),
                style: EatoTheme.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () async {
                  final bool? shouldDelete = await _showDeleteConfirmation();
                  if (shouldDelete == true) {
                    _deleteNotification(notification['id']);
                  }
                },
              ),
              // Unread indicator
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: () => _markAsRead(notification['id']),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notification', style: EatoTheme.headingSmall),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: EatoTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
