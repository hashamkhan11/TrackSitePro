import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class AppColors {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const successGreen  = Color(0xFF10B981);
  static const lightGreen    = Color(0xFFECFDF5);
  static const warningOrange = Color(0xFFF59E0B);
  static const lightOrange   = Color(0xFFFEF3C7);
  static const lightGray     = Color(0xFFF9FAFB);
  static const borderGray    = Color(0xFFE5E7EB);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const expiredRed    = Color(0xFFEF4444);
}

// ── Screen ────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAll  = false;
  bool _isDeletingAll = false;
  int  _unreadCount   = 0;
  int  _totalCount    = 0;

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    setState(() => _isMarkingAll = true);
    try {
      final uid  = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('notifications').doc(uid)
          .collection('user_notifications')
          .where('read', isEqualTo: false).get();
      for (final d in snap.docs) await d.reference.update({'read': true});
      _snack('All notifications marked as read');
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_totalCount == 0) return;
    final confirmed = await _confirmDialog(
      title: 'Clear All Notifications',
      body: 'This will permanently delete all notifications. This cannot be undone.',
      confirmLabel: 'Delete All',
    );
    if (confirmed != true) return;

    setState(() => _isDeletingAll = true);
    try {
      final uid  = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('notifications').doc(uid)
          .collection('user_notifications').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) batch.delete(d.reference);
      await batch.commit();
      _snack('All notifications deleted');
    } catch (e) {
      _snack('Failed to delete: $e', error: true);
    } finally {
      if (mounted) setState(() => _isDeletingAll = false);
    }
  }

  Future<void> _deleteNotification(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
      _snack('Notification deleted');
    } catch (e) {
      _snack('Failed to delete: $e', error: true);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: AppColors.expiredRed.withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded,
                  color: AppColors.expiredRed, size: 28),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.3),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(body,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppColors.borderGray),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  backgroundColor: AppColors.expiredRed,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? AppColors.expiredRed : AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _formatTime(DateTime time) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yest  = today.subtract(const Duration(days: 1));
    final date  = DateTime(time.year, time.month, time.day);
    if (date == today) return DateFormat.jm().format(time);
    if (date == yest)  return 'Yesterday';
    return DateFormat('MMM d').format(time);
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'expiry_alert': return Icons.warning_amber_rounded;
      case 'info':         return Icons.info_rounded;
      case 'success':      return Icons.check_circle_rounded;
      case 'message':      return Icons.message_rounded;
      default:             return Icons.notifications_rounded;
    }
  }

  Color _notifColor(String type, bool read) {
    if (read) return AppColors.textTertiary;
    switch (type) {
      case 'expiry_alert': return AppColors.warningOrange;
      case 'success':      return AppColors.successGreen;
      case 'info':
      case 'message':
      default:             return AppColors.primaryBlue;
    }
  }

  Color _notifBg(String type, bool read) {
    if (read) return AppColors.lightGray;
    switch (type) {
      case 'expiry_alert': return AppColors.lightOrange;
      case 'success':      return AppColors.lightGreen;
      default:             return AppColors.lightBlue;
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 96, height: 96,
          decoration: const BoxDecoration(
              color: AppColors.lightGray, shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded,
              size: 46, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 18),
        const Text('All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Notifications will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildNotificationItem(DocumentSnapshot doc, Map<String, dynamic> data) {
    final isRead   = data['read'] == true;
    final title    = data['title'] as String? ?? '';
    final body     = data['body']  as String? ?? '';
    final ts       = data['timestamp'] as Timestamp?;
    final time     = ts?.toDate();
    final type     = data['notificationType'] as String? ?? '';
    final iconColor = _notifColor(type, isRead);
    final iconBg    = _notifBg(type, isRead);

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: AppColors.expiredRed, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          SizedBox(height: 4),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) => _confirmDialog(
        title: 'Delete Notification',
        body: 'Remove this notification permanently?',
        confirmLabel: 'Delete',
      ),
      onDismissed: (_) => _deleteNotification(doc),
      child: GestureDetector(
        onTap: () { if (!isRead) doc.reference.update({'read': true}); },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? AppColors.borderGray
                  : (type == 'expiry_alert'
                      ? AppColors.warningOrange.withOpacity(0.35)
                      : AppColors.mediumBlue),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(_notifIcon(type), size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13, fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        color: AppColors.textPrimary, height: 1.3),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                        height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 11, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(time != null ? _formatTime(time.toLocal()) : '',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
                ]),
              ]),
            ),

            // Unread dot
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: AppColors.primaryBlue, shape: BoxShape.circle),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.5)),
            Text('Stay up to date',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        toolbarHeight: 62,
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _isMarkingAll
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primaryBlue)))
                  : IconButton(
                      onPressed: _markAllAsRead,
                      tooltip: 'Mark all as read',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.mark_email_read_rounded,
                            size: 18, color: AppColors.primaryBlue),
                      ),
                    ),
            ),
          if (_totalCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isDeletingAll
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.expiredRed)))
                  : IconButton(
                      onPressed: _deleteAllNotifications,
                      tooltip: 'Clear all',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: AppColors.expiredRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_sweep_rounded,
                            size: 18, color: AppColors.expiredRed),
                      ),
                    ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderGray),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications').doc(uid)
            .collection('user_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: AppColors.primaryBlue, strokeWidth: 3));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Update counts synchronously — no setState needed, counts are read
            // directly from the stream snapshot in the AppBar actions below.
            _totalCount  = 0;
            _unreadCount = 0;
            return _buildEmptyState();
          }

          final docs   = snapshot.data!.docs;
          final unread = docs.where((d) => (d.data() as Map)['read'] != true).length;

          // Keep fields in sync without triggering a rebuild loop.
          _totalCount  = docs.length;
          _unreadCount = unread;

          return Column(children: [
            // ── Unread banner ──
            if (unread > 0)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
                      const SizedBox(width: 5),
                      Text('$unread unread',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue)),
                    ]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.mediumBlue)),
                      child: const Text('Mark all read',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue)),
                    ),
                  ),
                ]),
              ),
            if (unread > 0)
              const Divider(height: 1, color: AppColors.borderGray),

            // ── List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                color: AppColors.primaryBlue,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _buildNotificationItem(docs[i], data);
                  },
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}