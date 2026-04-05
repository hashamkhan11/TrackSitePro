import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Shared color palette (must match the rest of the app) ───────────────────
class _C {
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
  static const fullyPaidGreen = Color(0xFF10B981);
}

// ── Screen ───────────────────────────────────────────────────────────────────
class CompletedProjectsScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> projects;
  const CompletedProjectsScreen({super.key, required this.projects});

  @override
  State<CompletedProjectsScreen> createState() =>
      _CompletedProjectsScreenState();
}

class _CompletedProjectsScreenState extends State<CompletedProjectsScreen> {
  final Map<String, _Financials> _cache = {};
  bool _isLoadingAll = true;

  @override
  void initState() {
    super.initState();
    _loadAllFinancials();
  }

  Future<void> _loadAllFinancials() async {
    await Future.wait(widget.projects.map((doc) => _fetchFinancials(doc.id)));
    if (mounted) setState(() => _isLoadingAll = false);
  }

  Future<void> _fetchFinancials(String projectId) async {
    if (_cache.containsKey(projectId)) return;
    try {
      final ref = FirebaseFirestore.instance.collection('projects').doc(projectId);
      final results = await Future.wait([
        ref.collection('payments').get(),
        ref.collection('expenses').get(),
      ]);
      double totalPaid = 0;
      for (var p in results[0].docs) {
        totalPaid += ((p.data())['amount'] ?? 0).toDouble();
      }
      double totalExpenses = 0;
      for (var e in results[1].docs) {
        totalExpenses += ((e.data())['amount'] ?? 0).toDouble();
      }
      _cache[projectId] = _Financials(totalPaid: totalPaid, totalExpenses: totalExpenses);
    } catch (_) {
      _cache[projectId] = const _Financials(totalPaid: 0, totalExpenses: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(context),
      body: _isLoadingAll
          ? const Center(child: CircularProgressIndicator(
              color: _C.primaryBlue, strokeWidth: 2.5))
          : widget.projects.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Use kToolbarHeight (56) as the content height — Scaffold automatically
    // adds the status-bar padding on top, so we must NOT wrap in SafeArea.
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _C.borderGray, width: 1)),
        ),
        // ⚠️  No SafeArea here — Scaffold already insets the AppBar for the
        //     status bar.  Wrapping in SafeArea added an extra top-padding
        //     that pushed content down and caused the 2 px bottom overflow.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _C.lightGray, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20,
                    color: _C.textSecondary),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "Completed & Paid",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _C.lightGreen, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, size: 13, color: _C.fullyPaidGreen),
                const SizedBox(width: 5),
                Text("${widget.projects.length} Settled",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: _C.fullyPaidGreen)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList() {
    double totalReceived = 0, totalExpenses = 0;
    for (var doc in widget.projects) {
      final f = _cache[doc.id];
      if (f != null) {
        totalReceived += f.totalPaid;
        totalExpenses += f.totalExpenses;
      }
    }
    final netProfit = totalReceived - totalExpenses;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSummaryBanner(totalReceived, totalExpenses, netProfit),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = widget.projects[index];
                final f = _cache[doc.id] ??
                    const _Financials(totalPaid: 0, totalExpenses: 0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildProjectCard(doc, f, index + 1),
                );
              },
              childCount: widget.projects.length,
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary Banner ────────────────────────────────────────────────────────
  Widget _buildSummaryBanner(double totalReceived, double totalExpenses, double net) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Portfolio Summary",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Colors.white70, letterSpacing: 0.3)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _summaryItem("Total Received",
              "PKR ${_fmt(totalReceived)}", Colors.white, Colors.white70)),
          _vDivider(),
          Expanded(child: _summaryItem("Total Expenses",
              "PKR ${_fmt(totalExpenses)}", Colors.white, Colors.white70)),
          _vDivider(),
          Expanded(child: _summaryItem(
            net >= 0 ? "Net Profit" : "Net Loss",
            "PKR ${_fmt(net.abs())}",
            net >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
            Colors.white70,
          )),
        ]),
      ]),
    );
  }

  Widget _summaryItem(String label, String value, Color valueColor, Color labelColor) {
    return Column(children: [
      Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: valueColor, letterSpacing: -0.3),
          textAlign: TextAlign.center, maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(fontSize: 10, color: labelColor),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _vDivider() => Container(
      width: 1, height: 36,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── Project Card ──────────────────────────────────────────────────────────
  Widget _buildProjectCard(QueryDocumentSnapshot doc, _Financials f, int position) {
    final data          = doc.data() as Map<String, dynamic>;
    final workOrderNo   = (data['workOrderNo']    ?? '').toString();
    final jobNo         = (data['jobNo']           ?? '').toString();
    final jobDescription = (data['jobDescription'] ?? '').toString();
    final location      = (data['location']        ?? '').toString();
    final contractValue = ((data['totalAmount']    ?? 0) as num).toDouble();
    final completedAt   = data['completedAt'] != null
        ? (data['completedAt'] as Timestamp).toDate() : null;
    final net      = f.totalPaid - f.totalExpenses;
    final isProfit = net >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card Header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(
            color: _C.lightGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: _C.borderGray)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Row 1: position badge  ←  spacer  →  "Paid" badge
            // Both are fixed-size — no Expanded competing here.
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: _C.primaryBlue, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text(position.toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: _C.lightGreen, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: _C.fullyPaidGreen),
                  SizedBox(width: 4),
                  Text("Paid", style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: _C.fullyPaidGreen)),
                ]),
              ),
            ]),

            // Row 2: chips — own row so they have full width and never overflow
            if (workOrderNo.isNotEmpty || jobNo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 7, runSpacing: 6, children: [
                if (workOrderNo.isNotEmpty)
                  _chip(label: "WO: $workOrderNo", bgColor: _C.lightBlue,
                      textColor: _C.primaryBlue, icon: Icons.assignment_rounded),
                if (jobNo.isNotEmpty)
                  _chip(label: "Job #$jobNo", bgColor: Colors.white,
                      textColor: _C.textSecondary, icon: Icons.tag_rounded,
                      borderColor: _C.borderGray),
              ]),
            ],
          ]),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (jobDescription.isNotEmpty) ...[
              Text(jobDescription,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: _C.textPrimary, height: 1.45),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
            ],

            // Location + date
            Row(children: [
              if (location.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined, size: 13, color: _C.textTertiary),
                const SizedBox(width: 4),
                Expanded(child: Text(location,
                    style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ] else
                const Spacer(),
              if (completedAt != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_rounded, size: 12, color: _C.textTertiary),
                  const SizedBox(width: 4),
                  Text("${completedAt.day}/${completedAt.month}/${completedAt.year}",
                      style: const TextStyle(fontSize: 11, color: _C.textSecondary,
                          fontWeight: FontWeight.w500)),
                ]),
            ]),

            const SizedBox(height: 14),

            // Financials block
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _C.lightGray, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.borderGray)),
              child: Column(children: [
                _finRow(icon: Icons.account_balance_wallet_outlined,
                    iconColor: _C.primaryBlue, label: "Contract Value",
                    value: "PKR ${_fmt(contractValue)}", valueColor: _C.primaryBlue),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: _C.borderGray)),
                _finRow(icon: Icons.payments_rounded, iconColor: _C.successGreen,
                    label: "Total Received", value: "PKR ${_fmt(f.totalPaid)}",
                    valueColor: _C.successGreen),
                const SizedBox(height: 8),
                _finRow(icon: Icons.receipt_long_rounded, iconColor: _C.warningOrange,
                    label: "Total Expenses", value: "PKR ${_fmt(f.totalExpenses)}",
                    valueColor: _C.warningOrange),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: _C.borderGray)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: isProfit ? _C.lightGreen : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: isProfit ? _C.successGreen : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(isProfit ? "Net Profit" : "Net Loss",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: _C.textPrimary)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text("PKR ${_fmt(net.abs())}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isProfit ? _C.successGreen : Colors.red,
                            letterSpacing: -0.3)),
                    if (f.totalPaid > 0)
                      Text(
                        isProfit
                            ? "+${(net / f.totalPaid * 100).toStringAsFixed(1)}%"
                            : "-${(net.abs() / f.totalPaid * 100).toStringAsFixed(1)}%",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: isProfit ? _C.successGreen : Colors.red),
                      ),
                  ]),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: _C.lightGray, shape: BoxShape.circle),
            child: const Icon(Icons.folder_open_rounded, size: 48, color: _C.textTertiary),
          ),
          const SizedBox(height: 20),
          const Text("No Completed Projects",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: _C.textPrimary, letterSpacing: -0.4)),
          const SizedBox(height: 10),
          const Text("Fully paid projects will appear here",
              style: TextStyle(fontSize: 14, color: _C.textSecondary)),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _finRow({
    required IconData icon, required Color iconColor,
    required String label, required String value, required Color valueColor,
  }) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 12, color: _C.textSecondary,
            fontWeight: FontWeight.w500)),
      ]),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: valueColor)),
    ]);
  }

  Widget _chip({
    required String label, required Color bgColor,
    required Color textColor, required IconData icon, Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(7),
          border: borderColor != null ? Border.all(color: borderColor) : null),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: textColor),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: textColor)),
      ]),
    );
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return "${(amount / 1000000).toStringAsFixed(2)}M";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(1)}K";
    return amount.toStringAsFixed(0);
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _Financials {
  final double totalPaid;
  final double totalExpenses;
  const _Financials({required this.totalPaid, required this.totalExpenses});
}