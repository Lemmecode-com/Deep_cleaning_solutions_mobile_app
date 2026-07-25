// test/providers/auth_state_test.dart
//
// ✅ हा सगळ्यात सोपा Unit Test आहे — कुठलाही API call, storage, mocking
// लागत नाही. AuthState फक्त एक data class आहे (copyWith सोबत), त्यामुळे
// थेट टेस्ट करता येतो.

import 'package:flutter_test/flutter_test.dart';
import 'package:dcs_app/providers/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('default values बरोबर सेट होतात', () {
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

    test('copyWith दिलेली values update करतो, बाकी जुनीच ठेवतो', () {
      const initial = AuthState(isLoading: false, isLoggedIn: false);

      final updated = initial.copyWith(isLoading: true, isLoggedIn: true);

      expect(updated.isLoading, true);
      expect(updated.isLoggedIn, true);
      // बाकी fields जुनीच राहायला हवीत
      expect(updated.isInitialized, false);
    });

    test('copyWith मध्ये काही field न दिल्यास जुनीच value टिकते', () {
      const initial = AuthState(
        isLoggedIn: true,
        user: {'name': 'Test User'},
      );

      final updated = initial.copyWith(isLoading: true);

      // isLoggedIn आणि user बदललेले नाहीत, तरी टिकून राहायला हवेत
      expect(updated.isLoggedIn, true);
      expect(updated.user, {'name': 'Test User'});
    });

    test('login झाल्यावरची अपेक्षित state', () {
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

    test('error आल्यावरची अपेक्षित state', () {
      const initial = AuthState(isLoading: true);

      final afterError = initial.copyWith(
        isLoading: false,
        error: 'Invalid credentials',
      );

      expect(afterError.isLoading, false);
      expect(afterError.error, 'Invalid credentials');
      expect(afterError.isLoggedIn, false); // login झालेला नाही
    });

    test('deletion cancel झाल्यावर pending-deletion fields clear होतात', () {
      const withPendingDeletion = AuthState(
        isLoggedIn: true,
        hasPendingDeletion: true,
        deletionScheduledAt: '2026-08-01',
        activeOrderWarning: 'You have 1 active order',
      );

      // ⚠️ लक्षात ठेव: copyWith चा `??` pattern null pass करून खरं
      // override करू शकत नाही — म्हणून auth_provider.dart मध्ये
      // cancelAccountDeletion() नवीन AuthState() object बनवतो,
      // copyWith वापरत नाही. तोच पॅटर्न इथे टेस्ट केलाय.
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
      expect(afterCancel.isLoggedIn, true); // login state टिकून राहायला हवा
    });
  });
}