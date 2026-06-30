import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Inline error messages — null means no error shown
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    // Clear field error as soon as the user starts typing
    _nameController.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
    _emailController.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _passwordController.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
      // Re-check confirm password match live
      if (_confirmPasswordError != null &&
          _confirmPasswordController.text.isNotEmpty) {
        if (_passwordController.text == _confirmPasswordController.text) {
          setState(() => _confirmPasswordError = null);
        }
      }
    });
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Email format helper ──────────────────────────────────────────────────
  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email);

  // ── Register logic ───────────────────────────────────────────────────────
  void _register() async {
    final name            = _nameController.text.trim();
    final email           = _emailController.text.trim();
    final password        = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Client-side validation
    String? nameErr;
    String? emailErr;
    String? passErr;
    String? confirmErr;

    if (name.isEmpty) {
      nameErr = 'Full name is required.';
    }

    if (email.isEmpty) {
      emailErr = 'Email address is required.';
    } else if (!_isValidEmail(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passErr = 'Password is required.';
    } else if (password.length < 6) {
      passErr = 'Password must be at least 6 characters.';
    }

    if (confirmPassword.isEmpty) {
      confirmErr = 'Please confirm your password.';
    } else if (password != confirmPassword) {
      confirmErr = 'Passwords do not match.';
    }

    if (nameErr != null || emailErr != null || passErr != null || confirmErr != null) {
      setState(() {
        _nameError            = nameErr;
        _emailError           = emailErr;
        _passwordError        = passErr;
        _confirmPasswordError = confirmErr;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Store user data in Firestore with role 'user'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'email-already-in-use':
          setState(() => _emailError = 'This email is already registered.');
          break;
        case 'invalid-email':
          setState(() => _emailError = 'Please enter a valid email address.');
          break;
        case 'weak-password':
          setState(() => _passwordError = 'Password must be at least 6 characters.');
          break;
        case 'operation-not-allowed':
          setState(() => _emailError = 'Email/password accounts are not enabled.');
          break;
        default:
          setState(() => _confirmPasswordError = e.message ?? 'Registration failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirmPasswordError = 'An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Inline error widget ──────────────────────────────────────────────────
  Widget _errorText(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          children: [
            const Icon(Icons.person_add_rounded, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text("Create Account", style: AppTextStyles.heading1()),
            const SizedBox(height: 8),
            Text("Join us to explore beautiful places", style: AppTextStyles.bodySmall()),
            const SizedBox(height: 40),

            TravelCard(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Full Name ────────────────────────────────────────────
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _nameError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.border,
                          width: _nameError != null ? 1.5 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _nameError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  _errorText(_nameError),

                  const SizedBox(height: AppSpacing.s20),

                  // ── Email ────────────────────────────────────────────────
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _emailError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.border,
                          width: _emailError != null ? 1.5 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _emailError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  _errorText(_emailError),

                  const SizedBox(height: AppSpacing.s20),

                  // ── Password ─────────────────────────────────────────────
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _passwordError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.border,
                          width: _passwordError != null ? 1.5 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _passwordError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  _errorText(_passwordError),

                  const SizedBox(height: AppSpacing.s20),

                  // ── Confirm Password ─────────────────────────────────────
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.border,
                          width: _confirmPasswordError != null ? 1.5 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppCorners.rounded16,
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  _errorText(_confirmPasswordError),

                  const SizedBox(height: AppSpacing.s32),

                  PremiumGradientButton(
                    onPressed: _register,
                    text: "Register",
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
