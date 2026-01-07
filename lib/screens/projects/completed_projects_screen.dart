import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompletedProjectsScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> projects;
  const CompletedProjectsScreen({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ Sort by completedAt or createdAt (latest first)
    final sortedProjects = List<QueryDocumentSnapshot>.from(projects);
    sortedProjects.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = aData['completedAt'] != null
          ? (aData['completedAt'] as Timestamp).toDate()
          : (aData['createdAt'] != null
              ? (aData['createdAt'] as Timestamp).toDate()
              : DateTime(2000));
      final bDate = bData['completedAt'] != null
          ? (bData['completedAt'] as Timestamp).toDate()
          : (bData['createdAt'] != null
              ? (bData['createdAt'] as Timestamp).toDate()
              : DateTime(2000));
      return bDate.compareTo(aDate);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Completed Projects"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedProjects.length,
        itemBuilder: (context, index) {
          final data = sortedProjects[index].data() as Map<String, dynamic>;
          final boq = (data['boqValue'] ?? 0).toDouble();
          final expenses = (data['totalExpenses'] ?? 0).toDouble();
          final profit = boq - expenses;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: colorScheme.surface.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['projectTitle'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("BOQ: ${boq.toStringAsFixed(0)}"),
                    Text("Exp: ${expenses.toStringAsFixed(0)}"),
                    Text(
                      profit >= 0
                          ? "Profit: ${profit.toStringAsFixed(0)}"
                          : "Loss: ${profit.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
