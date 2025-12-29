import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/colors.dart';
import '../../../core/supabase_config.dart';
import '../../../core/permission_service.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../main_navigation.dart';
import '../login/login_screen.dart';
import 'permission_screen.dart';

class VideoSplashScreen extends ConsumerStatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  ConsumerState<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends ConsumerState<VideoSplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeApp();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/images/car.mp4');

    try {
      await _videoController.initialize();
      setState(() {
        _isVideoInitialized = true;
      });

      // Play the video
      _videoController.play();

      // Don't loop the video
      _videoController.setLooping(false);
    } catch (e) {
      // If video fails, proceed without it
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for video to finish or at least 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      if (_hasNavigated) return;

      // Check current session directly from Supabase
      final currentSession = SupabaseConfig.client.auth.currentSession;
      final currentUser = SupabaseConfig.client.auth.currentUser;

      // Also check our provider state
      final providerAuth = ref.read(isAuthenticatedProvider);

      // Consider user authenticated if either session exists or provider says authenticated
      final isAuthenticated = (currentSession != null && currentUser != null) || providerAuth;

      if (isAuthenticated) {
        // User is logged in, go directly to main app
        _navigateToMainApp();
      } else {
        // User is not logged in, proceed with first-time setup

        // Check if we've already requested permissions before
        final hasRequestedPermissions = await PermissionService.hasRequestedPermissions();

        if (hasRequestedPermissions) {
          // Already requested permissions, go to auth
          _navigateToAuth();
        } else {
          // First time user, show permission screen
          _navigateToPermissions();
        }
      }
    } catch (e) {
      // If there's any error, default to auth screen as safe fallback
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
      backgroundColor: Colors.black,
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ctaPrimary.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
    );
  }
}
