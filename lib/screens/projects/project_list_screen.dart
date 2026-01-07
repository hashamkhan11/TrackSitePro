import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/expenses/ExpenseHistoryScreen.dart';
import 'package:track_site_pro_app/screens/projects/add_project_screen.dart';
import 'package:track_site_pro_app/screens/projects/edit_project_screen.dart';
import 'package:track_site_pro_app/screens/dpr/upload_dpr_screen.dart';
import 'package:track_site_pro_app/screens/dpr/dpr_history_screen.dart';
import 'package:track_site_pro_app/screens/documents/DocumentListScreen.dart';
import 'package:track_site_pro_app/screens/resources/ResourceHistoryScreen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> with WidgetsBindingObserver {
  String searchQuery = '';
  String? firmId;
  String filter = 'All';

  final List<String> _filters = const ['All', 'Active', 'Delayed', 'Completed'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFirmId();
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

  Future<void> _loadFirmId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          firmId = userDoc.data()?['assignedFirmId'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load firm: $e')),
        );
      }
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    final date = ts.toDate();
    return "${date.day}-${date.month}-${date.year}";
  }

  Future<void> _deleteProject(BuildContext context, String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Project"),
        content: const Text(
          "Are you sure you want to permanently delete this project and ALL its DPRs, documents, expenses and resources?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
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

      await deleteSubcollection('dprs');
      await deleteSubcollection('documents');
      await deleteSubcollection('expenses');
      await deleteSubcollection('resources');
      await projectRef.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project deleted permanently")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }

  Widget _buildStatusChip(String? status, ColorScheme colors) {
    final s = (status ?? '').trim();
    if (s.isEmpty) return const SizedBox.shrink();

    Color bg;
    Color fg;
    IconData icon;

    switch (s) {
      case 'Active':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        icon = Icons.play_arrow_rounded;
        break;
      case 'Delayed':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        icon = Icons.warning_amber_rounded;
        break;
      case 'Completed':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        break;
      default:
        bg = colors.surfaceVariant;
        fg = colors.onSurfaceVariant;
        icon = Icons.info_outline_rounded;
    }

    return Chip(
      label: Text(s),
      avatar: Icon(icon, size: 18, color: fg),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_rounded, size: 80, color: colors.primary.withOpacity(.35)),
            const SizedBox(height: 12),
            Text(
              'No projects found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface),
            ),    
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => searchQuery = v.toLowerCase().trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search by job no, location, title',
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchQuery = '');
                    },
                  ),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 0.5),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => filter = f),
                      selectedColor: colors.primaryContainer,
                      labelStyle: TextStyle(
                        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: firmId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('firmId', isEqualTo: firmId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load projects: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var projects = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    ...data,
                  };
                }).toList();

                if (filter != 'All') {
                  projects = projects
                      .where((p) => (p['status'] ?? '').toString().toLowerCase() == filter.toLowerCase())
                      .toList();
                }

                const order = {"Active": 0, "Delayed": 1, "Completed": 2};
                projects.sort((a, b) {
                  final statusA = (a['status'] ?? '').toString();
                  final statusB = (b['status'] ?? '').toString();
                  return (order[statusA] ?? 99).compareTo(order[statusB] ?? 99);
                });

                projects = projects.where((data) {
                  final jobNo = data['jobNo']?.toString().toLowerCase() ?? '';
                  final location = data['location']?.toString().toLowerCase() ?? '';
                  final title = data['projectTitle']?.toString().toLowerCase() ?? '';
                  final workOrderNo = data['workOrderNo']?.toString().toLowerCase() ?? '';
                  final q = searchQuery.toLowerCase();
                  return jobNo.contains(q) || 
                         location.contains(q) || 
                         title.contains(q) || 
                         workOrderNo.contains(q);
                }).toList();

                if (projects.isEmpty) return _buildEmptyState(colors);

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final data = projects[index];
                    return _ProjectCard(
                      data: data,
                      colors: colors,
                      onDelete: () => _deleteProject(context, data['id']),
                      formatDate: _formatDate,
                      buildStatusChip: _buildStatusChip,
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProjectScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Project"),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ColorScheme colors;
  final VoidCallback onDelete;
  final String Function(Timestamp?) formatDate;
  final Widget Function(String?, ColorScheme) buildStatusChip;

  const _ProjectCard({
    required this.data,
    required this.colors,
    required this.onDelete,
    required this.formatDate,
    required this.buildStatusChip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((data['progress'] ?? 0.0) as num).toDouble();
    final totalBoqValue = ((data['totalBoqValue'] ?? 0) as num).toDouble();
    final totalCompletedValue = ((data['totalCompletedValue'] ?? 0) as num).toDouble();
    final isCompleted = data['status'] == 'Completed';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16),
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
                            Row(
                              children: [
                                if (data['workOrderNo'] != null && data['workOrderNo'].toString().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.primary.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'WO: ${data['workOrderNo']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                if (data['jobNo'] != null && data['jobNo'].toString().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.secondary.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Job: ${data['jobNo']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colors.secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['projectTitle'] ?? 'Untitled Project',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text("Delete Project", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      buildStatusChip(data['status'], colors),
                      if (data['jobType'] != null && data['jobType'].toString().isNotEmpty)
                        Chip(
                          label: Text(data['jobType']),
                          backgroundColor: colors.surfaceContainerHighest,
                          labelStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Project Details - Compact Horizontal Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CompactInfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: data['location']?.toString() ?? '-',
                          colors: colors,
                        ),
                      ),
                      Container(width: 1, height: 30, color: colors.outlineVariant.withOpacity(0.3)),
                      Expanded(
                        child: _CompactInfoItem(
                          icon: Icons.map_outlined,
                          label: 'Region',
                          value: data['region']?.toString() ?? '-',
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactInfoItem(
                          icon: Icons.calendar_today,
                          label: 'Start',
                          value: formatDate(data['startDate']),
                          colors: colors,
                        ),
                      ),
                      Container(width: 1, height: 30, color: colors.outlineVariant.withOpacity(0.3)),
                      Expanded(
                        child: _CompactInfoItem(
                          icon: Icons.event_available,
                          label: 'End',
                          value: formatDate(data['completionDate']),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Financial Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  final remainingBoq = totalBoqValue - totalCompletedValue;
                  final profit = totalCompletedValue - totalExpenses;

                  return Column(
                    children: [
                      // Financial Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _FinanceItem(
                                    label: "Total BOQ",
                                    value: "PKR ${totalBoqValue.toStringAsFixed(0)}",
                                    colors: colors,
                                  ),
                                ),
                                Expanded(
                                  child: _FinanceItem(
                                    label: "Completed",
                                    value: "PKR ${totalCompletedValue.toStringAsFixed(0)}",
                                    colors: colors,
                                    valueColor: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _FinanceItem(
                                    label: "Total Expense",
                                    value: "PKR ${totalExpenses.toStringAsFixed(0)}",
                                    colors: colors,
                                    valueColor: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _FinanceItem(
                                    label: isCompleted ? (profit >= 0 ? "Profit" : "Loss") : "Remaining",
                                    value: isCompleted 
                                        ? "PKR ${profit.abs().toStringAsFixed(0)}"
                                        : "PKR ${remainingBoq.toStringAsFixed(0)}",
                                    colors: colors,
                                    valueColor: isCompleted
                                        ? (profit >= 0 ? Colors.green : Colors.red)
                                        : (remainingBoq > 0 ? Colors.blue : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                "${progress.toStringAsFixed(1)}%",
                                style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (progress / 100).clamp(0.0, 1.0),
                              backgroundColor: colors.surfaceContainerHighest,
                              color: colors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.3),
                border: Border(top: BorderSide(color: colors.outlineVariant, width: 0.5)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      colors: colors,
                      onTap: () {
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
                    ),
                    _ActionButton(
                      icon: Icons.upload_file_outlined,
                      label: 'Upload DPR',
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UploadDprScreen(
                              projectId: data['id'],
                              projectTitle: data['projectTitle'],
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.history_outlined,
                      label: 'DPR History',
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DprHistoryScreen(
                              projectId: data['id'],
                              projectTitle: data['projectTitle'],
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Expenses',
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpenseHistoryScreen(
                              projectId: data['id'],
                              projectTitle: data['projectTitle'] ?? 'Project',
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.folder_outlined,
                      label: 'Documents',
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentListScreen(
                              projectId: data['id'],
                              projectTitle: data['projectTitle'] ?? 'Project',
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.inventory_2_outlined,
                      label: 'Materials',
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResourceHistoryScreen(
                              projectId: data['id'],
                              projectTitle: data['projectTitle'] ?? 'Project',
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
      ),
    );
  }
}

class _CompactInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;

  const _CompactInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceItem extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colors;
  final Color? valueColor;

  const _FinanceItem({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? colors.onSurface,
          ),
        ),
      ],
    );
  }
}