import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// ── Design tokens (mirrors dashboard) ────────────────────────────────────────
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

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  Color? iconColor,
  Widget? suffix,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(
        fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
    floatingLabelStyle: const TextStyle(
        fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
    prefixIcon: Icon(icon, size: 18,
        color: (iconColor ?? AppColors.primaryBlue).withOpacity(0.75)),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGray)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGray)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.expiredRed)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.expiredRed, width: 2)),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class UploadFirmDocumentScreen extends StatefulWidget {
  final String firmId;
  const UploadFirmDocumentScreen({super.key, required this.firmId});

  @override
  State<UploadFirmDocumentScreen> createState() =>
      _UploadFirmDocumentScreenState();
}

class _UploadFirmDocumentScreenState extends State<UploadFirmDocumentScreen> {
  final _titleController = TextEditingController();
  DateTime? _expiryDate;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Uint8List? _fileBytes;
  String? _fileName;

  final List<String> _documentTypes = [
    'PEC License',
    'Company Registration',
    'Tax Certificate',
    'Insurance Policy',
    'Bank Guarantee',
    'Performance Bond',
    'Safety Certificate',
    'Quality Certificate',
    'Other',
  ];
  String _selectedType = 'PEC License';

  bool get _isOther => _selectedType == 'Other';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ── File picker ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes!;
        if (bytes.lengthInBytes / (1024 * 1024) > 5) {
          _snack('File too large — maximum 5 MB allowed', error: true); return;
        }
        setState(() { _fileBytes = bytes; _fileName = result.files.first.name; });
      }
    } catch (e) {
      _snack('Failed to pick file: $e', error: true);
    }
  }

  // ── Upload ──────────────────────────────────────────────────────────────────

  Future<void> _uploadDocument() async {
    if (_isOther && _titleController.text.trim().isEmpty) {
      _snack('Please enter a document title for "Other" type'); return;
    }
    if (_fileBytes == null) {
      _snack('Please select a file to upload'); return;
    }

    setState(() { _isUploading = true; _uploadProgress = 0.3; });

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _uploadProgress = 0.6);

      final finalTitle = _isOther ? _titleController.text.trim() : _selectedType;

      await FirebaseFirestore.instance
          .collection('firms')
          .doc(widget.firmId)
          .collection('documents')
          .add({
        'title': finalTitle,
        'documentType': _selectedType,
        'fileName': _fileName,
        'fileData': base64Encode(_fileBytes!),
        'fileSize': _fileBytes!.lengthInBytes / 1024,
        'uploadDate': Timestamp.now(),
        'expiryDate': _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        'createdAt': Timestamp.now(),
      });

      setState(() => _uploadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _snack('Document uploaded successfully', error: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('Upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0.0; });
    }
  }

  void _clearForm() {
    _titleController.clear();
    setState(() {
      _expiryDate = null; _fileName = null; _fileBytes = null;
      _selectedType = 'PEC License';
    });
  }

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

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            Text('Upload Document',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.5)),
            Text('Add a new firm document',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        toolbarHeight: 62,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderGray),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Document Type ──
          _sectionHeader('Document Details', Icons.folder_special_rounded),
          const SizedBox(height: 12),
          _buildDocumentTypeCard(),
          const SizedBox(height: 24),

          // ── Expiry Date ──
          _sectionHeader('Expiry Date', Icons.event_rounded),
          const SizedBox(height: 12),
          _buildExpiryCard(),
          const SizedBox(height: 24),

          // ── File ──
          _sectionHeader('Document File', Icons.attach_file_rounded),
          const SizedBox(height: 12),
          _buildFileCard(),
          const SizedBox(height: 12),
          _buildFileRequirementsNote(),
          const SizedBox(height: 28),

          // ── Actions ──
          _buildActions(),
        ]),
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: AppColors.lightBlue, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: AppColors.primaryBlue),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: -0.3)),
    ]);
  }

  // ── Document type card ──────────────────────────────────────────────────────

  Widget _buildDocumentTypeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Type chips grid
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _documentTypes.map((type) {
            final selected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedType = type;
                if (!_isOther) _titleController.clear();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryBlue : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: selected ? AppColors.primaryBlue : AppColors.borderGray,
                      width: selected ? 1.5 : 1),
                ),
                child: Text(type,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),

        // Custom title field — only when "Other"
        if (_isOther) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderGray),
          const SizedBox(height: 14),
          TextFormField(
            controller: _titleController,
            decoration: _fieldDecoration(
                label: 'Custom Document Title *',
                icon: Icons.drive_file_rename_outline_rounded,
                hint: 'e.g. Environmental Clearance'),
          ),
        ],
      ]),
    );
  }

  // ── Expiry card ─────────────────────────────────────────────────────────────

  Widget _buildExpiryCard() {
    final hasDate = _expiryDate != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasDate ? AppColors.mediumBlue : AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: hasDate ? AppColors.lightBlue : AppColors.lightGray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: hasDate ? AppColors.mediumBlue : AppColors.borderGray)),
          child: Icon(Icons.calendar_month_rounded, size: 18,
              color: hasDate ? AppColors.primaryBlue : AppColors.textTertiary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hasDate ? 'Expires on' : 'No expiry date set',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: hasDate ? AppColors.textTertiary : AppColors.textTertiary)),
            if (hasDate)
              Text(
                '${_expiryDate!.day.toString().padLeft(2,'0')}/'
                '${_expiryDate!.month.toString().padLeft(2,'0')}/'
                '${_expiryDate!.year}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue),
              )
            else
              const Text('Optional — tap to set',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),
        if (hasDate)
          GestureDetector(
            onTap: () => setState(() => _expiryDate = null),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close_rounded,
                  size: 15, color: AppColors.expiredRed),
            ),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryBlue, onPrimary: Colors.white,
                      surface: Colors.white, onSurface: AppColors.textPrimary),
                  dialogBackgroundColor: Colors.white,
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _expiryDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mediumBlue)),
            child: Text(hasDate ? 'Change' : 'Set Date',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue)),
          ),
        ),
      ]),
    );
  }

  // ── File card ───────────────────────────────────────────────────────────────

  Widget _buildFileCard() {
    final hasFile = _fileBytes != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasFile ? AppColors.successGreen.withOpacity(0.4) : AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (!hasFile)
          // Empty state — dashed upload zone
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.borderGray,
                    style: BorderStyle.solid,
                    width: 1.5),
              ),
              child: const Column(children: [
                Icon(Icons.upload_file_rounded, size: 36, color: AppColors.textTertiary),
                SizedBox(height: 10),
                Text('Tap to choose a file',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                SizedBox(height: 4),
                Text('PDF, JPG, PNG, DOC, XLS — max 5 MB',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ]),
            ),
          )
        else ...[
          // File preview row
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: AppColors.lightGreen, borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.successGreen.withOpacity(0.3))),
              child: const Icon(Icons.insert_drive_file_rounded,
                  size: 22, color: AppColors.successGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fileName ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${(_fileBytes!.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ]),
            ),
            // Ready badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.lightGreen, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, size: 12, color: AppColors.successGreen),
                SizedBox(width: 4),
                Text('Ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.successGreen)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          // Progress bar (filled)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor: AppColors.lightGreen,
              color: AppColors.successGreen,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),
          // Replace file button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Replace File',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.mediumBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── File requirements note ──────────────────────────────────────────────────

  Widget _buildFileRequirementsNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningOrange.withOpacity(0.3)),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warningOrange),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Max 5 MB · PDF, JPG, PNG, DOC, DOCX, XLS, XLSX',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: Color(0xFF92400E)),
          ),
        ),
      ]),
    );
  }

  // ── Action buttons / upload state ───────────────────────────────────────────

  Widget _buildActions() {
    if (_isUploading) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mediumBlue),
          ),
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primaryBlue)),
              const SizedBox(width: 12),
              Text(
                'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.lightBlue,
                color: AppColors.primaryBlue,
                minHeight: 6,
              ),
            ),
          ]),
        ),
      ]);
    }

    return Column(children: [
      SizedBox(
        height: 52, width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _uploadDocument,
          icon: const Icon(Icons.cloud_upload_rounded, size: 20),
          label: const Text('Upload Document',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  letterSpacing: 0.2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 48, width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _clearForm,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Clear Form',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderGray),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]);
  }
}