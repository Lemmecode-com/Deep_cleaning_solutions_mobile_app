// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'cart_provider.dart'; // ✅ NEW: needed to re-sync cart after auth changes
import 'wishlist_provider.dart'; // ✅ FIX: needed to clear wishlist on logout

// ── Auth State ────────────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isInitialized;
  final Map<String, dynamic>? user;
  final String? error;

  // ✅ NEW: pending account-deletion tracking (DPDPA — 7-day grace period)
  final bool hasPendingDeletion;
  final String? deletionScheduledAt;
  final String? activeOrderWarning;

  const AuthState({
    this.isLoading     = false,
    this.isLoggedIn    = false,
    this.isInitialized = false,
    this.user,
    this.error,
    this.hasPendingDeletion  = false, // ✅ NEW
    this.deletionScheduledAt,         // ✅ NEW
    this.activeOrderWarning,          // ✅ NEW
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isInitialized,
    Map<String, dynamic>? user,
    String? error,
    bool? hasPendingDeletion,   // ✅ NEW
    String? deletionScheduledAt, // ✅ NEW
    String? activeOrderWarning,  // ✅ NEW
  }) {
    return AuthState(
      isLoading:     isLoading     ?? this.isLoading,
      isLoggedIn:    isLoggedIn    ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized,
      user:          user          ?? this.user,
      error:         error         ?? this.error,
      hasPendingDeletion:  hasPendingDeletion  ?? this.hasPendingDeletion,
      deletionScheduledAt: deletionScheduledAt ?? this.deletionScheduledAt,
      activeOrderWarning:  activeOrderWarning  ?? this.activeOrderWarning,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final Ref _ref; // ✅ NEW

  AuthNotifier(this._ref) : super(const AuthState()) { // ✅ CHANGED
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
        // ✅ NEW: app-startup वेळी already-logged-in असेल तर cart पण
        // token-bound session शी sync कर (CartNotifier चा constructor
        // हा provider पहिल्यांदा read होतो तेव्हाच चालतो — तोपर्यंत
        // token attach झालेला नसू शकतो, म्हणून इथे परत sync करणं गरजेचं).
        await _ref.read(cartProvider.notifier).getCart();
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
      // ✅ NEW: register response मध्ये token मिळतो, म्हणजे यापुढे सगळे
      // calls Authorization header सोबत जातील — cart sync कर.
      await _ref.read(cartProvider.notifier).getCart();
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
      // ✅ NEW: token आता attach झालाय — backend ला logged-in user चा
      // (कदाचित वेगळा/रिकामा) cart दिसतो. Local cart state त्या
      // खऱ्या session शी sync कर, नाहीतर checkout वर stale items +
      // ₹0 totals दिसतात (server cart रिकामा असल्यामुळे).
      await _ref.read(cartProvider.notifier).getCart();
      // ✅ FIX: नवीन user login झाल्यावर त्याचा स्वतःचा wishlist लोड कर —
      // आधीच्या (जर कुणी logout न करता दुसरा user login केला तर) किंवा
      // guest state चा stale wishlist data राहू नये.
      await _ref.read(wishlistProvider.notifier).getWishlist();
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
      // ✅ NEW: token हटला — आता guest-id सोबत cart परत fetch कर,
      // जेणेकरून UI मध्ये मागच्या logged-in session चा cart राहणार नाही.
      await _ref.read(cartProvider.notifier).getCart();
      // ✅ FIX: wishlist हे wishlist API नुसार पूर्णपणे logged-in-user-only
      // ahे (guest ला wishlist नसतो) — logout झाल्यावर आधीच्या user चा
      // wishlist data (heart icons + count) local state मधून clear करणं
      // गरजेचं, नाहीतर तो तसाच UI वर दिसत राहतो जोपर्यंत कुणी परत login
      // करून खरा (कदाचित रिकामा) wishlist fetch करत नाही.
      await _ref.read(wishlistProvider.notifier).clearWishlist();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Get Profile ────────────────────────────────────────────────────
  Future<void> getProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.getProfile();
      final userData = response['user'];
      state = state.copyWith(
        isLoading:     false,
        isLoggedIn:    true,
        isInitialized: true,
        user:          userData,
        // ✅ NEW: server-side pending deletion status sync — app restart
        // झाल्यावरही "Cancel Deletion" banner टिकून राहावं म्हणून.
        // (server च्या /auth/profile response मध्ये deletion_scheduled_at
        // field असेल तर तो इथे पकडला जातो; नसेल तर काहीही परिणाम नाही.)
        hasPendingDeletion:  userData?['deletion_scheduled_at'] != null,
        deletionScheduledAt: userData?['deletion_scheduled_at']?.toString(),
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

  // ── Delete Account ────────────────────────────────────────────────
  // ✅ NEW: schedules deletion (7-day grace period). Account logged-in
  // राहतो — logout करत नाही, कारण grace period मध्ये user कधीही
  // cancel करू शकतो (see cancelAccountDeletion() खाली).
  Future<Map<String, dynamic>?> deleteAccount({
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.deleteAccount(password: password);
      state = state.copyWith(
        isLoading:           false,
        hasPendingDeletion:  true,
        deletionScheduledAt: response['deletion_scheduled_at']?.toString(),
        activeOrderWarning:  response['active_order_warning']?.toString(),
      );
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  // ── Cancel Account Deletion ───────────────────────────────────────
  Future<bool> cancelAccountDeletion() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.cancelAccountDeletion();
      // ⚠️ copyWith चा `??` pattern null override करू शकत नाही, म्हणून
      // इथे state पूर्ण नव्याने बनवली — hasPendingDeletion/deletionScheduledAt
      // खरंच false/null करण्यासाठी हे गरजेचं आहे.
      state = AuthState(
        isLoading:      false,
        isLoggedIn:     state.isLoggedIn,
        isInitialized:  state.isInitialized,
        user:           state.user,
        hasPendingDeletion:  false,
        deletionScheduledAt: null,
        activeOrderWarning:  null,
      );
      return true;
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
      (ref) => AuthNotifier(ref), // ✅ CHANGED: ref pass केला
);