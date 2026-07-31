// test/services/api_client_interceptors_test.dart
//
// ✅ These test the interceptors (auth token, guest-id, 401 handling,
// GET-retry) — on a real Dio, but using a fake HttpClientAdapter instead of
// the network (no real HTTP call goes out). FlutterSecureStorage is
// mocked, and SharedPreferences uses its built-in test-mode
// (setMockInitialValues).

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dcs_app/services/api_client.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ✅ FIX: if a content-type header isn't given, Dio doesn't auto-parse
// JSON — response.data stays a raw String (not a parsed Map), and later
// doing response.data['key'] crashes with "String is not a subtype of
// int". Content-type is now given explicitly as json, so Dio parses it
// correctly.
ResponseBody _bodyFor(dynamic json, {int statusCode = 200}) {
  final bytes = utf8.encode(jsonEncode(json));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late MockFlutterSecureStorage mockStorage;
  late Dio dio;
  late ApiClient apiClient;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    mockStorage = MockFlutterSecureStorage();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = mockAdapter;
    apiClient = ApiClient.test(dio, storage: mockStorage);
    dio.interceptors.add(apiClient.buildInterceptors());

    // ✅ reset static fields before every test — so state from a previous
    // test doesn't leak into the next one
    ApiClient.onUnauthorized = null;
    ApiClient.suppressUnauthorizedRedirect = false;
  });

  group('auth token injection', () {
    test('sets the Authorization header when a token exists', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'abc123');

      RequestOptions? captured;
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments[0] as RequestOptions;
        return _bodyFor({'ok': true});
      });

      await apiClient.get('/x');

      expect(captured!.headers['Authorization'], 'Bearer abc123');
      expect(captured!.headers.containsKey('X-Guest-Id'), false);
    });
  });

  group('guest-id injection', () {
    test('uses the existing guest_id if there is no token but one was already saved', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);
      SharedPreferences.setMockInitialValues({'guest_id': 'guest-existing'});

      RequestOptions? captured;
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments[0] as RequestOptions;
        return _bodyFor({'ok': true});
      });

      await apiClient.get('/x');

      expect(captured!.headers['X-Guest-Id'], 'guest-existing');
      expect(captured!.headers.containsKey('Authorization'), false);
    });

    test('creates and saves a new guest_id when there is no token and no guest_id saved yet',
            () async {
          when(() => mockStorage.read(key: 'auth_token'))
              .thenAnswer((_) async => null);
          SharedPreferences.setMockInitialValues({});

          RequestOptions? captured;
          when(() => mockAdapter.fetch(any(), any(), any()))
              .thenAnswer((inv) async {
            captured = inv.positionalArguments[0] as RequestOptions;
            return _bodyFor({'ok': true});
          });

          await apiClient.get('/x');

          final headerGuestId = captured!.headers['X-Guest-Id'];
          expect(headerGuestId, isNotNull);

          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('guest_id'), headerGuestId);
        });
  });

  group('401 handling', () {
    test('deletes the token + calls onUnauthorized on 401 when a token existed before',
            () async {
          when(() => mockStorage.read(key: 'auth_token'))
              .thenAnswer((_) async => 'abc123');
          when(() => mockStorage.delete(key: 'auth_token'))
              .thenAnswer((_) async {});
          when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
                (_) async => _bodyFor({'message': 'Unauthorized'}, statusCode: 401),
          );

          bool called = false;
          ApiClient.onUnauthorized = () => called = true;

          try {
            await apiClient.get('/x');
          } catch (_) {}

          verify(() => mockStorage.delete(key: 'auth_token')).called(1);
          expect(called, true);
        });

    test('onUnauthorized does not get called on 401 when there was no token to begin with (guest)', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.delete(key: 'auth_token'))
          .thenAnswer((_) async {});
      SharedPreferences.setMockInitialValues({'guest_id': 'g1'});
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((_) async => _bodyFor({}, statusCode: 401));

      bool called = false;
      ApiClient.onUnauthorized = () => called = true;

      try {
        await apiClient.get('/x');
      } catch (_) {}

      expect(called, false);
    });

    test('onUnauthorized does not get called even with a token when suppressUnauthorizedRedirect=true',
            () async {
          when(() => mockStorage.read(key: 'auth_token'))
              .thenAnswer((_) async => 'abc123');
          when(() => mockStorage.delete(key: 'auth_token'))
              .thenAnswer((_) async {});
          when(() => mockAdapter.fetch(any(), any(), any()))
              .thenAnswer((_) async => _bodyFor({}, statusCode: 401));

          bool called = false;
          ApiClient.onUnauthorized = () => called = true;
          ApiClient.suppressUnauthorizedRedirect = true;

          try {
            await apiClient.get('/x');
          } catch (_) {}

          expect(called, false);
        });
  });

  group('GET-only retry on timeout', () {
    test('retries once on a GET timeout, and gets the same response if the retry succeeds',
            () async {
          when(() => mockStorage.read(key: 'auth_token'))
              .thenAnswer((_) async => null);
          SharedPreferences.setMockInitialValues({'guest_id': 'g1'});

          var callCount = 0;
          when(() => mockAdapter.fetch(any(), any(), any()))
              .thenAnswer((inv) async {
            callCount++;
            final options = inv.positionalArguments[0] as RequestOptions;
            if (callCount == 1) {
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
              );
            }
            return _bodyFor({'ok': true});
          });

          final response = await apiClient.get('/x');

          expect(callCount, 2);
          expect(response.data['ok'], true);
        });

    test('does not retry on a POST timeout (to avoid duplicate orders)', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);
      SharedPreferences.setMockInitialValues({'guest_id': 'g1'});

      var callCount = 0;
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((inv) async {
        callCount++;
        final options = inv.positionalArguments[0] as RequestOptions;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      try {
        await apiClient.post('/x', data: {});
      } catch (_) {}

      expect(callCount, 1);
    });

    // ✅ FIX: previously used `expect(() => ..., throwsA(...))` — that
    // doesn't await properly with a Future-returning callback, which
    // caused a race condition followed by a 30-second timeout. Now uses
    // the same plain try/catch pattern as all the other tests — both
    // consistent and correct.
    test('if the retry also fails, the original error propagates unchanged (and no further retry happens)',
            () async {
          when(() => mockStorage.read(key: 'auth_token'))
              .thenAnswer((_) async => null);
          SharedPreferences.setMockInitialValues({'guest_id': 'g1'});

          var callCount = 0;
          when(() => mockAdapter.fetch(any(), any(), any()))
              .thenAnswer((inv) async {
            callCount++;
            final options = inv.positionalArguments[0] as RequestOptions;
            // ✅ returns a timeout both times — if the fix is correct,
            // callCount will stop at exactly 2 (otherwise it would loop
            // forever like before and the test would time out)
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            );
          });

          try {
            await apiClient.get('/x');
            fail('should have thrown');
          } catch (e) {
            expect(e, isA<ApiException>());
            expect(
              (e as ApiException).message,
              'Connection timed out. Please try again.',
            );
          }

          // ✅ exactly 2 — original + 1 retry, no more
          expect(callCount, 2);
        });
  });
}
