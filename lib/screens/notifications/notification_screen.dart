import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAll = false;
  bool _isDeletingAll = false;
  int _unreadCount = 0;
  int _totalNotifications = 0;

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    setState(() {
      _isMarkingAll = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection("notifications")
          .doc(uid)
          .collection("user_notifications")
          .where("read", isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAll = false;
        });
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_totalNotifications == 0) return;

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Notifications"),
        content: const Text("Are you sure you want to delete all notifications? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeletingAll = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection("notifications")
          .doc(uid)
          .collection("user_notifications")
          .get();

      // Delete all documents in batch
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications deleted permanently'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAll = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(time.year, time.month, time.day);

    if (notificationDate == today) {
      return DateFormat.jm().format(time);
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No notifications",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you get notifications, they'll appear here",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(DocumentSnapshot doc, Map<String, dynamic> data) {
    final isRead = data['read'] == true;
    final title = data['title'] ?? "";
    final body = data['body'] ?? "";
    final timestamp = data['timestamp'] as Timestamp?;
    final time = timestamp?.toDate();
    final hasAction = data['actionType'] != null;
    final notificationType = data['notificationType'] ?? '';

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Notification"),
            content: const Text("Are you sure you want to delete this notification?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteNotification(doc);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.blue[50]?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[200]! : Colors.blue[100]!,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isRead) {
                doc.reference.update({'read': true});
              }
              // Handle notification tap
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getNotificationIcon(notificationType),
                      color: isRead ? Colors.grey[600] : Colors.blue[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time != null ? _formatTime(time.toLocal()) : "",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            if (hasAction)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  data['actionType'] ?? "View",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4, top: 4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
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

  IconData _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'expiry_alert':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'message':
        return Icons.message_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Only show Mark All Read if there are unread notifications
          if (_unreadCount > 0)
            IconButton(
              onPressed: _markAllAsRead,
              icon: _isMarkingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mark_email_read_rounded),
              tooltip: 'Mark all as read',
            ),
          // Only show Clear All if there are notifications
          if (_totalNotifications > 0)
            IconButton(
              onPressed: _isDeletingAll ? null : _deleteAllNotifications,
              icon: _isDeletingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .doc(uid)
            .collection("user_notifications")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    "Loading...",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            _totalNotifications = 0;
            _unreadCount = 0;
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          // Update counts
          _totalNotifications = docs.length;
          _unreadCount = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['read'] != true;
          }).length;

          return Column(
            children: [
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_unreadCount unread',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _markAllAsRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'MARK ALL READ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Force refresh
                    setState(() {});
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildNotificationItem(docs[index], data);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}