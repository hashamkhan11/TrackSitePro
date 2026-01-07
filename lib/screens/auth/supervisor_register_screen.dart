import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SupervisorRegisterScreen extends StatefulWidget {
  const SupervisorRegisterScreen({super.key});

  @override
  State<SupervisorRegisterScreen> createState() => _SupervisorRegisterScreenState();
}

class _SupervisorRegisterScreenState extends State<SupervisorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> registerSupervisor() async {
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

      // Save supervisor user
      await firestore.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'supervisor',
        'emailVerified': false,
        'createdAt': Timestamp.now(),
        'status': 'active', // Supervisors are active immediately
      });

      if (context.mounted) {
        // Show success message with verification info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registration successful!'),
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
                  'Please check your email inbox and click the verification link we just sent to:',
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
                  'You must verify your email to access all features. '
                  'Once verified, you can be assigned to projects by contractors.',
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
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                    colorScheme.secondary,
                    colorScheme.secondary.withOpacity(0.8),
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
                    Icons.engineering,
                    color: colorScheme.onSecondary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Register as Site Supervisor',
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
                      'Join as a supervisor to manage site progress and daily activities',
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
                            // Registration Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[100]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.green[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Supervisor Registration',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Verify your email after registration\n'
                                    '• Contractors will assign you to projects\n'
                                    '• Upload DPRs and track site progress',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green[800],
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
                            const SizedBox(height: 28),

                            // Register Button
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.secondary,
                                  foregroundColor: colorScheme.onSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: isLoading ? null : registerSupervisor,
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
                                          Icon(Icons.engineering, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Register as Supervisor',
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
                                foregroundColor: colorScheme.secondary,
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
            color: Theme.of(context).colorScheme.secondary,
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
            color: Theme.of(context).colorScheme.secondary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
