import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'generate_invoice_screen.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class AppColors {
  static const primaryBlue    = Color(0xFF2563EB);
  static const lightBlue      = Color(0xFFEFF6FF);
  static const mediumBlue     = Color(0xFFBFDBFE);
  static const darkBlue       = Color(0xFF1E40AF);
  static const successGreen   = Color(0xFF10B981);
  static const lightGreen     = Color(0xFFECFDF5);
  static const warningOrange  = Color(0xFFF59E0B);
  static const lightOrange    = Color(0xFFFEF3C7);
  static const neutralGray    = Color(0xFF6B7280);
  static const lightGray      = Color(0xFFF9FAFB);
  static const borderGray     = Color(0xFFE5E7EB);
  static const textPrimary    = Color(0xFF111827);
  static const textSecondary  = Color(0xFF6B7280);
  static const textTertiary   = Color(0xFF9CA3AF);
  static const errorRed       = Color(0xFFEF4444);
  static const lightRed       = Color(0xFFFEF2F2);
}

class InvoiceHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const InvoiceHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  // ── Formatters ───────────────────────────────────────────────────────────────
  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  String _formatCurrency(double amount) =>
      NumberFormat("#,##0", "en_US").format(amount);

  Uint8List? _getPdfBytes(Map<String, dynamic> invoice) {
    final pdfData = invoice['pdfBytes'];
    if (pdfData == null) return null;
    if (pdfData is Uint8List) return pdfData;
    if (pdfData is List) return Uint8List.fromList(pdfData.cast<int>());
    return null;
  }

  String _generateInvoiceNumber(String? jobNo) {
    final now = DateTime.now();
    final y   = now.year.toString().substring(2);
    final m   = now.month.toString().padLeft(2, '0');
    final d   = now.day.toString().padLeft(2, '0');
    final code = jobNo?.split('/').last ?? '000';
    return 'INV-$y$m$d-$code';
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
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

  Future<void> _showInvoiceOptions(Map<String, dynamic> invoice) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Invoice Options',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 16),
          _sheetOption(Icons.visibility_rounded, AppColors.primaryBlue,
              AppColors.lightBlue, 'View Invoice',
              () { Navigator.pop(context); _viewInvoicePDF(invoice); }),
          const SizedBox(height: 10),
          _sheetOption(Icons.download_rounded, AppColors.successGreen,
              AppColors.lightGreen, 'Download PDF',
              () { Navigator.pop(context); _downloadInvoice(invoice); }),
          const SizedBox(height: 10),
          _sheetOption(Icons.share_rounded, AppColors.warningOrange,
              AppColors.lightOrange, 'Share Invoice',
              () { Navigator.pop(context); _shareInvoice(invoice); }),
        ]),
      ),
    );
  }

  Widget _sheetOption(IconData icon, Color color, Color bg,
      String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ]),
        ),
      ),
    );
  }

  Future<void> _viewInvoicePDF(Map<String, dynamic> invoice) async {
    try {
      final bytes = _getPdfBytes(invoice);
      if (bytes == null) throw Exception('PDF data not found');
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _snack('Failed to view invoice: $e', AppColors.errorRed);
    }
  }

  Future<void> _downloadInvoice(Map<String, dynamic> invoice) async {
    try {
      final bytes = _getPdfBytes(invoice);
      if (bytes == null) throw Exception('PDF data not found');
      await Printing.sharePdf(
          bytes: bytes, filename: '${invoice['invoiceNumber']}.pdf');
    } catch (e) {
      _snack('Failed to download invoice: $e', AppColors.errorRed);
    }
  }

  Future<void> _shareInvoice(Map<String, dynamic> invoice) async {
    try {
      final bytes = _getPdfBytes(invoice);
      if (bytes == null) throw Exception('PDF data not found');
      await Printing.sharePdf(
          bytes: bytes, filename: '${invoice['invoiceNumber']}.pdf');
    } catch (e) {
      _snack('Failed to share invoice: $e', AppColors.errorRed);
    }
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.lightRed,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.errorRed, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Delete Invoice',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
        content: const Text(
          'This will permanently delete the invoice. This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('projects').doc(widget.projectId)
          .collection('invoices').doc(invoiceId).delete();
      _snack('Invoice deleted successfully', AppColors.successGreen);
    } catch (e) {
      _snack('Delete failed: $e', AppColors.errorRed);
    }
  }

  Future<void> _navigateToGenerate() async {
    final projectDoc = await FirebaseFirestore.instance
        .collection('projects').doc(widget.projectId).get();
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateInvoiceScreen(
          projectId: widget.projectId,
          jobNo: projectDoc.data()?['jobNo'] ?? '',
          workOrderNo: projectDoc.data()?['workOrderNo'] ?? '',
          invoiceNumber: _generateInvoiceNumber(projectDoc.data()?['jobNo']),
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects').doc(widget.projectId)
            .collection('invoices')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: AppColors.primaryBlue, strokeWidth: 2.5));
          }
          if (snapshot.hasError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.errorRed),
                const SizedBox(height: 12),
                const Text('Failed to load invoices',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('${snapshot.error}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty();
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _InvoiceCard(
                invoice: data,
                invoiceId: doc.id,
                onTap: () => _showInvoiceOptions(data),
                onDelete: () => _deleteInvoice(doc.id),
                formatCurrency: _formatCurrency,
                formatDate: _formatDate,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToGenerate,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('New Invoice',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
          border: Border(bottom: BorderSide(color: AppColors.borderGray, width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Invoices',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, letterSpacing: -0.3)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mediumBlue),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_rounded, size: 13, color: AppColors.primaryBlue),
                SizedBox(width: 5),
                Text('History',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue)),
              ]),
            ),
          ]),
        ),
      ),
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
                color: AppColors.lightGray, shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGray)),
            child: const Icon(Icons.receipt_outlined,
                size: 48, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),
          const Text('No Invoices Generated',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          const Text('Generate your first invoice using the button below',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary,
                  height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToGenerate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Generate Invoice',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Invoice Card ──────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final String invoiceId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(double) formatCurrency;
  final String Function(DateTime) formatDate;

  const _InvoiceCard({
    required this.invoice,
    required this.invoiceId,
    required this.onTap,
    required this.onDelete,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final date        = (invoice['date'] as Timestamp).toDate();
    final totalAmount = (invoice['totalAmount'] ?? 0).toDouble();
    final exclusive   = (invoice['exclusiveValue'] ?? 0).toDouble();
    final pstRate     = invoice['pstRate'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // ── Main tappable area ──
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                // Icon
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.mediumBlue)),
                  child: const Icon(Icons.receipt_rounded,
                      color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                // Invoice number + date
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(invoice['invoiceNumber'] ?? 'INV-00000',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(formatDate(date),
                          style: const TextStyle(fontSize: 12,
                              color: AppColors.textSecondary)),
                    ]),
                  ]),
                ),
                // Amount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Text(
                    'PKR ${formatCurrency(totalAmount)}',
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successGreen),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Meta row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderGray)),
                child: Row(children: [
                  _metaItem(Icons.account_balance_wallet_outlined,
                      'Exclusive',
                      'PKR ${formatCurrency(exclusive)}',
                      AppColors.primaryBlue),
                  Container(width: 1, height: 28,
                      color: AppColors.borderGray,
                      margin: const EdgeInsets.symmetric(horizontal: 12)),
                  _metaItem(Icons.percent_rounded,
                      'PST', '$pstRate%', AppColors.warningOrange),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textTertiary),
                ]),
              ),
            ]),
          ),
        ),
        // ── Delete strip ──
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderGray)),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.errorRed),
            label: const Text('Delete',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.errorRed)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(double.infinity, 0),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _metaItem(IconData icon, String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: color)),
      ]),
    ]);
  }
}