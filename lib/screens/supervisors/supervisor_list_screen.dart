// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupervisorListScreen extends StatefulWidget {
  const SupervisorListScreen({super.key});

  @override
  State<SupervisorListScreen> createState() => _SupervisorListScreenState();
}

class _SupervisorListScreenState extends State<SupervisorListScreen> {
  List<Map<String, dynamic>> supervisors = [];
  List<String> supervisorIds = [];
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = true;
  String? firmId;
  bool _isAdding = false;
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadSupervisors();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadSupervisors() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      firmId = userDoc.data()?['assignedFirmId'];

      final snapshot = await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .orderBy('name')
          .get();

      setState(() {
        supervisors = snapshot.docs.map((e) => e.data()).toList();
        supervisorIds = snapshot.docs.map((e) => e.id).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading supervisors: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> addSupervisorByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter an email address"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'supervisor')
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("No supervisor found with this email."),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: "Retry",
                onPressed: () {
                  _emailFocusNode.requestFocus();
                },
              ),
            ),
          );
        }
        return;
      }

      final user = query.docs.first;
      final uid = user.id;
      final name = user['name'] ?? email.split('@').first;

      // Check if already added
      if (supervisorIds.contains(uid)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This supervisor is already added."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .doc(uid)
          .set({
        'email': email,
        'name': name,
        'addedAt': Timestamp.now(),
        'addedBy': FirebaseAuth.instance.currentUser!.uid,
      });

      _emailController.clear();
      await loadSupervisors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Supervisor added successfully!"),
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
            content: Text("Failed to add supervisor: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> deleteSupervisor(String supervisorId, String supervisorEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Remove Supervisor"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to permanently remove this supervisor?",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "⚠️ This will:",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                  SizedBox(height: 4),
                  Text("• Remove supervisor from firm"),
                  SizedBox(height: 2),
                  Text("• Unlink from all assigned projects"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Remove", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 🔹 Step 1: Delete from supervisors list
      await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .doc(supervisorId)
          .delete();

      // 🔹 Step 2: Unlink from all projects where this supervisor is assigned
      final projectSnap = await FirebaseFirestore.instance
          .collection('projects')
          .where('firmId', isEqualTo: firmId)
          .where('supervisorEmail', isEqualTo: supervisorEmail)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in projectSnap.docs) {
        batch.update(doc.reference, {
          'supervisorEmail': null,
          'supervisorId': null,
        });
      }
      await batch.commit();

      await loadSupervisors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Supervisor removed successfully"),
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
            content: Text("Failed to remove supervisor: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withOpacity(0.1), width: 2),
              ),
              child: Icon(
                Icons.engineering_outlined,
                size: 60,
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Supervisors Added",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Add supervisors by entering their email addresses.\nThey must have a 'supervisor' role in the system.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _emailFocusNode.requestFocus();
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text("Add First Supervisor"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorCard(int index, ColorScheme colorScheme) {
    final sup = supervisors[index];
    final supId = supervisorIds[index];
    final email = sup['email'] ?? '';
    final name = sup['name'] ?? email.split('@').first;
    final addedAt = sup['addedAt'] != null 
        ? (sup['addedAt'] as Timestamp).toDate()
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Optional: View supervisor details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Supervisor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (addedAt != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Added ${_formatDate(addedAt)}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Delete Button
                IconButton(
                  onPressed: () => deleteSupervisor(supId, email),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  tooltip: "Remove Supervisor",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "today";
    } else if (difference.inDays == 1) {
      return "yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return "$weeks week${weeks > 1 ? 's' : ''} ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Site Supervisors"),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: loadSupervisors,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
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
                  Text(
                    "Loading supervisors...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Add Supervisor Card
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Add New Supervisor",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                decoration: InputDecoration(
                                  hintText: "Enter supervisor's email address",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colorScheme.primary),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                onSubmitted: (_) => addSupervisorByEmail(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isAdding ? null : addSupervisorByEmail,
                                icon: _isAdding
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.add_rounded, size: 20),
                                label: Text(_isAdding ? "Adding..." : "Add"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Supervisor must have an existing account with 'supervisor' role",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    height: 1.4,
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

                // Supervisors List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Added Supervisors",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (supervisors.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${supervisors.length} supervisor${supervisors.length > 1 ? 's' : ''}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Supervisors List
                Expanded(
                  child: supervisors.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : RefreshIndicator(
                          onRefresh: loadSupervisors,
                          color: colorScheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: supervisors.length,
                            itemBuilder: (context, index) {
                              return _buildSupervisorCard(index, colorScheme);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}