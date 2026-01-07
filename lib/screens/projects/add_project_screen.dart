// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_site_pro_app/screens/schedule_rates/schedule_of_rates_screen.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _completionDateController = TextEditingController();

  // --- Fields ---
  String workOrderNo = '';
  String? tenderEnquiryNo;
  String projectTitle = '';
  String? selectedRegion;
  String location = '';
  String jobNo = '';
  String? selectedJobType;
  String? jobDescription;
  String? selectedSiteSupervisorId;
  String? selectedSiteSupervisorName;
  String? selectedSiteSupervisorEmail; // ADDED: Store email as well

  DateTime? startDate;
  DateTime? completionDate;

  // Enhanced work items with quantity
  List<WorkItemWithQuantity> selectedWorkItems = [];

  // Dropdown constants
  static const List<String> sngplRegions = [
    'Lahore',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Karachi',
    'Quetta',
    'Islamabad',
  ];

  static const List<String> jobTypes = [
    'Ditching, Backfilling & Reinstatement (MS & PE)',
    'Service Line Laying (New Connections)',
    'Main Laying (Phases, SRP, Combing Mains)',
    'Maintenance/UFG/Operational Work',
    'Valve Pit & Cover Construction',
  ];

  // State Management
  bool isLoading = false;
  String? firmId;
  List<Map<String, dynamic>> _availableSupervisors = [];
  bool _supervisorsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFirmDetails();
    _loadAvailableSupervisors();
  }

  Future<void> _loadAvailableSupervisors() async {
    try {
      setState(() => _supervisorsLoading = true);
      
      // Get current user's firm ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      var firmId = userDoc.data()?['assignedFirmId'];
      if (firmId == null) {
        // Try to get firmId from firmId field directly
        final userData = userDoc.data();
        firmId = userData?['firmId'] ?? userData?['assignedFirmId'];
        
        if (firmId == null) {
          setState(() {
            _availableSupervisors = [];
            _supervisorsLoading = false;
          });
          return;
        }
      }

      // Get supervisors from the nested collection structure
      final snapshot = await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _availableSupervisors = [];
          _supervisorsLoading = false;
        });
        return;
      }

      // Get supervisor details from users collection
      final List<Map<String, dynamic>> supervisors = [];
      
      for (final doc in snapshot.docs) {
        final supervisorId = doc.id;
        final supervisorData = doc.data() as Map<String, dynamic>;
        
        try {
          // Get detailed info from users collection
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(supervisorId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            supervisors.add({
              'id': supervisorId,
              'name': userData?['name'] ?? supervisorData['name'] ?? 'Unnamed Supervisor',
              'email': userData?['email'] ?? supervisorData['email'] ?? '',
              'phone': userData?['phone'] ?? '',
              'role': userData?['role'] ?? 'supervisor',
            });
          } else {
            // Use data from supervisors subcollection if user doc not found
            supervisors.add({
              'id': supervisorId,
              'name': supervisorData['name'] ?? 'Unnamed Supervisor',
              'email': supervisorData['email'] ?? '',
              'phone': '',
              'role': 'supervisor',
            });
          }
        } catch (e) {
          debugPrint("Error fetching supervisor $supervisorId: $e");
          // Add with available data if user fetch fails
          supervisors.add({
            'id': supervisorId,
            'name': supervisorData['name'] ?? 'Unnamed Supervisor',
            'email': supervisorData['email'] ?? '',
            'phone': '',
            'role': 'supervisor',
          });
        }
      }

      setState(() {
        _availableSupervisors = supervisors;
        _supervisorsLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading supervisors: $e");
      setState(() {
        _availableSupervisors = [];
        _supervisorsLoading = false;
      });
    }
  }

  Future<void> _loadFirmDetails() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Request timed out"),
          );

      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      setState(() {
        firmId = userData?['assignedFirmId'] ?? userData?['firmId'];
      });

      if (firmId == null) {
        debugPrint("Warning: No firmId assigned to user");
      }
    } catch (e) {
      debugPrint("Error loading firm details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading firm details: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        controller.text = DateFormat('dd-MMM-yyyy').format(picked);
        if (isStart) {
          startDate = picked;
        } else {
          completionDate = picked;
        }
      });
    }
  }

  void _addWorkItem(SORItem item, double quantity) {
    setState(() {
      selectedWorkItems.add(WorkItemWithQuantity(
        item: item,
        quantity: quantity,
      ));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.code} added successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeWorkItem(WorkItemWithQuantity item) {
    setState(() {
      selectedWorkItems.remove(item);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.item.code} removed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editWorkItemQuantity(WorkItemWithQuantity item) {
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Quantity - ${item.item.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate: PKR ${item.item.rate} / ${item.item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (${item.item.unit})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = double.tryParse(controller.text);
              if (newQuantity != null && newQuantity > 0) {
                setState(() {
                  item.quantity = newQuantity;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quantity updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null || completionDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select start and completion dates'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (completionDate!.isBefore(startDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completion date must be after start date'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (selectedRegion == null || selectedJobType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Region and Job Type'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (selectedWorkItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one work item'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // Re-fetch firmId if null
      if (firmId == null) {
        await _loadFirmDetails();
        if (firmId == null) throw Exception("No firm assigned to user.");
      }

      // Calculate total BOQ Value from selected work items with quantities
      final totalBoqValue = selectedWorkItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.item.rate * item.quantity),
      );

      // Prepare work items data
      final workItemsData = selectedWorkItems.map((item) {
        return {
          ...item.item.toMap(),
          'quantity': item.quantity,
          'totalAmount': item.item.rate * item.quantity,
        };
      }).toList();

      // Add to Firestore with timeout
      await FirebaseFirestore.instance
          .collection('projects')
          .add({
            'workOrderNo': workOrderNo.trim(),
            'jobNo': jobNo.trim(),
            'tenderEnquiryNo': tenderEnquiryNo?.trim(),
            'projectTitle': projectTitle.trim(),
            'region': selectedRegion,
            'location': location.trim(),
            'jobType': selectedJobType,
            'jobDescription': jobDescription?.trim(),
            'startDate': Timestamp.fromDate(startDate!),
            'completionDate': Timestamp.fromDate(completionDate!),
            'status': 'Active',
            'progress': 0.0,
            'totalBoqValue': totalBoqValue,
            'workItems': workItemsData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'firmId': firmId,
            'createdBy': FirebaseAuth.instance.currentUser?.uid,
            // FIXED: Save all three supervisor fields for compatibility
            'siteSupervisorId': selectedSiteSupervisorId,
            'siteSupervisorName': selectedSiteSupervisorName,
            'siteSupervisorEmail': selectedSiteSupervisorEmail, // Added
            'assignedSupervisor': selectedSiteSupervisorEmail, // For backward compatibility with dashboard
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception("Save operation timed out"),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Project created successfully'),
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
      debugPrint("Error saving project: $e");
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
  void dispose() {
    _startDateController.dispose();
    _completionDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create New Project",
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: colorScheme.primary.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Project Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Fill in all required fields to create a new project',
                                style: TextStyle(
                                  fontSize: 13,
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

                // Project Information Section
                _buildSectionHeader(
                  title: 'Project Information',
                  icon: Icons.info_outline,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),

                _buildTextFormField(
                  label: 'Work Order Number *',
                  icon: Icons.assignment_turned_in_outlined,
                  onChanged: (val) => workOrderNo = val.trim(),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextFormField(
                  label: 'Job Number *',
                  icon: Icons.confirmation_num_outlined,
                  onChanged: (val) => jobNo = val.trim(),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextFormField(
                  label: 'Project Title *',
                  icon: Icons.title,
                  onChanged: (val) => projectTitle = val.trim(),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextFormField(
                  label: 'Tender Inquiry No (Optional)',
                  icon: Icons.request_page_outlined,
                  onChanged: (val) => tenderEnquiryNo = val.trim(),
                  validator: (val) => null,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // Location & Job Details Section
                _buildSectionHeader(
                  title: 'Location & Job Details',
                  icon: Icons.location_on_outlined,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),

                _buildDropdownFormField(
                  label: 'Region *',
                  icon: Icons.public,
                  value: selectedRegion,
                  items: sngplRegions,
                  onChanged: (val) => setState(() => selectedRegion = val),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildTextFormField(
                  label: 'Location *',
                  icon: Icons.place_outlined,
                  onChanged: (val) => location = val.trim(),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                _buildDropdownFormField(
                  label: 'Job Type *',
                  icon: Icons.category_outlined,
                  value: selectedJobType,
                  items: jobTypes,
                  onChanged: (val) => setState(() => selectedJobType = val),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                // Site Supervisor Selection (FIXED)
                _buildSiteSupervisorDropdown(colorScheme),
                const SizedBox(height: 16),

                _buildTextFormField(
                  label: 'Job Description (Optional)',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  onChanged: (val) => jobDescription = val.trim(),
                  validator: (val) => null,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // Timeline Section
                _buildSectionHeader(
                  title: 'Project Timeline',
                  icon: Icons.timeline,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildDateFormField(
                        controller: _startDateController,
                        label: 'Start Date *',
                        icon: Icons.date_range,
                        onTap: () => _pickDate(_startDateController, true),
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateFormField(
                        controller: _completionDateController,
                        label: 'Completion Date *',
                        icon: Icons.event_busy_outlined,
                        onTap: () => _pickDate(_completionDateController, false),
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Work Items Section
                _buildSectionHeader(
                  title: 'Work Items & BOQ',
                  icon: Icons.list_alt,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),

                _buildWorkItemListView(colorScheme),
                const SizedBox(height: 12),

                // Display Total BOQ Value
                if (selectedWorkItems.isNotEmpty)
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
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total BOQ Value',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PKR ${_calculateTotalBoq().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: colorScheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${selectedWorkItems.length} items',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
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

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showWorkItemDialog(context),
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          'Add Work Item',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Document attachment feature coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach Docs'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Save Button
                isLoading
                    ? Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Creating Project...',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: saveProject,
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text(
                          "Create Project",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                const SizedBox(height: 10),

                // Info Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '* denotes required fields',
                    style: TextStyle(
                      fontSize: 12,
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

  Widget _buildSiteSupervisorDropdown(ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.supervised_user_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assign Site Supervisor (Optional)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Call helper method
            _buildConditionalContent(colorScheme),
          ],
        ),
      ),
    );
  }

Widget _buildConditionalContent(ColorScheme colorScheme) {
  if (_supervisorsLoading) {
    return _buildLoadingIndicator(colorScheme);
  } else if (_availableSupervisors.isEmpty) {
    return _buildNoSupervisorsMessage();
  } else {
    return _buildSupervisorDropdown(colorScheme);
  }
}

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Loading supervisors...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSupervisorsMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No supervisors available',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supervisors must be added via the Supervisors section',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Go to: Supervisors → Add by email',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loadAvailableSupervisors,
            child: Text(
              'Refresh',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      isExpanded: true, // FIXED: Added isExpanded to prevent overflow
      decoration: InputDecoration(
        labelText: 'Select Site Supervisor',
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.person_search, color: Colors.grey),
      ),
      value: selectedSiteSupervisorId,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Not Assigned'),
        ),
        ..._availableSupervisors.map((supervisor) {
          return DropdownMenuItem<String>(
            value: supervisor['id'],
            child: Text(
              supervisor['name'],
              overflow: TextOverflow.ellipsis, // FIXED: Prevent text overflow
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          selectedSiteSupervisorId = value;
          if (value != null) {
            final supervisor = _availableSupervisors.firstWhere(
              (s) => s['id'] == value,
              orElse: () => {'name': '', 'email': ''},
            );
            selectedSiteSupervisorName = supervisor['name'];
            selectedSiteSupervisorEmail = supervisor['email']; // Store email
          } else {
            selectedSiteSupervisorName = null;
            selectedSiteSupervisorEmail = null;
          }
        });
      },
      validator: (value) => null, // Optional field
    );
  }

  double _calculateTotalBoq() {
    return selectedWorkItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.item.rate * item.quantity),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData icon,
    required void Function(String) onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required ColorScheme colorScheme,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
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
          icon,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator ?? (val) => val == null || val.isEmpty ? 'Required' : null,
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildDateFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
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
          icon,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onTap: onTap,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required ColorScheme colorScheme,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true, // Added isExpanded for consistency
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
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
          icon,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Required' : null,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(
        Icons.arrow_drop_down,
        color: colorScheme.primary,
      ),
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildWorkItemListView(ColorScheme colorScheme) {
    if (selectedWorkItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No work items added yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add work items to create your BOQ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        children: selectedWorkItems.map((workItem) {
          final totalAmount = workItem.item.rate * workItem.quantity;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                workItem.item.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    workItem.item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          '${workItem.quantity} ${workItem.item.unit}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          'PKR ${workItem.item.rate.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blueGrey[50],
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PKR ${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue[600],
                        ),
                        onPressed: () => _editWorkItemQuantity(workItem),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit Quantity',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red[400],
                        ),
                        onPressed: () => _removeWorkItem(workItem),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showWorkItemDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_task,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Work Item',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.search),
                          text: 'Select Existing',
                        ),
                        Tab(
                          icon: Icon(Icons.add_circle_outline),
                          text: 'Add Custom',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _BuildExistingSorTab(
                          onItemSelected: (item, quantity) {
                            _addWorkItem(item, quantity);
                            Navigator.of(context).pop();
                          },
                        ),
                        _BuildCustomSorTab(
                          onItemAdded: (item, quantity) {
                            try {
                              ScheduleOfRates.addRate(item);
                              _addWorkItem(item, quantity);
                              Navigator.of(context).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Data Model for Work Item with Quantity ---
class WorkItemWithQuantity {
  final SORItem item;
  double quantity;

  WorkItemWithQuantity({
    required this.item,
    required this.quantity,
  });
}

// --- Helper Widgets for Tabs ---

class _BuildExistingSorTab extends StatefulWidget {
  final Function(SORItem, double) onItemSelected;
  const _BuildExistingSorTab({required this.onItemSelected});

  @override
  State<_BuildExistingSorTab> createState() => __BuildExistingSorTabState();
}

class __BuildExistingSorTabState extends State<_BuildExistingSorTab> {
  String? _selectedCategory;
  List<SORItem> _items = [];
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    final categories = ScheduleOfRates.getAllCategories();
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
      _items = ScheduleOfRates.getRatesByCategory(_selectedCategory!);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _selectItem(SORItem item) {
    _quantityController.text = '1';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate: PKR ${item.rate} / ${item.unit}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (${item.unit})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.numbers),
              ),
              autofocus: true,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                Navigator.pop(dialogContext);
                widget.onItemSelected(item, quantity);
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Add to Project',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: ScheduleOfRates.getAllCategories()
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  _items = ScheduleOfRates.getRatesByCategory(val!);
                });
              },
              style: const TextStyle(fontSize: 15),
              icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
              underline: const SizedBox(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No items found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a different category',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PKR ${item.rate} / ${item.unit}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        onTap: () => _selectItem(item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BuildCustomSorTab extends StatefulWidget {
  final Function(SORItem, double) onItemAdded;
  const _BuildCustomSorTab({required this.onItemAdded});

  @override
  State<_BuildCustomSorTab> createState() => __BuildCustomSorTabState();
}

class __BuildCustomSorTabState extends State<_BuildCustomSorTab> {
  final _formKey = GlobalKey<FormState>();
  String _code = '';
  String _description = '';
  String _unit = 'No.';
  double _rate = 0.0;
  double _quantity = 1.0;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final customItem = SORItem(
        code: _code.trim(),
        description: _description.trim(),
        unit: _unit,
        rate: _rate,
        category: ScheduleOfRates.CATEGORY_CUSTOM,
      );
      widget.onItemAdded(customItem, _quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Create Custom Work Item',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a custom item not available in the standard list',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildCustomField(
                  label: 'Item Code *',
                  icon: Icons.code,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  onSaved: (val) => _code = val!,
                ),
                const SizedBox(height: 16),
                _buildCustomField(
                  label: 'Description *',
                  icon: Icons.description,
                  maxLines: 3,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  onSaved: (val) => _description = val!,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCustomField(
                        label: 'Rate (PKR) *',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            (val == null || double.tryParse(val) == null)
                                ? 'Must be a number'
                                : null,
                        onSaved: (val) => _rate = double.tryParse(val!) ?? 0.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCustomField(
                        label: 'Quantity *',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        initialValue: '1',
                        validator: (val) =>
                            (val == null ||
                                double.tryParse(val) == null ||
                                double.parse(val) <= 0)
                                ? 'Must be > 0'
                                : null,
                        onSaved: (val) => _quantity = double.tryParse(val!) ?? 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCustomDropdown(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Custom Item to Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomField({
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? initialValue,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildCustomDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Unit *',
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.straighten, color: Colors.grey),
      ),
      value: _unit,
      items: const ['m', 'km', 'No.', 'cu.m', '8 hrs', 'Ft']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => setState(() => _unit = val!),
      validator: (val) => val == null ? 'Required' : null,
    );
  }
}