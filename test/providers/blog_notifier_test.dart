// test/providers/blog_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/providers/blog_provider.dart';
import 'package:dcs_app/services/blog_service.dart';

class MockBlogService extends Mock implements BlogService {}

void main() {
  late MockBlogService mockBlogService;
  late ProviderContainer container;

  setUp(() {
    mockBlogService = MockBlogService();

    container = ProviderContainer(
      overrides: [
        blogProvider.overrideWith(
              (ref) => BlogNotifier(blogService: mockBlogService),
        ),
      ],
    );

    addTearDown(container.dispose);
  });

  group('getBlogs', () {
    test('success झाल्यास blogs + categories state मध्ये set करतो', () async {
      when(() => mockBlogService.getBlogs(
        category: any(named: 'category'),
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).thenAnswer((_) async => {
        'data': {
          'blogs': [{'id': 1}, {'id': 2}],
          'categories': [{'id': 1, 'name': 'tips'}],
        },
      });

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogs();

      final state = container.read(blogProvider);
      expect(state.blogs.length, 2);
      expect(state.categories.length, 1);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('data missing असेल तर empty blogs/categories देतो', () async {
      when(() => mockBlogService.getBlogs(
        category: any(named: 'category'),
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).thenAnswer((_) async => {});

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogs();

      final state = container.read(blogProvider);
      expect(state.blogs, isEmpty);
      expect(state.categories, isEmpty);
    });

    test('error आल्यास error state मध्ये set होतो', () async {
      when(() => mockBlogService.getBlogs(
        category: any(named: 'category'),
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).thenThrow(Exception('network error'));

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogs();

      final state = container.read(blogProvider);
      expect(state.error, contains('network error'));
      expect(state.isLoading, false);
    });
  });

  group('getBlogDetail', () {
    test('success झाल्यास selectedBlog state मध्ये set करतो', () async {
      when(() => mockBlogService.getBlogDetail('my-slug')).thenAnswer(
            (_) async => {
          'data': {'id': 5, 'title': 'My Blog'},
        },
      );

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogDetail('my-slug');

      expect(container.read(blogProvider).selectedBlog?['title'], 'My Blog');
    });

    test('error आल्यास error state मध्ये set होतो', () async {
      when(() => mockBlogService.getBlogDetail('bad-slug'))
          .thenThrow(Exception('not found'));

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogDetail('bad-slug');

      expect(container.read(blogProvider).error, contains('not found'));
    });
  });

  group('addComment', () {
    test('success झाल्यास true return करतो', () async {
      when(() => mockBlogService.addComment(
        blogId: any(named: 'blogId'),
        comment: any(named: 'comment'),
      )).thenAnswer((_) async => {'status': true});

      final notifier = container.read(blogProvider.notifier);
      final result = await notifier.addComment(blogId: 7, comment: 'Nice!');

      expect(result, true);
    });

    test('error आल्यास false return करतो आणि error state सेट होते', () async {
      when(() => mockBlogService.addComment(
        blogId: any(named: 'blogId'),
        comment: any(named: 'comment'),
      )).thenThrow(Exception('comment failed'));

      final notifier = container.read(blogProvider.notifier);
      final result = await notifier.addComment(blogId: 7, comment: 'Nice!');

      expect(result, false);
      expect(container.read(blogProvider).error, contains('comment failed'));
    });
  });

  group('toggleLike', () {
    test('success झाल्यास true return करतो', () async {
      when(() => mockBlogService.toggleLike(7))
          .thenAnswer((_) async => {'liked': true});

      final notifier = container.read(blogProvider.notifier);
      final result = await notifier.toggleLike(7);

      expect(result, true);
    });

    test('error आल्यास false return करतो', () async {
      when(() => mockBlogService.toggleLike(7))
          .thenThrow(Exception('like failed'));

      final notifier = container.read(blogProvider.notifier);
      final result = await notifier.toggleLike(7);

      expect(result, false);
      expect(container.read(blogProvider).error, contains('like failed'));
    });
  });

  group('setSelectedCategory', () {
    test('index 0 वर सगळे blogs परत आणतो (category filter नाही)', () async {
      when(() => mockBlogService.getBlogs(
        category: null,
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).thenAnswer((_) async => {
        'data': {'blogs': [{'id': 1}, {'id': 2}], 'categories': []},
      });

      final notifier = container.read(blogProvider.notifier);
      notifier.setSelectedCategory(0);
      await Future.delayed(Duration.zero);

      expect(container.read(blogProvider).selectedCategory, 0);
      expect(container.read(blogProvider).blogs.length, 2);
    });

    test('index != 0 आणि categoryName दिलं तर त्याच category साठी filter करतो', () async {
      when(() => mockBlogService.getBlogs(
        category: 'tips',
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).thenAnswer((_) async => {
        'data': {'blogs': [{'id': 3}], 'categories': []},
      });

      final notifier = container.read(blogProvider.notifier);
      notifier.setSelectedCategory(1, categoryName: 'tips');
      await Future.delayed(Duration.zero);

      expect(container.read(blogProvider).selectedCategory, 1);
      expect(container.read(blogProvider).blogs.length, 1);
      verify(() => mockBlogService.getBlogs(
        category: 'tips',
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).called(1);
    });
  });

  group('clearError', () {
    test('फक्त error null करतो, बाकी state तशीच ठेवतो (copyWith bug fix)', () async {
      when(() => mockBlogService.getBlogs(
        category: any(named: 'category'),
        search: any(named: 'search'),
        page: any(named: 'page'),
      )).thenThrow(Exception('boom'));

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogs();
      expect(container.read(blogProvider).error, isNotNull);

      notifier.clearError();

      expect(container.read(blogProvider).error, isNull);
    });
  });

  group('clearSelectedBlog', () {
    test('selectedBlog null करतो (तोच copyWith bug इथेही होता, आता fix)', () async {
      when(() => mockBlogService.getBlogDetail('my-slug')).thenAnswer(
            (_) async => {'data': {'id': 5}},
      );

      final notifier = container.read(blogProvider.notifier);
      await notifier.getBlogDetail('my-slug');
      expect(container.read(blogProvider).selectedBlog, isNotNull);

      notifier.clearSelectedBlog();

      expect(container.read(blogProvider).selectedBlog, isNull);
    });
  });
}