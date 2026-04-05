// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ── Shared colour palette (mirrors ContractorDashboard) ─────────────────────
class AppColors {
  static const primaryBlue = Color(0xFF2563EB);
  static const lightBlue = Color(0xFFEFF6FF);
  static const mediumBlue = Color(0xFFBFDBFE);
  static const darkBlue = Color(0xFF1E40AF);
  static const successGreen = Color(0xFF10B981);
  static const lightGreen = Color(0xFFECFDF5);
  static const warningOrange = Color(0xFFF59E0B);
  static const lightOrange = Color(0xFFFEF3C7);
  static const neutralGray = Color(0xFF6B7280);
  static const lightGray = Color(0xFFF9FAFB);
  static const borderGray = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const unpaidRed = Color(0xFFEF4444);
}

class SupervisorListScreen extends StatefulWidget {
  const SupervisorListScreen({super.key});

  @override
  State<SupervisorListScreen> createState() => _SupervisorListScreenState();
}

class _SupervisorListScreenState extends State<SupervisorListScreen> {
  List<Map<String, dynamic>> supervisors = [];
  List<String> supervisorIds = [];
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = true;
  String? firmId;
  bool _isAdding = false;
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadSupervisors();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> loadSupervisors() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      firmId = userDoc.data()?['assignedFirmId'];

      final snapshot = await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .orderBy('name')
          .get();

      setState(() {
        supervisors = snapshot.docs.map((e) => e.data()).toList();
        supervisorIds = snapshot.docs.map((e) => e.id).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) _showSnack("Error loading supervisors: $e", isError: true);
    }
  }

  Future<void> addSupervisorByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack("Please enter an email address", isWarning: true);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnack("Please enter a valid email address", isWarning: true);
      return;
    }

    setState(() => _isAdding = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'supervisor')
          .get();

      if (query.docs.isEmpty) {
        if (mounted) _showSnack("No supervisor found with this email.", isError: true);
        return;
      }

      final user = query.docs.first;
      final uid = user.id;
      final name = user['name'] ?? email.split('@').first;

      if (supervisorIds.contains(uid)) {
        if (mounted) _showSnack("This supervisor is already added.", isWarning: true);
        return;
      }

      await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .doc(uid)
          .set({
        'email': email,
        'name': name,
        'addedAt': Timestamp.now(),
        'addedBy': FirebaseAuth.instance.currentUser!.uid,
      });

      _emailController.clear();
      await loadSupervisors();
      if (mounted) _showSnack("Supervisor added successfully!");
    } catch (e) {
      if (mounted) _showSnack("Failed to add supervisor: $e", isError: true);
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> deleteSupervisor(
      String supervisorId, String supervisorEmail) async {
    final confirmed = await _showDeleteDialog(supervisorEmail);
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .doc(supervisorId)
          .delete();

      final projectSnap = await FirebaseFirestore.instance
          .collection('projects')
          .where('firmId', isEqualTo: firmId)
          .where('supervisorEmail', isEqualTo: supervisorEmail)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in projectSnap.docs) {
        batch.update(doc.reference, {
          'supervisorEmail': null,
          'supervisorId': null,
        });
      }
      await batch.commit();

      await loadSupervisors();
      if (mounted) _showSnack("Supervisor removed successfully.");
    } catch (e) {
      if (mounted) _showSnack("Failed to remove supervisor: $e", isError: true);
    }
  }

  // ── Dialogs & snackbars ───────────────────────────────────────────────────

  /// Delete confirmation – mirrors ContractorDashboard's logout dialog style.
  Future<bool?> _showDeleteDialog(String supervisorEmail) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: AppColors.unpaidRed, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                "Remove Supervisor",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                "This will remove the supervisor from your firm and unlink them from all assigned projects.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.borderGray),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.unpaidRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Remove",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message,
      {bool isError = false, bool isWarning = false}) {
    final color = isError
        ? AppColors.unpaidRed
        : isWarning
            ? AppColors.warningOrange
            : AppColors.successGreen;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ── AppBar – same style as ContractorDashboard ──
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title block
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Site Supervisors",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                  // Refresh
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: loadSupervisors,
                      tooltip: "Refresh",
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue, strokeWidth: 3))
          : Column(
              children: [
                // ── Add Supervisor card ──
                _buildAddSupervisorCard(),

                // ── Section header ──
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: _buildSectionHeader(
                    "Added Supervisors",
                    supervisors.isEmpty
                        ? "No supervisors yet"
                        : "${supervisors.length} supervisor${supervisors.length > 1 ? 's' : ''}",
                    icon: Icons.engineering_rounded,
                    iconColor: AppColors.primaryBlue,
                    trailing: supervisors.isNotEmpty
                        ? _chip(
                            label: "${supervisors.length}",
                            bgColor: AppColors.lightBlue,
                            textColor: AppColors.primaryBlue,
                            icon: Icons.person_rounded,
                          )
                        : null,
                  ),
                ),

                // ── List ──
                Expanded(
                  child: supervisors.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: loadSupervisors,
                          color: AppColors.primaryBlue,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            itemCount: supervisors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildSupervisorCard(index),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // ── Add Supervisor card ───────────────────────────────────────────────────

  Widget _buildAddSupervisorCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          _buildSectionHeader(
            "Add Supervisor",
            "Search by registered email",
            icon: Icons.person_add_alt_1_rounded,
            iconColor: AppColors.primaryBlue,
          ),
          const SizedBox(height: 16),

          // Input + button row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: "supervisor@email.com",
                      hintStyle: TextStyle(
                          fontSize: 14, color: AppColors.textTertiary),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 18, color: AppColors.textSecondary),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => addSupervisorByEmail(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : addSupervisorByEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primaryBlue.withOpacity(0.6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_rounded, size: 18),
                          SizedBox(width: 6),
                          Text("Add",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info hint – matches ContractorDashboard's info strip style
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.mediumBlue),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Supervisor must have an existing account with 'supervisor' role.",
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Supervisor card ───────────────────────────────────────────────────────

  Widget _buildSupervisorCard(int index) {
    final sup = supervisors[index];
    final supId = supervisorIds[index];
    final email = sup['email'] ?? '';
    final name = sup['name'] ?? email.split('@').first;
    final addedAt = sup['addedAt'] != null
        ? (sup['addedAt'] as Timestamp).toDate()
        : null;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray, width: 1.5),
      ),
      child: Row(
        children: [
          // Avatar – same circle style as ContractorDashboard's firm icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mediumBlue),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (addedAt != null) ...[
                  const SizedBox(height: 6),
                  _chip(
                    label: "Added ${_formatDate(addedAt)}",
                    bgColor: AppColors.lightGray,
                    textColor: AppColors.textTertiary,
                    icon: Icons.calendar_today_rounded,
                    borderColor: AppColors.borderGray,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          GestureDetector(
            onTap: () => deleteSupervisor(supId, email),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(Icons.person_remove_rounded,
                  size: 18, color: AppColors.unpaidRed),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state – mirrors ContractorDashboard's empty state ──────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                  color: AppColors.lightGray, shape: BoxShape.circle),
              child: const Icon(Icons.engineering_rounded,
                  size: 56, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Supervisors Yet",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              "Add supervisors using their registered\nemail addresses above.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _emailFocusNode.requestFocus(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text("Add First Supervisor",
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers (match ContractorDashboard helpers exactly) ────────────

  /// Identical signature & look to ContractorDashboard's `_buildSectionHeader`.
  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Identical to ContractorDashboard's `_chip` helper.
  Widget _chip({
    required String label,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(7),
          border: borderColor != null
              ? Border.all(color: borderColor)
              : null),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: textColor),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor)),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return "today";
    if (diff.inDays == 1) return "yesterday";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return "${w}w ago";
    }
    return "${date.day}/${date.month}/${date.year}";
  }
}