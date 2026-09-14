import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_site_pro_app/screens/auth/login_screen.dart';
import 'package:track_site_pro_app/screens/profileManagementScreen/ProfileManagementScreen.dart';
import 'package:track_site_pro_app/screens/supervisors/supervisor_list_screen.dart';
import 'package:track_site_pro_app/screens/switch_firm/switch_firm_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class AppColors {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const darkBlue      = Color(0xFF1E40AF);
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool   notificationsEnabled = true;
  String? currentFirmName;
  String? userName;
  String? userEmail;
  List<Map<String, String>> allFirms = []; // {id, name}
  bool   isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid     = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data    = userDoc.data();
      final firmId  = data?['assignedFirmId'] as String?;

      String? firmName;
      if (firmId != null && firmId.isNotEmpty) {
        final fd = await FirebaseFirestore.instance.collection('firms').doc(firmId).get();
        firmName = fd.data()?['firmName'] as String? ?? 'Unknown';
      }

      final snap = await FirebaseFirestore.instance
          .collection('firms').where('ownerId', isEqualTo: uid).get();

      setState(() {
        userName        = data?['name'] as String? ?? 'User';
        userEmail       = FirebaseAuth.instance.currentUser?.email ?? '—';
        currentFirmName = firmName ?? 'No Firm Assigned';
        allFirms        = snap.docs.map((d) => {
          'id':   d.id,
          'name': (d.data()['firmName'] as String? ?? 'Unnamed'),
        }).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        userName        = 'User';
        userEmail       = FirebaseAuth.instance.currentUser?.email ?? '—';
        currentFirmName = 'Error loading';
        allFirms        = [];
        isLoading       = false;
      });
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: AppColors.lightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(height: 18),
            const Text('Logout Confirmation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 10),
            const Text('Are you sure you want to sign out?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppColors.borderGray),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Logout',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false);
      }
    }
  }

  // ── Snack ─────────────────────────────────────────────────────────────────

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

  // ── Info dialogs ──────────────────────────────────────────────────────────

  void _showInfoDialog({
    required IconData icon,
    required String title,
    required List<_InfoSection> sections,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary))),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderGray),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (s.heading != null) ...[
                        Text(s.heading!,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                      ],
                      Text(s.body,
                          style: const TextStyle(fontSize: 13,
                              color: AppColors.textSecondary, height: 1.5)),
                    ]),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

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
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.5)),
            Text('Manage your account & preferences',
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Profile card ──
          _buildProfileCard(),
          const SizedBox(height: 24),

          // ── Account ──
          _sectionLabel('Account'),
          const SizedBox(height: 10),
          _buildCard(children: [
            _rowItem(
              icon: Icons.person_outline_rounded,
              iconBg: AppColors.lightBlue, iconColor: AppColors.primaryBlue,
              title: 'Profile Management',
              subtitle: 'Update your personal information',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileManagementScreen())),
            ),
            _divider(),
            _rowItem(
              icon: Icons.supervisor_account_outlined,
              iconBg: const Color(0xFFF5F3FF), iconColor: const Color(0xFF7C3AED),
              title: 'Supervisors',
              subtitle: 'Manage your site supervisors',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupervisorListScreen())),
            ),
            _divider(),
            _rowItem(
              icon: Icons.business_rounded,
              iconBg: AppColors.lightOrange, iconColor: AppColors.warningOrange,
              title: 'Switch Firm',
              subtitle: 'Change your active construction firm',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SwitchFirmScreen())),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Preferences ──
          _sectionLabel('Preferences'),
          const SizedBox(height: 10),
          _buildCard(children: [
            _switchItem(
              icon: Icons.notifications_outlined,
              iconBg: AppColors.lightGreen, iconColor: AppColors.successGreen,
              title: 'Notifications',
              subtitle: 'Receive alerts and expiry reminders',
              value: notificationsEnabled,
              onChanged: (v) => setState(() => notificationsEnabled = v),
            ),
            _divider(),
            _switchItem(
              icon: Icons.dark_mode_outlined,
              iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF4F46E5),
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark themes',
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) => _snack('Theme switching requires app-level setup'),
            ),
          ]),
          const SizedBox(height: 24),

          // ── App Info ──
          _sectionLabel('App Information'),
          const SizedBox(height: 10),
          _buildCard(children: [
            _rowItem(
              icon: Icons.info_outline_rounded,
              iconBg: AppColors.lightGray, iconColor: AppColors.textSecondary,
              title: 'About App',
              subtitle: 'TrackSitePro v1.0.0',
              onTap: () => _showInfoDialog(
                icon: Icons.info_outline_rounded,
                title: 'About TrackSitePro',
                sections: [
                  _InfoSection(null, 'TrackSitePro is a comprehensive construction management app designed for SNGPL contractors to track projects, documents, and daily progress reports.'),
                  _InfoSection('Version', '1.0.0  ·  Build 2024.01'),
                  _InfoSection(null, '© 2024 TrackSitePro. All rights reserved.'),
                ],
              ),
            ),
            _divider(),
            _rowItem(
              icon: Icons.privacy_tip_outlined,
              iconBg: AppColors.lightGray, iconColor: AppColors.textSecondary,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => _showInfoDialog(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                sections: [
                  _InfoSection('1. Data Collection', 'We collect project details, document uploads, and progress reports to facilitate construction management.'),
                  _InfoSection('2. Data Usage', 'Your data is used solely for construction project management. We do not share it with third parties without consent.'),
                  _InfoSection('3. Data Security', 'Industry-standard security measures protect your data and documents.'),
                  _InfoSection('4. Contact', 'For privacy concerns: privacy@tracksitepro.com'),
                ],
              ),
            ),
            _divider(),
            _rowItem(
              icon: Icons.description_outlined,
              iconBg: AppColors.lightGray, iconColor: AppColors.textSecondary,
              title: 'Terms of Service',
              subtitle: 'SNGPL contractor agreement',
              onTap: () => _showInfoDialog(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                sections: [
                  _InfoSection('1. Acceptance', 'By using TrackSitePro, you agree to these terms as an SNGPL contractor.'),
                  _InfoSection('2. Responsibilities', 'Contractors must maintain accurate project data and ensure compliance with construction regulations.'),
                  _InfoSection('3. Liability', 'TrackSitePro is provided without warranty. Contractors are responsible for data accuracy.'),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Logout ──
          GestureDetector(
            onTap: _logout,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.expiredRed.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.expiredRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.logout_rounded,
                      size: 20, color: AppColors.expiredRed),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Logout',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.expiredRed)),
                    SizedBox(height: 2),
                    Text('Sign out from your account',
                        style: TextStyle(fontSize: 12,
                            color: AppColors.textSecondary)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textTertiary),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mediumBlue),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.lightBlue, shape: BoxShape.circle,
              border: Border.all(color: AppColors.mediumBlue, width: 2),
            ),
            child: const Icon(Icons.person_rounded,
                size: 26, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              isLoading
                  ? _shimmer(width: 120, height: 16)
                  : Text(userName ?? 'User',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              isLoading
                  ? _shimmer(width: 160, height: 12)
                  : Text(userEmail ?? '—',
                      style: const TextStyle(fontSize: 12,
                          color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),

        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.borderGray),
        const SizedBox(height: 14),

        // Current firm
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.business_rounded,
                size: 14, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isLoading
                ? _shimmer(width: 140, height: 12)
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Active Firm',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary)),
                    Text(currentFirmName ?? 'No Firm Assigned',
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
          ),
        ]),

        // Firm chips
        if (!isLoading && allFirms.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6,
            children: allFirms.map((f) {
              final isCurrent = f['name'] == currentFirmName;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.lightBlue : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isCurrent ? AppColors.mediumBlue : AppColors.borderGray),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isCurrent) ...[
                    const Icon(Icons.check_circle_rounded,
                        size: 10, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                  ],
                  Text(f['name']!,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary)),
                ]),
              );
            }).toList(),
          ),
        ],

        if (!isLoading && allFirms.isEmpty) ...[
          const SizedBox(height: 10),
          const Text('No firms registered yet',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }

  // ── Reusable card shell ───────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _rowItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textTertiary),
        ]),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Transform.scale(
          scale: 0.85,
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ),
      ]),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 68, color: AppColors.borderGray);

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.3));

  Widget _shimmer({required double width, required double height}) =>
      Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: AppColors.borderGray,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

// ── Helper data class ─────────────────────────────────────────────────────────
class _InfoSection {
  final String? heading;
  final String  body;
  const _InfoSection(this.heading, this.body);
}