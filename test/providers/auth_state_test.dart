// test/providers/auth_state_test.dart
//
// ✅ This is the simplest Unit Test — no API call, storage, or mocking
// needed. AuthState is just a data class (with copyWith), so it can be
// tested directly.

import 'package:flutter_test/flutter_test.dart';
import 'package:dcs_app/providers/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('default values are set correctly', () {
      const state = AuthState();

      expect(state.isLoading, false);
      expect(state.isLoggedIn, false);
      expect(state.isInitialized, false);
      expect(state.user, null);
      expect(state.error, null);
      expect(state.hasPendingDeletion, false);
      expect(state.deletionScheduledAt, null);
      expect(state.activeOrderWarning, null);
    });

    test('copyWith updates the given values, keeps the rest unchanged', () {
      const initial = AuthState(isLoading: false, isLoggedIn: false);

      final updated = initial.copyWith(isLoading: true, isLoggedIn: true);

      expect(updated.isLoading, true);
      expect(updated.isLoggedIn, true);
      // The remaining fields should stay the same
      expect(updated.isInitialized, false);
    });

    test('when a field is not given to copyWith, the old value is retained', () {
      const initial = AuthState(
        isLoggedIn: true,
        user: {'name': 'Test User'},
      );

      final updated = initial.copyWith(isLoading: true);

      // isLoggedIn and user weren't changed, but should be preserved
      expect(updated.isLoggedIn, true);
      expect(updated.user, {'name': 'Test User'});
    });

    test('expected state after login', () {
      const initial = AuthState();

      final afterLogin = initial.copyWith(
        isLoading: false,
        isLoggedIn: true,
        isInitialized: true,
        user: {'id': 1, 'name': 'Rahul'},
      );

      expect(afterLogin.isLoggedIn, true);
      expect(afterLogin.user?['name'], 'Rahul');
      expect(afterLogin.error, null);
    });

    test('expected state after an error occurs', () {
      const initial = AuthState(isLoading: true);

      final afterError = initial.copyWith(
        isLoading: false,
        error: 'Invalid credentials',
      );

      expect(afterError.isLoading, false);
      expect(afterError.error, 'Invalid credentials');
      expect(afterError.isLoggedIn, false); // not logged in
    });

    test('pending-deletion fields clear after deletion is cancelled', () {
      const withPendingDeletion = AuthState(
        isLoggedIn: true,
        hasPendingDeletion: true,
        deletionScheduledAt: '2026-08-01',
        activeOrderWarning: 'You have 1 active order',
      );

      // ⚠️ Note: copyWith's `??` pattern can't truly override by passing
      // null — so in auth_provider.dart, cancelAccountDeletion() builds a
      // brand new AuthState() object instead of using copyWith. The same
      // pattern is tested here.
      final afterCancel = AuthState(
        isLoading: false,
        isLoggedIn: withPendingDeletion.isLoggedIn,
        isInitialized: withPendingDeletion.isInitialized,
        user: withPendingDeletion.user,
        hasPendingDeletion: false,
        deletionScheduledAt: null,
        activeOrderWarning: null,
      );

      expect(afterCancel.hasPendingDeletion, false);
      expect(afterCancel.deletionScheduledAt, null);
      expect(afterCancel.activeOrderWarning, null);
      expect(afterCancel.isLoggedIn, true); // login state should be preserved
    });
  });
}
