import 'dart:async';

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String provider;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.provider,
  });
}

class AuthService {
  static AuthUser? _currentUser;
  static final StreamController<AuthUser?> _authController = StreamController<AuthUser?>.broadcast();

  // Sign in with Google (Functional mock implementation)
  static Future<AuthUser?> signInWithGoogle() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful Google sign-in
      final mockUser = AuthUser(
        id: 'google_user_123',
        email: 'user@gmail.com',
        name: 'Google User',
        provider: 'google',
      );

      _currentUser = mockUser;
      _authController.add(_currentUser);
      return mockUser;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Sign in with Apple (Functional mock implementation)
  static Future<AuthUser?> signInWithApple() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful Apple sign-in
      final mockUser = AuthUser(
        id: 'apple_user_456',
        email: 'user@icloud.com',
        name: 'Apple User',
        provider: 'apple',
      );

      _currentUser = mockUser;
      _authController.add(_currentUser);
      return mockUser;
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    _currentUser = null;
    _authController.add(_currentUser);
  }

  // Get current user
  static AuthUser? get currentUser => _currentUser;

  // Auth state changes
  static Stream<AuthUser?> get authStateChanges => _authController.stream;
}
