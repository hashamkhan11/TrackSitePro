import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

// ── Shared colour palette (mirrors ContractorDashboard) ──────────────────────
class AppColors {
  static const primaryBlue = Color(0xFF2563EB);
  static const lightBlue = Color(0xFFEFF6FF);
  static const mediumBlue = Color(0xFFBFDBFE);
  static const successGreen = Color(0xFF10B981);
  static const lightGreen = Color(0xFFECFDF5);
  static const warningOrange = Color(0xFFF59E0B);
  static const lightOrange = Color(0xFFFEF3C7);
  static const lightGray = Color(0xFFF9FAFB);
  static const borderGray = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const unpaidRed = Color(0xFFEF4444);

  // Payment type colours
  static const partial1Color = Color(0xFFF59E0B);   // 50%  — orange
  static const partial1Bg    = Color(0xFFFFFBEB);
  static const partial1Border= Color(0xFFFDE68A);
  static const partial2Color = Color(0xFF3B82F6);   // 80%  — blue
  static const partial2Bg    = Color(0xFFEFF6FF);
  static const partial2Border= Color(0xFFBFDBFE);
  static const finalColor    = Color(0xFF10B981);   // 100% — green
  static const finalBg       = Color(0xFFECFDF5);
  static const finalBorder   = Color(0xFF6EE7B7);
}

// ── Helpers ───────────────────────────────────────────────────────────────────
_PaymentStyle _styleForType(String type) {
  if (type.contains('50%')) {
    return _PaymentStyle(
      color: AppColors.partial1Color,
      bg: AppColors.partial1Bg,
      border: AppColors.partial1Border,
      icon: Icons.hourglass_top_rounded,
      shortLabel: '50%',
    );
  }
  if (type.contains('80%')) {
    return _PaymentStyle(
      color: AppColors.partial2Color,
      bg: AppColors.partial2Bg,
      border: AppColors.partial2Border,
      icon: Icons.account_balance_wallet_rounded,
      shortLabel: '80%',
    );
  }
  return _PaymentStyle(
    color: AppColors.finalColor,
    bg: AppColors.finalBg,
    border: AppColors.finalBorder,
    icon: Icons.check_circle_rounded,
    shortLabel: '100%',
  );
}

class _PaymentStyle {
  final Color color, bg, border;
  final IconData icon;
  final String shortLabel;
  const _PaymentStyle({
    required this.color, required this.bg, required this.border,
    required this.icon, required this.shortLabel,
  });
}

String _fmtDate(Timestamp? ts) {
  if (ts == null) return '—';
  final d = ts.toDate();
  return '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / ${d.year}';
}

String _fmtAmount(double amount) {
  if (amount >= 1000000) return 'PKR ${(amount / 1000000).toStringAsFixed(2)}M';
  if (amount >= 1000)    return 'PKR ${(amount / 1000).toStringAsFixed(1)}K';
  return 'PKR ${amount.toStringAsFixed(0)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PaymentHistoryScreen
// ═══════════════════════════════════════════════════════════════════════════════
class PaymentHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const PaymentHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {

  // ── Delete ──────────────────────────────────────────────────────────────────
  Future<void> _deletePayment(String paymentId, String? documentUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.unpaidRed, size: 30),
            ),
            const SizedBox(height: 20),
            const Text('Delete Payment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to delete this payment certificate? '
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.borderGray),
                      foregroundColor: AppColors.textSecondary),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.unpaidRed,
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Delete',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      if (documentUrl != null && documentUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(documentUrl).delete();
        } catch (_) {}
      }
      await FirebaseFirestore.instance
          .collection('projects').doc(widget.projectId)
          .collection('payments').doc(paymentId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Payment deleted',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.unpaidRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── Open add/edit bottom sheet ──────────────────────────────────────────────
  void _openPaymentSheet({Map<String, dynamic>? existing, String? paymentId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditPaymentSheet(
        projectId: widget.projectId,
        existingPayment: existing,
        paymentId: paymentId,
      ),
    );
  }

  // ── Payment card ────────────────────────────────────────────────────────────
  Widget _buildPaymentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['paymentType'] as String? ?? '';
    final amount = (data['amount'] ?? 0).toDouble();
    final certNo = data['certificateNumber'] as String? ?? '';
    final date = data['date'] as Timestamp?;
    final docUrl = data['documentUrl'] as String?;
    final style = _styleForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(children: [
            // Type badge icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: style.bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(style.icon, size: 20, color: style.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Short type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: style.border)),
                  child: Text(style.shortLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                          color: style.color)),
                ),
                const SizedBox(height: 5),
                Text(type,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            // Amount + actions column
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmtAmount(amount),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: style.color)),
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _iconBtn(
                  icon: Icons.edit_rounded,
                  color: AppColors.primaryBlue,
                  bg: AppColors.lightBlue,
                  onTap: () => _openPaymentSheet(existing: data, paymentId: doc.id),
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  icon: Icons.delete_rounded,
                  color: AppColors.unpaidRed,
                  bg: const Color(0xFFFEF2F2),
                  onTap: () => _deletePayment(doc.id, docUrl),
                ),
              ]),
            ]),
          ]),
        ),

        // ── Details strip (only if there is data) ──
        if (certNo.isNotEmpty || date != null || (docUrl != null && docUrl.isNotEmpty)) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.lightGray, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              if (certNo.isNotEmpty)
                _detailRow(Icons.receipt_long_rounded, 'Certificate No', certNo),
              if (certNo.isNotEmpty && date != null) const SizedBox(height: 8),
              if (date != null)
                _detailRow(Icons.calendar_today_rounded, 'Date', _fmtDate(date)),
              if ((certNo.isNotEmpty || date != null) &&
                  (docUrl != null && docUrl.isNotEmpty))
                const SizedBox(height: 10),
              if (docUrl != null && docUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Document viewer coming soon'),
                      backgroundColor: AppColors.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.mediumBlue)),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.attach_file_rounded,
                              size: 14, color: AppColors.primaryBlue),
                          SizedBox(width: 6),
                          Text('View Document',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue)),
                        ]),
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 13, color: AppColors.textTertiary),
      const SizedBox(width: 6),
      Text('$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      Expanded(
        child: Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _iconBtn({
    required IconData icon, required Color color,
    required Color bg, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ── Summary header card ─────────────────────────────────────────────────────
  Widget _buildSummaryCard(List<QueryDocumentSnapshot> payments) {
    double total = 0;
    for (var d in payments) {
      total += ((d.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(children: [
        Expanded(child: _summaryCell(
          label: 'Total Received',
          value: _fmtAmount(total),
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.successGreen,
          bg: AppColors.lightGreen,
        )),
        Container(width: 1, height: 44, color: AppColors.borderGray,
            margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(child: _summaryCell(
          label: 'Certificates',
          value: '${payments.length} added',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primaryBlue,
          bg: AppColors.lightBlue,
        )),
      ]),
    );
  }

  Widget _summaryCell({
    required String label, required String value,
    required IconData icon, required Color color, required Color bg,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
                color: AppColors.lightGray, shape: BoxShape.circle),
            child: const Icon(Icons.payment_rounded,
                size: 46, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          const Text('No Payments Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          const Text('Tap the button below to add a payment certificate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        ]),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      // ── AppBar — white + bottom border, no subtitle ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.borderGray, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Payment Certificates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, letterSpacing: -0.5)),
                ),
              ]),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects').doc(widget.projectId)
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: AppColors.primaryBlue, strokeWidth: 3));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.unpaidRed)));
          }

          final payments = snapshot.data?.docs ?? [];

          if (payments.isEmpty) return _buildEmptyState();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Summary card
              SliverToBoxAdapter(child: _buildSummaryCard(payments)),

              // Section label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 15, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 10),
                    const Text('All Certificates',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, letterSpacing: -0.4)),
                  ]),
                ),
              ),

              // List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildPaymentCard(payments[i]),
                    childCount: payments.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ── FAB ──
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () => _openPaymentSheet(),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Payment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _AddEditPaymentSheet  (bottom sheet replacing AlertDialog)
// ═══════════════════════════════════════════════════════════════════════════════
class _AddEditPaymentSheet extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? existingPayment;
  final String? paymentId;

  const _AddEditPaymentSheet({
    required this.projectId,
    this.existingPayment,
    this.paymentId,
  });

  @override
  State<_AddEditPaymentSheet> createState() => _AddEditPaymentSheetState();
}

class _AddEditPaymentSheetState extends State<_AddEditPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _certController = TextEditingController();

  String _selectedType = 'Partial Payment Certificate - 1 (50%)';
  DateTime? _selectedDate;
  File? _selectedFile;
  String? _existingDocUrl;
  bool _isLoading = false;

  List<String> _availableTypes = [];

  static const Map<String, String> _allTypes = {
    '50%': 'Partial Payment Certificate - 1 (50%)',
    '80%': 'Partial Payment Certificate - 2 (80%)',
    '100%': 'Final Payment Certificate (100%)',
  };

  bool get _isEditMode =>
      widget.paymentId != null && widget.existingPayment != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingPayment != null) {
      _amountController.text =
          (widget.existingPayment!['amount'] ?? '').toString();
      _certController.text =
          widget.existingPayment!['certificateNumber'] ?? '';
      _selectedType = widget.existingPayment!['paymentType'] ??
          _allTypes['50%']!;
      if (widget.existingPayment!['date'] != null) {
        _selectedDate =
            (widget.existingPayment!['date'] as Timestamp).toDate();
      }
      _existingDocUrl = widget.existingPayment!['documentUrl'] as String?;
    }
    _loadExistingPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _certController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPayments() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('projects').doc(widget.projectId)
          .collection('payments').get();

      final existing = snap.docs
          .where((d) => widget.paymentId == null || d.id != widget.paymentId)
          .map((d) => (d.data())['paymentType'] as String)
          .toSet();

      final available = _allTypes.values
          .where((t) => !existing.contains(t))
          .toList();

      if (_isEditMode) {
        final cur = widget.existingPayment!['paymentType'] as String;
        if (!available.contains(cur)) available.add(cur);
      }

      setState(() {
        _availableTypes = available;
        if (available.isNotEmpty && !_isEditMode) {
          _selectedType = available.first;
        }
      });
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFile = File(result.files.single.path!));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e'),
            backgroundColor: AppColors.unpaidRed),
      );
    }
  }

  Future<String?> _uploadDocument() async {
    if (_selectedFile == null) return _existingDocUrl;
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref().child('payments').child(widget.projectId).child(fileName);
      await ref.putFile(_selectedFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'),
              backgroundColor: AppColors.unpaidRed),
        );
      }
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docUrl = await _uploadDocument();
      final payload = <String, dynamic>{
        'paymentType': _selectedType,
        'amount': double.parse(_amountController.text),
        'certificateNumber': _certController.text.trim(),
        'date': _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!) : null,
        'documentUrl': docUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final colRef = FirebaseFirestore.instance
          .collection('projects').doc(widget.projectId)
          .collection('payments');

      if (_isEditMode) {
        await colRef.doc(widget.paymentId).update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await colRef.add(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(_isEditMode
                ? 'Payment updated successfully'
                : 'Payment added successfully',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.unpaidRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Field builder ────────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        onTap: onTap,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
            color: readOnly ? AppColors.textTertiary : AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18,
              color: readOnly ? AppColors.textTertiary : AppColors.primaryBlue),
          suffixIcon: suffix,
          filled: true,
          fillColor: readOnly ? AppColors.lightGray : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primaryBlue, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.unpaidRed)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.unpaidRed, width: 1.5)),
        ),
      ),
    ]);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // All types already used — show a simple notice sheet
    if (_availableTypes.isEmpty && !_isEditMode) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 28),
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: AppColors.lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                size: 36, color: AppColors.successGreen),
          ),
          const SizedBox(height: 20),
          const Text('All Certificates Added',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          const Text(
            'All three payment certificates (50%, 80%, 100%) have already been recorded for this project.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Got it!',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2)),
          )),
        ),

        // Sheet header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 18, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Text(
              _isEditMode ? 'Edit Payment Certificate' : 'Add Payment Certificate',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.4),
            ),
          ]),
        ),

        // Scrollable form body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Payment type dropdown ──
                  const Text('Payment Type *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _availableTypes.contains(_selectedType)
                        ? _selectedType : (_availableTypes.isNotEmpty ? _availableTypes.first : null),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.payments_rounded,
                          size: 18, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderGray)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primaryBlue, width: 1.5)),
                    ),
                    isExpanded: true,
                    items: _availableTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),

                  const SizedBox(height: 18),

                  // ── Amount ──
                  _field(
                    controller: _amountController,
                    label: 'Payment Amount (PKR) *',
                    icon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount is required';
                      if (double.tryParse(v) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ── Certificate number ──
                  _field(
                    controller: _certController,
                    label: 'Certificate Number (Optional)',
                    icon: Icons.receipt_long_rounded,
                  ),

                  const SizedBox(height: 18),

                  // ── Date ──
                  _field(
                    controller: TextEditingController(
                        text: _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : ''),
                    label: 'Date (Optional)',
                    icon: Icons.calendar_today_rounded,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme
                                .copyWith(primary: AppColors.primaryBlue),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    suffix: const Icon(Icons.edit_calendar_rounded,
                        size: 18, color: AppColors.primaryBlue),
                  ),

                  const SizedBox(height: 18),

                  // ── Attach file ──
                  const Text('Attach Document (Optional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedFile != null
                            ? AppColors.lightGreen : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _selectedFile != null
                                ? AppColors.finalBorder : AppColors.borderGray),
                      ),
                      child: Row(children: [
                        Icon(
                          _selectedFile != null
                              ? Icons.check_circle_rounded
                              : Icons.attach_file_rounded,
                          size: 18,
                          color: _selectedFile != null
                              ? AppColors.successGreen : AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedFile != null
                                ? _selectedFile!.path.split('/').last
                                : _existingDocUrl != null
                                    ? 'Tap to replace document'
                                    : 'Tap to attach PDF / Image',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _selectedFile != null
                                    ? AppColors.successGreen
                                    : AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Action buttons ──
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: AppColors.borderGray),
                            foregroundColor: AppColors.textSecondary),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isEditMode
                                      ? Icons.check_rounded : Icons.add_rounded,
                                      size: 18),
                                  const SizedBox(width: 6),
                                  Text(_isEditMode ? 'Update' : 'Save',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}