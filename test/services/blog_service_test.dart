// test/services/blog_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/api_client.dart';
import 'package:dcs_app/services/blog_service.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<T> _fakeResponse<T>(T data, {String path = '/blogs'}) {
  return Response<T>(
    data: data,
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

void main() {
  late MockApiClient mockApiClient;
  late BlogService blogService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = MockApiClient();
    blogService = BlogService(apiClient: mockApiClient);
  });

  group('getBlogs', () {
    test('sends category/search/page all as query params and returns response.data', () async {
      when(() => mockApiClient.get(
        '/blogs',
        queryParams: {'category': 'tips', 'search': 'clean', 'page': 2},
      )).thenAnswer((_) async => _fakeResponse({
        'data': {
          'blogs': [{'id': 1}],
          'categories': [{'id': 1, 'name': 'tips'}],
        },
      }));

      final result = await blogService.getBlogs(
        category: 'tips',
        search: 'clean',
        page: 2,
      );

      expect(result['data']['blogs'], [{'id': 1}]);
      verify(() => mockApiClient.get(
        '/blogs',
        queryParams: {'category': 'tips', 'search': 'clean', 'page': 2},
      )).called(1);
    });

    test('excludes category/search from query params when null, sends only page', () async {
      when(() => mockApiClient.get('/blogs', queryParams: {'page': 1}))
          .thenAnswer((_) async => _fakeResponse({'data': {}}));

      await blogService.getBlogs();

      verify(() => mockApiClient.get('/blogs', queryParams: {'page': 1}))
          .called(1);
    });
  });

  group('getBlogDetail', () {
    test('does a GET with the slug and returns response.data', () async {
      when(() => mockApiClient.get('/blogs/my-blog-post')).thenAnswer(
            (_) async => _fakeResponse({
          'data': {'id': 3, 'title': 'My Blog Post'},
        }),
      );

      final result = await blogService.getBlogDetail('my-blog-post');

      expect(result['data']['title'], 'My Blog Post');
    });
  });

  group('addComment', () {
    test('does a POST with blogId + comment and returns response.data', () async {
      when(() => mockApiClient.post(
        '/blogs/7/comment',
        data: {'comment': 'Nice post!'},
      )).thenAnswer((_) async => _fakeResponse({'status': true}));

      final result = await blogService.addComment(
        blogId: 7,
        comment: 'Nice post!',
      );

      expect(result['status'], true);
      verify(() => mockApiClient.post(
        '/blogs/7/comment',
        data: {'comment': 'Nice post!'},
      )).called(1);
    });
  });

  group('toggleLike', () {
    test('does a POST with blogId (empty data) and returns response.data', () async {
      when(() => mockApiClient.post('/blogs/7/like', data: {}))
          .thenAnswer((_) async => _fakeResponse({'liked': true}));

      final result = await blogService.toggleLike(7);

      expect(result['liked'], true);
      verify(() => mockApiClient.post('/blogs/7/like', data: {})).called(1);
    });
  });
}
