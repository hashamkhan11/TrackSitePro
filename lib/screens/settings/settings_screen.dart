import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_site_pro_app/screens/auth/login_screen.dart';
import 'package:track_site_pro_app/screens/profileManagementScreen/ProfileManagementScreen.dart';
import 'package:track_site_pro_app/screens/supervisors/supervisor_list_screen.dart';
import 'package:track_site_pro_app/screens/switch%20firm/switch_firm_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String? currentFirmName;
  String? userName;
  String? userEmail;
  List<String> allFirms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      // Load user data from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();
      
      setState(() {
        userName = userData?['name'] ?? 'User'; // Get name from Firestore
        userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Not signed in';
      });
      
      // Load current firm
      final currentFirmId = userData?['assignedFirmId'];
      
      if (currentFirmId != null && currentFirmId.isNotEmpty) {
        final firmDoc = await FirebaseFirestore.instance.collection('firms').doc(currentFirmId).get();
        setState(() {
          currentFirmName = firmDoc.data()?['firmName'] ?? 'No Firm Assigned';
        });
      } else {
        setState(() {
          currentFirmName = 'No Firm Assigned';
        });
      }
      
      // Load all firms owned by the user
      final snapshot = await FirebaseFirestore.instance
          .collection('firms')
          .where('ownerId', isEqualTo: uid)
          .get();

      setState(() {
        allFirms = snapshot.docs
            .map((doc) => doc.data()['firmName'] as String? ?? 'Unnamed Firm')
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = 'User';
        userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Not signed in';
        currentFirmName = 'Error loading firms';
        allFirms = [];
        isLoading = false;
      });
    }
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
              if (mounted) {
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

  Widget _buildUserInfoCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_outlined,
                  size: 30,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name
                    isLoading
                        ? SizedBox(
                            height: 20,
                            width: 120,
                            child: LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(10),
                              minHeight: 4,
                              color: colorScheme.primary,
                              backgroundColor: colorScheme.surfaceVariant,
                            ),
                          )
                        : Text(
                            userName ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(height: 4),
                    // User Email
                    Text(
                      userEmail ?? 'Not signed in',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Current Firm
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: isLoading
                              ? SizedBox(
                                  height: 16,
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 4,
                                    color: colorScheme.primary,
                                    backgroundColor: colorScheme.surfaceVariant,
                                  ),
                                )
                              : Text(
                                  "Current: ${currentFirmName ?? 'No Firm'}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // All Firms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.list_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: isLoading
                              ? SizedBox(
                                  height: 16,
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 4,
                                    color: colorScheme.primary,
                                    backgroundColor: colorScheme.surfaceVariant,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "All Firms:",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (allFirms.isEmpty)
                                      Text(
                                        "No firms registered",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: allFirms.map((firm) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: firm == currentFirmName
                                                  ? colorScheme.primary.withOpacity(0.1)
                                                  : colorScheme.surfaceVariant.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: firm == currentFirmName
                                                    ? colorScheme.primary.withOpacity(0.3)
                                                    : colorScheme.outline.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Text(
                                              firm,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: firm == currentFirmName
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurfaceVariant,
                                                fontWeight: firm == currentFirmName
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: backgroundColor ?? colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                if (trailing != null) trailing,
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Transform.scale(
                scale: 0.8,
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _logout,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sign out from your account",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.red.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text("About TrackSitePro"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TrackSitePro - SNGPL Contractors App",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Version: 1.0.0",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                "Build: 2024.01",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "TrackSitePro is a comprehensive construction management application designed specifically for SNGPL contractors to efficiently track and manage their construction projects, documents, and daily progress reports.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "© 2024 TrackSitePro. All rights reserved.",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text("Privacy Policy"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TrackSitePro - SNGPL Contractors App",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "1. Data Collection",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "We collect necessary information for SNGPL contractors including project details, document uploads, and daily progress reports to facilitate construction management.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "2. Data Usage",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "Your data is used solely for construction project management purposes within the SNGPL contractor ecosystem. We do not share your information with third parties without your consent.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "3. Data Security",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "We implement industry-standard security measures to protect your construction project data and documents.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "4. Contact",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "For privacy concerns related to SNGPL construction projects, contact: privacy@tracksitepro.com",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text("Terms of Service"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TrackSitePro - SNGPL Contractors Application",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "1. Acceptance of Terms",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "By using TrackSitePro, you agree to these terms as an SNGPL contractor for construction project management purposes.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "2. Contractor Responsibilities",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "SNGPL contractors are responsible for maintaining accurate project data, uploading valid documents, and ensuring compliance with construction regulations.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "3. Limitation of Liability",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "TrackSitePro is provided for SNGPL construction management without warranty. Contractors are responsible for their project data accuracy.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.03),
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // User Info Card with Name, Email, and All Firms
              _buildUserInfoCard(colorScheme),
              const SizedBox(height: 8),

              // Account Settings Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // Profile Management
              _buildSettingCard(
                icon: Icons.person_outline,
                title: "Profile Management",
                subtitle: "Update your personal information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileManagementScreen()),
                  );
                },
                iconColor: Colors.blue,
              ),

              // Supervisors
              _buildSettingCard(
                icon: Icons.supervisor_account_outlined,
                title: "Supervisors",
                subtitle: "Manage your site supervisors",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupervisorListScreen()),
                  );
                },
                iconColor: Colors.purple,
              ),

              // Switch Firm
              _buildSettingCard(
                icon: Icons.business_outlined,
                title: "Switch Firm",
                subtitle: "Change your active construction firm",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SwitchFirmScreen()),
                  );
                },
                iconColor: Colors.orange,
              ),

              // App Settings Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  "App Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // Notifications
              _buildSwitchSettingCard(
                icon: Icons.notifications_outlined,
                title: "Enable Notifications",
                subtitle: "Receive alerts and updates",
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() => notificationsEnabled = value);
                  // 🔔 Here you can integrate FirebaseMessaging subscribe/unsubscribe if needed
                },
                iconColor: Colors.green,
              ),

              // Dark Mode
              _buildSwitchSettingCard(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                subtitle: "Switch between light and dark themes",
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (value) {
                  // This should be implemented at the app level using a ThemeProvider
                  // For now, it will show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Theme switching requires app-level implementation"),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                },
                iconColor: Colors.indigo,
              ),

              // App Information Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  "App Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // About App
              _buildSettingCard(
                icon: Icons.info_outline,
                title: "About App",
                subtitle: "TrackSitePro for SNGPL Contractors",
                onTap: () => _showAboutDialog(context),
                iconColor: colorScheme.onSurfaceVariant,
              ),

              // Privacy Policy
              _buildSettingCard(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                subtitle: "SNGPL construction data privacy",
                onTap: () => _showPrivacyPolicy(context),
                iconColor: colorScheme.onSurfaceVariant,
              ),

              // Terms of Service
              _buildSettingCard(
                icon: Icons.description_outlined,
                title: "Terms of Service",
                subtitle: "SNGPL contractor agreement",
                onTap: () => _showTermsOfService(context),
                iconColor: colorScheme.onSurfaceVariant,
              ),

              // Logout Card
              _buildLogoutCard(colorScheme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}