// test/services/api_client_test.dart
//
// ✅ Uses ApiClient.test(mockDio) to test get/post/put/delete +
// error-mapping logic. Interceptors (auth token, guest-id, 401 redirect,
// retry) are NOT tested here — they get attached only inside init(), so
// they're bypassed by this constructor.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient.test(mockDio);
  });

  Response _res(dynamic data, {int statusCode = 200, String path = '/x'}) {
    return Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: path),
    );
  }

  DioException _dioErr({
    required DioExceptionType type,
    Response? response,
    String path = '/x',
  }) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: type,
      response: response,
    );
  }

  group('get / post / put / delete — success passthrough', () {
    test('get() returns Dio\'s response as-is on success', () async {
      when(() => mockDio.get('/wishlist', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _res({'ok': true}));

      final response = await apiClient.get('/wishlist');

      expect(response.data['ok'], true);
    });

    test('post() returns Dio\'s response as-is on success', () async {
      when(() => mockDio.post('/wishlist', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'status': true}));

      final response = await apiClient.post('/wishlist', data: {'a': 1});

      expect(response.data['status'], true);
      verify(() => mockDio.post('/wishlist', data: {'a': 1})).called(1);
    });

    test('put() returns Dio\'s response as-is on success', () async {
      when(() => mockDio.put('/profile', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'updated': true}));

      final response = await apiClient.put('/profile', data: {'name': 'x'});

      expect(response.data['updated'], true);
    });

    test('delete() returns Dio\'s response as-is on success', () async {
      when(() => mockDio.delete('/wishlist', data: any(named: 'data')))
          .thenAnswer((_) async => _res({'deleted': true}));

      final response = await apiClient.delete('/wishlist', data: {'product_id': 5});

      expect(response.data['deleted'], true);
    });
  });

  group('DioException → ApiException wrapping', () {
    test('ApiException is thrown when a DioException occurs in get() (statusCode is carried over)', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({'message': 'Not found'}, statusCode: 404),
      ));

      expect(
            () => apiClient.get('/missing'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Not found')),
      );
    });

    test('ApiException is thrown when a DioException occurs in post()', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(_dioErr(type: DioExceptionType.connectionError));

      expect(() => apiClient.post('/x', data: {}), throwsA(isA<ApiException>()));
    });
  });

  group('_handleError — timeout / connection', () {
    test('connectionTimeout → correct user-facing message', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(type: DioExceptionType.connectionTimeout));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Connection timed out. Please try again.');
      }
    });

    test('receiveTimeout → the same timeout message', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(type: DioExceptionType.receiveTimeout));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Connection timed out. Please try again.');
      }
    });

    test('connectionError → "No internet connection."', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(type: DioExceptionType.connectionError));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'No internet connection.');
      }
    });

    test('unknown/other DioExceptionType → generic fallback message', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(type: DioExceptionType.cancel));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Something went wrong. Please try again.');
      }
    });
  });

  group('_handleError — badResponse status-code fallbacks (when there is no backend message)', () {
    test('401 with no message in data → "Unauthorized. Please login again."', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({}, statusCode: 401),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Unauthorized. Please login again.');
      }
    });

    test('403 → "Access denied."', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({}, statusCode: 403),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Access denied.');
      }
    });

    test('404 → "Not found."', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({}, statusCode: 404),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Not found.');
      }
    });

    test('500 → "Server error. Please try again later."', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({}, statusCode: 500),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Server error. Please try again later.');
      }
    });

    test('any other statusCode (e.g. 418) with no message → "Something went wrong."', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({}, statusCode: 418),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Something went wrong.');
      }
    });
  });

  group('_extractServerMessage — Laravel-style errors map', () {
    test('shows all field-errors from the errors map combined (on new lines, duplicates removed)', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({
          'errors': {
            'email': ['Email is required', 'Email is invalid'],
            'mobile': ['Email is required'], // duplicate — should be deduped
          },
        }, statusCode: 422),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        final msg = e.toString();
        expect(msg, contains('Email is required'));
        expect(msg, contains('Email is invalid'));
        // dedupe: 'Email is required' should appear only once
        expect('Email is required'.allMatches(msg).length, 1);
      }
    });
  });

  group('_extractServerMessage — flat errors list', () {
    test('when errors is a flat list, joins and shows all of them too', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({
          'errors': ['Something broke', 'Try again later'],
        }, statusCode: 400),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        final msg = e.toString();
        expect(msg, contains('Something broke'));
        expect(msg, contains('Try again later'));
      }
    });
  });

  group('_extractServerMessage — plain message fallback', () {
    test('uses the message key when there is no errors key but there is a message key', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res({'message': 'Custom backend message'}, statusCode: 422),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Custom backend message');
      }
    });

    test('gives a generic fallback without crashing when data is not a Map (e.g. null or String)', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_dioErr(
        type: DioExceptionType.badResponse,
        response: _res(null, statusCode: 500),
      ));

      try {
        await apiClient.get('/x');
        fail('should have thrown');
      } catch (e) {
        expect(e.toString(), 'Server error. Please try again later.');
      }
    });
  });
}
