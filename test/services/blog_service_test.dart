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
    test('category/search/page सगळे query params मध्ये पाठवतो आणि response.data return करतो', () async {
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

    test('category/search null असतील तर query params मधून वगळतो, फक्त page पाठवतो', () async {
      when(() => mockApiClient.get('/blogs', queryParams: {'page': 1}))
          .thenAnswer((_) async => _fakeResponse({'data': {}}));

      await blogService.getBlogs();

      verify(() => mockApiClient.get('/blogs', queryParams: {'page': 1}))
          .called(1);
    });
  });

  group('getBlogDetail', () {
    test('slug सोबत GET करतो आणि response.data return करतो', () async {
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
    test('blogId + comment सोबत POST करतो आणि response.data return करतो', () async {
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
    test('blogId सोबत POST करतो (empty data) आणि response.data return करतो', () async {
      when(() => mockApiClient.post('/blogs/7/like', data: {}))
          .thenAnswer((_) async => _fakeResponse({'liked': true}));

      final result = await blogService.toggleLike(7);

      expect(result['liked'], true);
      verify(() => mockApiClient.post('/blogs/7/like', data: {})).called(1);
    });
  });
}