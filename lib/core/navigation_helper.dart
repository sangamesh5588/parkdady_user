import 'package:flutter/material.dart';

/// Safe navigation helper to prevent navigation errors
class NavigationHelper {
  /// Safely navigate to a route by name with mounted check
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    bool mounted = true,
  }) async {
    if (!mounted) return null;
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  /// Safely replace current route with named route
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    bool mounted = true,
  }) async {
    if (!mounted) return null;
    return Navigator.of(context).pushReplacementNamed<T, TO>(routeName);
  }

  /// Safely pop current route
  static void pop<T extends Object?>(
    BuildContext context, [
    T? result,
    bool mounted = true,
  ]) {
    if (!mounted) return;
    Navigator.of(context).pop<T>(result);
  }

  /// Safely push a route and remove all previous routes until predicate
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    bool mounted = true,
  }) async {
    if (!mounted) return null;
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
    );
  }

  /// Safely show a snackbar with mounted check
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool mounted = true,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}
