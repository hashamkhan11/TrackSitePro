import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UploadDprScreen extends StatefulWidget {
  final String? projectId;
  final String? projectTitle;

  const UploadDprScreen({super.key, this.projectId, this.projectTitle});

  @override
  State<UploadDprScreen> createState() => _UploadDprScreenState();
}

class _UploadDprScreenState extends State<UploadDprScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  String fitterWelderName = '';
  String location = '';
  DateTime? dprDate;
  String remarks = '';

  String? selectedProjectId;
  String? selectedProjectTitle;
  List<QueryDocumentSnapshot> activeProjects = [];
  bool isLoading = true;

  List<WorkItemProgress> workItemsProgress = [];

  String userRole = '';
  bool isSupervisor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();

    if (widget.projectId != null) {
      selectedProjectId = widget.projectId;
      selectedProjectTitle = widget.projectTitle;
      _loadProjectWorkItems();
    } else {
      _loadProjects();
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (mounted) {
        setState(() {
          userRole = userDoc.data()?['role'] ?? '';
          isSupervisor = userRole.toLowerCase() == 'supervisor';
        });
      }
    } catch (e) {
      debugPrint("Error loading user role: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.projectId == null) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      final firmId = userDoc.data()?['assignedFirmId'];
      final role = userDoc.data()?['role'];
      final email = userDoc.data()?['email'];

      Query query = FirebaseFirestore.instance
          .collection('projects')
          .where('firmId', isEqualTo: firmId)
          .where('status', whereIn: ['Active', 'Delayed']);

      if (role == 'supervisor' && email != null) {
        query = query.where('assignedSupervisor', isEqualTo: email);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          activeProjects = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading projects: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: ${e.toString()}')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadProjectWorkItems() async {
    if (selectedProjectId == null) return;

    try {
      setState(() => isLoading = true);

      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(selectedProjectId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!projectDoc.exists) {
        throw Exception("Project not found");
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;
      final workItems = projectData['workItems'] as List<dynamic>? ?? [];

      setState(() {
        workItemsProgress = workItems.map((item) {
          return WorkItemProgress(
            code: item['code'] ?? '',
            description: item['description'] ?? '',
            unit: item['unit'] ?? '',
            rate: (item['rate'] ?? 0).toDouble(),
            totalQuantity: (item['quantity'] ?? 0).toDouble(),
            completedQuantity: 0.0,
            todayProgress: 0.0,
          );
        }).toList();
        isLoading = false;
      });

      await _loadExistingProgress();
    } catch (e) {
      debugPrint("Error loading work items: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadExistingProgress() async {
    if (selectedProjectId == null) return;

    try {
      final dprsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(selectedProjectId)
          .collection('dprs')
          .get()
          .timeout(const Duration(seconds: 10));

      // Create a map to accumulate progress for each work item
      Map<String, double> progressMap = {};

      for (var workItem in workItemsProgress) {
        progressMap[workItem.code] = 0.0;
      }

      // Sum up all progress from DPRs
      for (var dpr in dprsSnapshot.docs) {
        final dprData = dpr.data();
        final workProgress = dprData['workProgress'] as List<dynamic>? ?? [];

        for (var progress in workProgress) {
          final code = progress['code'];
          final todayProgress = (progress['todayProgress'] ?? 0).toDouble();
          if (progressMap.containsKey(code)) {
            progressMap[code] = (progressMap[code] ?? 0.0) + todayProgress;
          }
        }
      }

      // Update work items with accumulated progress
      setState(() {
        for (var workItem in workItemsProgress) {
          workItem.completedQuantity = progressMap[workItem.code] ?? 0.0;
        }
      });
    } catch (e) {
      debugPrint("Error loading existing progress: $e");
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dprDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _updateTodayProgress(WorkItemProgress item, String value) {
    final progress = double.tryParse(value) ?? 0.0;
    setState(() {
      item.todayProgress = progress;
    });
  }

  double _calculateTotalValue() {
    return workItemsProgress.fold<double>(
      0.0,
      (sum, item) => sum + (item.todayProgress * item.rate),
    );
  }

  Future<void> _submitDpr() async {
    if (!_formKey.currentState!.validate()) return;
    if (dprDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select DPR date')),
      );
      return;
    }
    if (selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    final hasProgress = workItemsProgress.any((item) => item.todayProgress > 0);
    if (!hasProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter progress for at least one work item')),
      );
      return;
    }

    for (var item in workItemsProgress) {
      final remaining = item.totalQuantity - item.completedQuantity;
      if (item.todayProgress > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Progress for ${item.code} exceeds remaining quantity.\n'
              'Remaining: ${remaining.toStringAsFixed(2)} ${item.unit}',
            ),
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      final workProgressData = workItemsProgress
          .where((item) => item.todayProgress > 0)
          .map((item) => {
                'code': item.code,
                'description': item.description,
                'unit': item.unit,
                'rate': item.rate,
                'todayProgress': item.todayProgress,
                'progressValue': item.todayProgress * item.rate,
              })
          .toList();

      final dprRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(selectedProjectId)
          .collection('dprs');

      await dprRef
          .add({
            'fitterWelderName': fitterWelderName.trim(),
            'location': location.trim(),
            'date': Timestamp.fromDate(dprDate!),
            'remarks': remarks.trim(),
            'workProgress': workProgressData,
            'totalProgressValue': _calculateTotalValue(),
            'submittedBy': user.email,
            'submittedAt': FieldValue.serverTimestamp(),
            'createdAt': Timestamp.now(),
          })
          .timeout(const Duration(seconds: 15));

      await _updateProjectProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DPR submitted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        _resetForm();
      }
    } catch (e) {
      debugPrint("Error submitting DPR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _dateController.clear();
    fitterWelderName = '';
    location = '';
    dprDate = null;
    remarks = '';
    
    setState(() {
      for (var item in workItemsProgress) {
        item.todayProgress = 0.0;
      }
    });
    
    if (selectedProjectId != null) {
      _loadExistingProgress();
    }
  }

  Future<void> _updateProjectProgress() async {
    if (selectedProjectId == null) return;

    try {
      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(selectedProjectId);

      final projectSnap = await projectRef.get();
      final projectData = projectSnap.data() as Map<String, dynamic>;

      final totalBoqValue = (projectData['totalBoqValue'] ?? 0).toDouble();
      if (totalBoqValue == 0) return;

      final dprsSnapshot = await projectRef.collection('dprs').get();
      double totalCompletedValue = 0.0;

      for (var dpr in dprsSnapshot.docs) {
        final dprData = dpr.data();
        totalCompletedValue += (dprData['totalProgressValue'] ?? 0).toDouble();
      }

      final progressPercentage = (totalCompletedValue / totalBoqValue) * 100;

      String status = 'Active';
      if (progressPercentage >= 100) {
        status = 'Completed';
      } else {
        final completionDate = (projectData['completionDate'] as Timestamp?)?.toDate();
        if (completionDate != null && DateTime.now().isAfter(completionDate)) {
          status = 'Delayed';
        }
      }

      await projectRef.update({
        'progress': progressPercentage.clamp(0.0, 100.0),
        'totalCompletedValue': totalCompletedValue,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating project progress: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload DPR"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (widget.projectId == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh projects',
              onPressed: () {
                setState(() => isLoading = true);
                _loadProjects();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.projectId == null)
                        Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedProjectId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Project',
                                prefixIcon: const Icon(Icons.workspaces_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              items: activeProjects.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(
                                    "${data['workOrderNo'] ?? data['jobNo'] ?? ''} - ${data['projectTitle'] ?? ''}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedProjectId = val;
                                  final selectedDoc =
                                      activeProjects.firstWhere((doc) => doc.id == val);
                                  final data = selectedDoc.data() as Map<String, dynamic>;
                                  selectedProjectTitle =
                                      data['projectTitle'] ?? data['workOrderNo'] ?? 'Project';
                                });
                                _loadProjectWorkItems();
                              },
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                            if (activeProjects.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'No active projects found. Please create a project first.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        )
                      else
                        TextFormField(
                          initialValue: selectedProjectTitle,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Project',
                            prefixIcon: const Icon(Icons.workspaces_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: 'DPR Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Fitter/Welder Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        onChanged: (val) => fitterWelderName = val,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.place_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        onChanged: (val) => location = val,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Work Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (workItemsProgress.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _showProgressSummary(context),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Summary'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (workItemsProgress.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No work items found for this project.\nPlease select a project with work items.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        _buildWorkItemsProgressList(colorScheme),

                      const SizedBox(height: 14),

                      TextFormField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Remarks (Optional)',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        onChanged: (val) => remarks = val,
                      ),
                      const SizedBox(height: 20),

                      // Only show financial summary for non-supervisors
                      if (workItemsProgress.isNotEmpty && !isSupervisor)
                        Card(
                          color: colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\'s Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Work Value: PKR ${_calculateTotalValue().toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Show work items count for supervisors
                      if (workItemsProgress.isNotEmpty && isSupervisor)
                        Card(
                          color: colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\'s Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${workItemsProgress.where((item) => item.todayProgress > 0).length} work item(s) in progress',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: workItemsProgress.isEmpty ? null : _submitDpr,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Submit DPR"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWorkItemsProgressList(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: workItemsProgress.map((item) {
          final remaining = item.totalQuantity - item.completedQuantity;
          final progressPercent =
              (item.completedQuantity / item.totalQuantity * 100).clamp(0.0, 100.0);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ExpansionTile(
              title: Text(
                '${item.code} - ${item.description}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Hide rate for supervisors
                  if (!isSupervisor)
                    Text('Rate: PKR ${item.rate.toStringAsFixed(2)} / ${item.unit}'),
                  if (!isSupervisor)
                    const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressPercent >= 100 ? Colors.green : colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${progressPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Qty: ${item.totalQuantity} ${item.unit}'),
                          Text(
                            'Completed: ${item.completedQuantity.toStringAsFixed(2)} ${item.unit}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining: ${remaining.toStringAsFixed(2)} ${item.unit}',
                        style: TextStyle(
                          color: remaining > 0 ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Today\'s Progress (${item.unit})',
                          border: const OutlineInputBorder(),
                          hintText: 'Max: ${remaining.toStringAsFixed(2)}',
                          suffixText: item.unit,
                        ),
                        onChanged: (val) => _updateTodayProgress(item, val),
                      ),
                      // Hide value calculation for supervisors
                      if (item.todayProgress > 0 && !isSupervisor)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Today\'s Value: PKR ${(item.todayProgress * item.rate).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showProgressSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Project Progress Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: workItemsProgress.map((item) {
              final progressPercent =
                  (item.completedQuantity / item.totalQuantity * 100).clamp(0.0, 100.0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: progressPercent / 100),
                    const SizedBox(height: 2),
                    Text(
                      '${item.completedQuantity.toStringAsFixed(2)} / ${item.totalQuantity} ${item.unit} (${progressPercent.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class WorkItemProgress {
  final String code;
  final String description;
  final String unit;
  final double rate;
  final double totalQuantity;
  double completedQuantity;
  double todayProgress;

  WorkItemProgress({
    required this.code,
    required this.description,
    required this.unit,
    required this.rate,
    required this.totalQuantity,
    required this.completedQuantity,
    required this.todayProgress,
  });
}