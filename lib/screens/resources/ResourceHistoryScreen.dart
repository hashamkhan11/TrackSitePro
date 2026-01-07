// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'AddResourceScreen.dart';
import 'package:intl/intl.dart';

class ResourceHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ResourceHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ResourceHistoryScreen> createState() => _ResourceHistoryScreenState();
}

class _ResourceHistoryScreenState extends State<ResourceHistoryScreen> {
  double _totalResourcesCost = 0.0;

  Future<void> _deleteResource(BuildContext context, String resourceId, String materialName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Delete Resource"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to delete this resource?",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(
                "Material: $materialName",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: const Text(
                "⚠️ Associated expense will also be deleted",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
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
      // Delete the resource
      await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("resources")
          .doc(resourceId)
          .delete();

      // Delete associated expense
      final expenseQuery = await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("expenses")
          .where("resourceId", isEqualTo: resourceId)
          .get();

      for (var expenseDoc in expenseQuery.docs) {
        await expenseDoc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Resource and associated expense deleted successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildResourceCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    final category = data['category'] ?? 'Unknown';
    final materialName = category == "Other" 
        ? data['materialName'] ?? 'Custom Material'
        : category;
    final quantity = (data['quantity'] ?? 0).toString();
    final pricePerUnit = (data['pricePerUnit'] ?? 0.0).toDouble();
    final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
    final note = data['note'] ?? '';
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showResourceDetails(context, data, materialName, date);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Icon/Indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCategoryColor(category).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      materialName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _getCategoryColor(category),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Resource Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Material Name
                      Text(
                        materialName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Quantity and Price
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.scale, size: 12, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  "$quantity units",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_money, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  "PKR ${pricePerUnit.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Total Cost and Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: Text(
                              "PKR ${totalPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 11,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (updatedAt != null && updatedAt != date)
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      size: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddResourceScreen(
                            projectId: widget.projectId,
                            projectTitle: widget.projectTitle,
                            resourceId: doc.id,
                            resourceData: data,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      await _deleteResource(context, doc.id, materialName);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text("Edit", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text("Delete", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Bricks":
        return Colors.orange;
      case "Cement":
        return Colors.grey;
      case "Sand":
        return Colors.yellow;
      case "Steel":
        return Colors.blueGrey;
      default:
        return Colors.purple;
    }
  }

  void _showResourceDetails(BuildContext context, Map<String, dynamic> data, 
      String materialName, DateTime date) {
    final quantity = data['quantity'] ?? 0;
    final pricePerUnit = (data['pricePerUnit'] ?? 0.0).toDouble();
    final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
    final note = data['note'] ?? '';
    final category = data['category'] ?? 'Unknown';
    final createdBy = data['createdBy'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          materialName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            materialName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Material Resource",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Details Grid
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3,
                      ),
                      children: [
                        _buildDetailItem("Quantity", "$quantity units", Icons.scale),
                        _buildDetailItem("Unit Price", "PKR ${pricePerUnit.toStringAsFixed(2)}", Icons.attach_money),
                        _buildDetailItem("Total Cost", "PKR ${totalPrice.toStringAsFixed(2)}", Icons.calculate),
                        _buildDetailItem("Category", category, Icons.category),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Date and Added By
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem2("Date Added", _formatDetailedDate(date), Icons.calendar_today),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem2("Added By", createdBy.split('@').first, Icons.person),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    if (note.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Notes:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem2(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  String _formatDetailedDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Materials Added Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add your first material resource\nand track expenses automatically",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Materials",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("projects")
            .doc(widget.projectId)
            .collection("resources")
            .orderBy("date", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    "Loading resources...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final resources = snapshot.data!.docs;

          // Calculate total resources cost
          double totalCost = 0;
          for (var doc in resources) {
            final data = doc.data() as Map<String, dynamic>;
            totalCost += (data['totalPrice'] ?? 0.0).toDouble();
          }
          _totalResourcesCost = totalCost;

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.construction,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.projectTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${resources.length} material${resources.length > 1 ? 's' : ''} • PKR ${_totalResourcesCost.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "${resources.length}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Resources List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Force refresh
                    setState(() {});
                  },
                  color: colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                    itemCount: resources.length,
                    itemBuilder: (context, index) {
                      final doc = resources[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildResourceCard(doc, data);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddResourceScreen(
                projectId: widget.projectId,
                projectTitle: widget.projectTitle,
              ),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text("Add Material"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}