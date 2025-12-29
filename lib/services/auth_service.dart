import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// Authentication Service
/// Handles all authentication operations with Supabase
class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  /// Returns the created user or throws an exception
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw Exception('Signup failed: No user returned');
      }

      return response.user!;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  /// Returns the authenticated user or throws an exception
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      return response.user!;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.parkingapp://login-callback',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in with Apple OAuth
  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.parkingapp://login-callback',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Apple sign-in failed: ${e.toString()}');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.parkingapp://reset-password',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Fetch user profile from database with dual role support
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, phone, role, is_renter, is_host, created_at, onboarding_completed')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      // Return null if profile doesn't exist yet (trigger may be creating it)
      return null;
    }
  }

  /// Enable renter functionality for current user
  /// Call this when user logs into the RENTER app
  Future<void> enableRenterRole() async {
    if (currentUser == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'is_renter': true})
          .eq('id', currentUser!.id);
    } catch (e) {
      throw Exception('Error enabling renter role: ${e.toString()}');
    }
  }

  /// Check if user is a renter
  Future<bool> isRenter() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_renter')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['is_renter'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is a host
  Future<bool> isHost() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_host')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['is_host'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    bool? onboardingCompleted,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (onboardingCompleted != null) {
        updates['onboarding_completed'] = onboardingCompleted;
      }

      if (updates.isEmpty) return;

      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  /// Handle Supabase auth exceptions and provide user-friendly messages
  String _handleAuthException(AuthException e) {
    switch (e.message.toLowerCase()) {
      case String msg when msg.contains('user already registered'):
      case String msg when msg.contains('already been registered'):
        return 'This email is already registered. Please sign in instead.';

      case String msg when msg.contains('invalid login credentials'):
      case String msg when msg.contains('invalid email or password'):
        return 'Invalid email or password. Please try again.';

      case String msg when msg.contains('email not confirmed'):
        return 'Please verify your email before signing in.';

      case String msg when msg.contains('invalid email'):
        return 'Please enter a valid email address.';

      case String msg when msg.contains('password'):
        return 'Password must be at least 6 characters.';

      default:
        return e.message;
    }
  }
}
