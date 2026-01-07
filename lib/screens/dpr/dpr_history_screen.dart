import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DprHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const DprHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<DprHistoryScreen> createState() => _DprHistoryScreenState();
}

class _DprHistoryScreenState extends State<DprHistoryScreen> {
  List<QueryDocumentSnapshot> dprList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDprs();
  }

  Future<void> _fetchDprs() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('dprs')
          .orderBy('date', descending: true)
          .get();

      if (mounted) {
        setState(() {
          dprList = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching DPRs: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading DPRs: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteDpr(String dprId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete DPR"),
        content: const Text(
          "Are you sure you want to delete this DPR?\n\n"
          "This will recalculate the project progress.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('dprs')
          .doc(dprId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("DPR deleted successfully")),
        );
      }

      await _recalculateProjectProgress();
      await _fetchDprs();
    } catch (e) {
      debugPrint("Error deleting DPR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting DPR: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final date = ts.toDate();
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return 'N/A';
  }

  Future<void> _recalculateProjectProgress() async {
    try {
      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId);

      final projectSnap = await projectRef.get();
      if (!projectSnap.exists) return;

      final projectData = projectSnap.data() as Map<String, dynamic>;
      final totalBoqValue = (projectData['totalBoqValue'] ?? 0).toDouble();

      if (totalBoqValue == 0) return;

      // Calculate total completed value from all remaining DPRs
      final dprsSnapshot = await projectRef.collection('dprs').get();
      double totalCompletedValue = 0.0;

      for (var dpr in dprsSnapshot.docs) {
        final dprData = dpr.data();
        totalCompletedValue += (dprData['totalProgressValue'] ?? 0).toDouble();
      }

      final progressPercentage = (totalCompletedValue / totalBoqValue) * 100;

      // Determine status
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
      debugPrint("Error recalculating project progress: $e");
    }
  }

  void _showDprDetails(Map<String, dynamic> data) {
    final workProgress = data['workProgress'] as List<dynamic>? ?? [];
    final totalProgressValue = (data['totalProgressValue'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DPR Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Date', _formatDate(data['date'])),
              _buildDetailRow('Fitter/Welder', data['fitterWelderName'] ?? '-'),
              _buildDetailRow('Location', data['location'] ?? '-'),
              _buildDetailRow('Submitted By', data['submittedBy'] ?? '-'),
              if (data['remarks'] != null && data['remarks'].toString().isNotEmpty)
                _buildDetailRow('Remarks', data['remarks']),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Work Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (workProgress.isEmpty)
                const Text('No work progress recorded', style: TextStyle(fontStyle: FontStyle.italic))
              else
                ...workProgress.map((item) {
                  final code = item['code'] ?? '';
                  final description = item['description'] ?? '';
                  final unit = item['unit'] ?? '';
                  final rate = (item['rate'] ?? 0).toDouble();
                  final todayProgress = (item['todayProgress'] ?? 0).toDouble();
                  final progressValue = (item['progressValue'] ?? 0).toDouble();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quantity: $todayProgress $unit'),
                              Text('Rate: PKR ${rate.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Value: PKR ${progressValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Work Value:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'PKR ${totalProgressValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
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
        title: Text("${widget.projectTitle} - DPR History"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dprList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 80,
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No DPR entries found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Upload a DPR to see it here",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDprs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: dprList.length,
                    itemBuilder: (context, index) {
                      final dpr = dprList[index];
                      final data = dpr.data() as Map<String, dynamic>;
                      final workProgress = data['workProgress'] as List<dynamic>? ?? [];
                      final totalProgressValue = (data['totalProgressValue'] ?? 0).toDouble();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDprDetails(data),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatDate(data['date']),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete DPR',
                                      onPressed: () => _deleteDpr(dpr.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      data['fitterWelderName'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: 18,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        data['location'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Work Items: ${workProgress.length}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'PKR ${totalProgressValue.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (workProgress.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        ...workProgress.take(2).map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${item['code']} - ${item['description']}',
                                                    style: const TextStyle(fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${(item['todayProgress'] ?? 0).toStringAsFixed(2)} ${item['unit']}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        if (workProgress.length > 2)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '+${workProgress.length - 2} more items',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (data['remarks'] != null && 
                                    data['remarks'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.notes_outlined,
                                        size: 16,
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          data['remarks'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'By: ${data['submittedBy'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}