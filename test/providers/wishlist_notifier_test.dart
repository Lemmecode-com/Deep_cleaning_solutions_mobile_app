// test/providers/wishlist_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/auth_provider.dart';
import 'package:dcs_app/providers/wishlist_provider.dart';
import 'package:dcs_app/services/auth_service.dart';
import 'package:dcs_app/services/wishlist_service.dart';

class MockWishlistService extends Mock implements WishlistService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockWishlistService mockWishlistService;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(0);
  });

  setUp(() {
    mockWishlistService = MockWishlistService();
    mockAuthService = MockAuthService();
    // ✅ AuthNotifier चा constructor `_checkLoginStatus()` आतल्या आत
    // `await _authService.isLoggedIn()` कॉल करतो. इथे synchronously
    // throw करून टाकलं की तो await पर्यंत पोचण्याआधीच try/catch मध्ये
    // settle होतो — म्हणजे constructor परत येईपर्यंत AuthState आधीच
    // ठरलेली असते (race condition टाळण्यासाठी). खालचा test प्रत्यक्ष
    // हवा तो login-state नंतर थेट force करतो.
    when(() => mockAuthService.isLoggedIn())
        .thenThrow(Exception('stub: real value forced below'));
  });

  // ✅ helper: container बनवतो, wishlistService + authService mock
  // घुसवतो, आणि authState थेट हवं तसं (logged-in / logged-out) force
  // करतो.
  ProviderContainer buildContainer({required bool loggedIn}) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
              (ref) => AuthNotifier(ref, authService: mockAuthService),
        ),
        wishlistProvider.overrideWith(
              (ref) => WishlistNotifier(ref, wishlistService: mockWishlistService),
        ),
      ],
    );
    addTearDown(container.dispose);

    // ignore: invalid_use_of_protected_member
    container.read(authProvider.notifier).state = AuthState(
      isLoggedIn: loggedIn,
      isInitialized: true,
    );
    return container;
  }

  group('getWishlist', () {
    test('logged-out असताना service call होत नाही', () async {
      final container = buildContainer(loggedIn: false);

      await container.read(wishlistProvider.notifier).getWishlist();

      verifyNever(() => mockWishlistService.getWishlist());
      expect(container.read(wishlistProvider).wishlistItems, isEmpty);
    });

    test('logged-in असताना items + count state मध्ये set करतो', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.getWishlist()).thenAnswer(
            (_) async => {
          'items': [
            {'id': 1},
            {'id': 2},
          ],
          'count': 2,
        },
      );

      await container.read(wishlistProvider.notifier).getWishlist();

      final state = container.read(wishlistProvider);
      expect(state.wishlistItems.length, 2);
      expect(state.wishlistCount, 2);
      expect(state.isLoading, false);
    });

    test('error आल्यास error state मध्ये set होतो', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.getWishlist())
          .thenThrow(Exception('network error'));

      await container.read(wishlistProvider.notifier).getWishlist();

      final state = container.read(wishlistProvider);
      expect(state.error, contains('network error'));
      expect(state.isLoading, false);
    });
  });

  group('addToWishlist', () {
    test('logged-out असताना login_required return करतो', () async {
      final container = buildContainer(loggedIn: false);

      final result =
      await container.read(wishlistProvider.notifier).addToWishlist(5);

      expect(result, 'login_required');
      verifyNever(() => mockWishlistService.addToWishlist(any()));
    });

    test('success झाल्यास wishlist refresh करून success return करतो',
            () async {
          final container = buildContainer(loggedIn: true);
          when(() => mockWishlistService.addToWishlist(5))
              .thenAnswer((_) async => {'status': true});
          when(() => mockWishlistService.getWishlist()).thenAnswer(
                (_) async => {
              'items': [
                {'id': 5},
              ],
              'count': 1,
            },
          );

          final result =
          await container.read(wishlistProvider.notifier).addToWishlist(5);

          expect(result, 'success');
          expect(container.read(wishlistProvider).wishlistItems.length, 1);
        });

    test('error आल्यास error return करतो', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.addToWishlist(5))
          .thenThrow(Exception('add failed'));

      final result =
      await container.read(wishlistProvider.notifier).addToWishlist(5);

      expect(result, 'error');
      expect(container.read(wishlistProvider).error, contains('add failed'));
    });
  });

  group('removeFromWishlist', () {
    test('logged-out असताना false return करतो', () async {
      final container = buildContainer(loggedIn: false);

      final result = await container
          .read(wishlistProvider.notifier)
          .removeFromWishlist(5);

      expect(result, false);
      verifyNever(() => mockWishlistService.removeFromWishlist(any()));
    });

    test('success झाल्यास wishlist refresh करतो', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.removeFromWishlist(5))
          .thenAnswer((_) async => {'status': true});
      when(() => mockWishlistService.getWishlist())
          .thenAnswer((_) async => {'items': [], 'count': 0});

      final result = await container
          .read(wishlistProvider.notifier)
          .removeFromWishlist(5);

      expect(result, true);
      expect(container.read(wishlistProvider).wishlistItems, isEmpty);
    });

    test('backend bug मुळे API error आला तरी item local state मधून काढतो',
            () async {
          final container = buildContainer(loggedIn: true);
          when(() => mockWishlistService.getWishlist()).thenAnswer(
                (_) async => {
              'items': [
                {'id': 5},
                {'id': 9},
              ],
              'count': 2,
            },
          );
          await container.read(wishlistProvider.notifier).getWishlist();

          when(() => mockWishlistService.removeFromWishlist(5))
              .thenThrow(Exception('backend bug'));

          final result = await container
              .read(wishlistProvider.notifier)
              .removeFromWishlist(5);

          final state = container.read(wishlistProvider);
          expect(result, true);
          expect(state.wishlistItems.length, 1);
          expect(state.wishlistItems.first['id'], 9);
          expect(state.error, isNull);
        });
  });

  group('toggleWishlist', () {
    test('logged-out असताना login_required return करतो', () async {
      final container = buildContainer(loggedIn: false);

      final result =
      await container.read(wishlistProvider.notifier).toggleWishlist(5);

      expect(result, 'login_required');
    });

    test('item आधीच wishlist मध्ये असेल तर remove करतो ("removed")',
            () async {
          final container = buildContainer(loggedIn: true);
          when(() => mockWishlistService.getWishlist()).thenAnswer(
                (_) async => {
              'items': [
                {'id': 5},
              ],
              'count': 1,
            },
          );
          await container.read(wishlistProvider.notifier).getWishlist();

          when(() => mockWishlistService.removeFromWishlist(5))
              .thenAnswer((_) async => {'status': true});
          when(() => mockWishlistService.getWishlist())
              .thenAnswer((_) async => {'items': [], 'count': 0});

          final result =
          await container.read(wishlistProvider.notifier).toggleWishlist(5);

          expect(result, 'removed');
        });

    test('item wishlist मध्ये नसेल तर add करतो ("success")', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.addToWishlist(5))
          .thenAnswer((_) async => {'status': true});
      when(() => mockWishlistService.getWishlist()).thenAnswer(
            (_) async => {
          'items': [
            {'id': 5},
          ],
          'count': 1,
        },
      );

      final result =
      await container.read(wishlistProvider.notifier).toggleWishlist(5);

      expect(result, 'success');
    });
  });

  group('clearWishlist', () {
    test('state पूर्णपणे reset करतो', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.getWishlist()).thenAnswer(
            (_) async => {
          'items': [
            {'id': 5},
          ],
          'count': 1,
        },
      );
      await container.read(wishlistProvider.notifier).getWishlist();

      final result =
      await container.read(wishlistProvider.notifier).clearWishlist();

      expect(result, true);
      final state = container.read(wishlistProvider);
      expect(state.wishlistItems, isEmpty);
      expect(state.wishlistCount, 0);
    });
  });

  group('isInWishlist', () {
    test('logged-out असताना नेहमी false', () async {
      final container = buildContainer(loggedIn: false);

      expect(
        container.read(wishlistProvider.notifier).isInWishlist(5),
        false,
      );
    });

    test('item state मध्ये असेल तरच true देतो', () async {
      final container = buildContainer(loggedIn: true);
      when(() => mockWishlistService.getWishlist()).thenAnswer(
            (_) async => {
          'items': [
            {'id': 5},
          ],
          'count': 1,
        },
      );
      await container.read(wishlistProvider.notifier).getWishlist();

      expect(container.read(wishlistProvider.notifier).isInWishlist(5), true);
      expect(
        container.read(wishlistProvider.notifier).isInWishlist(999),
        false,
      );
    });
  });

  group('clearError', () {
    test('फक्त error null करतो, बाकी state तशीच ठेवतो (copyWith bug fix)',
            () async {
          final container = buildContainer(loggedIn: true);
          when(() => mockWishlistService.getWishlist())
              .thenThrow(Exception('boom'));
          await container.read(wishlistProvider.notifier).getWishlist();
          expect(container.read(wishlistProvider).error, isNotNull);

          container.read(wishlistProvider.notifier).clearError();

          expect(container.read(wishlistProvider).error, isNull);
        });
  });

  group('derived providers', () {
    test('wishlistCountProvider wishlist state चा count reflect करतो',
            () async {
          final container = buildContainer(loggedIn: true);
          when(() => mockWishlistService.getWishlist()).thenAnswer(
                (_) async => {
              'items': [
                {'id': 1},
                {'id': 2},
                {'id': 3},
              ],
              'count': 3,
            },
          );
          await container.read(wishlistProvider.notifier).getWishlist();

          expect(container.read(wishlistCountProvider), 3);
        });

    test('isInWishlistProvider specific productId साठी बरोबर बूल देतो',
            () async {
          final container = buildContainer(loggedIn: true);
          when(() => mockWishlistService.getWishlist()).thenAnswer(
                (_) async => {
              'items': [
                {'id': 7},
              ],
              'count': 1,
            },
          );
          await container.read(wishlistProvider.notifier).getWishlist();

          expect(container.read(isInWishlistProvider(7)), true);
          expect(container.read(isInWishlistProvider(1)), false);
        });
  });
}