// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_site_pro_app/screens/auth/registration_choice_screen.dart';
import 'package:track_site_pro_app/screens/auth/role_redirector.dart';
import 'package:track_site_pro_app/screens/auth/forgot_password_screen.dart'; // Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Function to check if email is verified
  Future<bool> _checkEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reload user to get latest email verification status
      await user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      return currentUser?.emailVerified ?? false;
    }
    return false;
  }

  // Function to show email verification reminder
  Future<void> _showVerificationReminder(String email) async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text("Email Not Verified"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your email address is not verified yet.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your inbox ($email) for the verification email we sent you.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you didn\'t receive it, you can request a new verification email.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Skip for now"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.sendEmailVerification();
                  if (mounted) {
                    Navigator.pop(context);
                    showSuccess("Verification email sent! Check your inbox.");
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Resend Verification"),
          ),
        ],
      ),
    );
  }

  Future<void> onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);

    try {
      // Attempt to login with Firebase Auth
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(), 
            password: _passwordController.text
          );

      User? user = userCred.user;

      if (user == null) {
        showError("Login failed. Please try again.");
        setState(() => isLoading = false);
        return;
      }

      // ✅ SUCCESSFUL LOGIN - Now check Firestore user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // User exists in Auth but not in Firestore - this shouldn't happen
        await FirebaseAuth.instance.signOut();
        showError("Account setup incomplete. Please contact support.");
        setState(() => isLoading = false);
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        await FirebaseAuth.instance.signOut();
        showError("User data error. Please contact support.");
        setState(() => isLoading = false);
        return;
      }

      final role = data['role']?.toString() ?? '';
      
      // ✅ Check contractor approval status
      if (role == 'contractor') {
        final status = data['status']?.toString() ?? '';
        if (status != 'approved') {
          await FirebaseAuth.instance.signOut();
          showError("Your contractor account is pending admin approval.\n"
              "You'll be notified via email once approved.");
          setState(() => isLoading = false);
          return;
        }
      }
      
      // ✅ Check supervisor assignments (optional warning)
      if (role == 'supervisor' && mounted) {
        final supervisorProjects = await FirebaseFirestore.instance
            .collection('projects')
            .where('assignedSupervisor', isEqualTo: _emailController.text.trim())
            .limit(1)
            .get();
        
        if (supervisorProjects.docs.isEmpty) {
          // Just a warning, not blocking login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not assigned to any projects yet.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // ✅ Check email verification (after successful login & role checks)
      final isEmailVerified = await _checkEmailVerification();
      
      // Update email verification status in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'emailVerified': isEmailVerified,
            'lastLogin': Timestamp.now(),
          });

      // ✅ Show verification reminder if email not verified
      if (!isEmailVerified && mounted) {
        await _showVerificationReminder(user.email ?? _emailController.text.trim());
      }

      // ✅ Navigate to appropriate dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleRedirector()),
        );
      }

    } on FirebaseAuthException catch (e) {
      // ✅ Handle specific Firebase Auth errors
      String errorMsg = "Login failed. Please check your credentials.";
      switch (e.code) {
        case 'user-not-found':
          errorMsg = "No account found with this email.\nPlease register first.";
          break;
        case 'wrong-password':
          errorMsg = "Incorrect password.\nPlease try again or use 'Forgot Password'.";
          break;
        case 'invalid-email':
          errorMsg = "Email address is not valid.\nPlease enter a valid email.";
          break;
        case 'user-disabled':
          errorMsg = "This account has been disabled.\nPlease contact support.";
          break;
        case 'too-many-requests':
          errorMsg = "Too many login attempts.\nPlease try again in a few minutes.";
          break;
        case 'network-request-failed':
          errorMsg = "Network error.\nPlease check your internet connection.";
          break;
        default:
          errorMsg = "Login failed: ${e.message}";
      }
      showError(errorMsg);
    } catch (e) {
      // ✅ Handle generic errors
      showError("Login failed. Please try again.");
      debugPrint("Login error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Navigate to forgot password screen
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/App Name
                    const SizedBox(height: 40),
                    Text(
                      'TrackSitePro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 36,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back! Please log in to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val == null || val.isEmpty || !val.contains('@') 
                          ? 'Please enter a valid email address' 
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (val) =>
                          val == null || val.length < 6 
                          ? 'Password must be at least 6 characters' 
                          : null,
                    ),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Login Button
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isLoading ? null : onLoginPressed,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistrationChoiceScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}