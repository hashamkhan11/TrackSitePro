import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/auth/login_screen.dart';
import 'package:track_site_pro_app/screens/documents/FirmDocumentListScreen.dart';
import 'package:track_site_pro_app/screens/documents/DocumentListScreen.dart';
import 'package:track_site_pro_app/screens/expenses/ExpenseHistoryScreen.dart';
import 'package:track_site_pro_app/screens/notifications/notification_screen.dart';
import 'package:track_site_pro_app/screens/payments/PaymentHistoryScreen.dart';
import 'package:track_site_pro_app/screens/projects/completed_projects_screen.dart';
import 'package:track_site_pro_app/screens/projects/project_list_screen.dart';
import 'package:track_site_pro_app/screens/settings/settings_screen.dart';
import 'package:track_site_pro_app/screens/switch_firm/switch_firm_screen.dart';

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
  static const partiallyPaidOrange = Color(0xFFF59E0B);
  static const fullyPaidGreen = Color(0xFF10B981);
}

// ── Data Models ──────────────────────────────────────────────────────────────
class _PaymentStats {
  final int total, unpaid, partial, full;
  const _PaymentStats({required this.total, required this.unpaid,
      required this.partial, required this.full});
}

class _ProjectWithPayment {
  final QueryDocumentSnapshot doc;
  final String paymentStatus;
  final double totalPaid;
  final double totalExpenses;
  const _ProjectWithPayment({required this.doc, required this.paymentStatus,
      required this.totalPaid, required this.totalExpenses});
}

class _DashboardData {
  final _PaymentStats stats;
  final List<_ProjectWithPayment> unpaidProjects;
  final List<_ProjectWithPayment> partialProjects;
  final List<_ProjectWithPayment> fullyPaidCompleted;
  const _DashboardData({required this.stats, required this.unpaidProjects,
      required this.partialProjects, required this.fullyPaidCompleted});
}

// ── ContractorDashboard ──────────────────────────────────────────────────────
class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});
  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  static const int _comingSoonIndex = 2;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeScreen(),
      const ProjectListScreen(),
      const SizedBox.shrink(),
      const FirmDocumentListScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];
  }

  void _showComingSoon(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.mediumBlue, width: 2),
              ),
              child: const Icon(Icons.construction_rounded,
                  size: 38, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Work Screen',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              "Don't worry Papa — this feature is\nalmost ready! 🚀",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 16, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Coming Soon',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue)),
              ]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Got it!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 64, height: 64,
                  decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: AppColors.primaryBlue, size: 32)),
              const SizedBox(height: 20),
              const Text("Logout Confirmation",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              const Text("Are you sure you want to logout from your account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.borderGray),
                        foregroundColor: AppColors.textSecondary),
                    child: const Text("Cancel",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Logout",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showSwitchFirmMenu(BuildContext context, String uid, Rect buttonRect) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          buttonRect.left, buttonRect.bottom + 8, buttonRect.right, buttonRect.top),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      items: [
        PopupMenuItem(
          enabled: false, padding: EdgeInsets.zero,
          child: Container(
            width: 280, padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Switch Firm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                SizedBox(height: 200, child: _buildFirmList(uid)),
                const Divider(height: 16, color: AppColors.borderGray),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SwitchFirmScreen()));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: AppColors.lightBlue, borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.settings_outlined, size: 18, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Text('Manage Firms',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFirmList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('firms')
          .where('ownerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error', style: TextStyle(color: Colors.red[300])));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(
              color: AppColors.primaryBlue, strokeWidth: 2));
        }
        final firms = snapshot.data!.docs;
        if (firms.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.corporate_fare_rounded, size: 40,
                color: AppColors.textTertiary.withOpacity(0.5)),
            const SizedBox(height: 8),
            const Text('No firms yet',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ]));
        }
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            final currentFirmId =
                userSnapshot.hasData ? userSnapshot.data!.get('assignedFirmId') : null;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final firm = firms[index];
                final firmData = firm.data() as Map<String, dynamic>;
                final firmName = firmData['firmName'] ?? firmData['name'] ?? 'Unknown Firm';
                final isCurrentFirm = firm.id == currentFirmId;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isCurrentFirm ? null : () async {
                      await FirebaseFirestore.instance.collection('users').doc(uid)
                          .update({'assignedFirmId': firm.id});
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Switched to $firmName',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrentFirm ? AppColors.lightBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isCurrentFirm ? AppColors.primaryBlue : AppColors.borderGray,
                            width: isCurrentFirm ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: isCurrentFirm
                                  ? AppColors.primaryBlue.withOpacity(0.1) : AppColors.lightGray,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.business_rounded, size: 16,
                              color: isCurrentFirm
                                  ? AppColors.primaryBlue : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(firmName,
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: isCurrentFirm
                                          ? FontWeight.w700 : FontWeight.w600,
                                      color: isCurrentFirm
                                          ? AppColors.primaryBlue : AppColors.textPrimary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (isCurrentFirm)
                                const Text('Current',
                                    style: TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
                            ])),
                        if (isCurrentFirm)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: AppColors.primaryBlue, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12)),
                        if (!isCurrentFirm)
                          const Icon(Icons.swap_horiz_rounded,
                              color: AppColors.textTertiary, size: 18),
                      ]),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onNavTap(int index) {
    if (index == _comingSoonIndex) {
      _showComingSoon(context);
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderGray, width: 1))),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Builder(builder: (context) {
                  return Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      onPressed: () {
                        final RenderBox button = context.findRenderObject() as RenderBox;
                        final RenderBox overlay =
                            Overlay.of(context).context.findRenderObject() as RenderBox;
                        final buttonRect = Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                              button.size.bottomRight(Offset.zero), ancestor: overlay),
                        );
                        _showSwitchFirmMenu(context, uid, buttonRect);
                      },
                      tooltip: 'Switch Firm',
                      color: AppColors.textSecondary, padding: EdgeInsets.zero,
                    ),
                  );
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const Text('Loading...',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary));
                      }
                      final firmId = userSnapshot.data!.get('assignedFirmId');
                      if (firmId == null) {
                        return Row(children: [
                          Container(width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.textTertiary, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text('No Firm',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ]);
                      }
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('firms').doc(firmId).snapshots(),
                        builder: (context, firmSnapshot) {
                          if (!firmSnapshot.hasData || !firmSnapshot.data!.exists) {
                            return Row(children: [
                              Container(width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                      color: AppColors.warningOrange, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              const Text('Firm Not Found',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ]);
                          }
                          final firmName = firmSnapshot.data!.get('firmName') ??
                              firmSnapshot.data!.get('name') ?? 'Unknown Firm';
                          return Row(children: [
                            Container(width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: AppColors.primaryBlue, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(firmName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary, letterSpacing: -0.5),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ]);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    onPressed: _logout, tooltip: 'Logout',
                    color: AppColors.textSecondary, padding: EdgeInsets.zero,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(uid),
    );
  }

  Widget _buildBottomNav(String uid) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderGray, width: 1))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildNavItem(0, Icons.home_rounded,          Icons.home_outlined,          'Home'),
            _buildNavItem(1, Icons.folder_rounded,        Icons.folder_outlined,        'Projects'),
            _buildNavItemComingSoon(Icons.engineering_rounded, 'Work'),
            _buildNavItem(3, Icons.description_rounded,   Icons.description_outlined,   'Docs'),
            _buildNavItemWithBadge(4, Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts', uid),
            _buildNavItem(5, Icons.settings_rounded,      Icons.settings_outlined,      'Settings'),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppColors.primaryBlue : AppColors.textTertiary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primaryBlue : AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavItemComingSoon(IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => _showComingSoon(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(icon, color: AppColors.textTertiary, size: 24),
              Positioned(
                right: -8, top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text('Soon',
                      style: TextStyle(fontSize: 7, color: Colors.white,
                          fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
      int index, IconData activeIcon, IconData inactiveIcon, String label, String uid) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppColors.primaryBlue : AppColors.textTertiary, size: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("notifications").doc(uid)
                    .collection("user_notifications")
                    .where("read", isEqualTo: false).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final count = snapshot.data!.docs.length;
                  return Positioned(
                    right: -6, top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2)),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(fontSize: 9, color: Colors.white,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primaryBlue : AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }
}

// ── Home Screen ──────────────────────────────────────────────────────────────
class _HomeScreen extends StatefulWidget {
  const _HomeScreen();
  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  bool _showAllPending = false;
  static const int _pendingPageSize = 7;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(child: CircularProgressIndicator(
              color: AppColors.primaryBlue, strokeWidth: 3));
        }
        final firmId = userSnap.data!.get('assignedFirmId');
        if (firmId == null) return _buildNoFirmAssigned(context);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('projects')
              .where('firmId', isEqualTo: firmId).snapshots(),
          builder: (context, projectSnap) {
            if (!projectSnap.hasData) {
              return const Center(child: CircularProgressIndicator(
                  color: AppColors.primaryBlue, strokeWidth: 3));
            }
            return _buildHomePage(context, projectSnap.data!.docs, uid);
          },
        );
      },
    );
  }

  Widget _buildNoFirmAssigned(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 120, height: 120,
              decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.corporate_fare_rounded, size: 56,
                  color: AppColors.primaryBlue)),
          const SizedBox(height: 32),
          const Text("No Firm Assigned",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text("You need to be assigned to a firm to access projects and features",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SwitchFirmScreen())),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Switch or Create Firm",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context,
      List<QueryDocumentSnapshot> allProjects, String uid) {
    return FutureBuilder<_DashboardData>(
      future: _buildDashboardData(allProjects),
      builder: (context, snap) {
        final data = snap.data ?? _DashboardData(
          stats: _PaymentStats(total: allProjects.length, unpaid: 0, partial: 0, full: 0),
          unpaidProjects: [], partialProjects: [], fullyPaidCompleted: [],
        );
        final isLoading = !snap.hasData;
        final allPending = [...data.unpaidProjects, ...data.partialProjects];
        final visiblePending = _showAllPending
            ? allPending : allPending.take(_pendingPageSize).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 400));
          },
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildWelcomeHeader(uid),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildInlineStats(data.stats, isLoading),
                ),
              ),
              if (allPending.isNotEmpty || isLoading) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
                    child: _buildSectionHeader(
                      "Pending Payments",
                      isLoading
                          ? "Loading..."
                          : "${allPending.length} project${allPending.length == 1 ? '' : 's'} awaiting payment",
                      icon: Icons.pending_actions_rounded,
                      iconColor: AppColors.warningOrange,
                    ),
                  ),
                ),
                if (isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(
                            color: AppColors.primaryBlue, strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPendingProjectCard(
                              context, visiblePending[index]),
                        ),
                        childCount: visiblePending.length,
                      ),
                    ),
                  ),
                if (!isLoading && allPending.length > _pendingPageSize)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: _buildExpandToggle(
                        isExpanded: _showAllPending,
                        totalCount: allPending.length,
                        onToggle: () =>
                            setState(() => _showAllPending = !_showAllPending),
                      ),
                    ),
                  ),
              ],
              if (!isLoading && data.fullyPaidCompleted.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
                    child: _buildSectionHeader(
                      "Completed & Paid",
                      "${data.fullyPaidCompleted.length} project${data.fullyPaidCompleted.length == 1 ? '' : 's'} fully settled",
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.fullyPaidGreen,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCompletedPaidCard(data.fullyPaidCompleted[index]),
                      ),
                      childCount: data.fullyPaidCompleted.length > 3
                          ? 3 : data.fullyPaidCompleted.length,
                    ),
                  ),
                ),
                if (data.fullyPaidCompleted.length > 3)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => CompletedProjectsScreen(
                                projects: data.fullyPaidCompleted.map((e) => e.doc).toList()))),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text("View All Completed",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
              if (!isLoading && allPending.isEmpty && data.fullyPaidCompleted.isEmpty)
                SliverFillRemaining(child: _buildEmptyState()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }

  // ── Dashboard data computation ──────────────────────────────────────────────
  Future<_DashboardData> _buildDashboardData(
      List<QueryDocumentSnapshot> allProjects) async {
    int unpaidCount = 0, partialCount = 0, fullCount = 0;
    final List<_ProjectWithPayment> unpaidList = [];
    final List<_ProjectWithPayment> partialList = [];
    final List<_ProjectWithPayment> completedPaidList = [];

    await Future.wait(allProjects.map((doc) async {
      final projectData = doc.data() as Map<String, dynamic>;
      final paymentsSnap = await FirebaseFirestore.instance
          .collection('projects').doc(doc.id).collection('payments').get();

      double totalPaid = 0;
      bool has100 = false, hasPartial = false;

      for (var p in paymentsSnap.docs) {
        final pData = p.data();
        final type = (pData['paymentType'] ?? '') as String;
        totalPaid += (pData['amount'] ?? 0).toDouble();
        if (type.contains('100%')) has100 = true;
        if (type.contains('50%') || type.contains('80%')) hasPartial = true;
      }

      final totalAmount = ((projectData['totalAmount'] ?? 0) as num).toDouble();
      final String payStatus;
      if (has100 || (paymentsSnap.docs.isNotEmpty && totalAmount > 0 && totalPaid >= totalAmount)) {
        payStatus = 'Fully Paid'; fullCount++;
      } else if (hasPartial || totalPaid > 0) {
        payStatus = 'Partially Paid'; partialCount++;
      } else {
        payStatus = 'Unpaid'; unpaidCount++;
      }

      // ── Fetch expenses for ALL projects (needed for pending detail sheet too) ──
      double totalExpenses = 0;
      final expSnap = await FirebaseFirestore.instance
          .collection('projects').doc(doc.id).collection('expenses').get();
      for (var e in expSnap.docs) {
        totalExpenses += ((e.data())['amount'] ?? 0).toDouble();
      }

      final item = _ProjectWithPayment(doc: doc, paymentStatus: payStatus,
          totalPaid: totalPaid, totalExpenses: totalExpenses);

      if (payStatus == 'Unpaid') unpaidList.add(item);
      else if (payStatus == 'Partially Paid') partialList.add(item);
      else completedPaidList.add(item);
    }));

    completedPaidList.sort((a, b) {
      final aData = a.doc.data() as Map<String, dynamic>;
      final bData = b.doc.data() as Map<String, dynamic>;
      final aDate = aData['completedAt'] != null
          ? (aData['completedAt'] as Timestamp).toDate() : DateTime(2000);
      final bDate = bData['completedAt'] != null
          ? (bData['completedAt'] as Timestamp).toDate() : DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return _DashboardData(
      stats: _PaymentStats(total: allProjects.length, unpaid: unpaidCount,
          partial: partialCount, full: fullCount),
      unpaidProjects: unpaidList,
      partialProjects: partialList,
      fullyPaidCompleted: completedPaidList,
    );
  }

  // ── Welcome ─────────────────────────────────────────────────────────────────
  Widget _buildWelcomeHeader(String uid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final name = snapshot.hasData
            ? snapshot.data!.get('name') ?? 'Contractor' : 'Contractor';
        final firstName = name.split(' ').first;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Good ${_timeOfDay()},",
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary,
                  letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Text(firstName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -1, height: 1.2)),
        ]);
      },
    );
  }

  String _timeOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return "Morning";
    if (h < 17) return "Afternoon";
    return "Evening";
  }

  // ── Inline Stats ────────────────────────────────────────────────────────────
  Widget _buildInlineStats(_PaymentStats stats, bool isLoading) {
    return Row(children: [
      _inlineStatCard(label: "Total", count: stats.total, color: AppColors.primaryBlue,
          bgColor: AppColors.lightBlue, borderColor: AppColors.mediumBlue,
          icon: Icons.folder_rounded, isLoading: false),
      const SizedBox(width: 8),
      _inlineStatCard(label: "Unpaid", count: stats.unpaid, color: AppColors.unpaidRed,
          bgColor: const Color(0xFFFEF2F2), borderColor: const Color(0xFFFECACA),
          icon: Icons.cancel_rounded, isLoading: isLoading),
      const SizedBox(width: 8),
      _inlineStatCard(label: "Partial", count: stats.partial,
          color: AppColors.partiallyPaidOrange,
          bgColor: const Color(0xFFFFFBEB), borderColor: const Color(0xFFFDE68A),
          icon: Icons.hourglass_top_rounded, isLoading: isLoading),
      const SizedBox(width: 8),
      _inlineStatCard(label: "Paid", count: stats.full, color: AppColors.fullyPaidGreen,
          bgColor: AppColors.lightGreen, borderColor: const Color(0xFF6EE7B7),
          icon: Icons.check_circle_rounded, isLoading: isLoading),
    ]);
  }

  Widget _inlineStatCard({
    required String label, required int count,
    required Color color, required Color bgColor, required Color borderColor,
    required IconData icon, required bool isLoading,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withOpacity(0.7)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 7),
          isLoading
              ? SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Text(count.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: color, letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: color.withOpacity(0.75))),
        ]),
      ),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle,
      {required IconData icon, required Color iconColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    ]);
  }

  // ── Pending Project Card (tappable) ─────────────────────────────────────────
  Widget _buildPendingProjectCard(BuildContext context, _ProjectWithPayment item) {
    final data = item.doc.data() as Map<String, dynamic>;
    final jobNo       = data['jobNo'] ?? '';
    final workOrderNo = data['workOrderNo'] ?? '';
    final isUnpaid    = item.paymentStatus == 'Unpaid';

    final Color statusColor  = isUnpaid ? AppColors.unpaidRed : AppColors.partiallyPaidOrange;
    final Color statusBg     = isUnpaid ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final Color statusBorder = isUnpaid ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final IconData statusIcon  = isUnpaid ? Icons.cancel_rounded : Icons.hourglass_top_rounded;
    final String statusLabel   = isUnpaid ? 'Unpaid' : 'Partially Paid';

    return InkWell(
      onTap: () => _showProjectDetailSheet(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusBorder, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status badge row
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
            const Spacer(),
            // "Tap for details" hint
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Details',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded,
                  size: 15, color: AppColors.textTertiary),
            ]),
          ]),
          const SizedBox(height: 8),
          // Reference chips
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (workOrderNo.isNotEmpty)
              _chip(label: "WO: $workOrderNo", bgColor: AppColors.lightBlue,
                  textColor: AppColors.primaryBlue, icon: Icons.assignment_rounded),
            if (jobNo.isNotEmpty)
              _chip(label: "Job #$jobNo", bgColor: AppColors.lightGray,
                  textColor: AppColors.textSecondary, icon: Icons.tag_rounded,
                  borderColor: AppColors.borderGray),
            if (workOrderNo.isEmpty && jobNo.isEmpty)
              _chip(label: "No reference", bgColor: AppColors.lightGray,
                  textColor: AppColors.textTertiary, icon: Icons.info_outline_rounded,
                  borderColor: AppColors.borderGray),
          ]),
          // Amount received strip (partial only)
          if (!isUnpaid) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A))),
              child: Row(children: [
                const Icon(Icons.payments_outlined, size: 13,
                    color: AppColors.partiallyPaidOrange),
                const SizedBox(width: 6),
                Text("Received: PKR ${_fmt(item.totalPaid)}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.partiallyPaidOrange)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Project Detail Bottom Sheet ─────────────────────────────────────────────
  void _showProjectDetailSheet(BuildContext context, _ProjectWithPayment item) {
    final data = item.doc.data() as Map<String, dynamic>;

    final jobNo          = data['jobNo']?.toString() ?? '';
    final workOrderNo    = data['workOrderNo']?.toString() ?? '';
    final tenderNo       = data['tenderEnquiryNo']?.toString() ?? '';
    final description    = data['jobDescription']?.toString() ?? 'No description';
    final location       = data['location']?.toString() ?? '';
    final supervisorName = data['siteSupervisorName']?.toString() ?? '';
    final totalAmount    = ((data['totalAmount'] ?? 0) as num).toDouble();
    final taxAmount      = ((data['taxAmount'] ?? 0) as num).toDouble();
    final totalExclTax   = ((data['totalExcludingTax'] ?? 0) as num).toDouble();
    final projectDate    = data['date'] != null
        ? (data['date'] as Timestamp).toDate() : null;

    final isUnpaid  = item.paymentStatus == 'Unpaid';
    final isPartial = item.paymentStatus == 'Partially Paid';

    final Color statusColor  = isUnpaid ? AppColors.unpaidRed : AppColors.partiallyPaidOrange;
    final Color statusBg     = isUnpaid ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final Color statusBorder = isUnpaid ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final IconData statusIcon = isUnpaid ? Icons.cancel_rounded : Icons.hourglass_top_rounded;
    final String statusLabel  = isUnpaid ? 'Unpaid' : 'Partially Paid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.93,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header strip ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                child: Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(statusLabel,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ]),
                    ),
                    const Spacer(),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              const Divider(height: 16, color: AppColors.borderGray),

              // ── Scrollable body ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [

                    // ── Reference Numbers ──
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (workOrderNo.isNotEmpty)
                        _chip(label: 'WO: $workOrderNo',
                            bgColor: AppColors.lightBlue,
                            textColor: AppColors.primaryBlue,
                            icon: Icons.assignment_rounded),
                      if (jobNo.isNotEmpty)
                        _chip(label: 'Job #$jobNo',
                            bgColor: AppColors.lightGray,
                            textColor: AppColors.textSecondary,
                            icon: Icons.tag_rounded,
                            borderColor: AppColors.borderGray),
                      if (tenderNo.isNotEmpty)
                        _chip(label: 'TE: $tenderNo',
                            bgColor: AppColors.lightGray,
                            textColor: AppColors.textSecondary,
                            icon: Icons.request_page_outlined,
                            borderColor: AppColors.borderGray),
                    ]),
                    const SizedBox(height: 14),

                    // ── Job Description ──
                    _detailCard(
                      icon: Icons.description_outlined,
                      label: 'Job Description',
                      child: Text(description,
                          style: const TextStyle(fontSize: 14,
                              color: AppColors.textPrimary, height: 1.5)),
                    ),
                    const SizedBox(height: 10),

                    // ── Date & Location ──
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (projectDate != null)
                        Expanded(
                          child: _detailCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'Project Date',
                            child: Text(
                              '${projectDate.day}/${projectDate.month}/${projectDate.year}',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      if (projectDate != null && location.isNotEmpty)
                        const SizedBox(width: 10),
                      if (location.isNotEmpty)
                        Expanded(
                          child: _detailCard(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            child: Text(location,
                                style: const TextStyle(fontSize: 13,
                                    color: AppColors.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),

                    // ── Financial Summary ──
                    _detailCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Financials',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Excl tax & tax row
                          if (totalExclTax > 0) ...[
                            Row(children: [
                              Expanded(
                                child: _miniFinBox(
                                  label: 'Excl. Tax',
                                  value: 'PKR ${_fmt(totalExclTax)}',
                                  color: AppColors.primaryBlue,
                                  bg: AppColors.lightBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _miniFinBox(
                                  label: 'Tax Amount',
                                  value: 'PKR ${_fmt(taxAmount)}',
                                  color: AppColors.warningOrange,
                                  bg: AppColors.lightOrange,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 10),
                          ],
                          // Total project value
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.mediumBlue),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(children: [
                                  Icon(Icons.payments_rounded,
                                      size: 15, color: AppColors.primaryBlue),
                                  SizedBox(width: 6),
                                  Text('Project Value',
                                      style: TextStyle(fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue)),
                                ]),
                                Text('PKR ${_fmt(totalAmount)}',
                                    style: const TextStyle(fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryBlue)),
                              ],
                            ),
                          ),
                          // Received + remaining (partial only)
                          if (isPartial) ...[
                            const SizedBox(height: 10),
                            _finRow('Amount Received',
                                'PKR ${_fmt(item.totalPaid)}',
                                AppColors.partiallyPaidOrange),
                            const SizedBox(height: 6),
                            _finRow(
                              'Remaining',
                              'PKR ${_fmt((totalAmount - item.totalPaid).clamp(0, double.infinity))}',
                              AppColors.unpaidRed,
                            ),
                            const SizedBox(height: 10),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: totalAmount > 0
                                    ? (item.totalPaid / totalAmount).clamp(0.0, 1.0)
                                    : 0,
                                backgroundColor: AppColors.borderGray,
                                color: AppColors.partiallyPaidOrange,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                totalAmount > 0
                                    ? '${(item.totalPaid / totalAmount * 100).toStringAsFixed(1)}% received'
                                    : '0% received',
                                style: const TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                          // Unpaid notice
                          if (isUnpaid) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Row(children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 13, color: AppColors.unpaidRed),
                                SizedBox(width: 6),
                                Text('No payment received yet',
                                    style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.unpaidRed)),
                              ]),
                            ),
                          ],

                          // ── Total Expenses (shown for all pending projects) ──
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(children: [
                                  Icon(Icons.receipt_long_rounded,
                                      size: 15, color: AppColors.warningOrange),
                                  SizedBox(width: 6),
                                  Text('Total Expenses',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.warningOrange)),
                                ]),
                                Text(
                                  'PKR ${_fmt(item.totalExpenses)}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warningOrange),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Site Supervisor ──
                    if (supervisorName.isNotEmpty) ...[
                      _detailCard(
                        icon: Icons.supervised_user_circle_outlined,
                        label: 'Site Supervisor',
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.successGreen.withOpacity(0.3)),
                            ),
                            child: const Icon(
                                Icons.person_rounded,
                                size: 20, color: AppColors.successGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(supervisorName,
                                style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Quick Actions ──
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: _sheetActionButton(
                        context: context,
                        icon: Icons.receipt_long_rounded,
                        label: 'Expenses',
                        color: AppColors.warningOrange,
                        bg: AppColors.lightOrange,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ExpenseHistoryScreen(
                              projectId: item.doc.id,
                              projectTitle: description,
                            ),
                          ));
                        },
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _sheetActionButton(
                        context: context,
                        icon: Icons.folder_rounded,
                        label: 'Documents',
                        color: AppColors.primaryBlue,
                        bg: AppColors.lightBlue,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DocumentListScreen(
                              projectId: item.doc.id,
                              projectTitle: description,
                            ),
                          ));
                        },
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _sheetActionButton(
                        context: context,
                        icon: Icons.payments_rounded,
                        label: 'Payments',
                        color: AppColors.successGreen,
                        bg: AppColors.lightGreen,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PaymentHistoryScreen(
                              projectId: item.doc.id,
                              projectTitle: description,
                            ),
                          ));
                        },
                      )),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail card container ───────────────────────────────────────────────────
  Widget _detailCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  // ── Mini financial box (excl. tax / tax amount side by side) ───────────────
  Widget _miniFinBox({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8))),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Sheet action button ─────────────────────────────────────────────────────
  Widget _sheetActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  // ── Expand / Collapse Toggle ────────────────────────────────────────────────
  Widget _buildExpandToggle({
    required bool isExpanded, required int totalCount, required VoidCallback onToggle,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGray)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isExpanded
                ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text(isExpanded
                ? "Show less"
                : "Show ${totalCount - _pendingPageSize} more",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue)),
          ]),
        ),
      ),
    );
  }

  // ── Completed & Fully Paid Card ─────────────────────────────────────────────
  Widget _buildCompletedPaidCard(_ProjectWithPayment item) {
    final data = item.doc.data() as Map<String, dynamic>;
    final projectTitle = data['projectTitle'] ?? 'Untitled';
    final jobNo = data['jobNo'] ?? '';
    final workOrderNo = data['workOrderNo'] ?? '';
    final location = data['location'] ?? '';
    final completedAt = data['completedAt'] != null
        ? (data['completedAt'] as Timestamp).toDate() : null;
    final net = item.totalPaid - item.totalExpenses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(projectTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.2),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(7)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, size: 11, color: AppColors.fullyPaidGreen),
              SizedBox(width: 4),
              Text("Fully Paid",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.fullyPaidGreen)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          if (workOrderNo.isNotEmpty)
            _chip(label: "WO: $workOrderNo", bgColor: AppColors.lightBlue,
                textColor: AppColors.primaryBlue, icon: Icons.assignment_rounded),
          if (jobNo.isNotEmpty)
            _chip(label: "Job #$jobNo", bgColor: AppColors.lightGray,
                textColor: AppColors.textSecondary, icon: Icons.tag_rounded,
                borderColor: AppColors.borderGray),
          if (completedAt != null)
            _chip(label: "${completedAt.day}/${completedAt.month}/${completedAt.year}",
                bgColor: AppColors.lightGray, textColor: AppColors.textSecondary,
                icon: Icons.calendar_today_rounded, borderColor: AppColors.borderGray),
        ]),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 9),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Expanded(child: Text(location,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _finRow("Total Received", "PKR ${_fmt(item.totalPaid)}", AppColors.successGreen),
            const SizedBox(height: 8),
            _finRow("Total Expenses", "PKR ${_fmt(item.totalExpenses)}", AppColors.warningOrange),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderGray)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(net >= 0 ? "Net Profit" : "Net Loss",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("PKR ${_fmt(net.abs())}",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: net >= 0 ? AppColors.successGreen : Colors.red)),
                if (item.totalPaid > 0)
                  Text(
                    net >= 0
                        ? "+${(net / item.totalPaid * 100).toStringAsFixed(1)}%"
                        : "-${(net.abs() / item.totalPaid * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: net >= 0 ? AppColors.successGreen : Colors.red),
                  ),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 120, height: 120,
              decoration: const BoxDecoration(color: AppColors.lightGray, shape: BoxShape.circle),
              child: const Icon(Icons.folder_open_rounded, size: 56,
                  color: AppColors.textTertiary)),
          const SizedBox(height: 24),
          const Text("No Projects Yet",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text("Your projects will appear here once they're created",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
        ]),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _chip({required String label, required Color bgColor,
      required Color textColor, required IconData icon, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(7),
          border: borderColor != null ? Border.all(color: borderColor) : null),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: textColor),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
      ]),
    );
  }

  Widget _finRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: valueColor)),
    ]);
  }

  /// Formats a number with comma separators and no abbreviations.
  /// e.g. 1500000 → "1,500,000"   |   2450.5 → "2,451"
  String _fmt(double amount) {
    if (amount == amount.truncateToDouble()) {
      // Whole number — no decimal places
      return _addCommas(amount.toInt().toString());
    }
    // Has decimals — keep up to 2 decimal places, strip trailing zeros
    final formatted = amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    final parts = formatted.split('.');
    return '${_addCommas(parts[0])}${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  String _addCommas(String intStr) {
    // Insert commas every 3 digits from the right
    final buffer = StringBuffer();
    final n = intStr.length;
    for (int i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buffer.write(',');
      buffer.write(intStr[i]);
    }
    return buffer.toString();
  }
}