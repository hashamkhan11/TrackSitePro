// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditProjectScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const EditProjectScreen({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all text fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _tenderEnquiryController = TextEditingController();
  final TextEditingController _jobNoController = TextEditingController();
  final TextEditingController _workOrderNoController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  
  // Controllers for amount fields
  final TextEditingController _totalExcludingTaxController = TextEditingController();
  final TextEditingController _taxAmountController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  // --- Fields ---
  DateTime? projectDate;
  
  // Tax related fields
  double taxRate = 0.0;
  double taxAmount = 0.0;
  double totalExcludingTax = 0.0;
  double totalAmount = 0.0;

  // State Management
  bool isLoading = false;
  String? firmId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadFirmDetails();
    
    // Add listeners to update calculations when amounts change
    _totalExcludingTaxController.addListener(_updateFromExcludingTax);
    _taxAmountController.addListener(_updateFromTaxAmount);
    _totalAmountController.addListener(_updateFromTotalAmount);
    _taxRateController.addListener(_updateFromTaxRate);
  }

  void _loadInitialData() {
    // Load basic information
    _tenderEnquiryController.text = widget.projectData['tenderEnquiryNo'] ?? '';
    _jobNoController.text = widget.projectData['jobNo'] ?? '';
    _workOrderNoController.text = widget.projectData['workOrderNo'] ?? '';
    _jobDescriptionController.text = widget.projectData['jobDescription'] ?? '';
    
    // Load date
    projectDate = (widget.projectData['date'] as Timestamp?)?.toDate();
    if (projectDate != null) {
      _dateController.text = DateFormat('dd-MMM-yyyy').format(projectDate!);
    }
    
    // Load tax and amount fields
    taxRate = ((widget.projectData['taxRate'] ?? 0) as num).toDouble();
    taxAmount = ((widget.projectData['taxAmount'] ?? 0) as num).toDouble();
    totalExcludingTax = ((widget.projectData['totalExcludingTax'] ?? 0) as num).toDouble();
    totalAmount = ((widget.projectData['totalAmount'] ?? 0) as num).toDouble();
    
    _taxRateController.text = taxRate.toString();
    _totalExcludingTaxController.text = totalExcludingTax.toStringAsFixed(2);
    _taxAmountController.text = taxAmount.toStringAsFixed(2);
    _totalAmountController.text = totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _tenderEnquiryController.dispose();
    _jobNoController.dispose();
    _workOrderNoController.dispose();
    _jobDescriptionController.dispose();
    _taxRateController.dispose();
    _totalExcludingTaxController.dispose();
    _taxAmountController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  bool _updatingFromExcludingTax = false;
  // Update calculations when total excluding tax changes
  void _updateFromExcludingTax() {
    if (_updatingFromExcludingTax) return;
    _updatingFromExcludingTax = true;
    
    final newTotalExcludingTax = double.tryParse(_totalExcludingTaxController.text) ?? 0;
    final currentTaxRate = double.tryParse(_taxRateController.text) ?? 0;
    
    setState(() {
      totalExcludingTax = newTotalExcludingTax;
      taxRate = currentTaxRate;
      taxAmount = totalExcludingTax * (taxRate / 100);
      totalAmount = totalExcludingTax + taxAmount;
      
      // Update other controllers without triggering listeners
      _taxAmountController.removeListener(_updateFromTaxAmount);
      _taxAmountController.text = taxAmount.toStringAsFixed(2);
      _taxAmountController.addListener(_updateFromTaxAmount);
      
      _totalAmountController.removeListener(_updateFromTotalAmount);
      _totalAmountController.text = totalAmount.toStringAsFixed(2);
      _totalAmountController.addListener(_updateFromTotalAmount);
    });
    _updatingFromExcludingTax = false;
  }

  bool _updatingFromTaxAmount = false;
  // Update calculations when tax amount changes
  void _updateFromTaxAmount() {
    if (_updatingFromTaxAmount) return;
    _updatingFromTaxAmount = true;
    
    final newTaxAmount = double.tryParse(_taxAmountController.text) ?? 0;
    final currentTaxRate = double.tryParse(_taxRateController.text) ?? 0;
    
    setState(() {
      taxAmount = newTaxAmount;
      taxRate = currentTaxRate;
      
      if (taxRate > 0) {
        totalExcludingTax = taxAmount / (taxRate / 100);
      }
      totalAmount = totalExcludingTax + taxAmount;
      
      // Update other controllers without triggering listeners
      _totalExcludingTaxController.removeListener(_updateFromExcludingTax);
      _totalExcludingTaxController.text = totalExcludingTax.toStringAsFixed(2);
      _totalExcludingTaxController.addListener(_updateFromExcludingTax);
      
      _totalAmountController.removeListener(_updateFromTotalAmount);
      _totalAmountController.text = totalAmount.toStringAsFixed(2);
      _totalAmountController.addListener(_updateFromTotalAmount);
    });
    _updatingFromTaxAmount = false;
  }

  bool _updatingFromTotalAmount = false;
  // Update calculations when total amount changes
  void _updateFromTotalAmount() {
    if (_updatingFromTotalAmount) return;
    _updatingFromTotalAmount = true;
    
    final newTotalAmount = double.tryParse(_totalAmountController.text) ?? 0;
    final currentTaxRate = double.tryParse(_taxRateController.text) ?? 0;
    
    setState(() {
      totalAmount = newTotalAmount;
      taxRate = currentTaxRate;
      
      if (taxRate > 0) {
        totalExcludingTax = totalAmount / (1 + (taxRate / 100));
        taxAmount = totalAmount - totalExcludingTax;
      }
      
      // Update other controllers without triggering listeners
      _totalExcludingTaxController.removeListener(_updateFromExcludingTax);
      _totalExcludingTaxController.text = totalExcludingTax.toStringAsFixed(2);
      _totalExcludingTaxController.addListener(_updateFromExcludingTax);
      
      _taxAmountController.removeListener(_updateFromTaxAmount);
      _taxAmountController.text = taxAmount.toStringAsFixed(2);
      _taxAmountController.addListener(_updateFromTaxAmount);
    });
    _updatingFromTotalAmount = false;
  }

  bool _updatingFromTaxRate = false;
  // Update calculations when tax rate changes
  void _updateFromTaxRate() {
    if (_updatingFromTaxRate) return;
    _updatingFromTaxRate = true;
    
    final newTaxRate = double.tryParse(_taxRateController.text) ?? 0;
    
    setState(() {
      taxRate = newTaxRate;
      
      // Recalculate based on total excluding tax (as base)
      taxAmount = totalExcludingTax * (taxRate / 100);
      totalAmount = totalExcludingTax + taxAmount;
      
      // Update amount controllers without triggering listeners
      _taxAmountController.removeListener(_updateFromTaxAmount);
      _taxAmountController.text = taxAmount.toStringAsFixed(2);
      _taxAmountController.addListener(_updateFromTaxAmount);
      
      _totalAmountController.removeListener(_updateFromTotalAmount);
      _totalAmountController.text = totalAmount.toStringAsFixed(2);
      _totalAmountController.addListener(_updateFromTotalAmount);
    });
    _updatingFromTaxRate = false;
  }

  Future<void> _loadFirmDetails() async {
    setState(() {
      firmId = widget.projectData['firmId'];
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: projectDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MMM-yyyy').format(picked);
        projectDate = picked;
      });
    }
  }

  Future<void> updateProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (projectDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select project date'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      if (firmId == null) {
        throw Exception("No firm assigned to project.");
      }

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'tenderEnquiryNo': _tenderEnquiryController.text.trim(),
        'jobNo': _jobNoController.text.trim(),
        'workOrderNo': _workOrderNoController.text.trim(),
        'date': Timestamp.fromDate(projectDate!),
        'jobDescription': _jobDescriptionController.text.trim(),
        
        'taxRate': double.tryParse(_taxRateController.text) ?? 0,
        'taxAmount': double.tryParse(_taxAmountController.text) ?? 0,
        'totalExcludingTax': double.tryParse(_totalExcludingTaxController.text) ?? 0,
        'totalAmount': double.tryParse(_totalAmountController.text) ?? 0,
        
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Project updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error updating project: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Project",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: colorScheme.primary.withOpacity(0.05),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_document,
                          color: colorScheme.primary,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Project Details',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Update project information below',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Basic Information Section
                _buildSectionHeader(
                  title: 'Basic Information',
                  icon: Icons.info_outline,
                  colorScheme: colorScheme,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),

                TextFormField(
                  controller: _tenderEnquiryController,
                  decoration: InputDecoration(
                    labelText: 'Tender Enquiry No *',
                    labelStyle: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(
                      Icons.request_page_outlined,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                TextFormField(
                  controller: _jobNoController,
                  decoration: InputDecoration(
                    labelText: 'Job No *',
                    labelStyle: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(
                      Icons.confirmation_num_outlined,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                TextFormField(
                  controller: _workOrderNoController,
                  decoration: InputDecoration(
                    labelText: 'Work Order No *',
                    labelStyle: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date *',
                    labelStyle: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  onTap: _pickDate,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                TextFormField(
                  controller: _jobDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Job Description *',
                    labelStyle: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),

                // Tax Calculation Section with Editable Fields
                _buildSectionHeader(
                  title: 'Financial Details',
                  icon: Icons.calculate,
                  colorScheme: colorScheme,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        // Tax Rate Input
                        TextFormField(
                          controller: _taxRateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tax Rate (%)',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: Icon(
                              Icons.percent,
                              color: colorScheme.primary.withOpacity(0.7),
                              size: isSmallScreen ? 20 : 24,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14 : 16,
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                        Divider(height: isSmallScreen ? 20 : 24),
                        
                        // Total Excluding Tax
                        TextFormField(
                          controller: _totalExcludingTaxController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Total Excluding Tax (PKR)',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: Icon(
                              Icons.money_off,
                              color: Colors.green[700],
                              size: isSmallScreen ? 20 : 24,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14 : 16,
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Tax Amount
                        TextFormField(
                          controller: _taxAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tax Amount (PKR)',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: Icon(
                              Icons.receipt,
                              color: Colors.orange[700],
                              size: isSmallScreen ? 20 : 24,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14 : 16,
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Total Amount
                        TextFormField(
                          controller: _totalAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Total Amount (PKR)',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: Icon(
                              Icons.payments,
                              color: colorScheme.primary,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14 : 16,
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 25),

                // Save Button
                isLoading
                  ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Text(
                            'Updating Project...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: updateProject,
                      icon: Icon(Icons.save_alt_rounded,
                          size: isSmallScreen ? 20 : 24),
                      label: Text(
                        "Update Project",
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: Size(double.infinity, isSmallScreen ? 50 : 56),
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                SizedBox(height: isSmallScreen ? 8 : 10),

                // Info Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                  child: Text(
                    '* denotes required fields',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: isSmallScreen ? 18 : 20,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}