import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/auth/login_screen.dart';
import 'package:track_site_pro_app/screens/dpr/upload_dpr_screen.dart';
import 'package:track_site_pro_app/screens/dpr/dpr_history_screen.dart';
import 'package:track_site_pro_app/screens/expenses/AddExpenseScreen.dart';
import 'package:track_site_pro_app/screens/expenses/ExpenseHistoryScreen.dart';
import 'package:track_site_pro_app/screens/profileManagementScreen/ProfileManagementScreen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? "Supervisor Dashboard" : "My Projects",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileManagementScreen(),
                ),
              );
            },
            tooltip: 'Profile Management',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildDashboardTab() : _buildProjectsTab(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              icon: Icons.dashboard,
              label: "Dashboard",
              isActive: _currentIndex == 0,
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                  _searchQuery = '';
                });
              },
            ),
            _buildBottomNavItem(
              icon: Icons.assignment,
              label: "Projects",
              isActive: _currentIndex == 1,
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              "No supervisor logged in",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please log in to access supervisor features",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('assignedSupervisor', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading projects...'),
              ],
            ),
          );
        }

        final assignedDocs = snapshot.data!.docs;

        if (assignedDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.secondary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    size: 70,
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "No Projects Assigned",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "You haven't been assigned any projects yet.\nPlease contact your contractor.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final welcomeHeader = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.15),
                colorScheme.secondary.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.supervised_user_circle_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Supervisor! 👋",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${assignedDocs.length} assigned project${assignedDocs.length != 1 ? 's' : ''}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: Colors.green,
                  size: 24,
                ),
              ),
            ],
          ),
        );

        return RefreshIndicator(
          onRefresh: () async => Future.delayed(Duration.zero),
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: welcomeHeader,
                ),
                const SizedBox(height: 28),
                _buildStatsSection(assignedDocs, colorScheme),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  "My Assigned Projects",
                  "${assignedDocs.length} project${assignedDocs.length != 1 ? 's' : ''}",
                  Icons.assignment_turned_in,
                  colorScheme,
                ),
                const SizedBox(height: 20),
                ...assignedDocs.take(3).map((doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDashboardProjectCard(doc, colorScheme, context),
                    )),
                if (assignedDocs.length > 3)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View all ${assignedDocs.length} projects",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardProjectCard(QueryDocumentSnapshot doc, ColorScheme colorScheme, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final projectTitle = data['projectTitle'] ?? 'Project';
    final jobNo = data['jobNo'] ?? '';
    final location = data['location'] ?? '';
    final region = data['region'] ?? '';
    final progress = (data['progress'] ?? 0).toDouble();
    final status = data['status']?.toString() ?? 'Active';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "$location • $region",
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.15),
                        colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "JOB $jobNo",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "${progress.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showProjectOptions(context, doc, projectTitle, colorScheme);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Manage",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                        ],
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

  void _showProjectOptions(BuildContext context, QueryDocumentSnapshot doc, String projectTitle, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.manage_accounts,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manage Project",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        projectTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.upload_file,
              title: "Upload DPR",
              subtitle: "Add daily progress report",
              color: colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadDprScreen(
                      projectId: doc.id,
                      projectTitle: projectTitle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.history,
              title: "DPR History",
              subtitle: "View all progress reports",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DprHistoryScreen(
                      projectId: doc.id,
                      projectTitle: projectTitle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.attach_money,
              title: "Add Expense",
              subtitle: "Record project expenses",
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      projectId: doc.id,
                      projectTitle: projectTitle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.receipt_long,
              title: "Expense History",
              subtitle: "View all expenses",
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseHistoryScreen(
                      projectId: doc.id,
                      projectTitle: projectTitle,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              "No supervisor logged in",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('assignedSupervisor', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading projects...'),
              ],
            ),
          );
        }

        final assignedDocs = snapshot.data!.docs;

        final filteredDocs = assignedDocs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          
          final data = doc.data() as Map<String, dynamic>;
          final projectTitle = (data['projectTitle'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();
          final jobNo = (data['jobNo'] ?? '').toString().toLowerCase();
          final region = (data['region'] ?? '').toString().toLowerCase();
          final status = (data['status'] ?? '').toString().toLowerCase();
          
          final query = _searchQuery.toLowerCase();
          return projectTitle.contains(query) ||
              location.contains(query) ||
              jobNo.contains(query) ||
              region.contains(query) ||
              status.contains(query);
        }).toList();

        final activeProjects = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']?.toString().toLowerCase() ?? '';
          return status == 'active';
        }).toList();

        final completedProjects = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']?.toString().toLowerCase() ?? '';
          return status == 'completed';
        }).toList();

        final delayedProjects = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']?.toString().toLowerCase() ?? '';
          return status == 'delayed';
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _searchQuery = '';
            });
            return Future.delayed(Duration.zero);
          },
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(colorScheme),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  "My Assigned Projects",
                  "${filteredDocs.length} project${filteredDocs.length != 1 ? 's' : ''} ${_searchQuery.isNotEmpty ? 'found' : 'total'}",
                  Icons.assignment,
                  colorScheme,
                ),
                const SizedBox(height: 20),

                if (activeProjects.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusSectionHeader(
                        "Active Projects",
                        activeProjects.length,
                        Colors.blue,
                        colorScheme,
                      ),
                      const SizedBox(height: 12),
                      ...activeProjects.map((doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildProjectsTabProjectCard(doc, colorScheme, context),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ),

                if (completedProjects.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusSectionHeader(
                        "Completed Projects",
                        completedProjects.length,
                        Colors.green,
                        colorScheme,
                      ),
                      const SizedBox(height: 12),
                      ...completedProjects.map((doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildProjectsTabProjectCard(doc, colorScheme, context),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ),

                if (delayedProjects.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusSectionHeader(
                        "Delayed Projects",
                        delayedProjects.length,
                        Colors.orange,
                        colorScheme,
                      ),
                      const SizedBox(height: 12),
                      ...delayedProjects.map((doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildProjectsTabProjectCard(doc, colorScheme, context),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ),

                if (filteredDocs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isEmpty
                              ? "No projects assigned"
                              : "No projects found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? "You haven't been assigned any projects yet"
                              : "Try a different search term",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectsTabProjectCard(QueryDocumentSnapshot doc, ColorScheme colorScheme, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final projectTitle = data['projectTitle'] ?? 'Project';
    final jobNo = data['jobNo'] ?? '';
    final location = data['location'] ?? '';
    final region = data['region'] ?? '';
    final progress = (data['progress'] ?? 0).toDouble();
    final status = data['status']?.toString() ?? 'Active';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$location • $region",
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "JOB $jobNo",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Progress",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${progress.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showProjectOptions(context, doc, projectTitle, colorScheme);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Manage",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: TextEditingController(text: _searchQuery),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search projects by name, location, status...",
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: colorScheme.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Searching...",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSectionHeader(String title, int count, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getStatusIcon(title),
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "$count project${count != 1 ? 's' : ''}",
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active projects':
        return Icons.play_circle_fill_outlined;
      case 'completed projects':
        return Icons.check_circle_outlined;
      case 'delayed projects':
        return Icons.schedule_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.15),
                colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(List<QueryDocumentSnapshot> docs, ColorScheme colorScheme) {
    final activeProjects = docs
        .where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = data['status'];
          return status != null && status.toString().toLowerCase() == "active";
        })
        .toList();
    
    final completedProjects = docs
        .where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = data['status'];
          return status != null && status.toString().toLowerCase() == "completed";
        })
        .toList();
    
    final delayedProjects = docs
        .where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = data['status'];
          return status != null && status.toString().toLowerCase() == "delayed";
        })
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            title: "Active",
            count: activeProjects.length,
            icon: Icons.play_circle_fill_outlined,
            color: Colors.blue,
            colorScheme: colorScheme,
          ),
          _buildStatItem(
            title: "Completed",
            count: completedProjects.length,
            icon: Icons.check_circle_outlined,
            color: Colors.green,
            colorScheme: colorScheme,
          ),
          _buildStatItem(
            title: "Delayed",
            count: delayedProjects.length,
            icon: Icons.schedule_outlined,
            color: Colors.orange,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _logout(BuildContext context) async {
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
}