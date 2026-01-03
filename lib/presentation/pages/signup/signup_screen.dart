import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logo_widget.dart';
import '../profile/web_view_screen.dart';

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
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
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
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      setState(() => _isLoading = true);

      try {
        print('=== SIGNUP ATTEMPT ===');
        print('Email: ${_emailController.text.trim()}');
        print('Name: ${_nameController.text.trim()}');
        print('Password length: ${_passwordController.text.length}');

        await ref.read(authProvider.notifier).signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );

        print('=== SIGNUP SUCCESS ===');

        if (!mounted) return;

        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! Please check your email to verify your account.'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            duration: const Duration(seconds: 5),
          ),
        );
        // Navigate back to login screen
        Navigator.of(context).pop();
      } catch (e, stackTrace) {
        print('=== SIGNUP ERROR ===');
        print('Error: $e');
        print('Error type: ${e.runtimeType}');
        print('Stack trace: $stackTrace');

        if (!mounted) return;

        setState(() => _isLoading = false);

        // Extract more user-friendly error message
        String errorMessage = 'Signup failed';
        String errorDetails = e.toString();

        if (errorDetails.contains('User already registered') ||
            errorDetails.contains('already been registered')) {
          errorMessage = 'This email is already registered. Please login instead.';
        } else if (errorDetails.contains('Invalid email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (errorDetails.contains('Password should be at least 6 characters')) {
          errorMessage = 'Password must be at least 6 characters.';
        } else if (errorDetails.contains('Unable to validate email address')) {
          errorMessage = 'Invalid email format. Please check and try again.';
        } else if (errorDetails.contains('Email not confirmed')) {
          errorMessage = 'Please verify your email before logging in.';
        } else if (errorDetails.contains('Network')) {
          errorMessage = 'Network error. Please check your connection.';
        } else {
          // Show the actual error for debugging
          errorMessage = 'Signup failed: $errorDetails';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to terms and conditions'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      await ref.read(authProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-up failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      setState(() => _isLoading = true);

      await ref.read(authProvider.notifier).signInWithApple();

      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple sign-up failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
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

                // Urban Company-style header with improved spacing
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        validator: _validateName,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      CustomTextField(
                        label: 'Email',
                        hintText: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      CustomTextField(
                        label: 'Password',
                        hintText: 'Create a password',
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
                      ),

                      SizedBox(height: AppConstants.spacing16),

                      // Terms checkbox - Urban Company style
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                            activeColor: AppColors.ctaPrimary,
                            checkColor: AppColors.getButtonPrimaryText(context),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radius4),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: AppConstants.spacing12),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSize14,
                                    color: AppColors.getPrimaryText(context),
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const WebViewScreen(
                                                url: 'https://www.parkdady.com/terms-of-service',
                                                title: 'Terms & Conditions',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Terms & Conditions',
                                          style: TextStyle(
                                            color: AppColors.ctaPrimary,
                                            fontWeight: AppConstants.fontWeightSemiBold,
                                            decoration: TextDecoration.underline,
                                            fontSize: AppConstants.fontSize14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const WebViewScreen(
                                                url: 'https://www.parkdady.com/privacy-policy',
                                                title: 'Privacy Policy',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            color: AppColors.ctaPrimary,
                                            fontWeight: AppConstants.fontWeightSemiBold,
                                            decoration: TextDecoration.underline,
                                            fontSize: AppConstants.fontSize14,
                                          ),
                                        ),
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

                      // Social Login Buttons - Official branding
                      Column(
                        children: [
                          // Google Sign Up
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
                                side: BorderSide(color: colorScheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                                ),
                              ),
                              icon: FaIcon(
                                FontAwesomeIcons.google,
                                size: AppConstants.fontSize18,
                                color: const Color(0xFF4285F4), // Official Google blue
                              ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: AppConstants.fontSize14,
                                  fontWeight: AppConstants.fontWeightMedium,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: AppConstants.spacing12),

                          // Apple Sign Up
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleAppleSignIn,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
                                side: BorderSide(color: colorScheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                                ),
                              ),
                              icon: FaIcon(
                                FontAwesomeIcons.apple,
                                size: AppConstants.fontSize18,
                                color: colorScheme.onSurface, // Apple logo in black/white
                              ),
                              label: Text(
                                'Continue with Apple',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: AppConstants.fontSize14,
                                  fontWeight: AppConstants.fontWeightMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppConstants.spacing24),

                      // Create Account Button - Urban Company style
                      CustomButton(
                        text: 'Create Account',
                        onPressed: _handleSignup,
                        isLoading: _isLoading,
                        icon: Icons.person_add,
                      ),

                      SizedBox(height: AppConstants.spacing32),

                      // Sign In link - Urban Company style
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: AppColors.getSecondaryText(context),
                              fontSize: AppConstants.fontSize14,
                              fontWeight: AppConstants.fontWeightRegular,
                            ),
                          ),
                          SizedBox(width: AppConstants.spacing4),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.spacing8,
                                vertical: AppConstants.spacing4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.radius8),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.ctaPrimary,
                                fontSize: AppConstants.fontSize14,
                                fontWeight: AppConstants.fontWeightSemiBold,
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
