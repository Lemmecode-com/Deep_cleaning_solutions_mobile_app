// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

// ── Auth State ────────────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isInitialized;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isLoading     = false,
    this.isLoggedIn    = false,
    this.isInitialized = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isInitialized,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isLoading:     isLoading     ?? this.isLoading,
      isLoggedIn:    isLoggedIn    ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized,
      user:          user          ?? this.user,
      error:         error         ?? this.error,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _checkLoginStatus();
  }

  // ── Check Login Status ─────────────────────────────────────────────
  // ✅ App startup वेळी 401 आला तरी silently guest mode मध्ये जा
  Future<void> _checkLoginStatus() async {
    ApiClient.suppressUnauthorizedRedirect = true;
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await getProfile();
      } else {
        state = state.copyWith(isInitialized: true, isLoggedIn: false);
      }
    } catch (e) {
      state = state.copyWith(isInitialized: true, isLoggedIn: false);
    } finally {
      ApiClient.suppressUnauthorizedRedirect = false;
    }
  }
  // ── Register ───────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.register(
        name:     name,
        email:    email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        user:      response['user'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(
        email:    email,
        password: password,
      );
      state = state.copyWith(
        isLoading:     false,
        isLoggedIn:    true,
        isInitialized: true,
        user:          response['user'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.logout();
      state = const AuthState(isInitialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Profile ────────────────────────────────────────────────────
  Future<void> getProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.getProfile();
      state = state.copyWith(
        isLoading:     false,
        isLoggedIn:    true,
        isInitialized: true,
        user:          response['user'],
      );
    } catch (e) {
      // ✅ token invalid/expired — guest म्हणून continue करा, login ला force नको
      state = const AuthState(isInitialized: true, isLoggedIn: false);
    }
  }

  // ── Update Profile ─────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.updateProfile(
        name:  name,
        email: email,
        phone: phone,
      );
      state = state.copyWith(
        isLoading: false,
        user:      response['user'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Change Password ────────────────────────────────────────────────
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword:     newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────
  Future<bool> forgotPassword({
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
      return response['status'] == true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.resetPassword(
        token:       token,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return response['status'] == true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Clear Error ────────────────────────────────────────────────────
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Provider ──────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(),
);