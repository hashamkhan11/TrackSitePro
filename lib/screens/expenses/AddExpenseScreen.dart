// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/expense_repository.dart';

// ── Shared colour palette ────────────────────────────────────────────────────
class AppColors {
  static const primaryBlue = Color(0xFF2563EB);
  static const lightBlue = Color(0xFFEFF6FF);
  static const mediumBlue = Color(0xFFBFDBFE);
  static const successGreen = Color(0xFF10B981);
  static const lightGreen = Color(0xFFECFDF5);
  static const warningOrange = Color(0xFFF59E0B);
  static const lightGray = Color(0xFFF9FAFB);
  static const borderGray = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const unpaidRed = Color(0xFFEF4444);
}

class AddExpenseScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String? expenseId;
  final Map<String, dynamic>? initialData;

  const AddExpenseScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    this.expenseId,
    this.initialData,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _expenseRepo = ExpenseRepository();
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  String _formattedAmount = '';
  String _amountInWords = '';

  bool get _isEditMode =>
      widget.expenseId != null && widget.initialData != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _descController.text = widget.initialData!['description'] ?? '';
      final amount = (widget.initialData!['amount'] ?? 0).toDouble();
      _amountController.text = amount.toStringAsFixed(2);
      _selectedDate =
          (widget.initialData!['date'] as Timestamp).toDate();
      _formatAmount(amount.toStringAsFixed(2));
    }
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ── Amount formatting ──────────────────────────────────────────────────────
  void _onAmountChanged() {
    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() {
        _formattedAmount = '';
        _amountInWords = '';
      });
      return;
    }
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(clean) ?? 0.0;
    _formatAmount(amount.toStringAsFixed(2));
    if (text != clean) {
      _amountController.value = TextEditingValue(
          text: clean,
          selection: TextSelection.collapsed(offset: clean.length));
    }
  }

  void _formatAmount(String amountStr) {
    final amount = double.tryParse(amountStr) ?? 0.0;
    final parts = amountStr.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      formatted = integerPart[i] + formatted;
      count++;
      if (count == 3 && i > 0) {
        formatted = ',$formatted';
        count = 0;
      }
    }
    setState(() {
      _formattedAmount = '$formatted.$decimalPart';
      _amountInWords = _convertToWords(amount);
    });
  }

  String _convertToWords(double amount) {
    if (amount == 0) return 'Zero';
    final rupees = amount.floor();
    final paisa = ((amount - rupees) * 100).round();
    String result =
        '${_convertNumberToWords(rupees)} Rupee${rupees == 1 ? '' : 's'}';
    if (paisa > 0) {
      result +=
          ' and ${_convertNumberToWords(paisa)} Paisa${paisa == 1 ? '' : 's'}';
    }
    return '$result Only';
  }

  String _convertNumberToWords(int number) {
    if (number == 0) return 'Zero';
    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'
    ];
    const teens = [
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];
    String words = '';
    if (number >= 10000000) {
      words += '${_convertNumberToWords(number ~/ 10000000)} Crore ';
      number %= 10000000;
    }
    if (number >= 100000) {
      words += '${_convertNumberToWords(number ~/ 100000)} Lakh ';
      number %= 100000;
    }
    if (number >= 1000) {
      words += '${_convertNumberToWords(number ~/ 1000)} Thousand ';
      number %= 1000;
    }
    if (number >= 100) {
      words += '${_convertNumberToWords(number ~/ 100)} Hundred ';
      number %= 100;
    }
    if (number > 0) {
      if (words.isNotEmpty) words += 'and ';
      if (number < 10) {
        words += units[number];
      } else if (number < 20) {
        words += teens[number - 10];
      } else {
        words += tens[number ~/ 10];
        if (number % 10 > 0) words += ' ${units[number % 10]}';
      }
    }
    return words.trim();
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final amount =
          double.tryParse(_amountController.text) ?? 0.0;
      final data = {
        'description': _descController.text.trim(),
        'amount': amount,
        'date': Timestamp.fromDate(_selectedDate),
        'submittedBy': user.email,
        'submittedAt': FieldValue.serverTimestamp(),
        'createdAt': (_isEditMode && widget.initialData != null)
            ? (widget.initialData!['createdAt'] as Timestamp?) ?? Timestamp.now()
            : Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      if (_isEditMode) {
        await _expenseRepo.updateExpense(
            widget.projectId, widget.expenseId!, data);
      } else {
        await _expenseRepo.addExpense(widget.projectId, data);
      }
      _updateProjectTotalExpenses();
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.unpaidRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── Delete (edit mode action) ──────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.unpaidRed, size: 30),
            ),
            const SizedBox(height: 20),
            const Text('Delete Expense',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to delete this expense? This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.unpaidRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Delete',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context, 'deleted');
  }

  Future<void> _updateProjectTotalExpenses() async {
    try {
      await _expenseRepo.recomputeTotalExpenses(widget.projectId);
    } catch (_) {}
  }

  // ── Field builder ──────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? AppColors.textTertiary : AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon,
              size: 18,
              color: readOnly
                  ? AppColors.textTertiary
                  : AppColors.primaryBlue),
          suffixIcon: suffix,
          filled: true,
          fillColor: readOnly ? AppColors.lightGray : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.borderGray)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primaryBlue, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.unpaidRed)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.unpaidRed, width: 1.5)),
        ),
      ),
    ]);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      // ── AppBar ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: AppColors.borderGray, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isEditMode ? 'Edit Expense' : 'Add Expense',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5),
                  ),
                ),
                // Delete button (edit mode)
                if (_isEditMode)
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete_rounded,
                          size: 18, color: AppColors.unpaidRed),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Form card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Column(children: [
                  // Section title
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 16, color: AppColors.warningOrange),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditMode
                          ? 'Update Expense Details'
                          : 'Expense Details',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Description
                  _buildField(
                    controller: _descController,
                    label: 'Description *',
                    icon: Icons.description_rounded,
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Description is required'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Amount
                  _buildField(
                    controller: _amountController,
                    label: 'Amount (PKR) *',
                    icon: Icons.payments_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount is required';
                      final a = double.tryParse(v);
                      if (a == null || a <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),

                  // Formatted amount display
                  if (_formattedAmount.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.mediumBlue)),
                      child: Row(children: [
                        const Icon(Icons.info_rounded,
                            size: 14, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PKR $_formattedAmount',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue),
                              ),
                              if (_amountInWords.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _amountInWords,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Date
                  _buildField(
                    controller: TextEditingController(
                        text:
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    label: 'Date',
                    icon: Icons.calendar_today_rounded,
                    readOnly: true,
                    onTap: _pickDate,
                    suffix: IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded,
                          size: 18, color: AppColors.primaryBlue),
                      onPressed: _pickDate,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Save button ──
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBlue, strokeWidth: 3))
                  : ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _isEditMode
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isEditMode
                                ? 'Update Expense'
                                : 'Save Expense',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: 12),

              // Cancel
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderGray),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}