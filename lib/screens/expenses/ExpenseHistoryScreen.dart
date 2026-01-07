import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_site_pro_app/screens/expenses/AddExpenseScreen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ExpenseHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  double _totalExpenses = 0.0;

  Future<void> _deleteExpense(BuildContext context, String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection("projects")
            .doc(widget.projectId)
            .collection("expenses")
            .doc(expenseId)
            .delete();

        // Refresh the list
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Expense deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete expense: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editExpense(BuildContext context, String expenseId, Map<String, dynamic> data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          projectId: widget.projectId,
          projectTitle: widget.projectTitle,
          expenseId: expenseId,
          initialData: data,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh the list
    }
  }

  Widget _buildCategoryChip(String category, ColorScheme colors) {
    Color chipColor;
    IconData icon;
    
    switch (category.toLowerCase()) {
      case 'labour':
        chipColor = Colors.blue.withOpacity(0.1);
        icon = Icons.people_outline;
        break;
      case 'material':
        chipColor = Colors.green.withOpacity(0.1);
        icon = Icons.inventory_2_outlined;
        break;
      case 'transport':
        chipColor = Colors.orange.withOpacity(0.1);
        icon = Icons.local_shipping_outlined;
        break;
      case 'equipment':
        chipColor = Colors.purple.withOpacity(0.1);
        icon = Icons.build_outlined;
        break;
      default:
        chipColor = colors.surfaceVariant;
        icon = Icons.receipt_long_outlined;
    }

    return Chip(
      label: Text(category),
      avatar: Icon(icon, size: 16),
      backgroundColor: chipColor,
      labelStyle: TextStyle(
        fontSize: 12,
        color: colors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildExpenseCard(DocumentSnapshot exp, ColorScheme colors) {
    final data = exp.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0).toDouble();
    final description = data['description'] ?? 'No description';
    final category = data['category']?.toString() ?? 'Other';
    final date = (data['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd-MMM-yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    final submittedBy = data['submittedBy']?.toString() ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.receipt_long,
            color: colors.primary,
            size: 24,
          ),
        ),
        title: Text(
          description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(category, colors),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "PKR ${amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "by ${submittedBy.split('@')[0]}",
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Details",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: colors.primary, size: 20),
                          onPressed: () => _editExpense(context, exp.id, data),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deleteExpense(context, exp.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: category,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.access_time_outlined,
                        label: 'Time',
                        value: formattedTime,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data['remarks'] != null && data['remarks'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Remarks",
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['remarks'].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface,
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Expenses - ${widget.projectTitle}"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('expenses')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data!.docs;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No expenses recorded yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your first expense by tapping the + button",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Calculate total expenses
          double total = 0;
          for (var e in expenses) {
            total += ((e.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble();
          }
          _totalExpenses = total;

          return Column(
            children: [
              // Total Expenses Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Expenses",
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              "PKR ${_totalExpenses.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${expenses.length} expense${expenses.length != 1 ? 's' : ''}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Expenses List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    return _buildExpenseCard(expenses[index], colorScheme);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                projectId: widget.projectId,
                projectTitle: widget.projectTitle,
              ),
            ),
          );

          if (result == true && mounted) {
            setState(() {}); // Refresh the list
          }
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}