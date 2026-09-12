// test/providers/auth_notifier_test.dart
//
// ✅ This test checks AuthNotifier's login/logout logic — without making a
// real API call or using the internet. A fake (mock) AuthService is used
// in place of AuthService — so we can control it: "when the login call
// comes, give a success response" or "when the login call comes, throw an
// error".

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/services/auth_service.dart';

// ── Step 1: Create a fake (mock) AuthService ────────────────────────
// This `extends Mock` is needed to create Mocktail's Mock class.
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  // ── Create a fresh mock + container before every test ──────────────
  // So one test's state doesn't affect another test.
  setUp(() {
    mockAuthService = MockAuthService();

    // ✅ As soon as AuthNotifier's constructor starts, it calls
    // _checkLoginStatus(), which asks isLoggedIn(). If this isn't mocked
    // an error will occur, so we set up a default "logged out" behavior
    // beforehand.
    when(() => mockAuthService.isLoggedIn())
        .thenAnswer((_) async => false);

    container = ProviderContainer(
      overrides: [
        // ✅ Step 2: Tell authProvider — don't use the real AuthService(),
        // use our mockAuthService.
        authProvider.overrideWith(
              (ref) => AuthNotifier(ref, authService: mockAuthService),
        ),
      ],
    );

    // To clean up the container after the test ends
    addTearDown(container.dispose);
  });

  group('AuthNotifier.login', () {
    test('isLoggedIn becomes true when login succeeds', () async {
      // ── Arrange: tell the mock to give a successful response ──────────────
      when(() => mockAuthService.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => {
        'user': {'id': 1, 'name': 'Rahul', 'email': 'rahul@test.com'},
      });

      // ✅ Note: inside login(), cartProvider.getCart() and
      // wishlistProvider.getWishlist() also get called. The test still
      // works without mocking these — because getCart()/getWishlist() in
      // cart_provider.dart / wishlist_provider.dart catch their own errors
      // (catching and setting only their own error state, not rethrowing).
      // So even if the real ApiClient fails internally, login()'s outer
      // try/catch doesn't get triggered by it — login()'s state stays
      // clean.

      // ── Act: call login() ──────────────────────────────────────
      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login(
        email: 'rahul@test.com',
        password: 'correctpassword',
      );

      // ── Assert: check that the state and return value are correct ──────────
      final state = container.read(authProvider);
      expect(result, true);
      expect(state.isLoggedIn, true);
      expect(state.isLoading, false);
      expect(state.error, null);
      expect(state.user?['name'], 'Rahul');
    });

    test('error state is set when login fails due to wrong credentials', () async {
      // ── Arrange: tell the mock to throw an error ──────────────────
      when(() => mockAuthService.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(Exception('Invalid credentials'));

      // ── Act ──────────────────────────────────────────────────────
      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login(
        email: 'rahul@test.com',
        password: 'wrongpassword',
      );

      // ── Assert ───────────────────────────────────────────────────
      final state = container.read(authProvider);
      expect(result, false);
      expect(state.isLoggedIn, false); // not logged in
      expect(state.isLoading, false);
      expect(state.error, contains('Invalid credentials'));
    });
  });

  group('AuthNotifier.logout', () {
    test('state becomes empty (guest) after logout', () async {
      when(() => mockAuthService.logout()).thenAnswer((_) async {});

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.isLoggedIn, false);
      expect(state.user, null);
      expect(state.isInitialized, true);
    });
  });
}
