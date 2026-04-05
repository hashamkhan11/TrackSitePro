// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'UploadDocumentScreen.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const lightGray     = Color(0xFFF9FAFB);
  static const borderGray    = Color(0xFFE5E7EB);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const successGreen  = Color(0xFF10B981);
  static const lightGreen    = Color(0xFFECFDF5);
  static const warningOrange = Color(0xFFF59E0B);
  static const lightOrange   = Color(0xFFFEF3C7);
  static const errorRed      = Color(0xFFEF4444);
  static const lightRed      = Color(0xFFFEF2F2);
}

class DocumentListScreen extends StatelessWidget {
  final String projectId;
  final String projectTitle;

  const DocumentListScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  // ── File Actions ─────────────────────────────────────────────────────────────
  Future<void> _openDocument(BuildContext context, Map<String, dynamic> data) async {
    try {
      final base64File = data['fileData'];
      if (base64File == null) return;
      final bytes = base64Decode(base64File);

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: data['fileName'] ?? "document",
          bytes: bytes,
          mimeType: MimeType.other,
        );
        _snack(context, "File downloaded (check browser downloads).", _C.successGreen);
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/${data['fileName'] ?? 'document'}";
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      _snack(context, "Failed to open file: $e", _C.errorRed);
    }
  }

  Future<void> _downloadDocument(BuildContext context, Map<String, dynamic> data) async {
    try {
      final bytes = base64Decode(data['fileData']);
      await FileSaver.instance.saveFile(
        name: data['fileName'] ?? "document",
        bytes: bytes,
        mimeType: MimeType.other,
      );
      _snack(context, "File saved successfully.", _C.successGreen);
    } catch (e) {
      _snack(context, "Download failed: $e", _C.errorRed);
    }
  }

  Future<void> _deleteDocument(
      BuildContext context, String docId, String fileName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.lightRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: _C.errorRed, size: 20),
          ),
          const SizedBox(width: 12),
          const Text("Delete Document",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
        ]),
        content: Text(
          "Are you sure you want to delete '$fileName'? This cannot be undone.",
          style: const TextStyle(fontSize: 14, color: _C.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _C.textSecondary),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.errorRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('projects').doc(projectId)
            .collection('documents').doc(docId).delete();
        if (context.mounted) {
          _snack(context, "'$fileName' deleted.", _C.successGreen);
        }
      } catch (e) {
        if (context.mounted) _snack(context, "Delete failed: $e", _C.errorRed);
      }
    }
  }

  void _showImagePreview(BuildContext context, Map<String, dynamic> data) {
    try {
      final base64File = data['fileData'];
      if (base64File == null) return;
      final fileName = data['fileName']?.toString().toLowerCase() ?? '';
      final isImage = fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png');
      if (!isImage) return;

      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: _C.lightGray,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: _C.borderGray)),
                ),
                child: Row(children: [
                  const Icon(Icons.image_outlined, size: 18, color: _C.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Image Preview',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: _C.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _C.borderGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16,
                          color: _C.textSecondary),
                    ),
                  ),
                ]),
              ),
              // Image
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(base64File),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 380,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: _C.lightGray,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            size: 48, color: _C.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    } catch (e) {
      _snack(context, "Failed to preview image: $e", _C.errorRed);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _snack(BuildContext context, String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  IconData _fileIcon(String fileName) {
    final f = fileName.toLowerCase();
    if (f.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.png')) {
      return Icons.image_rounded;
    }
    if (f.endsWith('.doc') || f.endsWith('.docx')) return Icons.description_rounded;
    if (f.endsWith('.xls') || f.endsWith('.xlsx')) return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileColor(String fileName, bool isExpired) {
    if (isExpired) return _C.errorRed;
    final f = fileName.toLowerCase();
    if (f.endsWith('.pdf')) return const Color(0xFFDC2626);
    if (f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.png')) {
      return _C.primaryBlue;
    }
    if (f.endsWith('.doc') || f.endsWith('.docx')) return const Color(0xFF2563EB);
    if (f.endsWith('.xls') || f.endsWith('.xlsx')) return _C.successGreen;
    return _C.textSecondary;
  }

  // ── Document Card ─────────────────────────────────────────────────────────────
  Widget _buildDocumentCard(
      BuildContext context, DocumentSnapshot doc) {
    final data       = doc.data() as Map<String, dynamic>;
    final expiry     = (data['expiryDate'] as Timestamp?)?.toDate();
    final uploadDate = (data['uploadDate'] as Timestamp?)?.toDate();
    final isExpired  = expiry != null && expiry.isBefore(DateTime.now());
    final fileName   = data['fileName']?.toString() ?? '';
    final isImage    = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');
    final fileSize = data['fileData'] != null
        ? (base64Decode(data['fileData']).lengthInBytes / 1024).toStringAsFixed(1)
        : '0.0';
    final fileColor  = _fileColor(fileName, isExpired);
    final fileBg     = isExpired ? _C.lightRed : _C.lightBlue;
    final fileBorder = isExpired ? const Color(0xFFFECACA) : _C.mediumBlue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isExpired ? const Color(0xFFFECACA) : _C.borderGray),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isImage ? () => _showImagePreview(context, data) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // File icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: fileBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: fileBorder),
              ),
              child: Icon(_fileIcon(fileName), color: fileColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700, color: _C.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isExpired) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _C.lightRed,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Text('Expired',
                          style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w700, color: _C.errorRed)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(fileName,
                    style: const TextStyle(fontSize: 12, color: _C.textTertiary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 4, children: [
                  _metaChip(Icons.upload_rounded,
                      uploadDate != null
                          ? "${uploadDate.day}/${uploadDate.month}/${uploadDate.year}"
                          : "–"),
                  _metaChip(Icons.event_rounded,
                      expiry != null
                          ? "${expiry.day}/${expiry.month}/${expiry.year}"
                          : "No expiry",
                      color: isExpired ? _C.errorRed : _C.textTertiary),
                  _metaChip(Icons.data_usage_rounded, "$fileSize KB"),
                ]),
              ]),
            ),

            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  size: 20, color: _C.textTertiary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 8,
              onSelected: (value) {
                if (value == 'open') _openDocument(context, data);
                if (value == 'download') _downloadDocument(context, data);
                if (value == 'preview' && isImage) _showImagePreview(context, data);
                if (value == 'delete') {
                  _deleteDocument(context, doc.id, fileName);
                }
              },
              itemBuilder: (_) => [
                if (isImage)
                  _menuItem('preview', Icons.image_search_rounded, 'Preview', _C.primaryBlue),
                _menuItem('open', Icons.open_in_new_rounded, 'Open', _C.primaryBlue),
                _menuItem('download', Icons.download_rounded, 'Download', _C.successGreen),
                _menuItem('delete', Icons.delete_outline_rounded, 'Delete', _C.errorRed),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: value == 'delete' ? _C.errorRed : _C.textPrimary)),
      ]),
    );
  }

  Widget _metaChip(IconData icon, String text, {Color color = _C.textTertiary}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(text,
          style: TextStyle(fontSize: 11, color: color,
              fontWeight: FontWeight.w500)),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightGray,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects').doc(projectId)
            .collection('documents')
            .orderBy('uploadDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(
                color: _C.primaryBlue, strokeWidth: 2.5));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: docs.length,
            itemBuilder: (_, i) => _buildDocumentCard(context, docs[i]),
          );
        },
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _C.borderGray, width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _C.lightGray, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    size: 20, color: _C.textSecondary),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Documents',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: _C.textPrimary, letterSpacing: -0.3),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────────
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UploadDocumentScreen(
            projectId: projectId,
            projectTitle: projectTitle,
          ),
        ),
      ),
      backgroundColor: _C.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.upload_file_rounded, size: 20),
      label: const Text('Upload',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: _C.lightGray, shape: BoxShape.circle,
                border: Border.all(color: _C.borderGray)),
            child: const Icon(Icons.folder_open_rounded,
                size: 48, color: _C.textTertiary),
          ),
          const SizedBox(height: 20),
          const Text("No Documents Yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: _C.textPrimary, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          const Text("Upload your first document using the button below",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _C.textSecondary, height: 1.5)),
        ]),
      ),
    );
  }
}