// test/services/api_client_interceptors_test.dart
//
// ✅ हे इंटरसेप्टर्स (auth token, guest-id, 401 handling, GET-retry) टेस्ट
// करतात — खऱ्या Dio वर, पण नेटवर्कऐवजी fake HttpClientAdapter वापरून
// (कुठलाही खरा HTTP call जात नाही). FlutterSecureStorage mock केलंय,
// SharedPreferences साठी built-in test-mode (setMockInitialValues) वापरलंय.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dcs_app/services/api_client.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ✅ FIX: content-type header न दिल्यास Dio JSON auto-parse करत नाही —
// response.data raw String राहतो (parsed Map नाही), आणि नंतर
// response.data['key'] केल्यावर "String is not a subtype of int" crash
// येतो. आता content-type explicitly json दिलंय, त्यामुळे Dio बरोबर
// parse करतो.
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

    // ✅ static fields प्रत्येक test आधी reset — मागच्या test चा state
    // पुढच्या test मध्ये लीक होऊ नये म्हणून
    ApiClient.onUnauthorized = null;
    ApiClient.suppressUnauthorizedRedirect = false;
  });

  group('auth token injection', () {
    test('token असेल तर Authorization header लावतो', () async {
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
    test('token नसेल आणि आधीच guest_id saved असेल तर तोच वापरतो', () async {
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

    test('token नाही आणि guest_id सुद्धा saved नसेल तर नवीन तयार करून save करतो',
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
    test('401 आणि आधी token होता तर token delete करतो + onUnauthorized call होतो',
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

    test('401 आणि token नव्हताच (guest) तर onUnauthorized call होत नाही', () async {
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

    test('suppressUnauthorizedRedirect=true असताना token असूनही onUnauthorized call होत नाही',
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
    test('GET timeout वर 1 वेळा retry करतो, retry success झाल्यास तोच response मिळतो',
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

    test('POST timeout वर retry करत नाही (duplicate order टाळण्यासाठी)', () async {
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

    // ✅ FIX: आधी `expect(() => ..., throwsA(...))` वापरलं होतं — ते
    // Future-returning callback सोबत नीट await होत नाही, त्यामुळे
    // race condition + नंतर 30-second timeout येत होता. बाकीच्या सगळ्या
    // टेस्ट्ससारखं साधं try/catch पॅटर्न वापरलंय — सुसंगत आणि योग्य दोन्ही.
    test('retry सुद्धा fail झाला तर original error तसाच पुढे जातो (आणि पुन्हा retry करत नाही)',
            () async {
          when(() => mockStorage.read(key: 'auth_token'))
              .thenAnswer((_) async => null);
          SharedPreferences.setMockInitialValues({'guest_id': 'g1'});

          var callCount = 0;
          when(() => mockAdapter.fetch(any(), any(), any()))
              .thenAnswer((inv) async {
            callCount++;
            final options = inv.positionalArguments[0] as RequestOptions;
            // ✅ दोन्ही वेळा timeout देतो — fix बरोबर असेल तरच callCount
            // बरोब्बर 2 वर थांबेल (नाहीतर आधीसारखं अनंत loop होईल आणि
            // test timeout होईल)
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

          // ✅ नेमकं 2 — original + 1 retry, त्यापुढे नाही
          expect(callCount, 2);
        });
  });
}