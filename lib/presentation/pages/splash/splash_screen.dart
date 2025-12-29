import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../core/supabase_config.dart';
import '../../../core/permission_service.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../main_navigation.dart';
import '../login/login_screen.dart';
import 'permission_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoAnimation;
  late AnimationController _textAnimationController;
  late Animation<double> _textAnimation;

  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Text animation
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _logoAnimationController.forward().then((_) {
      _textAnimationController.forward();
    });

    // Start initialization process
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Supabase
      setState(() => _statusText = 'Connecting to services...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Check authentication status with session restoration
      setState(() => _statusText = 'Restoring session...');

      // Wait for Supabase to restore session from storage
      await Future.delayed(const Duration(milliseconds: 1200));

      // Check current session directly from Supabase
      final currentSession = SupabaseConfig.client.auth.currentSession;
      final currentUser = SupabaseConfig.client.auth.currentUser;

      print('SplashScreen: Current session: ${currentSession != null ? "exists" : "null"}');
      print('SplashScreen: Current user: ${currentUser != null ? "exists" : "null"}');
      print('SplashScreen: User email: ${currentUser?.email}');

      // Also check our provider state
      final providerAuth = ref.read(isAuthenticatedProvider);
      print('SplashScreen: Provider auth state: $providerAuth');

      // Consider user authenticated if either session exists or provider says authenticated
      final isAuthenticated = (currentSession != null && currentUser != null) || providerAuth;

      print('SplashScreen: Final authentication result: $isAuthenticated');

      if (isAuthenticated) {
        // User is logged in, go directly to main app
        setState(() => _statusText = 'Welcome back!');
        print('SplashScreen: User authenticated, navigating to main app');
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateToMainApp();
      } else {
        // User is not logged in, proceed with first-time setup
        print('SplashScreen: User not authenticated, proceeding with setup');
        setState(() => _statusText = 'Setting up...');
        await Future.delayed(const Duration(milliseconds: 300));

        // Check if we've already requested permissions before
        final hasRequestedPermissions = await PermissionService.hasRequestedPermissions();
        print('SplashScreen: Has requested permissions: $hasRequestedPermissions');

        if (hasRequestedPermissions) {
          // Already requested permissions, go to auth
          setState(() => _statusText = 'Ready to login!');
          await Future.delayed(const Duration(milliseconds: 400));
          _navigateToAuth();
        } else {
          // First time user, show permission screen
          setState(() => _statusText = 'First time setup...');
          await Future.delayed(const Duration(milliseconds: 400));
          _navigateToPermissions();
        }
      }
    } catch (e, stackTrace) {
      print('SplashScreen: Initialization error: $e');
      print('SplashScreen: Stack trace: $stackTrace');

      // If there's any error, default to auth screen as safe fallback
      setState(() => _statusText = 'Loading...');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToAuth();
    }
  }

  void _navigateToMainApp() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  void _navigateToAuth() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToPermissions() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.ctaPrimary.withOpacity(0.05),
              AppColors.primaryBackground,
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Animation
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.ctaPrimary,
                              AppColors.ctaPrimary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ctaPrimary.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_parking,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: AppConstants.spacing32),

                // App Name
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _textAnimation.value)),
                        child: Column(
                          children: [
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: AppConstants.spacing8),
                            Text(
                              'Find & Book Parking Spaces',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: AppConstants.spacing48),

                // Loading Indicator
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textAnimation.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.ctaPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing16),
                          Text(
                            _statusText,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Bottom spacing to prevent overflow on small screens
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
