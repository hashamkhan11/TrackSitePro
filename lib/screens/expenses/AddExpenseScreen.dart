// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String? expenseId;
  final Map<String, dynamic>? initialData;

  const AddExpenseScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    this.expenseId,
    this.initialData,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String category = "Labour";
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  final List<String> _categories = [
    "Labour",
    "Material",
    "Transport",
    "Equipment",
    "Fuel",
    "Maintenance",
    "Office Supplies",
    "Utilities",
    "Rent",
    "Insurance",
    "Permits",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _descController.text = widget.initialData!['description'] ?? '';
      _amountController.text = (widget.initialData!['amount'] ?? 0).toString();
      category = widget.initialData!['category'] ?? 'Labour';
      _remarksController.text = widget.initialData!['remarks'] ?? '';
      _selectedDate = (widget.initialData!['date'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      final expenseData = {
        "description": _descController.text.trim(),
        "amount": amount,
        "category": category,
        "remarks": _remarksController.text.trim(),
        "date": Timestamp.fromDate(_selectedDate),
        "submittedBy": user.email,
        "submittedAt": FieldValue.serverTimestamp(),
        "createdAt": widget.expenseId == null 
            ? Timestamp.now() 
            : widget.initialData?['createdAt'] ?? Timestamp.now(),
        "updatedAt": Timestamp.now(),
      };

      final expensesRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("expenses");

      if (widget.expenseId != null) {
        // Update existing expense
        await expensesRef.doc(widget.expenseId).update(expenseData);
      } else {
        // Add new expense
        await expensesRef.add(expenseData);
      }

      // Update project total expenses in background (don't wait for it)
      _updateProjectTotalExpenses();

      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProjectTotalExpenses() async {
    try {
      final projectRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId);
      
      final expensesSnap = await projectRef.collection('expenses').get();
      double totalExpenses = 0.0;
      
      for (var doc in expensesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalExpenses += (data['amount'] ?? 0).toDouble();
      }

      await projectRef.update({
        "totalExpenses": totalExpenses,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating project total expenses: $e");
      // Silently fail - this is a background operation
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditMode = widget.expenseId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? "Edit Expense" : "Add Expense - ${widget.projectTitle}",
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
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

                    if (confirmed == true && mounted) {
                      Navigator.pop(context, 'deleted');
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: "Description *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? "Required" : null,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Amount (PKR) *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Required";
                          }
                          final amount = double.tryParse(val);
                          if (amount == null || amount <= 0) {
                            return "Enter valid amount";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => category = val ?? "Labour"),
                        decoration: const InputDecoration(
                          labelText: "Category *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remarksController,
                        decoration: const InputDecoration(
                          labelText: "Remarks (Optional)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: "Date",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: _pickDate,
                          ),
                        ),
                        controller: TextEditingController(
                          text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveExpense,
                        icon: Icon(isEditMode ? Icons.save : Icons.add),
                        label: Text(isEditMode ? "Update Expense" : "Save Expense"),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}