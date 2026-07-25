// test/providers/auth_notifier_test.dart
//
// ✅ हा टेस्ट AuthNotifier चा login/logout logic तपासतो — खरा API call
// किंवा internet न वापरता. AuthService च्या जागी खोटं (mock) AuthService
// वापरलंय — त्यामुळे आपण control करू शकतो: "login call आला की success
// data दे" किंवा "login call आला की error फेकून टाक".

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/services/auth_service.dart';

// ── Step 1: खोटं (mock) AuthService बनवा ────────────────────────────
// Mocktail चं Mock class बनवण्यासाठी हे `extends Mock` लागतं.
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  // ── प्रत्येक test आधी नवीन (कोरी) mock + container बनवा ────────────
  // म्हणजे एका test चा state दुसऱ्या test वर परिणाम करणार नाही.
  setUp(() {
    mockAuthService = MockAuthService();

    // ✅ AuthNotifier चा constructor सुरू होताच _checkLoginStatus() call
    // होतो, जो isLoggedIn() ला विचारतो. हे mock न केल्यास error येईल,
    // म्हणून डिफॉल्ट "logged out" behavior आधीच सेट करून ठेवतोय.
    when(() => mockAuthService.isLoggedIn())
        .thenAnswer((_) async => false);

    container = ProviderContainer(
      overrides: [
        // ✅ Step 2: authProvider ला सांगा — खरं AuthService() नको,
        // आपलं mockAuthService वापर.
        authProvider.overrideWith(
              (ref) => AuthNotifier(ref, authService: mockAuthService),
        ),
      ],
    );

    // टेस्ट संपल्यावर container clean करण्यासाठी
    addTearDown(container.dispose);
  });

  group('AuthNotifier.login', () {
    test('login यशस्वी झाल्यास isLoggedIn = true होतं', () async {
      // ── Arrange: mock ला सांगा यशस्वी response दे ──────────────────
      when(() => mockAuthService.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => {
        'user': {'id': 1, 'name': 'Rahul', 'email': 'rahul@test.com'},
      });

      // ✅ लक्षात ठेव: login() च्या आत cartProvider.getCart() आणि
      // wishlistProvider.getWishlist() पण call होतात. हे mock न करताही
      // test चालतो — कारण cart_provider.dart / wishlist_provider.dart
      // मधलं getCart()/getWishlist() स्वतःचा error स्वतःच पकडतं (catch
      // करून फक्त स्वतःची error state सेट करतं, वर rethrow करत नाही).
      // त्यामुळे आतमध्ये real ApiClient fail झाला तरी login() चा वरचा
      // try/catch त्यामुळे trigger होत नाही — login() ची state clean राहते.

      // ── Act: login() call करा ──────────────────────────────────────
      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login(
        email: 'rahul@test.com',
        password: 'correctpassword',
      );

      // ── Assert: state आणि return value बरोबर आहे का तपासा ──────────
      final state = container.read(authProvider);
      expect(result, true);
      expect(state.isLoggedIn, true);
      expect(state.isLoading, false);
      expect(state.error, null);
      expect(state.user?['name'], 'Rahul');
    });

    test('login चुकीच्या credentials मुळे fail झाल्यास error state सेट होते', () async {
      // ── Arrange: mock ला सांगा error फेकून दे ──────────────────────
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
      expect(state.isLoggedIn, false); // login झालेला नाही
      expect(state.isLoading, false);
      expect(state.error, contains('Invalid credentials'));
    });
  });

  group('AuthNotifier.logout', () {
    test('logout झाल्यावर state रिकामी (guest) होते', () async {
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