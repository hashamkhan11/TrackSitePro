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

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const lightGray     = Color(0xFFF9FAFB);
  static const borderGray    = Color(0xFFE5E7EB);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const successGreen  = Color(0xFF10B981);
  static const lightGreen    = Color(0xFFECFDF5);
  static const warningAmber  = Color(0xFFF59E0B);
  static const lightAmber    = Color(0xFFFEF3C7);
}

class ContractorRegisterScreen extends StatefulWidget {
  const ContractorRegisterScreen({super.key});

  @override
  State<ContractorRegisterScreen> createState() =>
      _ContractorRegisterScreenState();
}

class _ContractorRegisterScreenState extends State<ContractorRegisterScreen> {
  final _formKey                    = GlobalKey<FormState>();
  final _nameController             = TextEditingController();
  final _emailController            = TextEditingController();
  final _passwordController         = TextEditingController();
  final _confirmPasswordController  = TextEditingController();
  final _firmNameController         = TextEditingController();
  final _pecNumberController        = TextEditingController();

  bool    _isLoading              = false;
  bool    _obscurePassword        = true;
  bool    _obscureConfirmPassword = true;
  File?   _pecLicenseFile;
  String? _pecFileName;
  String? _pecBase64Image;

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

  // ── Snackbar ────────────────────────────────────────────────────────────────
  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Image Picker ────────────────────────────────────────────────────────────
  Future<void> _pickPECLicense() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
          if (!status.isGranted) {
            _snack('Gallery permission denied. Please enable in settings.',
                Colors.red);
            return;
          }
        }
      }

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );
      if (pickedFile == null) return;

      final bytes = kIsWeb
          ? await pickedFile.readAsBytes()
          : await File(pickedFile.path).readAsBytes();

      final sizeKB = bytes.length / 1024;
      if (sizeKB > 800) {
        _snack(
            'Image too large (${sizeKB.toStringAsFixed(0)} KB). Max 800 KB.',
            Colors.red);
        return;
      }

      final b64 = base64Encode(bytes);
      if (b64.length > 1000000) {
        _snack('Image still too large. Please select a smaller one.', Colors.red);
        return;
      }

      setState(() {
        _pecLicenseFile = kIsWeb ? null : File(pickedFile.path);
        _pecFileName    = pickedFile.name;
        _pecBase64Image = b64;
      });
      _snack('PEC license uploaded successfully', _C.successGreen);
    } catch (e) {
      _snack('Error uploading image: $e', Colors.red);
    }
  }

  // ── Register ────────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _snack('Passwords do not match', Colors.red);
      return;
    }
    if (_pecBase64Image == null || _pecBase64Image!.isEmpty) {
      _snack('Please upload your PEC license', Colors.red);
      return;
    }
    if (_pecBase64Image!.length > 1000000) {
      _snack('PEC license image is too large. Max 1 MB allowed.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = cred.user!;
      await user.sendEmailVerification();

      final fs = FirebaseFirestore.instance;
      await fs.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'contractor',
        'status': 'pending',
        'emailVerified': false,
        'pecNumber': _pecNumberController.text.trim(),
        'pecLicenseImage': _pecBase64Image,
        'pecFileName': _pecFileName,
        'pecFileType': _pecFileName?.split('.').last.toLowerCase(),
        'createdAt': Timestamp.now(),
        'firmName': _firmNameController.text.trim(),
      });

      final firmRef = await fs.collection('firms').add({
        'firmName': _firmNameController.text.trim(),
        'ownerId': user.uid,
        'ownerEmail': _emailController.text.trim(),
        'pecNumber': _pecNumberController.text.trim(),
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      await fs.collection('users').doc(user.uid).update({
        'assignedFirmId': firmRef.id,
      });

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(email: _emailController.text.trim()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msgs = {
        'email-already-in-use':
            'Email is already registered. Please use a different email or log in.',
        'weak-password': 'Password is too weak. Please use a stronger password.',
        'invalid-email': 'Email address is not valid.',
        'operation-not-allowed':
            'Email/password accounts not enabled. Please contact support.',
        'network-request-failed':
            'Network error. Check your internet connection.',
      };
      _snack(msgs[e.code] ?? 'Registration failed: ${e.message}', Colors.red);
    } catch (e) {
      _snack('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightGray,
      body: SafeArea(
        child: Column(children: [
          // ── Top Bar ──
          _buildTopBar(context),

          // ── Form ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(children: [
                // Process Steps Banner
                _buildStepsBanner(),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.borderGray),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      _sectionLabel('Personal Information'),
                      const SizedBox(height: 14),
                      _field(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      _field(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || !v.contains('@')
                                  ? 'Enter a valid email address'
                                  : null),
                      const SizedBox(height: 14),
                      _passwordField(
                          controller: _passwordController,
                          label: 'Password',
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          validator: (v) =>
                              v == null || v.length < 6
                                  ? 'Minimum 6 characters'
                                  : null),
                      const SizedBox(height: 14),
                      _passwordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? 'Please confirm your password'
                                  : null),

                      const SizedBox(height: 24),
                      _sectionLabel('Company Details'),
                      const SizedBox(height: 14),
                      _field(
                          controller: _firmNameController,
                          label: 'Firm / Company Name',
                          icon: Icons.business_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      _field(
                          controller: _pecNumberController,
                          label: 'PEC License Number',
                          icon: Icons.badge_outlined,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      _buildUploadTile(),

                      const SizedBox(height: 28),
                      _buildRegisterButton(),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _C.borderGray, width: 1)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.borderGray),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 17, color: _C.textSecondary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Contractor Registration',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Text(
              'Create your contracting firm account',
              style: TextStyle(fontSize: 12, color: _C.textTertiary),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _C.lightBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.mediumBlue),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.business_center_rounded,
                size: 14, color: _C.primaryBlue),
            SizedBox(width: 5),
            Text('Contractor',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.primaryBlue)),
          ]),
        ),
      ]),
    );
  }

  // ── Steps Banner ─────────────────────────────────────────────────────────────
  Widget _buildStepsBanner() {
    const steps = [
      ('1', 'Register'),
      ('2', 'Verify Email'),
      ('3', 'Await Approval'),
      ('4', 'Start Work'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.mediumBlue),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.route_rounded,
                color: _C.primaryBlue, size: 14),
          ),
          const SizedBox(width: 8),
          const Text(
            'Registration Process',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.primaryBlue),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) {
            return Expanded(
              child: Column(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _C.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(s.$1,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.$2,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _C.primaryBlue),
                  textAlign: TextAlign.center,
                ),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── Section Label ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: _C.primaryBlue,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _C.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    ]);
  }

  // ── Text Field ──────────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: _C.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _C.textSecondary),
        filled: true,
        fillColor: _C.lightGray,
        prefixIcon: Icon(icon, size: 20, color: _C.textTertiary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.borderGray)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.borderGray)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Password Field ──────────────────────────────────────────────────────────
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: _C.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _C.textSecondary),
        filled: true,
        fillColor: _C.lightGray,
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 20, color: _C.textTertiary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: _C.textTertiary,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.borderGray)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.borderGray)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Upload Tile ─────────────────────────────────────────────────────────────
  Widget _buildUploadTile() {
    final uploaded = _pecBase64Image != null;
    return GestureDetector(
      onTap: _pickPECLicense,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? _C.lightGreen : _C.lightGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? _C.successGreen : _C.borderGray,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: uploaded
                  ? _C.successGreen.withOpacity(0.12)
                  : _C.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              uploaded
                  ? Icons.check_circle_outline_rounded
                  : Icons.cloud_upload_outlined,
              size: 22,
              color: uploaded ? _C.successGreen : _C.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                uploaded ? (_pecFileName ?? 'PEC License') : 'Upload PEC License *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: uploaded ? _C.successGreen : _C.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                uploaded ? 'Tap to replace' : 'JPG or PNG, max 800 KB',
                style: TextStyle(
                  fontSize: 12,
                  color: uploaded
                      ? _C.successGreen.withOpacity(0.7)
                      : _C.textTertiary,
                ),
              ),
            ]),
          ),
          Icon(
            uploaded
                ? Icons.swap_horiz_rounded
                : Icons.arrow_forward_ios_rounded,
            size: 16,
            color: uploaded ? _C.successGreen : _C.textTertiary,
          ),
        ]),
      ),
    );
  }

  // ── Register Button ──────────────────────────────────────────────────────────
  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: _C.primaryBlue.withOpacity(0.6),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.app_registration_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Register as Contractor',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// ── Success Dialog ────────────────────────────────────────────────────────────
class _SuccessDialog extends StatelessWidget {
  final String email;
  const _SuccessDialog({required this.email});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: Color(0xFF10B981), size: 22),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'Registration Submitted!',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
          ),
        ),
      ]),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A verification email has been sent to:',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(children: [
                const Icon(Icons.email_outlined,
                    size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(email,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB))),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'You must verify your email before your account can be approved by admin.',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.5),
              ),
            ),
          ]),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Go to Login',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}