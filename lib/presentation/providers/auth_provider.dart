import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user.dart' as domain_user;
import '../../core/supabase_config.dart';

class AuthNotifier extends StateNotifier<domain_user.User?> {
  AuthNotifier() : super(null) {
    // Initialize auth state when notifier is created
    _initializeAuthState();
  }

  bool _isInitialized = false;

  // Helper method to fetch user profile from database with retry
  Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
    const maxRetries = 3;
    const delayMs = 1000; // 1 second delay between retries

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await SupabaseConfig.client
            .from('profiles')
            .select('role, full_name')
            .eq('id', userId)
            .single();

        return response;
      } catch (e) {
        print('Error fetching user profile (attempt $attempt/$maxRetries): $e');

        // If this is not the last attempt, wait before retrying
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    // If all retries failed, return null (fallback to default)
    print('Failed to fetch user profile after $maxRetries attempts');
    return null;
  }

  Future<void> _initializeAuthState() async {
    if (_isInitialized) return;

    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser != null) {
        // Fetch user profile from database after authentication
        final profile = await _fetchUserProfile(currentUser.id);
        state = domain_user.User.fromSupabaseUserWithProfile(currentUser, profile);
      }
      _isInitialized = true;
    } catch (e) {
      print('Error initializing auth state: $e');
      _isInitialized = true;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      print('AuthProvider: Attempting sign in for email: $email');

      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('AuthProvider: Sign in response received');
      print('AuthProvider: Response user is null: ${response.user == null}');

      if (response.user != null) {
        print('AuthProvider: User found, ID: ${response.user!.id}');

        // Fetch user profile from database after authentication
        final profile = await _fetchUserProfile(response.user!.id);
        print('AuthProvider: Profile fetched: $profile');

        // Create user with defensive programming
        try {
          state = domain_user.User.fromSupabaseUserWithProfile(response.user!, profile);
          print('AuthProvider: User state updated successfully');
        } catch (userCreationError) {
          print('AuthProvider: Error creating user object: $userCreationError');
          // Fallback: create user without profile data
          state = domain_user.User.fromSupabaseUser(response.user!, name: response.user!.email);
          print('AuthProvider: Fallback user created');
        }
      } else {
        print('AuthProvider: WARNING - No user in sign in response');
        throw Exception('Sign in failed: No user data received');
      }
    } catch (e, stackTrace) {
      print('AuthProvider: Sign in error: $e');
      print('AuthProvider: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    try {
      print('AuthProvider: Starting signUp for email: $email');
      print('AuthProvider: Full name: $fullName');

      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      print('AuthProvider: SignUp response received');
      print('AuthProvider: User ID: ${response.user?.id}');
      print('AuthProvider: User email: ${response.user?.email}');
      print('AuthProvider: Session: ${response.session != null ? "exists" : "null"}');

      if (response.user != null) {
        print('AuthProvider: Fetching user profile for ID: ${response.user!.id}');
        // Fetch user profile from database after signup (profile should be auto-created by trigger)
        final profile = await _fetchUserProfile(response.user!.id);
        print('AuthProvider: Profile fetched: $profile');

        state = domain_user.User.fromSupabaseUserWithProfile(response.user!, profile);
        print('AuthProvider: User state updated successfully');
      } else {
        print('AuthProvider: WARNING - No user in signup response');
      }
    } catch (e, stackTrace) {
      print('AuthProvider: SignUp ERROR: $e');
      print('AuthProvider: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: 'io.supabase.parkingapp://login-callback',
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );
      // Note: OAuth will handle the redirect and state change listener will update state
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        supabase.OAuthProvider.apple,
        redirectTo: 'io.supabase.parkingapp://login-callback',
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );
      // Note: OAuth will handle the redirect and state change listener will update state
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      state = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Listen to auth state changes
  void listenToAuthChanges() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      switch (event) {
        case supabase.AuthChangeEvent.signedIn:
        case supabase.AuthChangeEvent.initialSession:
          if (session?.user != null) {
            final user = session!.user;
            // Fetch user profile from database after authentication
            final profile = await _fetchUserProfile(user.id);
            state = domain_user.User.fromSupabaseUserWithProfile(user, profile);
          }
          break;
        case supabase.AuthChangeEvent.signedOut:
          state = null;
          break;
        case supabase.AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            final user = session!.user;
            // Fetch updated profile after token refresh
            final profile = await _fetchUserProfile(user.id);
            state = domain_user.User.fromSupabaseUserWithProfile(user, profile);
          }
          break;
        case supabase.AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            final user = session!.user;
            // Fetch updated profile after user update
            final profile = await _fetchUserProfile(user.id);
            state = domain_user.User.fromSupabaseUserWithProfile(user, profile);
          }
          break;
        case supabase.AuthChangeEvent.passwordRecovery:
          // Handle password recovery if needed
          break;
        default:
          // Handle any other auth events
          break;
      }
    });
  }
}

// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, domain_user.User?>((ref) {
  final authNotifier = AuthNotifier();
  authNotifier.listenToAuthChanges();
  // Auth state is automatically initialized in constructor
  return authNotifier;
});

// Derived provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider);
  return user != null;
});
