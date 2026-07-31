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
    // ✅ AuthNotifier's constructor calls `await _authService.isLoggedIn()`
    // inside `_checkLoginStatus()`. By throwing synchronously here, it
    // settles in the try/catch before even reaching that await — meaning
    // AuthState is already decided by the time the constructor returns
    // (to avoid a race condition). The test below then directly forces
    // whatever login-state it actually needs.
    when(() => mockAuthService.isLoggedIn())
        .thenThrow(Exception('stub: real value forced below'));
  });

  // ✅ helper: builds the container, injects the wishlistService +
  // authService mocks, and directly forces authState to whatever we want
  // (logged-in / logged-out).
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
    test('service call does not happen when logged out', () async {
      final container = buildContainer(loggedIn: false);

      await container.read(wishlistProvider.notifier).getWishlist();

      verifyNever(() => mockWishlistService.getWishlist());
      expect(container.read(wishlistProvider).wishlistItems, isEmpty);
    });

    test('sets items + count in state when logged in', () async {
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

    test('sets error state when an error occurs', () async {
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
    test('returns login_required when logged out', () async {
      final container = buildContainer(loggedIn: false);

      final result =
      await container.read(wishlistProvider.notifier).addToWishlist(5);

      expect(result, 'login_required');
      verifyNever(() => mockWishlistService.addToWishlist(any()));
    });

    test('refreshes the wishlist and returns success on success',
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

    test('returns error when an error occurs', () async {
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
    test('returns false when logged out', () async {
      final container = buildContainer(loggedIn: false);

      final result = await container
          .read(wishlistProvider.notifier)
          .removeFromWishlist(5);

      expect(result, false);
      verifyNever(() => mockWishlistService.removeFromWishlist(any()));
    });

    test('refreshes the wishlist on success', () async {
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

    test('removes the item from local state even if a backend bug causes an API error',
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
    test('returns login_required when logged out', () async {
      final container = buildContainer(loggedIn: false);

      final result =
      await container.read(wishlistProvider.notifier).toggleWishlist(5);

      expect(result, 'login_required');
    });

    test('removes the item if it is already in the wishlist ("removed")',
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

    test('adds the item if it is not in the wishlist ("success")', () async {
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
    test('fully resets the state', () async {
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
    test('always false when logged out', () async {
      final container = buildContainer(loggedIn: false);

      expect(
        container.read(wishlistProvider.notifier).isInWishlist(5),
        false,
      );
    });

    test('returns true only if the item is in state', () async {
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
    test('only clears error to null, keeps the rest of the state as-is (copyWith bug fix)',
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
    test('wishlistCountProvider reflects the count from wishlist state',
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

    test('isInWishlistProvider gives the correct boolean for a specific productId',
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
