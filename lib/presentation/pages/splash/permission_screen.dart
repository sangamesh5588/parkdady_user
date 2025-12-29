import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../core/permission_service.dart';
import '../login/login_screen.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with TickerProviderStateMixin {
  bool _isRequesting = false;
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  final List<Permission> _requiredPermissions = [
    Permission.location,
    Permission.camera,
    Permission.notification,
    Permission.storage,
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final statuses = await PermissionService.checkAllPermissions();
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);

    try {
      final results = await PermissionService.requestAllPermissions();
      if (mounted) {
        setState(() {
          _permissionStatuses = results;
          _isRequesting = false;
        });

        // Navigate to login after requesting permissions
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToLogin();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permissions: $e')),
        );
      }
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _openSettings() async {
    await PermissionService.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to ${AppConstants.appName}!',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacing4),
                        Text(
                          'We need a few permissions to provide the best experience',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppConstants.spacing32),

              // Permission List
              Expanded(
                child: ListView.builder(
                  itemCount: _requiredPermissions.length,
                  itemBuilder: (context, index) {
                    final permission = _requiredPermissions[index];
                    final status = _permissionStatuses[permission];
                    final isGranted = status?.isGranted ?? false;
                    final isDenied = status?.isDenied ?? false;

                    return Container(
                      margin: EdgeInsets.only(bottom: AppConstants.spacing16),
                      padding: EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(AppConstants.radius16),
                        border: Border.all(
                          color: isGranted
                              ? Colors.green.shade200
                              : isDenied
                                  ? Colors.red.shade200
                                  : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isGranted
                                  ? Colors.green.shade100
                                  : isDenied
                                      ? Colors.red.shade100
                                      : AppColors.ctaPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.radius12),
                            ),
                            child: Center(
                              child: Text(
                                PermissionService.getPermissionIcon(permission),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),

                          SizedBox(width: AppConstants.spacing16),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PermissionService.getPermissionDisplayName(permission),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppConstants.spacing4),
                                Text(
                                  PermissionService.getPermissionDescription(permission),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: AppConstants.spacing12),

                          // Status Icon
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isGranted
                                  ? Colors.green.shade500
                                  : isDenied
                                      ? Colors.red.shade500
                                      : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isGranted
                                  ? Icons.check
                                  : isDenied
                                      ? Icons.close
                                      : Icons.schedule,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  // Grant Permissions Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestAllPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaPrimary,
                        foregroundColor: AppColors.ctaOnPrimary,
                        padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                        ),
                        elevation: 0,
                      ),
                      child: _isRequesting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaOnPrimary),
                              ),
                            )
                          : Text(
                              'Grant Permissions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing12),

                  // Skip for Now (Optional)
                  TextButton(
                    onPressed: _navigateToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing8),

                  // Settings Link
                  TextButton.icon(
                    onPressed: _openSettings,
                    icon: Icon(
                      Icons.settings,
                      size: 16,
                      color: AppColors.ctaPrimary,
                    ),
                    label: Text(
                      'Open Settings',
                      style: TextStyle(
                        color: AppColors.ctaPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacing8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
