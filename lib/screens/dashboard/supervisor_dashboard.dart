import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/auth/login_screen.dart';
import 'package:track_site_pro_app/screens/dpr/upload_dpr_screen.dart';
import 'package:track_site_pro_app/screens/dpr/dpr_history_screen.dart';
import 'package:track_site_pro_app/screens/expenses/AddExpenseScreen.dart';
import 'package:track_site_pro_app/screens/expenses/ExpenseHistoryScreen.dart';
import 'package:track_site_pro_app/screens/profileManagementScreen/ProfileManagementScreen.dart';

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

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Logout – identical dialog to ContractorDashboard ─────────────────────
  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: AppColors.lightBlue, shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.primaryBlue, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                "Logout Confirmation",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to logout from your account?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(
                            color: AppColors.borderGray),
                        foregroundColor: AppColors.textSecondary),
                    child: const Text("Cancel",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12))),
                    child: const Text("Logout",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ── AppBar – same pattern as ContractorDashboard ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom:
                    BorderSide(color: AppColors.borderGray, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(children: [
                // Dot + title
                Expanded(
                  child: Row(children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      _currentIndex == 0
                          ? "Dashboard"
                          : "My Projects",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5),
                    ),
                  ]),
                ),
                // Profile button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.person_rounded, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ProfileManagementScreen()),
                    ),
                    tooltip: 'Profile',
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                // Logout button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon:
                        const Icon(Icons.logout_rounded, size: 20),
                    onPressed: _logout,
                    tooltip: 'Logout',
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      body: _currentIndex == 0
          ? _buildDashboardTab()
          : _buildProjectsTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom nav – same style as ContractorDashboard ────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: AppColors.borderGray, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    0,
                    Icons.home_rounded,
                    Icons.home_outlined,
                    "Home"),
                _buildNavItem(
                    1,
                    Icons.folder_rounded,
                    Icons.folder_outlined,
                    "Projects"),
              ]),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon,
      IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _currentIndex = index;
          if (index == 1) {
            _searchQuery = '';
            _searchController.clear();
          }
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(isActive ? activeIcon : inactiveIcon,
                color: isActive
                    ? AppColors.primaryBlue
                    : AppColors.textTertiary,
                size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isActive
                        ? AppColors.primaryBlue
                        : AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }

  // ── Dashboard tab ─────────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    final email = FirebaseAuth.instance.currentUser?.email;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (email == null) return _buildNoUserState();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('assignedSupervisor', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue, strokeWidth: 3));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildNoProjectsState();

        return RefreshIndicator(
          onRefresh: () async =>
              Future.delayed(Duration.zero),
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              // Welcome header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildWelcomeHeader(uid, docs.length),
                ),
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildStatsRow(docs),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 36, 20, 16),
                  child: _buildSectionHeader(
                    "Assigned Projects",
                    "${docs.length} project${docs.length == 1 ? '' : 's'}",
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: AppColors.primaryBlue,
                  ),
                ),
              ),

              // Project cards (first 3)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: _buildProjectCard(docs[index]),
                    ),
                    childCount:
                        docs.length > 3 ? 3 : docs.length,
                  ),
                ),
              ),

              // View all button
              if (docs.length > 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _currentIndex = 1),
                        style: TextButton.styleFrom(
                            foregroundColor:
                                AppColors.primaryBlue,
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12)),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  "View all ${docs.length} projects",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w600)),
                              const SizedBox(width: 6),
                              const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16),
                            ]),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }

  // ── Welcome header – same style as ContractorDashboard ───────────────────
  Widget _buildWelcomeHeader(String? uid, int projectCount) {
    if (uid == null) {
      return _welcomeText("Supervisor", projectCount);
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snap) {
        String name = 'Supervisor';
        if (snap.hasData && snap.data != null) {
          final data = snap.data!.data() as Map<String, dynamic>?;
          name = (data?['name'] as String?) ?? 'Supervisor';
        }
        return _welcomeText(name.split(' ').first, projectCount);
      },
    );
  }

  Widget _welcomeText(String firstName, int projectCount) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Good ${_timeOfDay()},",
        style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            letterSpacing: 0.2),
      ),
      const SizedBox(height: 4),
      Text(
        firstName,
        style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -1,
            height: 1.2),
      ),
    ]);
  }

  String _timeOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return "Morning";
    if (h < 17) return "Afternoon";
    return "Evening";
  }

  // ── Stats row – same _inlineStatCard pattern ──────────────────────────────
  Widget _buildStatsRow(List<QueryDocumentSnapshot> docs) {
    int active = 0, completed = 0, delayed = 0;
    for (final d in docs) {
      final status = ((d.data() as Map<String, dynamic>)['status']
                  ?.toString() ??
              '')
          .toLowerCase();
      if (status == 'active') active++;
      if (status == 'completed') completed++;
      if (status == 'delayed') delayed++;
    }

    return Row(children: [
      _inlineStatCard(
          label: "Total",
          count: docs.length,
          color: AppColors.primaryBlue,
          bgColor: AppColors.lightBlue,
          borderColor: AppColors.mediumBlue,
          icon: Icons.folder_rounded),
      const SizedBox(width: 8),
      _inlineStatCard(
          label: "Active",
          count: active,
          color: const Color(0xFF2563EB),
          bgColor: AppColors.lightBlue,
          borderColor: AppColors.mediumBlue,
          icon: Icons.play_circle_rounded),
      const SizedBox(width: 8),
      _inlineStatCard(
          label: "Done",
          count: completed,
          color: AppColors.successGreen,
          bgColor: AppColors.lightGreen,
          borderColor: const Color(0xFF6EE7B7),
          icon: Icons.check_circle_rounded),
      const SizedBox(width: 8),
      _inlineStatCard(
          label: "Delayed",
          count: delayed,
          color: AppColors.warningOrange,
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
          icon: Icons.schedule_rounded),
    ]);
  }

  /// Identical to ContractorDashboard's `_inlineStatCard`.
  Widget _inlineStatCard({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: borderColor.withOpacity(0.7)),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 7),
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.75))),
        ]),
      ),
    );
  }

  // ── Projects tab ──────────────────────────────────────────────────────────
  Widget _buildProjectsTab() {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return _buildNoUserState();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('assignedSupervisor', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue, strokeWidth: 3));
        }

        final all = snapshot.data!.docs;
        final filtered = all.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final d = doc.data() as Map<String, dynamic>;
          final q = _searchQuery.toLowerCase();
          return (d['projectTitle'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (d['location'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (d['jobNo'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (d['region'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (d['status'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q);
        }).toList();

        _byStatus(String s) => filtered
            .where((d) =>
                ((d.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase() ??
                        '') ==
                    s)
            .toList();

        final active = _byStatus('active');
        final completed = _byStatus('completed');
        final delayed = _byStatus('delayed');

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          },
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildSearchBar(),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: _buildSectionHeader(
                    "My Projects",
                    "${filtered.length} project${filtered.length == 1 ? '' : 's'}${_searchQuery.isNotEmpty ? ' found' : ''}",
                    icon: Icons.assignment_rounded,
                    iconColor: AppColors.primaryBlue,
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverFillRemaining(
                    child: _buildSearchEmptyState()),

              // Active
              if (active.isNotEmpty)
                ..._statusSection(
                    "Active", active, AppColors.primaryBlue,
                    Icons.play_circle_rounded),

              // Completed
              if (completed.isNotEmpty)
                ..._statusSection(
                    "Completed",
                    completed,
                    AppColors.successGreen,
                    Icons.check_circle_rounded),

              // Delayed
              if (delayed.isNotEmpty)
                ..._statusSection(
                    "Delayed",
                    delayed,
                    AppColors.warningOrange,
                    Icons.schedule_rounded),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _statusSection(String label,
      List<QueryDocumentSnapshot> docs, Color color, IconData icon) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3)),
            const SizedBox(width: 8),
            _chip(
                label: "${docs.length}",
                bgColor: color.withOpacity(0.08),
                textColor: color,
                icon: Icons.circle,
                borderColor: color.withOpacity(0.2)),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProjectCard(docs[index]),
            ),
            childCount: docs.length,
          ),
        ),
      ),
    ];
  }

  // ── Project card – flat white, borderGray border, no shadow ──────────────
  Widget _buildProjectCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['projectTitle'] ?? 'Untitled';
    final jobNo = data['jobNo'] ?? '';
    final workOrderNo = data['workOrderNo'] ?? '';
    final location = data['location'] ?? '';
    final region = data['region'] ?? '';
    final progress =
        ((data['progress'] ?? 0) as num).toDouble();
    final status =
        data['status']?.toString() ?? 'Active';

    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final statusBorder = _statusBorder(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.borderGray, width: 1.5),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: title + status badge ──
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius:
                            BorderRadius.circular(8),
                        border:
                            Border.all(color: statusBorder)),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(status,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: statusColor)),
                        ]),
                  ),
                ]),
            const SizedBox(height: 10),

            // ── Row 2: chips ──
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (workOrderNo.isNotEmpty)
                _chip(
                    label: "WO: $workOrderNo",
                    bgColor: AppColors.lightBlue,
                    textColor: AppColors.primaryBlue,
                    icon: Icons.assignment_rounded),
              if (jobNo.isNotEmpty)
                _chip(
                    label: "Job #$jobNo",
                    bgColor: AppColors.lightGray,
                    textColor: AppColors.textSecondary,
                    icon: Icons.tag_rounded,
                    borderColor: AppColors.borderGray),
              if (location.isNotEmpty)
                _chip(
                    label: location,
                    bgColor: AppColors.lightGray,
                    textColor: AppColors.textSecondary,
                    icon: Icons.location_on_outlined,
                    borderColor: AppColors.borderGray),
            ]),
            const SizedBox(height: 12),

            // ── Progress bar ──
            Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Progress",
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  Text("${progress.toStringAsFixed(0)}%",
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue)),
                ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor:
                    AppColors.primaryBlue.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 14),

            // ── Manage button ──
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () =>
                    _showManageSheet(context, doc, title),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.mediumBlue),
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Manage",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w600,
                                color: AppColors
                                    .primaryBlue)),
                        SizedBox(width: 6),
                        Icon(
                            Icons
                                .arrow_forward_rounded,
                            size: 14,
                            color:
                                AppColors.primaryBlue),
                      ]),
                ),
              ),
            ),
          ]),
    );
  }

  // ── Manage bottom sheet – mirrors ContractorDashboard's coming-soon sheet ─
  void _showManageSheet(BuildContext context,
      QueryDocumentSnapshot doc, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding:
            const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sheet header
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.mediumBlue)),
                child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.primaryBlue,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text("Manage Project",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w700,
                              color: AppColors
                                  .textPrimary,
                              letterSpacing: -0.4)),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors
                                  .textSecondary),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis),
                    ]),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius:
                        BorderRadius.circular(10)),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18),
                  onPressed: () =>
                      Navigator.pop(context),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Options
            _sheetOption(
              icon: Icons.upload_file_rounded,
              title: "Upload DPR",
              subtitle: "Add daily progress report",
              color: AppColors.primaryBlue,
              bgColor: AppColors.lightBlue,
              borderColor: AppColors.mediumBlue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UploadDprScreen(
                            projectId: doc.id,
                            projectTitle: title)));
              },
            ),
            const SizedBox(height: 10),
            _sheetOption(
              icon: Icons.history_rounded,
              title: "DPR History",
              subtitle: "View all progress reports",
              color: AppColors.primaryBlue,
              bgColor: AppColors.lightBlue,
              borderColor: AppColors.mediumBlue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            DprHistoryScreen(
                                projectId: doc.id,
                                projectTitle: title)));
              },
            ),
            const SizedBox(height: 10),
            _sheetOption(
              icon: Icons.payments_rounded,
              title: "Add Expense",
              subtitle: "Record project expenses",
              color: AppColors.successGreen,
              bgColor: AppColors.lightGreen,
              borderColor: const Color(0xFF6EE7B7),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(
                            projectId: doc.id,
                            projectTitle: title)));
              },
            ),
            const SizedBox(height: 10),
            _sheetOption(
              icon: Icons.receipt_long_rounded,
              title: "Expense History",
              subtitle: "View all expenses",
              color: AppColors.warningOrange,
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ExpenseHistoryScreen(
                                projectId: doc.id,
                                projectTitle: title)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ])),
          Icon(Icons.arrow_forward_rounded,
              size: 16, color: color),
        ]),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
            fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: "Search by name, location, status…",
          hintStyle: const TextStyle(
              fontSize: 14, color: AppColors.textTertiary),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Empty / error states ──────────────────────────────────────────────────
  Widget _buildNoUserState() {
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
                      color: AppColors.lightGray,
                      shape: BoxShape.circle),
                  child: const Icon(
                      Icons.person_off_outlined,
                      size: 56,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 24),
              const Text("Not Logged In",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              const Text(
                  "Please log in to access supervisor features.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ]),
      ),
    );
  }

  Widget _buildNoProjectsState() {
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
                      color: AppColors.lightGray,
                      shape: BoxShape.circle),
                  child: const Icon(
                      Icons.assignment_outlined,
                      size: 56,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 24),
              const Text("No Projects Assigned",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              const Text(
                  "You haven't been assigned any projects yet.\nPlease contact your contractor.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ]),
      ),
    );
  }

  Widget _buildSearchEmptyState() {
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
                      color: AppColors.lightGray,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.search_off_rounded,
                      size: 56,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 24),
              const Text("No Results Found",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              const Text("Try a different search term.",
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary)),
            ]),
      ),
    );
  }

  // ── Shared helpers (identical to ContractorDashboard) ────────────────────
  Widget _buildSectionHeader(String title, String subtitle,
      {required IconData icon, required Color iconColor}) {
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                ]),
          ),
        ]);
  }

  Widget _chip({
    required String label,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 9, vertical: 5),
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

  // ── Status colour helpers ─────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return AppColors.primaryBlue;
      case 'completed':
        return AppColors.successGreen;
      case 'delayed':
        return AppColors.warningOrange;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return AppColors.lightBlue;
      case 'completed':
        return AppColors.lightGreen;
      case 'delayed':
        return const Color(0xFFFFFBEB);
      default:
        return AppColors.lightGray;
    }
  }

  Color _statusBorder(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return AppColors.mediumBlue;
      case 'completed':
        return const Color(0xFF6EE7B7);
      case 'delayed':
        return const Color(0xFFFDE68A);
      default:
        return AppColors.borderGray;
    }
  }
}