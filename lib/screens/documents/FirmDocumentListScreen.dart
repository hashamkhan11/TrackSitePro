// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:file_saver/file_saver.dart';
import 'UploadFirmDocumentScreen.dart';

class AppColors {
  static const primaryBlue  = Color(0xFF2563EB);
  static const lightBlue    = Color(0xFFEFF6FF);
  static const mediumBlue   = Color(0xFFBFDBFE);
  static const successGreen = Color(0xFF10B981);
  static const lightGreen   = Color(0xFFECFDF5);
  static const lightGray    = Color(0xFFF9FAFB);
  static const borderGray   = Color(0xFFE5E7EB);
  static const textPrimary  = Color(0xFF111827);
  static const textSecondary= Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const expiredRed   = Color(0xFFEF4444);
  static const soonOrange   = Color(0xFFF59E0B);
  static const safeGreen    = Color(0xFF10B981);
}

class FirmDocumentListScreen extends StatefulWidget {
  const FirmDocumentListScreen({super.key});

  @override
  State<FirmDocumentListScreen> createState() => _FirmDocumentListScreenState();
}

class _FirmDocumentListScreenState extends State<FirmDocumentListScreen> {
  bool   _isDownloading    = false;
  double _downloadProgress = 0.0;
  String _expiryFilter     = 'All';

  final List<String> _filters = const ['All', 'Expired', 'Expiring Soon', 'Valid'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cleanupOldNotifications());
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

  Future<String?> _getFirmId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['assignedFirmId'];
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '—';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Expiry ────────────────────────────────────────────────────────────────

  String _expiryCategory(DateTime? expiry) {
    if (expiry == null) return 'Valid';
    final now = DateTime.now();
    if (expiry.isBefore(now)) return 'Expired';
    if (expiry.difference(now).inDays <= 30) return 'Expiring Soon';
    return 'Valid';
  }

  /// Returns a time-remaining string, or null if already expired.
  /// Callers that only want the badge label should use [_expiryCategory].
  String? _timeRemaining(DateTime? expiry) {
    if (expiry == null) return 'No expiry';
    final now = DateTime.now();
    if (expiry.isBefore(now)) return null; // expired — no secondary label needed
    final diff = expiry.difference(now);
    final days = diff.inDays;
    if (days == 0) {
      final h = diff.inHours;
      return h == 0 ? '${diff.inMinutes} min left' : '$h hrs left';
    }
    return '$days days left';
  }

  Color _expiryColor(DateTime? expiry) {
    if (expiry == null) return AppColors.textTertiary;
    final now = DateTime.now();
    if (expiry.isBefore(now)) return AppColors.expiredRed;
    final days = expiry.difference(now).inDays;
    if (days <= 7)  return AppColors.expiredRed;
    if (days <= 30) return AppColors.soonOrange;
    return AppColors.safeGreen;
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'Expired':       return AppColors.expiredRed;
      case 'Expiring Soon': return AppColors.soonOrange;
      case 'Valid':         return AppColors.safeGreen;
      default:              return AppColors.primaryBlue;
    }
  }

  // ── File helpers ──────────────────────────────────────────────────────────

  IconData _fileIcon(String name) {
    final f = name.toLowerCase();
    if (f.endsWith('.pdf'))  return Icons.picture_as_pdf_rounded;
    if (RegExp(r'\.(jpg|jpeg|png)$').hasMatch(f)) return Icons.image_rounded;
    if (f.endsWith('.doc') || f.endsWith('.docx')) return Icons.description_rounded;
    if (f.endsWith('.xls') || f.endsWith('.xlsx')) return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileIconColor(String name, bool expired) {
    if (expired) return AppColors.expiredRed;
    final f = name.toLowerCase();
    if (f.endsWith('.pdf'))  return AppColors.expiredRed;
    if (RegExp(r'\.(jpg|jpeg|png)$').hasMatch(f)) return AppColors.primaryBlue;
    if (f.endsWith('.doc') || f.endsWith('.docx')) return const Color(0xFF2B6CB0);
    if (f.endsWith('.xls') || f.endsWith('.xlsx')) return AppColors.safeGreen;
    return AppColors.textSecondary;
  }

  // ── I/O ───────────────────────────────────────────────────────────────────

  Future<bool> _checkPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      var s = await Permission.storage.status;
      if (s.isDenied || s.isRestricted) s = await Permission.storage.request();
      return s.isGranted;
    }
    return true;
  }

  Future<void> _openDocument(BuildContext context, Map<String, dynamic> data) async {
    try {
      final b64 = data['fileData'];
      if (b64 == null) return;
      final bytes    = base64Decode(b64);
      final fileName = data['fileName'] ?? 'document';
      if (kIsWeb) {
        await _webDownload(bytes, fileName, context);
      } else {
        final dir  = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      _snack(context, 'Failed to open: $e', error: true);
    }
  }

  Future<void> _webDownload(List<int> bytes, String fileName, BuildContext ctx) async {
    try {
      await FileSaver.instance.saveFile(
        name: fileName, bytes: Uint8List.fromList(bytes), mimeType: MimeType.other);
      _snack(ctx, 'Downloaded successfully');
    } catch (_) {
      _snack(ctx, 'Download started – check browser downloads');
    }
  }

  Future<void> _downloadFile(String b64, String fileName, BuildContext ctx) async {
    try {
      setState(() { _isDownloading = true; _downloadProgress = 0.2; });
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _downloadProgress = 0.6);

      final bytes = base64Decode(b64);
      if (kIsWeb) {
        await _webDownload(bytes, fileName, ctx);
      } else {
        if (!await _checkPermission()) { _snack(ctx, 'Storage permission denied', error: true); return; }
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) dir = await getExternalStorageDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
        final file = File('${dir!.path}/$fileName');
        await file.writeAsBytes(bytes);
        _snack(ctx, 'Saved to: ${file.path}');
      }
      setState(() => _downloadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _snack(ctx, 'Download failed: $e', error: true);
    } finally {
      setState(() { _isDownloading = false; _downloadProgress = 0.0; });
    }
  }

  // ── Details sheet ─────────────────────────────────────────────────────────

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final fileName = data['fileName']?.toString() ?? '—';
    final fileSize = data['fileData'] != null
        ? '${(base64Decode(data['fileData']).lengthInBytes / 1024).toStringAsFixed(1)} KB'
        : '—';
    final uploaded = _formatDate(data['uploadDate'] as Timestamp?);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Document Details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 20),
            _detailRow(Icons.insert_drive_file_rounded, 'File Name', fileName),
            const Divider(height: 24, color: AppColors.borderGray),
            _detailRow(Icons.storage_rounded, 'File Size', fileSize),
            const Divider(height: 24, color: AppColors.borderGray),
            _detailRow(Icons.upload_rounded, 'Uploaded On', uploaded),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.primaryBlue),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  // ── Image preview ─────────────────────────────────────────────────────────

  void _showImagePreview(BuildContext context, Map<String, dynamic> data) {
    final b64 = data['fileData'];
    if (b64 == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(children: [
                Expanded(child: Text(data['title'] ?? 'Preview',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1, color: AppColors.borderGray),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(b64),
                  fit: BoxFit.contain, width: double.infinity, height: 360,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 140,
                    child: Center(child: Icon(Icons.broken_image, size: 48, color: AppColors.textTertiary))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteDocument(BuildContext ctx, String docId, String fileName, String firmId) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 32)),
            const SizedBox(height: 20),
            const Text('Delete Document',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.4)),
            const SizedBox(height: 12),
            Text('Are you sure you want to delete "$fileName"? This cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.borderGray),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.red, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('firms').doc(firmId)
            .collection('documents').doc(docId).delete();
        _snack(ctx, '"$fileName" deleted');
      } catch (e) {
        _snack(ctx, 'Delete failed: $e', error: true);
      }
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> _checkAndNotify(Map<String, dynamic> data, String docId) async {
    final expiry = (data['expiryDate'] as Timestamp?)?.toDate();
    if (expiry == null) return;
    final daysLeft = expiry.difference(DateTime.now()).inDays;
    if (daysLeft > 7 || daysLeft < 0) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final existing = await FirebaseFirestore.instance
        .collection('notifications').doc(uid)
        .collection('user_notifications')
        .where('documentId', isEqualTo: docId)
        .where('notificationType', isEqualTo: 'expiry_alert')
        .get();
    if (existing.docs.isEmpty) {
      await FirebaseFirestore.instance
          .collection('notifications').doc(uid)
          .collection('user_notifications').add({
        'documentId': docId,
        'notificationType': 'expiry_alert',
        'title': 'Firm Document Expiry Alert',
        'body': '${data['title']} expires in $daysLeft days (${_formatDate(data['expiryDate'])})',
        'timestamp': Timestamp.now(),
        'read': false,
        'expiryDate': data['expiryDate'],
      });
    }
  }

  Future<void> _cleanupOldNotifications() async {
    final uid    = FirebaseAuth.instance.currentUser!.uid;
    final firmId = await _getFirmId();
    if (firmId == null) return;
    final notifs = await FirebaseFirestore.instance
        .collection('notifications').doc(uid)
        .collection('user_notifications')
        .where('notificationType', isEqualTo: 'expiry_alert').get();
    for (var n in notifs.docs) {
      final docId = n.data()['documentId'];
      try {
        final snap = await FirebaseFirestore.instance
            .collection('firms').doc(firmId)
            .collection('documents').doc(docId).get();
        if (!snap.exists) {
          await n.reference.delete();
        } else {
          final exp = (snap.data()?['expiryDate'] as Timestamp?)?.toDate();
          if (exp != null && DateTime.now().difference(exp).inDays > 7) {
            await n.reference.delete();
          }
        }
      } catch (_) {}
    }
  }

  // ── Snack ─────────────────────────────────────────────────────────────────

  void _snack(BuildContext ctx, String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.expiredRed : AppColors.safeGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext ctx, DocumentSnapshot doc, String firmId) {
    final data      = doc.data() as Map<String, dynamic>;
    final expiry    = (data['expiryDate'] as Timestamp?)?.toDate();
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final fileName  = data['fileName']?.toString() ?? '';
    final isImage   = RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false).hasMatch(fileName);
    final eColor    = _expiryColor(expiry);
    final category  = _expiryCategory(expiry);
    // Only show time-remaining label when NOT expired (avoids duplicate "Expired" text)
    final timeLeft  = _timeRemaining(expiry);

    _checkAndNotify(data, doc.id);

    return GestureDetector(
      onTap: () => isImage ? _showImagePreview(ctx, data) : _openDocument(ctx, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpired ? AppColors.expiredRed.withOpacity(0.3) : AppColors.borderGray,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // File icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isExpired ? AppColors.expiredRed.withOpacity(0.08) : AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpired ? AppColors.expiredRed.withOpacity(0.2) : AppColors.mediumBlue,
                ),
              ),
              child: Icon(_fileIcon(fileName), color: _fileIconColor(fileName, isExpired), size: 22),
            ),
            const SizedBox(width: 12),

            // Title + status row
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  data['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  // Status badge — shows category only (e.g. "Expired" once)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: eColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isExpired ? Icons.cancel_rounded : Icons.verified_rounded,
                          size: 11, color: eColor),
                      const SizedBox(width: 3),
                      Text(category,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: eColor)),
                    ]),
                  ),
                  // Time-remaining label — only shown when document is NOT yet expired
                  if (timeLeft != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.schedule_rounded, size: 11, color: eColor),
                    const SizedBox(width: 3),
                    Text(timeLeft,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: eColor)),
                  ],
                ]),
              ]),
            ),

            // 3-dot menu
            PopupMenuButton<String>(
              icon: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: const Icon(Icons.more_vert_rounded, size: 17, color: AppColors.textSecondary),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              elevation: 4,
              onSelected: (v) async {
                if (v == 'preview') {
                  isImage ? _showImagePreview(ctx, data) : await _openDocument(ctx, data);
                } else if (v == 'download') {
                  await _downloadFile(data['fileData'], fileName.isEmpty ? 'document.bin' : fileName, ctx);
                } else if (v == 'details') {
                  _showDetails(ctx, data);
                } else if (v == 'delete') {
                  await _deleteDocument(ctx, doc.id, fileName, firmId);
                }
              },
              itemBuilder: (_) => [
                _menuItem('preview', isImage ? Icons.image_search_rounded : Icons.open_in_new_rounded,
                    'Preview', AppColors.lightBlue, AppColors.primaryBlue),
                _menuItem('download', Icons.download_rounded,
                    'Download', AppColors.lightGreen, AppColors.safeGreen),
                _menuItem('details', Icons.info_outline_rounded,
                    'Details', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
                const PopupMenuDivider(height: 1),
                _menuItem('delete', Icons.delete_rounded,
                    'Delete', AppColors.expiredRed.withOpacity(0.08), AppColors.expiredRed,
                    labelColor: AppColors.expiredRed),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      Color iconBg, Color iconColor, {Color? labelColor}) {
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: labelColor ?? AppColors.textPrimary,
        )),
      ]),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFirmId(),
      builder: (ctx, firmSnap) {
        if (!firmSnap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue, strokeWidth: 3)),
          );
        }

        final firmId = firmSnap.data!;

        if (firmId.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Firm Documents'),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            ),
            body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 88, height: 88,
                decoration: const BoxDecoration(color: AppColors.lightGray, shape: BoxShape.circle),
                child: const Icon(Icons.business_outlined, size: 42, color: AppColors.textTertiary)),
              const SizedBox(height: 18),
              const Text('No Firm Assigned',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text('Please contact your administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              ),
            ])),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 16,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Firm Documents',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: -0.5)),
                Text('Manage all firm-level documents',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w400)),
              ],
            ),
            toolbarHeight: 62,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: Colors.white,
                child: Column(children: [
                  const Divider(height: 1, color: AppColors.borderGray),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filters.length,
                      itemBuilder: (_, i) {
                        final f        = _filters[i];
                        final selected = _expiryFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: selected,
                            onSelected: (_) => setState(() => _expiryFilter = f),
                            backgroundColor: Colors.white,
                            selectedColor: _filterColor(f),
                            side: BorderSide(color: selected ? _filterColor(f) : AppColors.borderGray),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600, fontSize: 12,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ),
          body: Column(children: [
            if (_isDownloading)
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppColors.borderGray,
                color: AppColors.primaryBlue,
                minHeight: 3,
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('firms').doc(firmId)
                    .collection('documents')
                    .orderBy('uploadDate', descending: true)
                    .snapshots(),
                builder: (ctx2, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(
                        color: AppColors.primaryBlue, strokeWidth: 3));
                  }

                  var docs = snap.data!.docs;

                  if (_expiryFilter != 'All') {
                    docs = docs.where((d) {
                      final data   = d.data() as Map<String, dynamic>;
                      final expiry = (data['expiryDate'] as Timestamp?)?.toDate();
                      return _expiryCategory(expiry) == _expiryFilter;
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 96, height: 96,
                        decoration: const BoxDecoration(color: AppColors.lightGray, shape: BoxShape.circle),
                        child: const Icon(Icons.folder_open_rounded, size: 46, color: AppColors.textTertiary)),
                      const SizedBox(height: 18),
                      const Text('No Documents Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Tap + to upload a document',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ]));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    itemCount: docs.length,
                    itemBuilder: (_, i) => _buildCard(ctx2, docs[i], firmId),
                  );
                },
              ),
            ),
          ]),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UploadFirmDocumentScreen(firmId: firmId)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          ),
        );
      },
    );
  }
}