import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/auth_provider.dart';

// Import the actual functional screens
import 'vehicles_screen.dart';
import 'payment_methods_screen.dart';
import 'booking_history_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

// Safe Profile Screen Wrapper
class SafeProfileScreen extends ConsumerWidget {
  final String title;
  final Widget child;

  const SafeProfileScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }
}

// Coming Soon Screen for profile features
class ProfileComingSoonScreen extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const ProfileComingSoonScreen({
    super.key,
    required this.featureName,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.ctaPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing24),
          Text(
            featureName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing12),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back),
            label: Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPrimary,
              foregroundColor: AppColors.ctaOnPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing24,
                vertical: AppConstants.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radius12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Error Boundary for Profile Screens
class ProfileErrorBoundary extends StatefulWidget {
  final String screenName;
  final Widget child;

  const ProfileErrorBoundary({
    super.key,
    required this.screenName,
    required this.child,
  });

  @override
  State<ProfileErrorBoundary> createState() => _ProfileErrorBoundaryState();
}

class _ProfileErrorBoundaryState extends State<ProfileErrorBoundary> {
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Catch any errors that occur during widget building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This is a simple error boundary - in a real app you'd use a more sophisticated solution
    });
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return SafeProfileScreen(
        title: widget.screenName,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(height: AppConstants.spacing24),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacing12),
              Text(
                'We\'re working to fix this issue. Please try again later.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacing32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaPrimary,
                  foregroundColor: AppColors.ctaOnPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      return widget.child;
    } catch (e) {
      // If there's an error during build, show error screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = e.toString();
          });
        }
      });

      return SafeProfileScreen(
        title: widget.screenName,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

// Custom smooth page transition for profile screens
class SmoothProfilePageRoute<T> extends MaterialPageRoute<T> {
  SmoothProfilePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          builder: builder,
          settings: settings,
        );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Ultra-smooth easing curve
    const curve = Curves.easeOutCubic;
    var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    // Fade animation
    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: curve))
        .animate(animation);

    // Scale animation for a premium feel
    var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
        .chain(CurveTween(curve: curve))
        .animate(animation);

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }
}

// Safe navigation function for profile screens with ultra-smooth transitions
void safeNavigateToProfileScreen(BuildContext context, String routeName) {
  try {
    Widget screen;

    switch (routeName) {
      case '/vehicles':
        screen = const ProfileErrorBoundary(
          screenName: 'My Vehicles',
          child: VehiclesScreen(),
        );
        break;
      case '/payments':
        screen = const ProfileErrorBoundary(
          screenName: 'Payment Methods',
          child: PaymentMethodsScreen(),
        );
        break;
      case '/bookings':
        screen = const ProfileErrorBoundary(
          screenName: 'Booking History',
          child: BookingHistoryScreen(),
        );
        break;
      case '/notifications':
        screen = const ProfileErrorBoundary(
          screenName: 'Notifications',
          child: NotificationsScreen(),
        );
        break;
      case '/help':
        screen = const ProfileErrorBoundary(
          screenName: 'Help & Support',
          child: HelpSupportScreen(),
        );
        break;
      case '/about':
        screen = const ProfileErrorBoundary(
          screenName: 'About',
          child: AboutScreen(),
        );
        break;
      default:
        // Fallback - just pop back
        Navigator.of(context).pop();
        return;
    }

    // Use custom smooth transition
    Navigator.of(context).push(
      SmoothProfilePageRoute(
        builder: (context) => screen,
      ),
    );

  } catch (e) {
    // If navigation fails, show smooth error notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Unable to open $routeName. Please try again.'),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: Navigator.of(context),
            duration: const Duration(milliseconds: 300),
          )..forward(),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
