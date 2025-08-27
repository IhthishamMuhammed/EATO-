// FILE: lib/widgets/floating_notification_button.dart
// Global floating notification button that appears on all customer pages

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 650, // Adjust position as needed
      right: 16,
      child: Stack(
        children: [
          FloatingActionButton(
            heroTag: "notification_fab", // Unique tag to avoid conflicts
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

  // Same notification sheet methods as before...
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

          // Header
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
              ],
            ),
          ),

          // Notifications list
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
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

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as Timestamp?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
        ),
      ),
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
        subtitle: Text(notification['message']),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          if (!isRead) {
            await NotificationHelper.markNotificationAsRead(notification['id']);
          }
        },
      ),
    );
  }
}
