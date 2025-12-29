import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app permissions across Android and iOS
class PermissionService {
  static const String _permissionsRequestedKey = 'permissions_requested';

  /// Check if permissions have been requested before
  static Future<bool> hasRequestedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  /// Mark that permissions have been requested
  static Future<void> markPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsRequestedKey, true);
  }

  /// Request all required permissions for the parking app
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.notification,
      Permission.storage,
    ];

    final Map<Permission, PermissionStatus> results = {};

    for (final permission in permissions) {
      final status = await permission.request();
      results[permission] = status;
    }

    // Mark that we've requested permissions
    await markPermissionsRequested();

    return results;
  }

  /// Check current status of all required permissions
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.notification,
      Permission.storage,
    ];

    final Map<Permission, PermissionStatus> statuses = {};

    for (final permission in permissions) {
      final status = await permission.status;
      statuses[permission] = status;
    }

    return statuses;
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    final statuses = await checkAllPermissions();
    return statuses.values.every((status) => status.isGranted);
  }

  /// Get user-friendly names for permissions
  static String getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Location Access';
      case Permission.camera:
        return 'Camera Access';
      case Permission.notification:
        return 'Notifications';
      case Permission.storage:
        return 'Storage Access';
      default:
        return permission.toString();
    }
  }

  /// Get description for each permission
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Find nearby parking spaces and get accurate directions';
      case Permission.camera:
        return 'Scan QR codes for parking bookings and payments';
      case Permission.notification:
        return 'Receive booking confirmations and parking reminders';
      case Permission.storage:
        return 'Save parking receipts and app data';
      default:
        return 'Required for app functionality';
    }
  }

  /// Get icon for each permission
  static String getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.location:
        return '📍';
      case Permission.camera:
        return '📷';
      case Permission.notification:
        return '🔔';
      case Permission.storage:
        return '💾';
      default:
        return '⚙️';
    }
  }

  /// Open app settings for manual permission management
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Request a specific permission
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }
}
