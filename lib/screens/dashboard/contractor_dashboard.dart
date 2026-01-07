import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/auth/login_screen.dart';
import 'package:track_site_pro_app/screens/documents/FirmDocumentListScreen.dart';
import 'package:track_site_pro_app/screens/dpr/upload_dpr_screen.dart';
import 'package:track_site_pro_app/screens/notifications/notification_screen.dart';
import 'package:track_site_pro_app/screens/projects/completed_projects_screen.dart';
import 'package:track_site_pro_app/screens/projects/project_list_screen.dart';
import 'package:track_site_pro_app/screens/settings/settings_screen.dart';
import 'package:track_site_pro_app/screens/switch%20firm/switch_firm_screen.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});
  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeScreen(),
      const ProjectListScreen(),
      const UploadDprScreen(),
      const FirmDocumentListScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.location_on,
        color: colorScheme.onPrimary,
        size: 20,
      ),
      const SizedBox(width: 8),
      const Text(
        'TrackSitePro',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ],
  ),
  centerTitle: true,
  backgroundColor: colorScheme.primary,
  foregroundColor: colorScheme.onPrimary,
  leading: IconButton(
    icon: const Icon(Icons.switch_account),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SwitchFirmScreen()),
      );
    },
    tooltip: 'Switch Firm',
  ),
  actions: [
    // Logout Icon (now on the right side)
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: _logout,
      tooltip: 'Logout',
    ),
  ],
),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(uid, colorScheme),
    );
  }

  Widget _buildBottomNav(String uid, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        destinations: [
          NavigationDestination(
            icon: Icon(
              _currentIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              _currentIndex == 1 ? Icons.folder : Icons.folder_outlined,
            ),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.add,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
            label: 'Upload DPR',
          ),
          NavigationDestination(
            icon: Icon(
              _currentIndex == 3 ? Icons.insert_drive_file : Icons.insert_drive_file_outlined,
            ),
            label: 'Firm Docs',
          ),
          NavigationDestination(
            icon: _buildNotificationIcon(uid),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(
              _currentIndex == 5 ? Icons.settings : Icons.settings_outlined,
            ),
            label: 'Settings',
          ),
        ],
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  Widget _buildNotificationIcon(String uid) {
    return Stack(
      children: [
        Icon(
          _currentIndex == 4 ? Icons.notifications : Icons.notifications_outlined,
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("notifications")
              .doc(uid)
              .collection("user_notifications")
              .where("read", isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            final count = snapshot.data!.docs.length;
            return Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Enhanced Home Screen Widget
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final firmId = userSnap.data!.get('assignedFirmId');
        if (firmId == null) {
          return _buildNoFirmAssigned(context, colorScheme);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('projects')
              .where('firmId', isEqualTo: firmId)
              .snapshots(),
          builder: (context, projectSnap) {
            if (!projectSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allProjects = projectSnap.data!.docs;
            return _buildHomePage(context, allProjects, colorScheme, textTheme);
          },
        );
      },
    );
  }

  Widget _buildNoFirmAssigned(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 60,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Firm Assigned",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Please Add a firm",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SwitchFirmScreen(),
                ),
              );
            },
            icon: const Icon(Icons.business),
            label: const Text("Switch/Create Firm"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(
    BuildContext context,
    List<QueryDocumentSnapshot> allProjects,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final activeProjects = allProjects
        .where((d) => (d.data() as Map<String, dynamic>)['status'] == "Active")
        .toList();
    final completedProjects = allProjects
        .where((d) => (d.data() as Map<String, dynamic>)['status'] == "Completed")
        .toList();
    final delayedProjects = allProjects
        .where((d) => (d.data() as Map<String, dynamic>)['status'] == "Delayed")
        .toList();

    // Sort completed projects by completion date
    completedProjects.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = aData['completedAt'] != null
          ? (aData['completedAt'] as Timestamp).toDate()
          : DateTime(2000);
      final bDate = bData['completedAt'] != null
          ? (bData['completedAt'] as Timestamp).toDate()
          : DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          // Force refresh by rebuilding
          return;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(colorScheme, textTheme),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsRow(activeProjects, completedProjects, delayedProjects, colorScheme),
              const SizedBox(height: 28),

              // Active Projects Section
              if (activeProjects.isNotEmpty) ...[
                _buildSectionHeader(
                  "Active Projects",
                  "${activeProjects.length} Projects",
                  Icons.rocket_launch_outlined,
                  colorScheme,
                ),
                const SizedBox(height: 16),
                ...activeProjects.map((doc) => _buildActiveProjectCard(doc, colorScheme)).toList(),
                const SizedBox(height: 32),
              ],

              // Recent Completed Projects
              if (completedProjects.isNotEmpty) ...[
                _buildSectionHeader(
                  "Recent Completions",
                  "Latest completed projects",
                  Icons.check_circle_outline,
                  colorScheme,
                ),
                const SizedBox(height: 16),
                ...completedProjects.take(3).map((doc) => _buildCompletedProjectCard(doc, colorScheme)).toList(),
                if (completedProjects.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompletedProjectsScreen(
                                projects: completedProjects,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text("View All Completed"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],

              // If no projects
              if (activeProjects.isEmpty && completedProjects.isEmpty)
                _buildEmptyProjectsState(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primaryContainer.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome Back,",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
                  builder: (context, snapshot) {
                    final name = snapshot.hasData ? snapshot.data!.get('name') ?? 'Contractor' : 'Contractor';
                    return Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "Track and manage your construction projects efficiently",
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    List<QueryDocumentSnapshot> activeProjects,
    List<QueryDocumentSnapshot> completedProjects,
    List<QueryDocumentSnapshot> delayedProjects,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          title: "Active",
          count: activeProjects.length,
          icon: Icons.play_circle_fill_outlined,
          color: colorScheme.primary,
        ),
        _buildStatItem(
          title: "Completed",
          count: completedProjects.length,
          icon: Icons.check_circle_outlined,
          color: Colors.green,
        ),
        _buildStatItem(
          title: "Delayed",
          count: delayedProjects.length,
          icon: Icons.schedule_outlined,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProjectCard(QueryDocumentSnapshot doc, ColorScheme colorScheme) {
    final data = doc.data() as Map<String, dynamic>;
    final progress = (data['progress'] ?? 0.0).toDouble();
    final totalBoqValue = (data['totalBoqValue'] ?? 0).toDouble();
    final totalCompletedValue = (data['totalCompletedValue'] ?? 0).toDouble();
    final projectTitle = data['projectTitle'] ?? 'Untitled Project';
    final jobNo = data['jobNo'] ?? '';
    final region = data['region'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "JOB $jobNo",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              projectTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            region,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFinancialCard(
                  "BOQ Value",
                  "PKR ${totalBoqValue.toStringAsFixed(0)}",
                  Icons.attach_money_outlined,
                  colorScheme.onSurfaceVariant,
                ),
                _buildFinancialCard(
                  "Completed",
                  "PKR ${totalCompletedValue.toStringAsFixed(0)}",
                  Icons.check_circle_outline,
                  colorScheme.primary,
                ),
                _buildFinancialCard(
                  "Pending",
                  "PKR ${(totalBoqValue - totalCompletedValue).toStringAsFixed(0)}",
                  Icons.pending_actions_outlined,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "${progress.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: colorScheme.surfaceVariant,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progress / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedProjectCard(QueryDocumentSnapshot doc, ColorScheme colorScheme) {
    final data = doc.data() as Map<String, dynamic>;
    final totalBoqValue = (data['totalBoqValue'] ?? 0).toDouble();
    final expenses = (data['totalExpenses'] ?? 0).toDouble();
    final profit = totalBoqValue - expenses;
    final projectTitle = data['projectTitle'] ?? 'Untitled';
    final jobNo = data['jobNo'] ?? 'N/A';
    final completedAt = data['completedAt'] != null
        ? (data['completedAt'] as Timestamp).toDate()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "COMPLETED",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              projectTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Job No: $jobNo",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (completedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "Completed: ${completedAt.day}/${completedAt.month}/${completedAt.year}",
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial Summary - Enhanced with clear labels
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // BOQ Value
                  _buildFinancialSummaryRow(
                    icon: Icons.attach_money_outlined,
                    title: "Total BOQ Value",
                    value: "PKR ${totalBoqValue.toStringAsFixed(0)}",
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(height: 8),
                  
                  // Expenses
                  _buildFinancialSummaryRow(
                    icon: Icons.receipt_outlined,
                    title: "Total Expenses",
                    value: "PKR ${expenses.toStringAsFixed(0)}",
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  
                  // Profit/Loss
                  _buildFinancialSummaryRow(
                    icon: profit >= 0 ? Icons.trending_up : Icons.trending_down,
                    title: profit >= 0 ? "Total Profit" : "Total Loss",
                    value: "PKR ${profit.abs().toStringAsFixed(0)}",
                    color: profit >= 0 ? Colors.green : Colors.red,
                    isBold: true,
                  ),
                  
                  // Profit/Loss Percentage
                  if (totalBoqValue > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: profit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: profit >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          profit >= 0 
                            ? "+${(profit / totalBoqValue * 100).toStringAsFixed(1)}% Profit Margin"
                            : "-${(profit.abs() / totalBoqValue * 100).toStringAsFixed(1)}% Loss",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProjectsState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "No Projects Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 250),
            child: Text(
              "Start by adding your first project",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}