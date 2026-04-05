import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class UploadDocumentScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const UploadDocumentScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _titleController     = TextEditingController();
  final _descController      = TextEditingController();

  DateTime?  _expiryDate;
  Uint8List? _selectedBytes;
  String?    _fileName;
  bool       _loading     = false;
  double     _progress    = 0.0;
  bool       _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── File Picker ───────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    if (_isUploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes  = result.files.single.bytes!;
      final sizeKB = bytes.lengthInBytes / 1024;
      if (sizeKB > 800) {
        _snack("File too large! Max 800 KB allowed.", _C.errorRed);
        return;
      }
      setState(() {
        _fileName      = result.files.single.name;
        _selectedBytes = bytes;
      });
    } catch (e) {
      _snack("Failed to pick file: $e", _C.errorRed);
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────────
  Future<void> _saveDocument() async {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) {
      _snack("Please fill all required fields.", _C.errorRed);
      return;
    }
    if (_selectedBytes == null) {
      _snack("Please select a file to upload.", _C.errorRed);
      return;
    }

    setState(() { _loading = true; _isUploading = true; _progress = 0.3; });

    try {
      final uid        = FirebaseAuth.instance.currentUser!.uid;
      final userEmail  = FirebaseAuth.instance.currentUser!.email ?? 'Unknown';
      final base64File = base64Encode(_selectedBytes!);

      setState(() => _progress = 0.6);

      await FirebaseFirestore.instance
          .collection("projects").doc(widget.projectId)
          .collection("documents").add({
        "title":        _titleController.text.trim(),
        "description":  _descController.text.trim(),
        "fileName":     _fileName,
        "fileData":     base64File,
        "uploadDate":   Timestamp.now(),
        "expiryDate":   _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        "uploadedBy":   userEmail,
        "uploadedById": uid,
        "createdAt":    Timestamp.now(),
      });

      setState(() => _progress = 1.0);
      _snack("Document uploaded successfully!", _C.successGreen);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack("Upload failed: ${e.toString()}", _C.errorRed);
    } finally {
      if (mounted) setState(() { _loading = false; _isUploading = false; });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descController.clear();
    setState(() { _expiryDate = null; _fileName = null; _selectedBytes = null; });
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightGray,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildFileCard(),
              const SizedBox(height: 16),
              _buildInfoBanner(),
              const SizedBox(height: 24),
              _loading ? _buildProgressBlock() : _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
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
                'Upload Document',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: _C.textPrimary, letterSpacing: -0.3),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _C.lightBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.mediumBlue),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upload_file_rounded, size: 13, color: _C.primaryBlue),
                SizedBox(width: 5),
                Text('New',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _C.primaryBlue)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Form Card (title + desc + expiry) ─────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Document Details'),
        const SizedBox(height: 16),

        // Title
        _field(
          controller: _titleController,
          label: 'Document Title',
          icon: Icons.title_rounded,
          required: true,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),

        // Description
        TextFormField(
          controller: _descController,
          maxLines: 3,
          style: const TextStyle(fontSize: 14, color: _C.textPrimary),
          decoration: _inputDec('Description (optional)', Icons.notes_rounded),
        ),
        const SizedBox(height: 14),

        // Expiry Date
        _buildExpiryRow(),
      ]),
    );
  }

  Widget _buildExpiryRow() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: _C.primaryBlue),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _expiryDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _C.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.borderGray),
        ),
        child: Row(children: [
          const Icon(Icons.event_rounded, size: 20, color: _C.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _expiryDate == null
                  ? 'Expiry date (optional)'
                  : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
              style: TextStyle(
                fontSize: 14,
                color: _expiryDate == null ? _C.textTertiary : _C.textPrimary,
                fontWeight: _expiryDate != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (_expiryDate != null)
            GestureDetector(
              onTap: () => setState(() => _expiryDate = null),
              child: const Icon(Icons.close_rounded, size: 18, color: _C.textTertiary),
            )
          else
            const Icon(Icons.chevron_right_rounded, size: 18, color: _C.textTertiary),
        ]),
      ),
    );
  }

  // ── File Card ─────────────────────────────────────────────────────────────────
  Widget _buildFileCard() {
    final uploaded = _selectedBytes != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('File'),
        const SizedBox(height: 16),

        // Upload tile
        GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: uploaded ? _C.lightGreen : _C.lightGray,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: uploaded ? _C.successGreen : _C.borderGray,
                width: uploaded ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: uploaded
                      ? _C.successGreen.withOpacity(0.12)
                      : _C.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  uploaded
                      ? Icons.check_circle_outline_rounded
                      : Icons.attach_file_rounded,
                  size: 22,
                  color: uploaded ? _C.successGreen : _C.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    uploaded ? (_fileName ?? 'File selected') : 'Tap to choose file',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: uploaded ? _C.successGreen : _C.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uploaded
                        ? '${(_selectedBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB  •  Tap to replace'
                        : 'PDF, JPG, PNG, DOC, XLS — max 800 KB',
                    style: TextStyle(
                      fontSize: 12,
                      color: uploaded
                          ? _C.successGreen.withOpacity(0.7)
                          : _C.textTertiary,
                    ),
                  ),
                ]),
              ),
              Icon(
                uploaded ? Icons.swap_horiz_rounded : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: uploaded ? _C.successGreen : _C.textTertiary,
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Info Banner ───────────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.lightOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.warningOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.info_outline_rounded,
              size: 16, color: _C.warningOrange),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Max file size: 800 KB\nSupported: PDF, JPG, PNG, DOC, DOCX, XLS, XLSX',
            style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.55),
          ),
        ),
      ]),
    );
  }

  // ── Progress Block ────────────────────────────────────────────────────────────
  Widget _buildProgressBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
      ),
      child: Column(children: [
        Row(children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: _C.primaryBlue),
          ),
          const SizedBox(width: 12),
          Text(
            'Uploading… ${(_progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _C.textPrimary),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: _C.mediumBlue,
            color: _C.primaryBlue,
          ),
        ),
      ]),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Column(children: [
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _isUploading ? null : _saveDocument,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: _C.primaryBlue.withOpacity(0.5),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_upload_rounded, size: 18),
            SizedBox(width: 8),
            Text('Upload Document',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: _clearForm,
          style: OutlinedButton.styleFrom(
            foregroundColor: _C.textSecondary,
            side: const BorderSide(color: _C.borderGray),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.clear_all_rounded, size: 18),
            SizedBox(width: 8),
            Text('Clear Form',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    ]);
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(
        width: 3, height: 16,
        decoration: BoxDecoration(
          color: _C.primaryBlue,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: _C.textSecondary, letterSpacing: 0.3)),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: _C.textPrimary),
      decoration: _inputDec(label, icon),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: _C.textSecondary),
      filled: true,
      fillColor: _C.lightGray,
      prefixIcon: Icon(icon, size: 20, color: _C.textTertiary),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.borderGray)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.borderGray)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primaryBlue, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.errorRed)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}