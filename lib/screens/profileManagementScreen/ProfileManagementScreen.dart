import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _email;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        _nameController.text = data['name'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        _email = data['email'] ?? FirebaseAuth.instance.currentUser?.email;
        _profileImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text("Confirm Update"),
          ],
        ),
        content: const Text("Are you sure you want to update your profile?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        _isEditing = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text("Profile updated successfully!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text("Error: ${e.toString()}"),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
          child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : "User",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_email != null)
          Text(
            _email!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isNotEmpty ? value : "Not set",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
          "Profile Management",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 32),

            if (_isEditing)
              // Edit Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: "Full Name",
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? "Please enter your name"
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _email,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Email Address",
                                prefixIcon: const Icon(Icons.email),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: "+1 234 567 8900",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter phone number";
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined),
                                SizedBox(width: 8),
                                Text(
                                  "Cancel",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Save Changes",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              // View Mode
              Column(
                children: [
                  _infoCard("Full Name", _nameController.text, Icons.person),
                  _infoCard("Email Address", _email ?? "", Icons.email),
                  _infoCard(
                      "Phone Number", _phoneController.text, Icons.phone),
                  const SizedBox(height: 32),

                  // Edit Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional: Additional information
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your email cannot be changed for security reasons.",
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}