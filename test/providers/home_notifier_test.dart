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

  // ✅ FIX: आधी buildNotifier() sync होतं आणि गृहीत धरलं होतं की
  // constructor चा auto `getHomeData()` call नेहमी explicit call च्या
  // आधी resolve होतो — पण प्रत्यक्षात तसं guaranteed नाही (विशेषतः
  // `thenThrow` वापरणाऱ्या calls synchronously पूर्ण होतात, तर
  // `thenAnswer(async => ...)` ला extra microtask लागतो — त्यामुळे
  // ordering उलटू शकते आणि success call चा `clearError:true` नंतर
  // येऊन test चा error state पुसून टाकत होता). आता constructor नंतर
  // `Future.delayed(Duration.zero)` ने एक पूर्ण event-loop tick थांबतो,
  // जेणेकरून auto-init call १००% settle झाल्यावरच पुढचा explicit call
  // सुरू होतो — race condition संपूर्ण टळते.
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
    test('success झाल्यास सगळे fields state मध्ये set होतात', () async {
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

    test('error आल्यास error state मध्ये set होतो, isLoading false', () async {
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
    test('success झाल्यास फक्त banners update होतात, बाकी unaffected राहतात',
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

    test('error आल्यास error state मध्ये set होतो', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getBanners())
          .thenThrow(Exception('banners failed'));
      await notifier.getBanners();

      expect(notifier.state.error, contains('banners failed'));
    });
  });

  group('getCategories', () {
    test('success झाल्यास categories update होतात', () async {
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

    test('error आल्यास error state मध्ये set होतो', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getCategories())
          .thenThrow(Exception('categories failed'));
      await notifier.getCategories();

      expect(notifier.state.error, contains('categories failed'));
    });
  });

  group('getFAQs', () {
    test('success झाल्यास faqs update होतात', () async {
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

    test('error आल्यास error state मध्ये set होतो', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getFAQs())
          .thenThrow(Exception('faqs failed'));
      await notifier.getFAQs();

      expect(notifier.state.error, contains('faqs failed'));
    });
  });

  group('getVideos', () {
    test('success झाल्यास videos update होतात', () async {
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

    test('error आल्यास error state मध्ये set होतो', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getVideos())
          .thenThrow(Exception('videos failed'));
      await notifier.getVideos();

      expect(notifier.state.error, contains('videos failed'));
    });
  });

  group('refresh', () {
    test('refresh() हे getHomeData() ला delegate करतो', () async {
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
    test('फक्त error null करतो, बाकी state तशीच ठेवतो', () async {
      final notifier = await buildNotifier();

      when(() => mockHomeService.getBanners()).thenThrow(Exception('boom'));
      await notifier.getBanners();
      expect(notifier.state.error, isNotNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });
  });
}