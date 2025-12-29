import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../presentation/widgets/custom_button.dart';
import '../presentation/widgets/custom_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check terms agreement
    if (!_agreedToTerms) {
      _showError('Please agree to terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign up
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created! Please check your email to verify.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      // Go back to login
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      // OAuth will redirect, no need to navigate
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignup() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithApple();
      // OAuth will redirect, no need to navigate
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: colorScheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppConstants.spacing64),

                // Header
                Row(
                  children: [
                    Container(
                      width: AppConstants.spacing56,
                      height: AppConstants.spacing56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.ctaPrimary,
                            AppColors.ctaPrimary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.radius16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ctaPrimary.withOpacity(0.2),
                            blurRadius: AppConstants.elevation2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_parking_outlined,
                        color: AppColors.getButtonPrimaryText(context),
                        size: AppConstants.fontSize24,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: AppConstants.fontSize32,
                              fontWeight: AppConstants.fontWeightBold,
                              color: AppColors.getPrimaryText(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing4),
                          Text(
                            'Join us today',
                            style: TextStyle(
                              fontSize: AppConstants.fontSize16,
                              fontWeight: AppConstants.fontWeightRegular,
                              color: AppColors.getSecondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppConstants.spacing48),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        validator: _validateName,
                        prefixIcon: const Icon(Icons.person_outline),
                        enabled: !_isLoading,
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      CustomTextField(
                        label: 'Email',
                        hintText: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                        enabled: !_isLoading,
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      CustomTextField(
                        label: 'Password',
                        hintText: 'Create a password (min 6 characters)',
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: _validatePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        enabled: !_isLoading,
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      CustomTextField(
                        label: 'Confirm Password',
                        hintText: 'Confirm your password',
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        validator: _validateConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                        enabled: !_isLoading,
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      // Terms checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: _isLoading ? null : (value) => setState(() => _agreedToTerms = value ?? false),
                            activeColor: AppColors.ctaPrimary,
                            checkColor: AppColors.getButtonPrimaryText(context),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: AppConstants.spacing12),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSize14,
                                    color: AppColors.getPrimaryText(context),
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(
                                        color: AppColors.ctaPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.ctaPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppConstants.spacing32),

                      // Social buttons
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignup,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(AppConstants.spacing16),
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius12),
                          ),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.google, size: 18, color: Color(0xFF4285F4)),
                        label: Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: AppConstants.fontSize14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: AppConstants.spacing12),

                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleAppleSignup,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(AppConstants.spacing16),
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius12),
                          ),
                        ),
                        icon: FaIcon(FontAwesomeIcons.apple, size: 18, color: colorScheme.onSurface),
                        label: Text(
                          'Continue with Apple',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: AppConstants.fontSize14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: AppConstants.spacing24),

                      // Signup button
                      CustomButton(
                        text: 'Create Account',
                        onPressed: _isLoading ? null : _handleSignup,
                        isLoading: _isLoading,
                        icon: Icons.person_add,
                      ),

                      SizedBox(height: AppConstants.spacing32),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: AppColors.getSecondaryText(context),
                              fontSize: AppConstants.fontSize14,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.ctaPrimary,
                                fontSize: AppConstants.fontSize14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppConstants.spacing32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
