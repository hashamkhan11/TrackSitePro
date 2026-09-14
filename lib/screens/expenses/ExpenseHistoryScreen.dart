import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_site_pro_app/screens/expenses/AddExpenseScreen.dart';
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

class ExpenseHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ExpenseHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  final _expenseRepo = ExpenseRepository();

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), shape: BoxShape.circle),
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
              'Are you sure you want to delete this expense? This action cannot be undone.',
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
                      side:
                          const BorderSide(color: AppColors.borderGray),
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

    if (confirmed != true) return;

    try {
      await _expenseRepo.deleteExpense(widget.projectId, expenseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Expense deleted',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
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

  // ── Edit ───────────────────────────────────────────────────────────────────
  Future<void> _editExpense(
      String expenseId, Map<String, dynamic> data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          projectId: widget.projectId,
          projectTitle: widget.projectTitle,
          expenseId: expenseId,
          initialData: data,
        ),
      ),
    );
  }

  // ── Expense card ───────────────────────────────────────────────────────────
  Widget _buildExpenseCard(DocumentSnapshot exp) {
    final data = exp.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0).toDouble();
    final description = data['description'] ?? 'No description';
    final date = (data['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    final submittedBy =
        (data['submittedBy']?.toString() ?? 'Unknown').split('@')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          // Leading icon
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.primaryBlue, size: 20),
          ),
          // Description
          title: Text(
            description,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(formattedDate,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          // Amount
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${_fmt(amount)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 2),
              Text(
                'by $submittedBy',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Expanded details
          children: [
            Container(
              margin:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _detailRow(
                    icon: Icons.description_rounded,
                    label: 'Description',
                    value: description),
                const SizedBox(height: 10),
                _detailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: formattedDate),
                const SizedBox(height: 10),
                _detailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: formattedTime),
                const SizedBox(height: 10),
                _detailRow(
                    icon: Icons.person_rounded,
                    label: 'Submitted by',
                    value: submittedBy),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.borderGray),
                ),
                // Actions row
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _deleteExpense(exp.id),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: AppColors.unpaidRed,
                          side: const BorderSide(
                              color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_rounded, size: 15),
                            SizedBox(width: 5),
                            Text('Delete',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _editExpense(exp.id, data),
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_rounded, size: 15),
                            SizedBox(width: 5),
                            Text('Edit',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
      {required IconData icon,
      required String label,
      required String value}) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.textTertiary),
      const SizedBox(width: 8),
      Text('$label: ',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  // ── Summary header ─────────────────────────────────────────────────────────
  Widget _buildSummaryHeader(
      {required int count, required double total}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(children: [
        Expanded(
          child: _summaryCell(
            label: 'Total Expenses',
            value: 'PKR ${_fmt(total)}',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primaryBlue,
            bgColor: AppColors.lightBlue,
          ),
        ),
        Container(
          width: 1,
          height: 48,
          color: AppColors.borderGray,
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        Expanded(
          child: _summaryCell(
            label: 'Entries',
            value: '$count expense${count != 1 ? 's' : ''}',
            icon: Icons.receipt_long_rounded,
            color: AppColors.warningOrange,
            bgColor: const Color(0xFFFFFBEB),
          ),
        ),
      ]),
    );
  }

  Widget _summaryCell({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]);
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
                color: AppColors.lightGray, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded,
                size: 46, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          const Text('No Expenses Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          const Text('Tap the button below to record your first expense.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5)),
        ]),
      ),
    );
  }

  /// Formats a number with comma separators and no abbreviations.
  /// e.g. 1500000 → "1,500,000"   |   2450.5 → "2,451"
  String _fmt(double amount) {
    if (amount == amount.truncateToDouble()) {
      return _addCommas(amount.toInt().toString());
    }
    final formatted = amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    final parts = formatted.split('.');
    return '${_addCommas(parts[0])}${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  String _addCommas(String intStr) {
    final buffer = StringBuffer();
    final n = intStr.length;
    for (int i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buffer.write(',');
      buffer.write(intStr[i]);
    }
    return buffer.toString();
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
                    'Expenses',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _expenseRepo.streamExpenses(widget.projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryBlue, strokeWidth: 3));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(
                        color: AppColors.unpaidRed)));
          }

          final expenses = snapshot.data!.docs;

          if (expenses.isEmpty) {
            return _buildEmptyState();
          }

          double total = 0;
          for (var e in expenses) {
            total += ((e.data() as Map<String, dynamic>)['amount'] ?? 0)
                .toDouble();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Summary header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                  child:
                      _buildSummaryHeader(count: expenses.length, total: total),
                ),
              ),

              // Section label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: AppColors.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 15, color: AppColors.warningOrange),
                    ),
                    const SizedBox(width: 10),
                    const Text('All Expenses',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4)),
                  ]),
                ),
              ),

              // List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildExpenseCard(expenses[index]),
                    childCount: expenses.length,
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                projectId: widget.projectId,
                projectTitle: widget.projectTitle,
              ),
            ),
          ),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Expense',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}