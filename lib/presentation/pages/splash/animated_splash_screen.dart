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
import 'dart:math' as math;

class AnimatedSplashScreen extends ConsumerStatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  ConsumerState<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends ConsumerState<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _circleScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _rippleAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Main controller for entire animation sequence
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    // Logo scale animation (zoom in with strong elastic bounce)
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    // Logo rotate animation (full rotation for dramatic effect)
    _logoRotateAnimation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // Circle background animation (expand with overshoot)
    _circleScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    // Ripple effect animation (continuous pulse)
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
    ));

    // Text fade in animation (smooth fade)
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
    ));

    // Text slide up animation (from below)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimation() {
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 3500));

      if (_hasNavigated) return;

      // Check current session
      final currentSession = SupabaseConfig.client.auth.currentSession;
      final currentUser = SupabaseConfig.client.auth.currentUser;
      final providerAuth = ref.read(isAuthenticatedProvider);

      final isAuthenticated = (currentSession != null && currentUser != null) || providerAuth;

      if (isAuthenticated) {
        _navigateToMainApp();
      } else {
        final hasRequestedPermissions = await PermissionService.hasRequestedPermissions();

        if (hasRequestedPermissions) {
          _navigateToAuth();
        } else {
          _navigateToPermissions();
        }
      }
    } catch (e) {
      _navigateToAuth();
    }
  }

  void _navigateToMainApp() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _navigateToAuth() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _navigateToPermissions() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PermissionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.ctaPrimary,
              AppColors.ctaPrimary.withValues(alpha: 0.9),
              const Color(0xFF1a1a1a),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles/dots
            ...List.generate(20, (index) {
              final offset = (index * 0.05);
              final progress = (_mainController.value - offset).clamp(0.0, 1.0);
              final random = (index * 137.5) % 1.0;

              return Positioned(
                left: MediaQuery.of(context).size.width * random,
                top: MediaQuery.of(context).size.height * ((index * 0.07) % 1.0),
                child: Opacity(
                  opacity: (math.sin(progress * math.pi) * 0.3).clamp(0.0, 0.3),
                  child: Container(
                    width: 4 + (random * 6),
                    height: 4 + (random * 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple effect circles (enhanced)
                      ...List.generate(4, (index) {
                        final delay = index * 0.08;
                        final progress = (_rippleAnimation.value - delay).clamp(0.0, 1.0);

                        return Opacity(
                          opacity: (1 - progress) * 0.4,
                          child: Transform.scale(
                            scale: 1 + (progress * 2.5),
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Outer glow circle
                      Transform.scale(
                        scale: _circleScaleAnimation.value,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Inner background circle
                      Transform.scale(
                        scale: _circleScaleAnimation.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 50,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Parking icon with enhanced animations
                      Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotateAnimation.value * math.pi,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF5F5F5),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppColors.ctaPrimary.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_parking,
                              size: 85,
                              color: AppColors.ctaPrimary,
                            ),
                          ),
                        ),
                      ),

                      // App name and tagline below the icon
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.5 + 100,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: FadeTransition(
                            opacity: _textFadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  AppConstants.appName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppConstants.appTagline,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
