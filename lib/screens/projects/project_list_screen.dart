import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/expenses/ExpenseHistoryScreen.dart';
import 'package:track_site_pro_app/screens/projects/add_project_screen.dart';
import 'package:track_site_pro_app/screens/projects/edit_project_screen.dart';
import 'package:track_site_pro_app/screens/documents/DocumentListScreen.dart';
import 'package:track_site_pro_app/screens/payments/PaymentHistoryScreen.dart';
import 'package:track_site_pro_app/screens/invoices/invoice_history_screen.dart';
import 'package:track_site_pro_app/services/currency_format.dart';

// Modern Color Palette - Clean & Professional Blue Theme
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
  
  // Payment status colors
  static const unpaidRed = Color(0xFFEF4444);
  static const partiallyPaidOrange = Color(0xFFF59E0B);
  static const fullyPaidGreen = Color(0xFF10B981);
}

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> with WidgetsBindingObserver {
  String searchQuery = '';
  String filter = 'All';
  final Map<String, String> _paymentStatusCache = {}; // Cache for payment status

  final List<String> _filters = const ['All', 'Unpaid', 'Partially Paid', 'Fully Paid'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    final date = ts.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  // Updated currency formatter with proper comma separation
  String _formatCurrency(double amount) {
    return formatPKR(amount);
  }

  Future<void> _deleteProject(BuildContext context, String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delete Project",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This will permanently delete this project and ALL its documents, expenses, payments, invoices and resources. This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.borderGray),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final projectRef = FirebaseFirestore.instance.collection('projects').doc(projectId);

      Future<void> deleteSubcollection(String name) async {
        final snap = await projectRef.collection(name).get();
        if (snap.docs.isEmpty) return;

        const int batchSize = 450;
        for (int i = 0; i < snap.docs.length; i += batchSize) {
          final batch = FirebaseFirestore.instance.batch();
          final chunk = snap.docs.sublist(i, (i + batchSize).clamp(0, snap.docs.length));
          for (var d in chunk) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }
      }

      await deleteSubcollection('documents');
      await deleteSubcollection('expenses');
      await deleteSubcollection('payments');
      await deleteSubcollection('resources');
      await deleteSubcollection('invoices');
      await projectRef.delete();

      // Clear cache for this project
      _paymentStatusCache.remove(projectId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Project deleted successfully"),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Delete failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Optimized function to determine payment status with caching
  Future<String> _getPaymentStatus(String projectId, double totalAmount) async {
    // Return from cache if available
    if (_paymentStatusCache.containsKey(projectId)) {
      return _paymentStatusCache[projectId]!;
    }

    try {
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('payments')
          .get();

      String status;

      if (paymentsSnapshot.docs.isEmpty) {
        status = 'Unpaid';
      } else {
        double totalPayments = 0;
        bool has50Percent = false;
        bool has80Percent = false;
        bool has100Percent = false;

        for (var doc in paymentsSnapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] ?? 0).toDouble();
          totalPayments += amount;
          
          final paymentType = data['paymentType'] ?? '';
          if (paymentType.contains('50%')) has50Percent = true;
          if (paymentType.contains('80%')) has80Percent = true;
          if (paymentType.contains('100%')) has100Percent = true;
        }

        if (has100Percent || totalPayments >= totalAmount) {
          status = 'Fully Paid';
        } else if (has50Percent || has80Percent || totalPayments > 0) {
          status = 'Partially Paid';
        } else {
          status = 'Unpaid';
        }
      }

      // Store in cache
      _paymentStatusCache[projectId] = status;
      return status;
    } catch (e) {
      return 'Unpaid';
    }
  }

  // Function to load all payment statuses in batch
  Future<Map<String, String>> _loadAllPaymentStatuses(List<Map<String, dynamic>> projects) async {
    final Map<String, String> statuses = {};
    final List<Future> futures = [];

    for (var project in projects) {
      final projectId = project['id'];
      final totalAmount = ((project['totalAmount'] ?? 0) as num).toDouble();
      
      futures.add(_getPaymentStatus(projectId, totalAmount).then((status) {
        statuses[projectId] = status;
      }));
    }

    await Future.wait(futures);
    return statuses;
  }

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
                color: AppColors.lightGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Projects Found",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Try adjusting your search or filter",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Unpaid':
        return AppColors.unpaidRed;
      case 'Partially Paid':
        return AppColors.partiallyPaidOrange;
      case 'Fully Paid':
        return AppColors.fullyPaidGreen;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(210),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderGray,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projects',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage all your construction projects',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => searchQuery = v.toLowerCase().trim()),
                            decoration: const InputDecoration(
                              hintText: 'Search by job no, work order, description...',
                              hintStyle: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = '');
                            },
                            color: AppColors.textTertiary,
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),

                // Filter Chips
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final f = _filters[index];
                      final selected = filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            filter = f;
                            _paymentStatusCache.clear(); // Clear cache when filter changes
                          }),
                          backgroundColor: Colors.white,
                          selectedColor: _getFilterColor(f),
                          side: BorderSide(
                            color: selected ? _getFilterColor(f) : AppColors.borderGray,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 3,
              ),
            );
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return _buildEmptyState();
          }
          final firmId = userSnapshot.data!.get('assignedFirmId');
          if (firmId == null) {
            return _buildEmptyState();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .where('firmId', isEqualTo: firmId)
                .snapshots(),
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 3,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load projects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 3,
                    ),
                  );
                }

                var projects = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    ...data,
                  };
                }).toList();

                // Filter projects by search query
                projects = projects.where((data) {
                  final jobNo = data['jobNo']?.toString().toLowerCase() ?? '';
                  final workOrderNo = data['workOrderNo']?.toString().toLowerCase() ?? '';
                  final tenderEnquiryNo = data['tenderEnquiryNo']?.toString().toLowerCase() ?? '';
                  final jobDescription = data['jobDescription']?.toString().toLowerCase() ?? '';
                  final q = searchQuery.toLowerCase();
                  return jobNo.contains(q) || 
                         workOrderNo.contains(q) || 
                         tenderEnquiryNo.contains(q) ||
                         jobDescription.contains(q);
                }).toList();

                if (projects.isEmpty) return _buildEmptyState();

                return FutureBuilder<Map<String, String>>(
                  future: _loadAllPaymentStatuses(projects),
                  builder: (context, statusSnapshot) {
                    if (statusSnapshot.connectionState == ConnectionState.waiting && _paymentStatusCache.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          strokeWidth: 3,
                        ),
                      );
                    }

                    final statuses = statusSnapshot.data ?? _paymentStatusCache;
                    
                    // Filter by payment status
                    List<Map<String, dynamic>> filteredProjects;
                    if (filter == 'All') {
                      filteredProjects = projects;
                    } else {
                      filteredProjects = projects.where((project) {
                        final status = statuses[project['id']] ?? 'Unpaid';
                        return status == filter;
                      }).toList();
                    }

                    if (filteredProjects.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final data = filteredProjects[index];
                        final paymentStatus = statuses[data['id']] ?? 'Unpaid';
                        
                        return _ProjectCard(
                          data: data,
                          paymentStatus: paymentStatus,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProjectScreen(
                                  projectId: data['id'],
                                  projectData: data,
                                ),
                              ),
                            );
                          },
                          onDelete: () => _deleteProject(context, data['id']),
                          formatDate: _formatDate,
                          formatCurrency: _formatCurrency,
                        );
                      },
                    );
                  },
                );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProjectScreen()),
          );
          if (created == true && mounted) {
            // Clear cached payment statuses so the new project appears fresh
            setState(() {
              _paymentStatusCache.clear();
            });
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Add Project",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String paymentStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(Timestamp?) formatDate;
  final String Function(double) formatCurrency;

  const _ProjectCard({
    required this.data,
    required this.paymentStatus,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = ((data['totalAmount'] ?? 0) as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Payment Status Badge
                          _buildPaymentStatusBadge(paymentStatus),
                          const SizedBox(height: 12),
                          
                          // Reference Numbers
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (data['workOrderNo'] != null && data['workOrderNo'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'WO ${data['workOrderNo']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              if (data['jobNo'] != null && data['jobNo'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderGray),
                                  ),
                                  child: Text(
                                    'Job #${data['jobNo']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              if (data['tenderEnquiryNo'] != null && data['tenderEnquiryNo'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderGray),
                                  ),
                                  child: Text(
                                    'TE ${data['tenderEnquiryNo']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Job Description
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGray),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.description_outlined, 
                                         size: 14, 
                                         color: AppColors.textTertiary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['jobDescription'] ?? 'No description',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // More Menu with Edit and Delete options - Consistently styled
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        } else if (value == 'payments') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentHistoryScreen(
                                projectId: data['id'],
                                projectTitle: data['jobDescription'] ?? 'Project',
                              ),
                            ),
                          );
                        } else if (value == 'invoices') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoiceHistoryScreen(
                                projectId: data['id'],
                                projectTitle: data['jobDescription'] ?? 'Project',
                              ),
                            ),
                          );
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 2,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          height: 48,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Edit Project",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          height: 48,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Delete Project",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'payments',
                          height: 44,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.payment_rounded,
                                  color: AppColors.successGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "View Payments",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'invoices',
                          height: 44,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.receipt_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "View Invoices",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Single Date Field
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Project Date: ${formatDate(data['date'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Financial Summary - Project Value and Expenses with proper formatting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(data['id'])
                  .collection('expenses')
                  .snapshots(),
              builder: (context, expenseSnap) {
                double totalExpenses = 0.0;
                if (expenseSnap.hasData) {
                  for (var doc in expenseSnap.data!.docs) {
                    final expData = doc.data() as Map<String, dynamic>;
                    totalExpenses += (expData['amount'] ?? 0).toDouble();
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFinanceItem(
                          "Project Value",
                          "PKR ${formatCurrency(totalAmount)}",
                          AppColors.primaryBlue,
                        ),
                      ),
                      Expanded(
                        child: _buildFinanceItem(
                          "Total Expenses",
                          "PKR ${formatCurrency(totalExpenses)}",
                          AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Supervisor Information (if assigned)
          if (data['siteSupervisorName'] != null && data['siteSupervisorName'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.supervised_user_circle_rounded,
                      color: AppColors.successGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Site Supervisor',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['siteSupervisorName'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons (without Edit button)
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderGray, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Expenses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseHistoryScreen(
                            projectId: data['id'],
                            projectTitle: data['jobDescription'] ?? 'Project',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.folder_rounded,
                    label: 'Documents',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentListScreen(
                            projectId: data['id'],
                            projectTitle: data['jobDescription'] ?? 'Project',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Unpaid':
        bgColor = AppColors.unpaidRed.withOpacity(0.1);
        textColor = AppColors.unpaidRed;
        icon = Icons.cancel_rounded;
        break;
      case 'Partially Paid':
        bgColor = AppColors.partiallyPaidOrange.withOpacity(0.1);
        textColor = AppColors.partiallyPaidOrange;
        icon = Icons.hourglass_top_rounded;
        break;
      case 'Fully Paid':
        bgColor = AppColors.fullyPaidGreen.withOpacity(0.1);
        textColor = AppColors.fullyPaidGreen;
        icon = Icons.check_circle_rounded;
        break;
      default:
        bgColor = AppColors.lightGray;
        textColor = AppColors.textSecondary;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}