import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Inline error messages — null means no error shown
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Clear field error as soon as the user starts typing
    _emailController.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _passwordController.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Email format helper ──────────────────────────────────────────────────
  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email);

  // ── Login logic ──────────────────────────────────────────────────────────
  void _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Client-side validation
    String? emailErr;
    String? passErr;

    if (email.isEmpty) {
      emailErr = 'Email address is required.';
    } else if (!_isValidEmail(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passErr = 'Password is required.';
    }

    if (emailErr != null || passErr != null) {
      setState(() {
        _emailError    = emailErr;
        _passwordError = passErr;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // AuthWrapper handles navigation
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'user-not-found':
          setState(() => _emailError = 'Email not found.');
          break;
        case 'invalid-email':
          setState(() => _emailError = 'Please enter a valid email address.');
          break;
        case 'wrong-password':
          setState(() => _passwordError = 'Incorrect password.');
          break;
        case 'invalid-credential':
          // Newer Firebase SDK merges user-not-found + wrong-password under 'invalid-credential'
          try {
            final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
            if (methods.isEmpty) {
              // Try Firestore check in case of email enumeration protection
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (query.docs.isEmpty) {
                setState(() => _emailError = 'Email not found.');
              } else {
                setState(() => _passwordError = 'Incorrect password.');
              }
            } else {
              setState(() => _passwordError = 'Incorrect password.');
            }
          } catch (err) {
            try {
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (query.docs.isEmpty) {
                setState(() => _emailError = 'Email not found.');
              } else {
                setState(() => _passwordError = 'Incorrect password.');
              }
            } catch (err2) {
              // Default fallback
              setState(() => _passwordError = 'Incorrect password.');
            }
          }
          break;
        case 'user-disabled':
          setState(() => _emailError = 'This account has been disabled.');
          break;
        case 'too-many-requests':
          setState(() => _passwordError = 'Too many attempts. Try again later.');
          break;
        default:
          setState(() => _passwordError = e.message ?? 'Login failed.');
      }
    } catch (e) {
      if (mounted) setState(() => _passwordError = 'An unexpected error occurred.');
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.travel_explore_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSpacing.s24),
              Text("Welcome Back", style: AppTextStyles.heading1()),
              const SizedBox(height: AppSpacing.s8),
              Text("Explore beautiful destinations", style: AppTextStyles.bodySmall()),
              const SizedBox(height: AppSpacing.s40),

              TravelCard(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Email field ──────────────────────────────────────
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email Address",
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

                    // ── Password field ───────────────────────────────────
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

                    const SizedBox(height: AppSpacing.s32),

                    PremiumGradientButton(
                      onPressed: _login,
                      text: "Sign In",
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.s32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("New traveler?", style: AppTextStyles.body()),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    ),
                    child: const Text(
                      "Register Now",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
