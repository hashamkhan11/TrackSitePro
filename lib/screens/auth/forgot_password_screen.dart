import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  
  bool isLoading = false;
  bool emailSent = false;
  String? errorMessage;

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      setState(() {
        isLoading = false;
        emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      String message = "Failed to send reset email";
      if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'invalid-email') {
        message = "Email address is not valid.";
      } else if (e.code == 'too-many-requests') {
        message = "Too many attempts. Please try again later.";
      } else if (e.code == 'network-request-failed') {
        message = "Network error. Please check your internet connection.";
      }
      
      setState(() {
        isLoading = false;
        errorMessage = message;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _goBackToLogin() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToLogin,
        ),
        title: const Text("Reset Password"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Container(
                margin: const EdgeInsets.only(top: 40, bottom: 30),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              
              // Title
              Text(
                "Forgot Password?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Instructions
              Text(
                emailSent
                    ? "We've sent password reset instructions to your email."
                    : "Enter your email address and we'll send you instructions to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (!emailSent)
                // Email Input Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'you@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Error Message
                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (errorMessage != null) const SizedBox(height: 20),
                      
                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
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
                                  'Send Reset Instructions',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Success State
                Column(
                  children: [
                    // Success Icon
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green[200]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Colors.green[600],
                      ),
                    ),
                    
                    // Success Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Check Your Email",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "We've sent password reset instructions to:",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _emailController.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "The link will expire in 1 hour. "
                            "If you don't see the email, check your spam folder.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sendResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[50],
                              foregroundColor: Colors.blue[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.blue[200]!),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text("Resend Email"),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _goBackToLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Back to Login"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              
              const SizedBox(height: 30),
              
              // Additional Help
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Need help?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Check your spam or junk folder\n"
                      "• Make sure you entered the correct email\n"
                      "• Contact support if you continue to have issues",
                      style: TextStyle(
                        fontSize: 14,
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
    );
  }
}