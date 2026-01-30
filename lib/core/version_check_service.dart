import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'supabase_config.dart';

class VersionCheckService {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.heybanni.parkdady.user';

  static String? _currentVersion;
  static String? _latestVersion;
  static bool? _forceUpdate;

  static Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
  }

  static String get currentVersion => _currentVersion ?? '1.0.0';

  static Future<VersionCheckResult> checkForUpdate() async {
    try {
      await initialize();

      // Fetch latest version info from Supabase
      final response = await SupabaseConfig.client
          .from('app_config')
          .select('value')
          .eq('key', 'android_min_version')
          .maybeSingle();

      final forceResponse = await SupabaseConfig.client
          .from('app_config')
          .select('value')
          .eq('key', 'android_force_update')
          .maybeSingle();

      final latestResponse = await SupabaseConfig.client
          .from('app_config')
          .select('value')
          .eq('key', 'android_latest_version')
          .maybeSingle();

      if (response == null) {
        return VersionCheckResult(
          status: VersionStatus.upToDate,
          currentVersion: currentVersion,
        );
      }

      final minVersion = response['value'] as String? ?? '1.0.0';
      _latestVersion = latestResponse?['value'] as String? ?? minVersion;
      _forceUpdate = forceResponse?['value']?.toString().toLowerCase() == 'true';

      final currentVersionParts = _parseVersion(currentVersion);
      final minVersionParts = _parseVersion(minVersion);
      final latestVersionParts = _parseVersion(_latestVersion!);

      // Check if current version is below minimum required
      if (_compareVersions(currentVersionParts, minVersionParts) < 0) {
        return VersionCheckResult(
          status: VersionStatus.updateRequired,
          currentVersion: currentVersion,
          latestVersion: _latestVersion,
          forceUpdate: true,
        );
      }

      // Check if there's an optional update available
      if (_compareVersions(currentVersionParts, latestVersionParts) < 0) {
        return VersionCheckResult(
          status: VersionStatus.updateAvailable,
          currentVersion: currentVersion,
          latestVersion: _latestVersion,
          forceUpdate: _forceUpdate ?? false,
        );
      }

      return VersionCheckResult(
        status: VersionStatus.upToDate,
        currentVersion: currentVersion,
        latestVersion: _latestVersion,
      );
    } catch (e) {
      // If version check fails, allow app to continue
      return VersionCheckResult(
        status: VersionStatus.checkFailed,
        currentVersion: currentVersion,
        error: e.toString(),
      );
    }
  }

  static List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  static int _compareVersions(List<int> v1, List<int> v2) {
    for (var i = 0; i < 3; i++) {
      final a = i < v1.length ? v1[i] : 0;
      final b = i < v2.length ? v2[i] : 0;
      if (a < b) return -1;
      if (a > b) return 1;
    }
    return 0;
  }

  static Future<void> openPlayStore() async {
    if (Platform.isAndroid) {
      final uri = Uri.parse(_playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<bool?> showUpdateDialog(
    BuildContext context,
    VersionCheckResult result,
  ) async {
    final isForceUpdate = result.forceUpdate;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => PopScope(
        canPop: !isForceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isForceUpdate ? Icons.warning_amber_rounded : Icons.system_update,
                color: isForceUpdate ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 12),
              Text(
                isForceUpdate ? 'Update Required' : 'Update Available',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isForceUpdate
                    ? 'A new version of Park Daddy is required to continue. Please update to the latest version.'
                    : 'A new version of Park Daddy is available! Update now to enjoy the latest features and improvements.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'v${result.currentVersion}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[400],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'v${result.latestVersion ?? "New"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                openPlayStore();
                if (isForceUpdate) {
                  // Don't close dialog for force update
                } else {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Update Now',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum VersionStatus {
  upToDate,
  updateAvailable,
  updateRequired,
  checkFailed,
}

class VersionCheckResult {
  final VersionStatus status;
  final String currentVersion;
  final String? latestVersion;
  final bool forceUpdate;
  final String? error;

  VersionCheckResult({
    required this.status,
    required this.currentVersion,
    this.latestVersion,
    this.forceUpdate = false,
    this.error,
  });

  bool get needsUpdate =>
      status == VersionStatus.updateAvailable ||
      status == VersionStatus.updateRequired;
}
