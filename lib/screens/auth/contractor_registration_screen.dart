// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'login_screen.dart';

class ContractorRegisterScreen extends StatefulWidget {
  const ContractorRegisterScreen({super.key});

  @override
  State<ContractorRegisterScreen> createState() => _ContractorRegisterScreenState();
}

class _ContractorRegisterScreenState extends State<ContractorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _pecNumberController = TextEditingController();
  
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _pecLicenseFile;
  String? _pecFileName;
  String? _pecBase64Image;

  Future<void> _pickPECLicense() async {
    try {
      print('📸 Starting PEC license picker...');
      
      // Check permission for mobile devices
      if (!kIsWeb) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gallery permission denied. Please enable in settings.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,  // Reduced from 1024 for better compression
        maxHeight: 800, // Reduced from 1024
        imageQuality: 50, // Reduced from 70 for better compression
      );

      if (pickedFile == null) {
        print('❌ User cancelled image selection');
        return;
      }
      
      print('✅ Image picked: ${pickedFile.name}');

      Uint8List bytes;
      
      if (kIsWeb) {
        // Web platform
        bytes = await pickedFile.readAsBytes();
      } else {
        // Mobile platform
        final file = File(pickedFile.path);
        bytes = await file.readAsBytes();
      }
      
      // Check size BEFORE encoding (max 800KB before Base64)
      final sizeInKB = bytes.length / 1024;
      print('📊 Original image size: ${sizeInKB.toStringAsFixed(1)} KB');
      
      if (sizeInKB > 800) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image too large (${sizeInKB.toStringAsFixed(0)} KB). '
                  'Please select a smaller image (max 800KB).'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final base64Image = base64Encode(bytes);
      
      print('📊 Base64 encoded size: ${(base64Image.length / 1024).toStringAsFixed(1)} KB');
      
      // Final check for Firestore 1MB limit
      if (base64Image.length > 1000000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is still too large after compression. Please select a smaller image.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _pecLicenseFile = kIsWeb ? null : File(pickedFile.path);
        _pecFileName = pickedFile.name;
        _pecBase64Image = base64Image;
      });
      
      print('✅ PEC license uploaded successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PEC license uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error uploading PEC license: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> registerContractor() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if PEC license is uploaded
    if (_pecBase64Image == null || _pecBase64Image!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload PEC license'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Final check for Firestore 1MB limit
    if (_pecBase64Image!.length > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PEC license image is too large. Max 1MB allowed. '
              'Please select a smaller image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Create user with email and password
      UserCredential userCred = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      User? user = userCred.user;
      String uid = user!.uid;

      // Send email verification
      await user.sendEmailVerification();

      // Save contractor as "pending" for admin approval
      await firestore.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'contractor',
        'status': 'pending',
        'emailVerified': false,
        'pecNumber': _pecNumberController.text.trim(),
        'pecLicenseImage': _pecBase64Image, // Store as base64 string
        'pecFileName': _pecFileName,
        'pecFileType': _pecFileName?.split('.').last.toLowerCase(),
        'createdAt': Timestamp.now(),
        'firmName': _firmNameController.text.trim(),
      });

      // Create firm record
      DocumentReference firmRef = await firestore.collection('firms').add({
        'firmName': _firmNameController.text.trim(),
        'ownerId': uid,
        'ownerEmail': _emailController.text.trim(),
        'pecNumber': _pecNumberController.text.trim(),
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      // Link firm to user
      await firestore.collection('users').doc(uid).update({
        'assignedFirmId': firmRef.id,
      });

      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registration submitted successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Verification email sent to ${_emailController.text}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Show verification reminder dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Verify Your Email'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Important: Please check your email inbox and click the verification link we just sent to:',
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You must verify your email before your account can be approved by admin.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already registered. Please use a different email or login.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email address is not valid.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Email/password accounts are not enabled. Please contact support.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firmNameController.dispose();
    _pecNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.business,
                    color: colorScheme.onPrimary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Register as Contractor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Create your contracting firm and get started with project management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Registration Steps Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[100]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Registration Process',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1. Complete registration\n'
                                    '2. Verify your email (check inbox)\n'
                                    '3. Wait for admin approval\n'
                                    '4. Start managing projects',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Form Fields
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => val == null || !val.contains('@')
                                  ? 'Enter a valid email address'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              validator: (val) => val == null || val.length < 6
                                  ? 'Minimum 6 characters required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Please confirm your password'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _firmNameController,
                              label: 'Firm/Company Name',
                              icon: Icons.business,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _pecNumberController,
                              label: 'PEC License Number',
                              icon: Icons.badge_outlined,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),

                            // PEC License Upload
                            _buildPECLicenseUpload(),
                            const SizedBox(height: 28),

                            // Register Button
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: isLoading ? null : registerContractor,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.app_registration, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Register as Contractor',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Back to login
                            TextButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to Login'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.grey[700]),
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
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
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
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildPECLicenseUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PEC License Upload *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPECLicense,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: _pecBase64Image == null ? Colors.grey[400]! : Colors.green,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _pecBase64Image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload PEC License',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'JPG, PNG (Max 800KB)',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _pecFileName?.toLowerCase().endsWith('.pdf') == true
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              size: 40,
                              color: Colors.green[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _pecFileName ?? 'PEC License',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tap to change',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_pecBase64Image != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'PEC License uploaded successfully',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}