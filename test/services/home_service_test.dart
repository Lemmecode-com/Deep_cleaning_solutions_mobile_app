// test/services/home_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/api_client.dart';
import 'package:dcs_app/services/home_service.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<T> _fakeResponse<T>(T data, {String path = '/home'}) {
  return Response<T>(
    data: data,
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

void main() {
  late MockApiClient mockApiClient;
  late HomeService homeService;

  setUp(() {
    mockApiClient = MockApiClient();
    homeService = HomeService(apiClient: mockApiClient);
  });

  test('getHomeData: /home वरून GET करतो आणि response.data return करतो',
          () async {
        when(() => mockApiClient.get('/home')).thenAnswer(
              (_) async => _fakeResponse({'banners': [], 'categories': []}),
        );

        final result = await homeService.getHomeData();

        expect(result['banners'], []);
        verify(() => mockApiClient.get('/home')).called(1);
      });

  test('getCategories: /categories वरून GET करतो', () async {
    when(() => mockApiClient.get('/categories')).thenAnswer(
          (_) async => _fakeResponse({
        'categories': [
          {'id': 1},
        ],
      }),
    );

    final result = await homeService.getCategories();

    expect(result['categories'], [
      {'id': 1},
    ]);
    verify(() => mockApiClient.get('/categories')).called(1);
  });

  test('getBanners: /home/banners वरून GET करतो', () async {
    when(() => mockApiClient.get('/home/banners')).thenAnswer(
          (_) async => _fakeResponse({
        'banners': [
          {'id': 1},
        ],
      }),
    );

    final result = await homeService.getBanners();

    expect(result['banners'], [
      {'id': 1},
    ]);
    verify(() => mockApiClient.get('/home/banners')).called(1);
  });

  test('getTeam: /home/team वरून GET करतो', () async {
    when(() => mockApiClient.get('/home/team')).thenAnswer(
          (_) async => _fakeResponse({
        'team': [
          {'name': 'Rahul'},
        ],
      }),
    );

    final result = await homeService.getTeam();

    expect(result['team'], [
      {'name': 'Rahul'},
    ]);
    verify(() => mockApiClient.get('/home/team')).called(1);
  });

  test('getTestimonials: /home/testimonials वरून GET करतो', () async {
    when(() => mockApiClient.get('/home/testimonials')).thenAnswer(
          (_) async => _fakeResponse({
        'testimonials': [
          {'rating': 5},
        ],
      }),
    );

    final result = await homeService.getTestimonials();

    expect(result['testimonials'], [
      {'rating': 5},
    ]);
    verify(() => mockApiClient.get('/home/testimonials')).called(1);
  });

  test('getFAQs: /home/faqs वरून GET करतो', () async {
    when(() => mockApiClient.get('/home/faqs')).thenAnswer(
          (_) async => _fakeResponse({
        'faqs': [
          {'q': 'test'},
        ],
      }),
    );

    final result = await homeService.getFAQs();

    expect(result['faqs'], [
      {'q': 'test'},
    ]);
    verify(() => mockApiClient.get('/home/faqs')).called(1);
  });

  test('getVideos: /home/videos वरून GET करतो', () async {
    when(() => mockApiClient.get('/home/videos')).thenAnswer(
          (_) async => _fakeResponse({
        'videos': [
          {'url': 'x.mp4'},
        ],
      }),
    );

    final result = await homeService.getVideos();

    expect(result['videos'], [
      {'url': 'x.mp4'},
    ]);
    verify(() => mockApiClient.get('/home/videos')).called(1);
  });
}