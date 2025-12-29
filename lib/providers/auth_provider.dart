import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../domain/entities/user.dart';
import '../services/auth_service.dart';

/// Auth State Notifier
/// Manages authentication state throughout the app
class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    _initAuth();
  }

  /// Initialize authentication state
  Future<void> _initAuth() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser);
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(supabase.User supabaseUser) async {
    try {
      // Enable renter role when user logs into RENTER app
      await _authService.enableRenterRole();

      // Retry profile fetch with delays (in case trigger is still creating it)
      Map<String, dynamic>? profile;

      for (int i = 0; i < 3; i++) {
        profile = await _authService.fetchUserProfile(supabaseUser.id);
        if (profile != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Update state with user data
      state = User.fromSupabaseUserWithProfile(supabaseUser, profile);
    } catch (e) {
      // Fallback to basic user data without profile
      state = User.fromSupabaseUserWithProfile(supabaseUser, null);
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final user = await _authService.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );

    await _loadUserProfile(user);
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    await _loadUserProfile(user);
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
    // OAuth flow will trigger auth state change listener
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    await _authService.signInWithApple();
    // OAuth flow will trigger auth state change listener
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    bool? onboardingCompleted,
  }) async {
    if (state == null) return;

    await _authService.updateProfile(
      userId: state!.id,
      fullName: fullName,
      phone: phone,
      onboardingCompleted: onboardingCompleted,
    );

    // Reload profile
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser);
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges() {
    _authService.authStateChanges.listen((authState) async {
      final event = authState.event;
      final session = authState.session;

      switch (event) {
        case supabase.AuthChangeEvent.signedIn:
        case supabase.AuthChangeEvent.initialSession:
        case supabase.AuthChangeEvent.tokenRefreshed:
        case supabase.AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            await _loadUserProfile(session!.user);
          }
          break;

        case supabase.AuthChangeEvent.signedOut:
          state = null;
          break;

        default:
          break;
      }
    });
  }
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  notifier.listenToAuthChanges();
  return notifier;
});

/// Authenticated user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider);
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});
