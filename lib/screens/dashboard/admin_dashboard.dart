// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_site_pro_app/screens/schedule_rates/schedule_of_rates_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final firestore = FirebaseFirestore.instance;
  Map<String, bool> isLoadingMap = {};
  int _selectedIndex = 0;

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ContractorManagementScreen(),
      const ScheduleOfRatesManagementScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0 
            ? const Text("Admin Panel - Contractors")
            : const Text("Admin Panel - Schedule Rates"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Contractors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Schedule Rates',
          ),
        ],
      ),
    );
  }
}

// Enhanced Contractor Management Screen with Tabs
class ContractorManagementScreen extends StatefulWidget {
  const ContractorManagementScreen({super.key});

  @override
  State<ContractorManagementScreen> createState() => _ContractorManagementScreenState();
}

class _ContractorManagementScreenState extends State<ContractorManagementScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Pending',
              ),
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Approved',
              ),
              Tab(
                icon: Icon(Icons.cancel),
                text: 'Rejected',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              PendingContractorsTab(),
              ApprovedContractorsTab(),
              RejectedContractorsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// Pending Contractors Tab
class PendingContractorsTab extends StatefulWidget {
  const PendingContractorsTab({super.key});

  @override
  State<PendingContractorsTab> createState() => _PendingContractorsTabState();
}

class _PendingContractorsTabState extends State<PendingContractorsTab> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, bool> isLoadingMap = {};

  Future<void> _viewPECLicense(String base64Image, String fileName, BuildContext context) async {
    if (base64Image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PEC license uploaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final decodedImage = base64Decode(base64Image);
      
      // Calculate file sizes
      final originalSize = base64Image.length;
      final decodedSize = decodedImage.length;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PEC License'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Base64: ${(originalSize / 1024).toStringAsFixed(1)} KB | '
                  'Decoded: ${(decodedSize / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      decodedImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 40),
                              SizedBox(height: 8),
                              Text('Cannot display image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Actions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final data = ClipboardData(text: base64Image);
                          await Clipboard.setData(data);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Base64 data copied to clipboard'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error copying data: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Base64'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // You could add download functionality here if needed
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error decoding image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> approveContractor(String contractorId, String name, String email) async {
    setState(() => isLoadingMap[contractorId] = true);

    try {
      await firestore.collection('users').doc(contractorId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
      });

      // Send approval notification
      await firestore
          .collection('notifications')
          .doc(contractorId)
          .collection('user_notifications')
          .add({
        'title': 'Application Approved',
        'body': 'Your contractor application has been approved! You can now login and access the system.',
        'notificationType': 'approval',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Approved $name successfully! Notification sent.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving $name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingMap[contractorId] = false);
      }
    }
  }

  Future<void> rejectContractor(String contractorId, String name, String email) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => RejectContractorDialog(contractorName: name),
    );

    if (result == null) return;

    setState(() => isLoadingMap[contractorId] = true);

    try {
      await firestore.collection('users').doc(contractorId).update({
        'status': 'rejected',
        'rejectionReason': result['reason'],
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
      });

      // Store rejection notification
      await firestore
          .collection('notifications')
          .doc(contractorId)
          .collection('user_notifications')
          .add({
        'title': 'Application Rejected',
        'body': 'Your contractor application has been rejected. Reason: ${result['reason']}',
        'notificationType': 'rejection',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Rejected $name. Notification sent.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting $name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingMap[contractorId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('users')
          .where('role', isEqualTo: 'contractor')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending contractors',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final contractors = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: contractors.length,
          itemBuilder: (context, index) {
            final contractor = contractors[index];
            final contractorId = contractor.id;
            final data = contractor.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? 'No Email';
            final phone = data['phone'] ?? 'N/A';
            final pecNumber = data['pecNumber'] ?? 'Not Provided';
            final firmName = data['firmName'] ?? 'Not Provided';
            final pecLicenseImage = data['pecLicenseImage'] ?? '';
            final pecFileName = data['pecFileName'] ?? 'PEC License';
            final createdAt = data['createdAt'] as Timestamp?;
            final emailVerified = data['emailVerified'] ?? false;

            final isLoading = isLoadingMap[contractorId] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: emailVerified ? Colors.green[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: emailVerified ? Colors.green : Colors.orange,
                            ),
                          ),
                          child: Text(
                            emailVerified ? 'Email Verified' : 'Email Not Verified',
                            style: TextStyle(
                              color: emailVerified ? Colors.green : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Firm Name
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Firm: $firmName',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // PEC Number
                    Row(
                      children: [
                        Icon(Icons.badge, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'PEC No: $pecNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // PEC License Section
                    if (pecLicenseImage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.image,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PEC License:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    pecFileName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(pecLicenseImage.length / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.visibility,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              onPressed: () => _viewPECLicense(
                                pecLicenseImage,
                                pecFileName,
                                context,
                              ),
                              tooltip: 'View PEC License',
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No PEC License Uploaded',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 207, 45, 45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Other info
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (createdAt != null)
                          Text(
                            'Applied: ${_formatDate(createdAt.toDate())}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => approveContractor(contractorId, name, email),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => rejectContractor(contractorId, name, email),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Approved Contractors Tab
class ApprovedContractorsTab extends StatelessWidget {
  const ApprovedContractorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'contractor')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No approved contractors',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final contractors = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: contractors.length,
          itemBuilder: (context, index) {
            final contractor = contractors[index];
            final data = contractor.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? 'No Email';
            final phone = data['phone'] ?? 'N/A';
            final firmName = data['firmName'] ?? 'Not Provided';
            final pecNumber = data['pecNumber'] ?? 'Not Provided';
            final pecLicenseImage = data['pecLicenseImage'] ?? '';
            final pecFileName = data['pecFileName'] ?? 'PEC License';
            final approvedAt = data['approvedAt'] as Timestamp?;
            final approvedBy = data['approvedBy'] ?? 'Unknown';
            final emailVerified = data['emailVerified'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(
                    Icons.check,
                    color: Colors.green[700],
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    Text('Firm: $firmName'),
                    if (approvedAt != null)
                      Text(
                        'Approved: ${_formatDate(approvedAt.toDate())} by $approvedBy',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'APPROVED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      emailVerified ? Icons.verified : Icons.warning,
                      color: emailVerified ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PEC Number: $pecNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: emailVerified ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Email: ${emailVerified ? 'Verified' : 'Not Verified'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: emailVerified ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (pecLicenseImage.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PEC License: $pecFileName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  try {
                                    final decodedImage = base64Decode(pecLicenseImage);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('PEC License'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pecFileName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              height: 300,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(
                                                  decodedImage,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.error, color: Colors.red, size: 40),
                                                          SizedBox(height: 8),
                                                          Text('Cannot display image'),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error displaying image: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('View PEC License'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Rejected Contractors Tab
class RejectedContractorsTab extends StatelessWidget {
  const RejectedContractorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'contractor')
          .where('status', isEqualTo: 'rejected')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No rejected contractors',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final contractors = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: contractors.length,
          itemBuilder: (context, index) {
            final contractor = contractors[index];
            final data = contractor.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? 'No Email';
            final phone = data['phone'] ?? 'N/A';
            final firmName = data['firmName'] ?? 'Not Provided';
            final pecNumber = data['pecNumber'] ?? 'Not Provided';
            final pecLicenseImage = data['pecLicenseImage'] ?? '';
            final pecFileName = data['pecFileName'] ?? 'PEC License';
            final rejectedAt = data['rejectedAt'] as Timestamp?;
            final rejectedBy = data['rejectedBy'] ?? 'Unknown';
            final rejectionReason = data['rejectionReason'] ?? 'No reason provided';
            final emailVerified = data['emailVerified'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Icon(
                    Icons.cancel,
                    color: Colors.red[700],
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    Text('Firm: $firmName'),
                    if (rejectedAt != null)
                      Text(
                        'Rejected: ${_formatDate(rejectedAt.toDate())} by $rejectedBy',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'REJECTED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      emailVerified ? Icons.verified : Icons.warning,
                      color: emailVerified ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border(
                        top: BorderSide(color: Colors.red[100]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            rejectionReason,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PEC Number: $pecNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: emailVerified ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Email: ${emailVerified ? 'Verified' : 'Not Verified'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: emailVerified ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (pecLicenseImage.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PEC License: $pecFileName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  try {
                                    final decodedImage = base64Decode(pecLicenseImage);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('PEC License'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pecFileName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              height: 300,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(
                                                  decodedImage,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.error, color: Colors.red, size: 40),
                                                          SizedBox(height: 8),
                                                          Text('Cannot display image'),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error displaying image: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('View PEC License'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Reject Contractor Dialog
class RejectContractorDialog extends StatefulWidget {
  final String contractorName;

  const RejectContractorDialog({
    super.key,
    required this.contractorName,
  });

  @override
  State<RejectContractorDialog> createState() => _RejectContractorDialogState();
}

class _RejectContractorDialogState extends State<RejectContractorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  final List<String> _predefinedReasons = [
    'Incomplete documentation',
    'Invalid PEC credentials',
    'Does not meet requirements',
    'Duplicate application',
    'Fraudulent information',
    'Insufficient experience',
    'Unverifiable firm details',
    'Poor quality PEC license image',
    'Other (specify below)',
  ];

  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reject ${widget.contractorName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a reason for rejection:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.list),
                  hintText: 'Select reason',
                ),
                items: _predefinedReasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                    if (value != 'Other (specify below)') {
                      _reasonController.text = value ?? '';
                    } else {
                      _reasonController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: _selectedReason == 'Other (specify below)'
                      ? 'Specify reason *'
                      : 'Additional details (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes),
                  hintText: 'Enter detailed reason for rejection',
                ),
                maxLines: 4,
                validator: (value) {
                  if (_selectedReason == 'Other (specify below)') {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please specify the rejection reason';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The contractor will be notified about the rejection via Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final reason = _reasonController.text.trim().isNotEmpty
                  ? _reasonController.text.trim()
                  : _selectedReason!;
              
              Navigator.pop(context, {'reason': reason});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

// Schedule of Rates Management Screen (Keep as is from your original code)
class ScheduleOfRatesManagementScreen extends StatefulWidget {
  const ScheduleOfRatesManagementScreen({super.key});

  @override
  State<ScheduleOfRatesManagementScreen> createState() => _ScheduleOfRatesManagementScreenState();
}

class _ScheduleOfRatesManagementScreenState extends State<ScheduleOfRatesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<SORItem> _rates = [];
  List<SORItem> _filteredRates = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRates();
    _searchController.addListener(_filterRates);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _categories = ['All'];
          for (var doc in snapshot.docs) {
            if (doc['name'] != null) {
              _categories.add(doc['name'] as String);
            }
          }
        });
      } else {
        setState(() {
          _categories = ['All', ...ScheduleOfRates.getAllCategories()];
        });
      }
    } catch (e) {
      setState(() {
        _categories = ['All', ...ScheduleOfRates.getAllCategories()];
      });
    }
  }

  Future<void> _loadRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore.collection('schedule_of_rates').orderBy('code').get();
      
      if (snapshot.docs.isNotEmpty) {
        final loadedRates = snapshot.docs.map((doc) {
          return SORItem.fromFirestore(doc.id, doc.data());
        }).toList();
        
        setState(() {
          _rates = loadedRates;
          _filteredRates = loadedRates;
        });
      } else {
        setState(() {
          _rates = [];
          _filteredRates = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rates: $e')),
      );
      setState(() {
        _rates = [];
        _filteredRates = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRates() {
    final searchText = _searchController.text.toLowerCase();
    
    if (searchText.isEmpty && _selectedCategory == 'All') {
      setState(() {
        _filteredRates = _rates;
      });
      return;
    }

    final filtered = _rates.where((rate) {
      final matchesSearch = searchText.isEmpty ||
          rate.code.toLowerCase().contains(searchText) ||
          rate.description.toLowerCase().contains(searchText);
      
      if (_selectedCategory == 'All') return matchesSearch;
      
      final matchesCategory = rate.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
    
    setState(() {
      _filteredRates = filtered;
    });
  }

  Future<void> _addNewRate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddRateDialog(),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newRate = SORItem(
          code: result['code']!,
          description: result['description']!,
          unit: result['unit']!,
          rate: double.parse(result['rate']!),
          category: result['category']!,
        );

        final existingRates = await _firestore
            .collection('schedule_of_rates')
            .where('code', isEqualTo: result['code']!)
            .get();

        if (existingRates.docs.isNotEmpty) {
          throw Exception('Rate with code ${result['code']!} already exists!');
        }

        await _firestore.collection('schedule_of_rates').add(newRate.toMap());
        
        await _loadRates();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rate ${result['code']!} added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding rate: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editRate(SORItem rate) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddRateDialog(
        initialCode: rate.code,
        initialDescription: rate.description,
        initialUnit: rate.unit,
        initialRate: rate.rate.toString(),
        initialCategory: rate.category,
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedRate = rate.copyWith(
          code: result['code']!,
          description: result['description']!,
          unit: result['unit']!,
          rate: double.parse(result['rate']!),
          category: result['category']!,
        );

        await _firestore.collection('schedule_of_rates')
            .doc(rate.id!)
            .update(updatedRate.toMap());
        
        await _loadRates();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rate ${result['code']!} updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating rate: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRate(SORItem rate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rate'),
        content: Text('Are you sure you want to delete rate ${rate.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _firestore.collection('schedule_of_rates').doc(rate.id!).delete();
        
        await _loadRates();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rate ${rate.code} deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting rate: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Code or Description...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterRates();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, size: 30),
                    onPressed: _addNewRate,
                    tooltip: 'Add New Rate',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _filterRates();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total Rates: ${_filteredRates.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredRates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No rates found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the + button to add new rates',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredRates.length,
                      itemBuilder: (context, index) {
                        final rate = _filteredRates[index];
                        final isCustomRate = rate.category == ScheduleOfRates.CATEGORY_CUSTOM;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              rate.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCustomRate ? Colors.green : Colors.blue,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  rate.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${rate.rate} Rs.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'per ${rate.unit}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCustomRate ? Colors.green[50] : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isCustomRate ? Colors.green : Colors.blue,
                                    ),
                                  ),
                                  child: Text(
                                    rate.category,
                                    style: TextStyle(
                                      color: isCustomRate ? Colors.green : Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editRate(rate),
                                  tooltip: 'Edit Rate',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteRate(rate),
                                  tooltip: 'Delete Rate',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Dialog for adding/editing rates
class AddRateDialog extends StatefulWidget {
  final String? initialCode;
  final String? initialDescription;
  final String? initialUnit;
  final String? initialRate;
  final String? initialCategory;

  const AddRateDialog({
    super.key,
    this.initialCode,
    this.initialDescription,
    this.initialUnit,
    this.initialRate,
    this.initialCategory,
  });

  @override
  State<AddRateDialog> createState() => _AddRateDialogState();
}

class _AddRateDialogState extends State<AddRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _rateController = TextEditingController();
  
  String _selectedCategory = ScheduleOfRates.CATEGORY_CUSTOM;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) _codeController.text = widget.initialCode!;
    if (widget.initialDescription != null) _descriptionController.text = widget.initialDescription!;
    if (widget.initialUnit != null) _unitController.text = widget.initialUnit!;
    if (widget.initialRate != null) _rateController.text = widget.initialRate!;
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCode != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Rate' : 'Add New Rate'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code (e.g., CUSTOM-001)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g., m, sq.m, cu.m, No.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.square_foot),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Rate (in Rs.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ScheduleOfRates.getAllCategories().map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'code': _codeController.text,
                'description': _descriptionController.text,
                'unit': _unitController.text,
                'rate': _rateController.text,
                'category': _selectedCategory,
              });
            }
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}