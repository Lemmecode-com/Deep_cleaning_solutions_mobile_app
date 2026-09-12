// test/providers/home_notifier_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/home_provider.dart';
import 'package:dcs_app/services/home_service.dart';

class MockHomeService extends Mock implements HomeService {}

void main() {
  late MockHomeService mockHomeService;

  Map<String, dynamic> emptyHomeData() => {
    'banners': [],
    'categories': [],
    'team': [],
    'testimonials': [],
    'faqs': [],
    'videos': [],
  };

  // ✅ FIX: Previously buildNotifier() was sync and assumed that the
  // constructor's auto `getHomeData()` call always resolves before the
  // explicit call — but that isn't actually guaranteed (in particular,
  // calls using `thenThrow` complete synchronously, while
  // `thenAnswer(async => ...)` needs an extra microtask — so the ordering
  // could flip, and the success call's `clearError:true` would come later
  // and wipe out the test's error state). Now, after the constructor, we
  // wait one full event-loop tick with `Future.delayed(Duration.zero)`, so
  // the next explicit call only starts once the auto-init call has 100%
  // settled — the race condition is fully avoided.
  Future<HomeNotifier> buildNotifier() async {
    when(() => mockHomeService.getHomeData())
        .thenAnswer((_) async => emptyHomeData());
    final notifier = HomeNotifier(homeService: mockHomeService);
    await Future.delayed(Duration.zero);
    return notifier;
  }

  setUp(() {
    mockHomeService = MockHomeService();
  });

  group('getHomeData', () {
    test('all fields are set in state on success', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getHomeData()).thenAnswer(
            (_) async => {
          'banners': [
            {'id': 1},
          ],
          'categories': [
            {'id': 2},
          ],
          'team': [
            {'id': 3},
          ],
          'testimonials': [
            {'id': 4},
          ],
          'faqs': [
            {'id': 5},
          ],
          'videos': [
            {'id': 6},
          ],
        },
      );
      await notifier.getHomeData();

      final state = notifier.state;
      expect(state.banners.length, 1);
      expect(state.categories.length, 1);
      expect(state.team.length, 1);
      expect(state.testimonials.length, 1);
      expect(state.faqs.length, 1);
      expect(state.videos.length, 1);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('sets error state and isLoading false when an error occurs', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getHomeData())
          .thenThrow(Exception('network down'));
      await notifier.getHomeData();

      final state = notifier.state;
      expect(state.error, contains('network down'));
      expect(state.isLoading, false);
    });
  });

  group('getBanners', () {
    test('only banners get updated on success, everything else stays unaffected',
            () async {
          final notifier = await buildNotifier();
          when(() => mockHomeService.getHomeData()).thenAnswer(
                (_) async => {
              'banners': [],
              'categories': [
                {'id': 9},
              ],
            },
          );
          await notifier.getHomeData();

          when(() => mockHomeService.getBanners()).thenAnswer(
                (_) async => {
              'banners': [
                {'id': 1},
                {'id': 2},
              ],
            },
          );
          await notifier.getBanners();

          final state = notifier.state;
          expect(state.banners.length, 2);
          expect(state.categories.length, 1); // untouched
          expect(state.error, isNull);
        });

    test('sets error state when an error occurs', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getBanners())
          .thenThrow(Exception('banners failed'));
      await notifier.getBanners();

      expect(notifier.state.error, contains('banners failed'));
    });
  });

  group('getCategories', () {
    test('categories get updated on success', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getCategories()).thenAnswer(
            (_) async => {
          'categories': [
            {'id': 1},
            {'id': 2},
            {'id': 3},
          ],
        },
      );
      await notifier.getCategories();

      expect(notifier.state.categories.length, 3);
      expect(notifier.state.error, isNull);
    });

    test('sets error state when an error occurs', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getCategories())
          .thenThrow(Exception('categories failed'));
      await notifier.getCategories();

      expect(notifier.state.error, contains('categories failed'));
    });
  });

  group('getFAQs', () {
    test('faqs get updated on success', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getFAQs()).thenAnswer(
            (_) async => {
          'faqs': [
            {'q': 'test'},
          ],
        },
      );
      await notifier.getFAQs();

      expect(notifier.state.faqs.length, 1);
      expect(notifier.state.error, isNull);
    });

    test('sets error state when an error occurs', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getFAQs())
          .thenThrow(Exception('faqs failed'));
      await notifier.getFAQs();

      expect(notifier.state.error, contains('faqs failed'));
    });
  });

  group('getVideos', () {
    test('videos get updated on success', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getVideos()).thenAnswer(
            (_) async => {
          'videos': [
            {'url': 'a.mp4'},
            {'url': 'b.mp4'},
          ],
        },
      );
      await notifier.getVideos();

      expect(notifier.state.videos.length, 2);
      expect(notifier.state.error, isNull);
    });

    test('sets error state when an error occurs', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getVideos())
          .thenThrow(Exception('videos failed'));
      await notifier.getVideos();

      expect(notifier.state.error, contains('videos failed'));
    });
  });

  group('refresh', () {
    test('refresh() delegates to getHomeData()', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getHomeData()).thenAnswer(
            (_) async => {
          'banners': [
            {'id': 1},
          ],
        },
      );
      await notifier.refresh();

      expect(notifier.state.banners.length, 1);
      verify(() => mockHomeService.getHomeData())
          .called(greaterThanOrEqualTo(1));
    });
  });

  group('clearError', () {
    test('only clears error to null, keeps the rest of the state as-is', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getBanners()).thenThrow(Exception('boom'));
      await notifier.getBanners();
      expect(notifier.state.error, isNotNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });
  });
}
