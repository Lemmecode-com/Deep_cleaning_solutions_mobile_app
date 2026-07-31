// test/services/auth_service_test.dart
//
// ✅ This test checks AuthService's token-handling and response-shape
// logic — without using a real network call or a real secure-storage
// platform channel. Both ApiClient and FlutterSecureStorage are mocked.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dcs_app/services/auth_service.dart';
import 'package:dcs_app/services/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

Response _res(dynamic data, {int statusCode = 200}) => Response(
  requestOptions: RequestOptions(path: ''),
  data:           data,
  statusCode:     statusCode,
);

void main() {
  late MockApiClient mockApi;
  late MockSecureStorage mockStorage;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApi = MockApiClient();
    mockStorage = MockSecureStorage();
    authService = AuthService(apiClient: mockApi, storage: mockStorage);

    when(() => mockStorage.write(
      key:   any(named: 'key'),
      value: any(named: 'value'),
    )).thenAnswer((_) async {});
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
  });

  group('AuthService.login', () {
    test('saves the token to secure storage when one is received', () async {
      when(() => mockApi.post('/auth/login', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'data': {
          'token': 'abc123',
          'user':  {'id': 1, 'name': 'Rahul'},
        },
      }));

      final result = await authService.login(
        email: 'rahul@test.com',
        password: 'correctpassword',
      );

      expect(result['token'], 'abc123');
      verify(() => mockStorage.write(key: 'auth_token', value: 'abc123'))
          .called(1);
    });

    test('propagates the error and does not save a token when the API fails due to wrong credentials', () async {
      when(() => mockApi.post('/auth/login', data: any(named: 'data')))
          .thenThrow(ApiException('Invalid credentials'));

      expect(
            () => authService.login(email: 'x@test.com', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );

      verifyNever(() => mockStorage.write(
        key:   any(named: 'key'),
        value: any(named: 'value'),
      ));
    });
  });

  group('AuthService.register', () {
    test('storage.write is not called when there is no token', () async {
      when(() => mockApi.post('/auth/register', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'data': {'id': 5, 'name': 'New User'},
      }));

      final result = await authService.register(
        name: 'New User',
        email: 'new@test.com',
        password: 'pass1234',
      );

      expect(result['id'], 5);
      verifyNever(() => mockStorage.write(
        key:   any(named: 'key'),
        value: any(named: 'value'),
      ));
    });
  });

  group('AuthService.logout', () {
    test('the local token still gets deleted even if the logout API call fails (try/finally)', () async {
      when(() => mockApi.post('/auth/logout'))
          .thenThrow(ApiException('Network error'));

      await expectLater(authService.logout(), throwsA(isA<ApiException>()));

      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
    });

    test('the token also gets deleted when the logout API succeeds', () async {
      when(() => mockApi.post('/auth/logout'))
          .thenAnswer((_) async => _res({'status': true}));

      await authService.logout();

      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
    });
  });

  group('AuthService.getProfile / updateProfile', () {
    test('wraps the getProfile response in a {"user": {...}} shape', () async {
      when(() => mockApi.get('/auth/profile')).thenAnswer((_) async => _res({
        'data': {'id': 1, 'name': 'Rahul', 'email': 'rahul@test.com'},
      }));

      final result = await authService.getProfile();

      expect(result['user']['name'], 'Rahul');
    });

    test('updateProfile also gives the same {"user": {...}} shape', () async {
      when(() => mockApi.put('/auth/profile', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'data': {'id': 1, 'name': 'Rahul Updated', 'phone': '9999999999'},
      }));

      final result = await authService.updateProfile(
        name: 'Rahul Updated',
        email: 'rahul@test.com',
        phone: '9999999999',
      );

      expect(result['user']['name'], 'Rahul Updated');
      expect(result['user']['phone'], '9999999999');
    });
  });

  group('AuthService.isLoggedIn', () {
    test('returns true when a token exists', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'sometoken');

      expect(await authService.isLoggedIn(), true);
    });

    test('returns false when there is no token', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);

      expect(await authService.isLoggedIn(), false);
    });
  });

  group('AuthService.deleteAccount', () {
    test('merges and returns the top-level message and data', () async {
      when(() => mockApi.delete('/auth/account', data: any(named: 'data')))
          .thenAnswer((_) async => _res({
        'message': 'Deletion scheduled.',
        'data': {
          'deletion_scheduled_at': '2026-08-01',
          'active_order_warning':  true,
        },
      }));

      final result = await authService.deleteAccount(password: 'mypassword');

      expect(result['message'], 'Deletion scheduled.');
      expect(result['deletion_scheduled_at'], '2026-08-01');
      expect(result['active_order_warning'], true);
    });
  });
}
