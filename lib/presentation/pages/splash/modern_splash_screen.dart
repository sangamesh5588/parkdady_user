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

class ModernSplashScreen extends ConsumerStatefulWidget {
  const ModernSplashScreen({super.key});

  @override
  ConsumerState<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends ConsumerState<ModernSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particlesController;
  late AnimationController _progressController;

  // Logo animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _logoGlowAnimation;

  // Text animations
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  // Background animations
  late Animation<Color?> _bgColorAnimation;

  // Progress animation
  late Animation<double> _progressAnimation;

  bool _hasNavigated = false;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Main controller for overall timing
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Particles controller
    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    // Progress controller - make it faster
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotateAnimation = Tween<double>(
      begin: -0.15,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _logoGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    // Text animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Background color animation
    _bgColorAnimation = ColorTween(
      begin: AppColors.ctaPrimary,
      end: const Color(0xFF1a1a2e),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() {
    // Start main controller
    _mainController.forward();

    // Start logo animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
    });

    // Start text animation
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    // Start particles
    _particlesController.forward();

    // Start progress after logo is done
    Future.delayed(const Duration(milliseconds: 1500), () {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _particlesController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Supabase
      setState(() => _statusText = 'Connecting to services...');
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 2: Check authentication status
      setState(() => _statusText = 'Restoring session...');

      await Future.delayed(const Duration(milliseconds: 1200));

      final currentSession = SupabaseConfig.client.auth.currentSession;
      final currentUser = SupabaseConfig.client.auth.currentUser;
      final providerAuth = ref.read(isAuthenticatedProvider);

      final isAuthenticated = (currentSession != null && currentUser != null) || providerAuth;

      if (isAuthenticated) {
        setState(() => _statusText = 'Welcome back!');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToMainApp();
      } else {
        setState(() => _statusText = 'Setting up...');
        await Future.delayed(const Duration(milliseconds: 400));

        final hasRequestedPermissions = await PermissionService.hasRequestedPermissions();

        if (hasRequestedPermissions) {
          setState(() => _statusText = 'Ready to login!');
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToAuth();
        } else {
          setState(() => _statusText = 'First time setup...');
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToPermissions();
        }
      }
    } catch (e) {
      setState(() => _statusText = 'Loading...');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToAuth();
    }
  }

  void _navigateToMainApp() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      // Smoothly complete progress bar
      _progressController.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    }
  }

  void _navigateToAuth() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      // Smoothly complete progress bar
      _progressController.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    }
  }

  void _navigateToPermissions() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      // Smoothly complete progress bar
      _progressController.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const PermissionScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _progressController,
        ]),
        builder: (context, child) {
          // Force rebuild for pulse animation
          if (_logoController.isCompleted) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) setState(() {});
            });
          }

          return Container(
            color: Colors.white,
            child: Stack(
              children: [
                // Minimal content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Clean parking icon
                      _buildLogo(),

                      const SizedBox(height: 40),

                      // App name and tagline
                      _buildText(),

                      const SizedBox(height: 60),

                      // Clean progress indicator
                      _buildProgressIndicator(),

                      // Status text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          key: ValueKey<String>(_statusText),
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle bottom fade
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(25, (index) {
      final random = math.Random(index);
      final size = 3 + random.nextDouble() * 4;
      final opacity = 0.1 + random.nextDouble() * 0.3;

      return Positioned(
        left: MediaQuery.of(context).size.width * random.nextDouble(),
        top: MediaQuery.of(context).size.height * random.nextDouble(),
        child: AnimatedBuilder(
          animation: _particlesController,
          builder: (context, child) {
            final offset = math.sin(_particlesController.value * 2 * math.pi + index) * 10;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity * (0.5 + 0.5 * math.sin(_particlesController.value * math.pi))),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: size * 2,
                      spreadRadius: size * 0.5,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildLogo() {
    // Add a subtle pulse animation after the initial animation
    final pulseValue = _logoController.isCompleted
        ? (math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) * 0.02 + 1.0)
        : 1.0;

    return Transform.scale(
      scale: _logoScaleAnimation.value * pulseValue,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 50,
              offset: const Offset(0, 12),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return SlideTransition(
      position: _textSlideAnimation,
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: Column(
          children: [
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.black.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildRippleEffects() {
    return Stack(
      children: List.generate(3, (index) {
        final delay = index * 0.3;
        final progress = (_progressAnimation.value - delay).clamp(0.0, 1.0);

        return Center(
          child: Container(
            width: 200 + (progress * 100),
            height: 200 + (progress * 100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity((1 - progress) * 0.2),
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}
