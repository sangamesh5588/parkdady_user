import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isCheckingVerification = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          ),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Email icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.ctaPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 50,
                  color: AppColors.ctaPrimary,
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Title
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: AppConstants.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.spacing16),

              // Description
              Text(
                'We\'ve sent a verification link to',
                style: TextStyle(
                  fontSize: AppConstants.fontSize16,
                  color: AppColors.getSecondaryText(context),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.spacing8),

              // Email address
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: AppConstants.fontSize16,
                  fontWeight: AppConstants.fontWeightSemiBold,
                  color: AppColors.ctaPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.ctaPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.ctaPrimary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.ctaPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps:',
                          style: TextStyle(
                            fontSize: AppConstants.fontSize16,
                            fontWeight: AppConstants.fontWeightSemiBold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem('1. Check your email inbox'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('2. Click the verification link'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('3. Return here and tap "I\'ve Verified"'),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // I've verified button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCheckingVerification ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                    ),
                    elevation: 0,
                  ),
                  child: _isCheckingVerification
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'I\'ve Verified My Email',
                          style: TextStyle(
                            fontSize: AppConstants.fontSize16,
                            fontWeight: AppConstants.fontWeightSemiBold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppConstants.spacing16),

              // Resend email button
              TextButton(
                onPressed: _isResending ? null : _resendVerificationEmail,
                child: _isResending
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
                        ),
                      )
                    : Text(
                        'Didn\'t receive the email? Resend',
                        style: TextStyle(
                          fontSize: AppConstants.fontSize14,
                          color: AppColors.ctaPrimary,
                          fontWeight: AppConstants.fontWeightSemiBold,
                        ),
                      ),
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Check spam folder note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Don\'t forget to check your spam/junk folder',
                        style: TextStyle(
                          fontSize: AppConstants.fontSize12,
                          color: Colors.orange[900],
                        ),
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

  Widget _buildInstructionItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 18,
          color: AppColors.ctaPrimary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppConstants.fontSize14,
              color: AppColors.getSecondaryText(context),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);

    try {
      await ref.read(authProvider.notifier).resendVerificationEmail(widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Verification email sent to ${widget.email}'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Failed to resend: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isCheckingVerification = true);

    try {
      // Try to sign in to check if email is verified
      // This will fail if email is not verified
      final currentUser = ref.read(authProvider);

      if (currentUser != null) {
        // User is already signed in, navigate to main app
        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Email verified successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // User not signed in, show message to check email and return to login
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please click the verification link in your email first, then return to login.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please verify your email first using the link sent to ${widget.email}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }
}
