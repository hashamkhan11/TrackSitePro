import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/pdf_invoice_generator.dart';

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
}

class GenerateInvoiceScreen extends StatefulWidget {
  final String projectId;
  final String jobNo;
  final String workOrderNo;
  final String invoiceNumber;

  const GenerateInvoiceScreen({
    super.key,
    required this.projectId,
    required this.jobNo,
    required this.workOrderNo,
    required this.invoiceNumber,
  });

  @override
  State<GenerateInvoiceScreen> createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  final _formKey                  = GlobalKey<FormState>();
  final _exclusiveValueController = TextEditingController();
  final _pstRateController        = TextEditingController(text: '16');
  final _pstAmountController      = TextEditingController();
  final _totalAmountController    = TextEditingController();

  DateTime _invoiceDate  = DateTime.now();
  bool     _isGenerating = false;

  @override
  void dispose() {
    _exclusiveValueController.dispose();
    _pstRateController.dispose();
    _pstAmountController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  // ── Calculation ───────────────────────────────────────────────────────────────
  void _calculateValues() {
    final exclusive = double.tryParse(_exclusiveValueController.text) ?? 0;
    final rate      = double.tryParse(_pstRateController.text) ?? 16;
    final pst       = exclusive * (rate / 100);
    final total     = exclusive + pst;
    setState(() {
      _pstAmountController.text   = pst.toStringAsFixed(0);
      _totalAmountController.text = total.toStringAsFixed(0);
    });
  }

  // ── Date Picker ───────────────────────────────────────────────────────────────
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _C.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _invoiceDate = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────────
  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isGenerating = true);

    try {
      final pdfBytes = await PdfInvoiceGenerator.generateInvoice(
        invoiceDate:    _invoiceDate,
        jobNo:          widget.jobNo,
        workOrderNo:    widget.workOrderNo,
        exclusiveValue: double.parse(_exclusiveValueController.text),
        pstRate:        double.parse(_pstRateController.text),
        pstAmount:      double.parse(_pstAmountController.text),
        totalAmount:    double.parse(_totalAmountController.text),
      );

      await FirebaseFirestore.instance
          .collection('projects').doc(widget.projectId)
          .collection('invoices').add({
        'invoiceNumber':  widget.invoiceNumber,
        'date':           Timestamp.fromDate(_invoiceDate),
        'jobNo':          widget.jobNo,
        'workOrderNo':    widget.workOrderNo,
        'exclusiveValue': double.parse(_exclusiveValueController.text),
        'pstRate':        double.parse(_pstRateController.text),
        'pstAmount':      double.parse(_pstAmountController.text),
        'totalAmount':    double.parse(_totalAmountController.text),
        'createdAt':      FieldValue.serverTimestamp(),
        'pdfBytes':       pdfBytes,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Invoice saved successfully',
              style: TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: _C.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save invoice: $e',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: _C.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
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
              // Preview card
              _buildPreviewCard(),
              const SizedBox(height: 16),
              // Input card
              _buildInputCard(),
              const SizedBox(height: 16),
              // Calculated values card
              _buildCalculatedCard(),
              const SizedBox(height: 24),
              // Save button
              _buildSaveButton(),
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
                  color: _C.lightGray,
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    size: 20, color: _C.textSecondary),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Generate Invoice',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: _C.textPrimary, letterSpacing: -0.3)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _C.lightBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.mediumBlue),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_rounded, size: 13, color: _C.primaryBlue),
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

  // ── Preview Card ──────────────────────────────────────────────────────────────
  Widget _buildPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Invoice Details'),
        const SizedBox(height: 16),
        _previewRow(Icons.tag_rounded,            'Invoice No', widget.invoiceNumber),
        const SizedBox(height: 10),
        _previewRow(Icons.calendar_today_rounded, 'Date',       _formatDate(_invoiceDate)),
        const SizedBox(height: 10),
        _previewRow(Icons.work_outline_rounded,   'Job No',     widget.jobNo.isEmpty ? '—' : widget.jobNo),
        const SizedBox(height: 10),
        _previewRow(Icons.assignment_rounded,     'Work Order', widget.workOrderNo.isEmpty ? '—' : widget.workOrderNo),
      ]),
    );
  }

  Widget _previewRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: _C.lightBlue, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: _C.primaryBlue),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 86,
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: _C.textTertiary,
                fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: _C.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  // ── Input Card ────────────────────────────────────────────────────────────────
  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Payment Certificate Values'),
        const SizedBox(height: 16),

        // Exclusive Value
        _field(
          controller: _exclusiveValueController,
          label: 'Exclusive Value (Total Work Done)',
          icon: Icons.account_balance_wallet_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => _calculateValues(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (double.tryParse(v) == null) return 'Invalid number';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // PST Rate
        _field(
          controller: _pstRateController,
          label: 'PST Rate (%)',
          icon: Icons.percent_rounded,
          keyboardType: TextInputType.number,
          onChanged: (_) => _calculateValues(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (double.tryParse(v) == null) return 'Invalid number';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Invoice Date
        GestureDetector(
          onTap: _selectDate,
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
                child: Text(_formatDate(_invoiceDate),
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600, color: _C.textPrimary)),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: _C.textTertiary),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Calculated Card ───────────────────────────────────────────────────────────
  Widget _buildCalculatedCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Calculated Summary'),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _C.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.borderGray)),
          child: Column(children: [
            _calcRow('PST Amount', _pstAmountController.text,
                _C.warningOrange, bold: false),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: _C.borderGray),
            ),
            _calcRow('Total (Inclusive)', _totalAmountController.text,
                _C.primaryBlue, bold: true),
          ]),
        ),
      ]),
    );
  }

  Widget _calcRow(String label, String value, Color color,
      {required bool bold}) {
    final formatted = _formatCurrency(value);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: _C.textSecondary)),
      Text('PKR $formatted',
          style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3)),
    ]);
  }

  // ── Save Button ───────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _saveInvoice,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: _C.primaryBlue.withOpacity(0.5),
        ),
        child: _isGenerating
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white)),
                SizedBox(width: 10),
                Text('Saving…',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ])
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.save_rounded, size: 18),
                SizedBox(width: 8),
                Text('Save Invoice',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(
        width: 3, height: 16,
        decoration: BoxDecoration(
            color: _C.primaryBlue, borderRadius: BorderRadius.circular(2)),
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
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _C.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _C.textSecondary),
        filled: true,
        fillColor: _C.lightGray,
        prefixIcon: Icon(icon, size: 20, color: _C.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.borderGray)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.borderGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.errorRed)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
                    'JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${date.day.toString().padLeft(2, '0')}-'
        '${months[date.month - 1]}-${date.year}';
  }

  String _formatCurrency(String value) {
    final n = int.tryParse(value) ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}