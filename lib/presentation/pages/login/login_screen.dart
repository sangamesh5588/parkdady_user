import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/user.dart' as domain_user;
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logo_widget.dart';
import '../main_navigation.dart';
import '../profile/web_view_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    if (value.length > AppConstants.maxEmailLength) {
      return 'Email is too long';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password is too long';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Privacy Policy to continue'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('LoginScreen: Starting login process');
        await ref.read(authProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        print('LoginScreen: Auth successful, checking user state');
        final user = ref.read(authProvider);
        print('LoginScreen: User state: ${user != null ? 'exists' : 'null'}');

        if (!mounted) {
          print('LoginScreen: Widget not mounted, aborting navigation');
          return;
        }

        setState(() => _isLoading = false);

        print('LoginScreen: Navigating to main app');
        // Navigate to main app using MaterialPageRoute to avoid route table issues
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
        print('LoginScreen: Navigation completed');

      } catch (e, stackTrace) {
        print('LoginScreen: Login error: $e');
        print('LoginScreen: Stack trace: $stackTrace');

        if (!mounted) return;

        setState(() => _isLoading = false);

        // Provide more user-friendly error messages
        String errorMessage = 'Login failed';
        String errorDetails = e.toString().toLowerCase();
        bool isEmailNotConfirmed = errorDetails.contains('email not confirmed') ||
                                    errorDetails.contains('email_not_confirmed');

        if (isEmailNotConfirmed) {
          errorMessage = 'Please verify your email address before logging in. Check your inbox for the verification link.';
        } else if (errorDetails.contains('invalid login credentials')) {
          errorMessage = 'Invalid email or password. Please check your credentials.';
        } else if (errorDetails.contains('network') ||
                   errorDetails.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (errorDetails.contains('too many requests')) {
          errorMessage = 'Too many login attempts. Please try again later.';
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            duration: const Duration(seconds: 6),
            action: isEmailNotConfirmed
                ? SnackBarAction(
                    label: 'Resend',
                    textColor: Colors.white,
                    onPressed: () => _resendVerificationEmail(),
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Privacy Policy to continue'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Call Google sign-in
      await ref.read(authProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      // Wait a moment for auth state to update
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Check if user is actually authenticated
      final user = ref.read(authProvider);

      setState(() => _isLoading = false);

      if (user != null) {
        // User successfully signed in, navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        // User cancelled or sign-in failed
        print('Google sign-in cancelled or failed - user is null');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Only show error if it's not a cancellation
      if (!e.toString().toLowerCase().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).resendVerificationEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent to $email. Please check your inbox.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend verification email: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Privacy Policy to continue'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Call Apple sign-in
      await ref.read(authProvider.notifier).signInWithApple();

      if (!mounted) return;

      // Wait a moment for auth state to update
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Check if user is actually authenticated
      final user = ref.read(authProvider);

      setState(() => _isLoading = false);

      if (user != null) {
        // User successfully signed in, navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        // User cancelled or sign-in failed
        print('Apple sign-in cancelled or failed - user is null');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Only show error if it's not a cancellation
      if (!e.toString().toLowerCase().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple sign-in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
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
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: AppConstants.fontSize32,
                              fontWeight: AppConstants.fontWeightBold,
                              color: AppColors.getPrimaryText(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing4),
                          Text(
                            'Sign in to continue',
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

                // Form - HIDDEN (kept for future use)
                Visibility(
                  visible: false,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          hintText: 'Enter your password',
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

                        // Forgot Password - Urban Company style
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.spacing12,
                                vertical: AppConstants.spacing8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.radius8),
                              ),
                            ),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: AppColors.ctaPrimary,
                                fontSize: AppConstants.fontSize14,
                                fontWeight: AppConstants.fontWeightSemiBold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: AppConstants.spacing32),
                      ],
                    ),
                  ),
                ),

                // Social Login Buttons - Official branding
                Column(
                  children: [
                    // Google Sign In
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

                    // Apple Sign In
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

                    SizedBox(height: AppConstants.spacing24),

                    // Terms and Privacy Policy Agreement
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            activeColor: AppColors.ctaPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        SizedBox(width: AppConstants.spacing12),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                'I agree to the ',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSize14,
                                  color: AppColors.getSecondaryText(context),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const WebViewScreen(
                                        url: 'https://www.parkdady.com/terms-of-service',
                                        title: 'Terms of Service',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSize14,
                                    color: AppColors.ctaPrimary,
                                    fontWeight: AppConstants.fontWeightSemiBold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(
                                ' and ',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSize14,
                                  color: AppColors.getSecondaryText(context),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
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
                                    fontSize: AppConstants.fontSize14,
                                    color: AppColors.ctaPrimary,
                                    fontWeight: AppConstants.fontWeightSemiBold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: AppConstants.spacing32),

                    // Sign Up link - HIDDEN (kept for future use)
                    Visibility(
                      visible: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: TextStyle(
                              color: AppColors.getSecondaryText(context),
                              fontSize: AppConstants.fontSize14,
                              fontWeight: AppConstants.fontWeightRegular,
                            ),
                          ),
                          SizedBox(width: AppConstants.spacing4),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/signup'),
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
                              'Sign up',
                              style: TextStyle(
                                color: AppColors.ctaPrimary,
                                fontSize: AppConstants.fontSize14,
                                fontWeight: AppConstants.fontWeightSemiBold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppConstants.spacing32),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
