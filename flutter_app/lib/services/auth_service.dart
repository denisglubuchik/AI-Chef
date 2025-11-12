import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for authentication operations
class AuthService {
  final SupabaseClient _supabase;

  AuthService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthServiceException(e.message);
    } catch (e) {
      throw AuthServiceException('Failed to sign in: $e');
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Return true if email confirmation is needed
      return response.session == null;
    } on AuthException catch (e) {
      throw AuthServiceException(e.message);
    } catch (e) {
      throw AuthServiceException('Failed to sign up: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthServiceException('Failed to sign out: $e');
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}

/// Custom exception for auth service errors
class AuthServiceException implements Exception {
  final String message;

  AuthServiceException(this.message);

  @override
  String toString() => message;
}
