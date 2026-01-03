import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/auth_provider.dart';
import 'profile_wrapper.dart';

// Custom page transition for smooth navigation
class SmoothPageRoute<T> extends MaterialPageRoute<T> {
  SmoothPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          builder: builder,
          settings: settings,
        );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Custom smooth transition
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  late AnimationController _menuAnimationController;
  late List<Animation<double>> _menuItemAnimations;

  @override
  void initState() {
    super.initState();

    // Header animation with smoother curve
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );

    // Menu items staggered animation with better timing
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _menuItemAnimations = List.generate(6, (index) {
      final start = index * 0.08; // Reduced spacing for smoother feel
      final end = (start + 0.7).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuAnimationController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    // Start animations with optimized timing
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _menuAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile header with animation
              AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: _buildProfileHeader(context, userAsync),
                    ),
                  );
                },
              ),

              SizedBox(height: AppConstants.spacing32),

              // Menu items with staggered animations
              _buildMenuSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Column(
      children: [
        // Profile picture
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            size: 50,
            color: AppColors.getButtonPrimaryText(context),
          ),
        ),

        SizedBox(height: AppConstants.spacing16),

        // Name and email
        Text(
          user?.name ?? 'User',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),

        SizedBox(height: AppConstants.spacing4),

        Text(
          user?.email ?? '',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.getSecondaryText(context),
          ),
        ),

        SizedBox(height: AppConstants.spacing8),

        // Role badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing12,
            vertical: AppConstants.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radius20),
          ),
          child: Text(
            'Renter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ctaPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final menuItems = [
      {
        'icon': Icons.directions_car,
        'title': 'My Vehicles',
        'subtitle': 'Manage your vehicles',
        'route': '/vehicles',
      },
      {
        'icon': Icons.credit_card,
        'title': 'Payment Methods',
        'subtitle': 'Add or manage cards',
        'route': '/payments',
      },
      {
        'icon': Icons.history,
        'title': 'Booking History',
        'subtitle': 'View past bookings',
        'route': '/bookings',
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Manage preferences',
        'route': '/notifications',
      },
      {
        'icon': Icons.help,
        'title': 'Help & Support',
        'subtitle': 'Get help or contact us',
        'route': '/help',
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'subtitle': 'App version and info',
        'route': '/about',
      },
    ];

    return AnimatedBuilder(
      animation: _menuAnimationController,
      builder: (context, child) {
        return Column(
          children: [
            ...List.generate(menuItems.length, (index) {
              final item = menuItems[index];
              return AnimatedBuilder(
                animation: _menuItemAnimations[index],
                builder: (context, child) {
                  final slideOffset = 50.0 * (1 - _menuItemAnimations[index].value);
                  return Transform.translate(
                    offset: Offset(slideOffset, 0),
                    child: Opacity(
                      opacity: _menuItemAnimations[index].value,
                      child: _buildMenuItem(
                        context,
                        icon: item['icon'] as IconData,
                        title: item['title'] as String,
                        subtitle: item['subtitle'] as String,
                        route: item['route'] as String,
                      ),
                    ),
                  );
                },
              );
            }),

            SizedBox(height: AppConstants.spacing32),

            // Sign out button with animation
            AnimatedBuilder(
              animation: _menuAnimationController,
              builder: (context, child) {
                final signOutAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _menuAnimationController,
                    curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
                  ),
                );

                return Transform.translate(
                  offset: Offset(0, 30 * (1 - signOutAnimation.value)),
                  child: Opacity(
                    opacity: signOutAnimation.value,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSignOutDialog(context, ref),
                        icon: Icon(Icons.logout),
                        label: Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius12),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: AppConstants.spacing12),

            // Delete account button with animation
            AnimatedBuilder(
              animation: _menuAnimationController,
              builder: (context, child) {
                final deleteAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _menuAnimationController,
                    curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
                  ),
                );

                return Transform.translate(
                  offset: Offset(0, 30 * (1 - deleteAnimation.value)),
                  child: Opacity(
                    opacity: deleteAnimation.value,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteAccountDialog(context, ref),
                        icon: Icon(Icons.delete_forever),
                        label: Text('Delete Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius12),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.ctaPrimary),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              // Close the dialog
              Navigator.pop(dialogContext);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Signing out...',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.signOut();

                // Close loading dialog
                if (navigator.canPop()) {
                  navigator.pop();
                }

                // Navigate to login screen and remove all previous routes
                navigator.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );

                // Show success message
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Signed out successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                // Close loading dialog
                if (navigator.canPop()) {
                  navigator.pop();
                }

                // Show error message
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Failed to sign out: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _showSignOutDialog(context, ref),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone. All your data including:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            _buildDeleteWarningItem('Profile information'),
            _buildDeleteWarningItem('Booking history'),
            _buildDeleteWarningItem('Payment methods'),
            _buildDeleteWarningItem('Saved preferences'),
            SizedBox(height: 12),
            Text(
              'will be permanently deleted.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              // Close the dialog
              Navigator.pop(dialogContext);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Deleting account...',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.deleteAccount();

                // Close loading dialog
                if (navigator.canPop()) {
                  navigator.pop();
                }

                // Navigate to login screen and remove all previous routes
                navigator.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );

                // Show success message
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Account deleted successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                // Close loading dialog
                if (navigator.canPop()) {
                  navigator.pop();
                }

                // Show error message
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Failed to delete account: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.spacing8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radius8),
          ),
          child: Icon(
            icon,
            color: AppColors.ctaPrimary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getSecondaryText(context),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.getSecondaryText(context),
        ),
        onTap: () => safeNavigateToProfileScreen(context, route),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        ),
      ),
    );
  }
}
