// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:intl/intl.dart';

class AddResourceScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String? resourceId; // for editing
  final Map<String, dynamic>? resourceData;

  const AddResourceScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    this.resourceId,
    this.resourceData,
  });

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customMaterialController = TextEditingController();

  bool _loading = false;
  String? _selectedCategory;
  bool _showCustomMaterialField = false;

  /// 🔹 Only these 4 materials + Other option
  final List<String> _categories = [
    "Bricks",
    "Cement",
    "Sand",
    "Steel",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.resourceData != null) {
      _selectedCategory = widget.resourceData!['category'] ?? _categories.first;
      _qtyController.text = (widget.resourceData!['quantity'] ?? '').toString();
      _priceController.text = (widget.resourceData!['price'] ?? '').toString();
      _noteController.text = widget.resourceData!['note'] ?? '';
      
      // Check if it's a custom material
      if (_selectedCategory == "Other" && widget.resourceData!['materialName'] != null) {
        _customMaterialController.text = widget.resourceData!['materialName'];
        _showCustomMaterialField = true;
      }
    } else {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _customMaterialController.dispose();
    super.dispose();
  }

  Future<void> _saveResourceAndExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Determine the material name
      final materialName = _selectedCategory == "Other" 
          ? _customMaterialController.text.trim()
          : _selectedCategory!;
      
      final quantity = int.tryParse(_qtyController.text) ?? 0;
      final pricePerUnit = double.tryParse(_priceController.text) ?? 0.0;
      final totalPrice = quantity * pricePerUnit;

      // Create resource data
      final resourceData = {
        "category": _selectedCategory,
        "materialName": _selectedCategory == "Other" ? materialName : null,
        "quantity": quantity,
        "pricePerUnit": pricePerUnit,
        "totalPrice": totalPrice,
        "note": _noteController.text.trim(),
        "date": Timestamp.now(),
        "createdBy": user.email,
        "createdAt": widget.resourceId == null 
            ? Timestamp.now() 
            : widget.resourceData?['createdAt'] ?? Timestamp.now(),
        "updatedAt": Timestamp.now(),
      };

      final resourcesRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("resources");

      String resourceId;
      if (widget.resourceId == null) {
        // Add new resource
        final docRef = await resourcesRef.add(resourceData);
        resourceId = docRef.id;
      } else {
        // Update existing resource
        await resourcesRef.doc(widget.resourceId).update(resourceData);
        resourceId = widget.resourceId!;
      }

      // Create or update associated expense
      await _createExpenseForResource(resourceId, materialName, quantity, totalPrice, user.email!);

      // Update project totals
      await _updateProjectTotals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.resourceId == null 
                ? "Material added and expense recorded!" 
                : "Material updated successfully!",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createExpenseForResource(
    String resourceId, 
    String materialName, 
    int quantity, 
    double totalAmount,
    String submittedBy
  ) async {
    final expensesRef = FirebaseFirestore.instance
        .collection("projects")
        .doc(widget.projectId)
        .collection("expenses");

    // Check if expense already exists for this resource
    final existingExpense = await expensesRef
        .where("resourceId", isEqualTo: resourceId)
        .get();

    final expenseData = {
      "description": "$materialName (${quantity} units)",
      "amount": totalAmount,
      "category": "Material",
      "resourceId": resourceId,
      "remarks": "Resource purchase: $materialName",
      "date": Timestamp.now(),
      "submittedBy": submittedBy,
      "submittedAt": FieldValue.serverTimestamp(),
      "createdAt": widget.resourceId == null 
          ? Timestamp.now() 
          : widget.resourceData?['expenseCreatedAt'] ?? Timestamp.now(),
      "updatedAt": Timestamp.now(),
    };

    if (existingExpense.docs.isNotEmpty) {
      // Update existing expense
      await expensesRef.doc(existingExpense.docs.first.id).update(expenseData);
    } else {
      // Create new expense
      expenseData["createdAt"] = Timestamp.now();
      await expensesRef.add(expenseData);
    }
  }

  Future<void> _updateProjectTotals() async {
    try {
      final projectRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId);

      // Get total expenses
      final expensesSnap = await projectRef.collection('expenses').get();
      double totalExpenses = 0.0;
      for (var doc in expensesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalExpenses += (data['amount'] ?? 0).toDouble();
      }

      // Get total resources cost
      final resourcesSnap = await projectRef.collection('resources').get();
      double totalResourcesCost = 0.0;
      for (var doc in resourcesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalResourcesCost += (data['totalPrice'] ?? 0).toDouble();
      }

      await projectRef.update({
        "totalExpenses": totalExpenses,
        "totalResourcesCost": totalResourcesCost,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating project totals: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.resourceId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Material" : "Add Material & Expense",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Info Card
                Container(
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                           
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Material Category Dropdown
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Material",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            hintText: "Select material",
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _showCustomMaterialField = (value == "Other");
                              if (!_showCustomMaterialField) {
                                _customMaterialController.clear();
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please select a material";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom Material Name (only shown when "Other" is selected)
                if (_showCustomMaterialField)
                  Column(
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Custom Material Name",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _customMaterialController,
                                decoration: InputDecoration(
                                  labelText: "Enter material name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  hintText: "e.g., Gravel, Wood, etc.",
                                ),
                                validator: (value) {
                                  if (_selectedCategory == "Other" && 
                                      (value == null || value.trim().isEmpty)) {
                                    return "Please enter material name";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Quantity Input
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quantity Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Quantity",
                            hintText: "Enter number of units",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixText: "units",
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter quantity";
                            }
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed <= 0) {
                              return "Enter a valid positive number";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Price Input
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Price Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Price per unit",
                            hintText: "Enter price for one unit",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixText: "PKR ",
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter price";
                            }
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed <= 0) {
                              return "Enter a valid positive amount";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calculate,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Total Cost: PKR ${_calculateTotalCost()}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
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
                const SizedBox(height: 16),

                // Notes Input
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Additional Notes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Add any important details, quality specifications, or supplier information",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: "Notes (Optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "This Material will be automatically added as a material expense in the project expenses.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _saveResourceAndExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: _loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Icon(isEditing ? Icons.update : Icons.save),
                    label: Text(
                      _loading 
                        ? "Saving..." 
                        : isEditing ? "Update Material" : "Save Material & Expense",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateTotalCost() {
    try {
      final quantity = int.tryParse(_qtyController.text) ?? 0;
      final pricePerUnit = double.tryParse(_priceController.text) ?? 0.0;
      final total = quantity * pricePerUnit;
      return total.toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }
}