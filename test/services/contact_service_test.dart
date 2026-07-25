// test/services/contact_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/api_client.dart';
import 'package:dcs_app/services/contact_service.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<T> _fakeResponse<T>(T data, {String path = '/contact'}) {
  return Response<T>(
    data: data,
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

void main() {
  late MockApiClient mockApiClient;
  late ContactService contactService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = MockApiClient();
    contactService = ContactService(apiClient: mockApiClient);
  });

  group('sendMessage', () {
    test('name/email/mobile/service/message सगळे बरोबर payload मध्ये पाठवतो', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _fakeResponse({'status': true}));

      await contactService.sendMessage(
        name:    'Rahul Shinde',
        email:   'rahul@example.com',
        mobile:  '9876543210',
        service: 'deep-cleaning',
        message: 'Need a quote for 2BHK',
      );

      final captured = verify(
            () => mockApiClient.post('/contact', data: captureAny(named: 'data')),
      ).captured.single as Map<String, dynamic>;

      expect(captured['name'], 'Rahul Shinde');
      expect(captured['email'], 'rahul@example.com');
      expect(captured['mobile'], '9876543210');
      expect(captured['service'], 'deep-cleaning');
      expect(captured['message'], 'Need a quote for 2BHK');
    });

    test('response.data जसाच्या तसा return करतो', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _fakeResponse({
        'status':  true,
        'message': 'Thank you, we will contact you soon',
      }));

      final result = await contactService.sendMessage(
        name:    'Priya Kulkarni',
        email:   'priya@example.com',
        mobile:  '9123456780',
        service: 'sofa-cleaning',
        message: 'Please call back',
      );

      expect(result['status'], true);
      expect(result['message'], 'Thank you, we will contact you soon');
    });

    test('DELETE/GET नाही, फक्त एकदाच POST /contact हिट होतो', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _fakeResponse({'status': true}));

      await contactService.sendMessage(
        name:    'Sneha Patil',
        email:   'sneha@example.com',
        mobile:  '9000011122',
        service: 'bathroom-cleaning',
        message: 'test',
      );

      verify(() => mockApiClient.post('/contact', data: any(named: 'data')))
          .called(1);
    });
  });

  group('getContactInfo', () {
    test('GET /contact करतो आणि response.data return करतो', () async {
      when(() => mockApiClient.get('/contact')).thenAnswer(
            (_) async => _fakeResponse({
          'address': 'Pune, Maharashtra',
          'phone':   '020-12345678',
          'email':   'info@dcs.com',
        }),
      );

      final result = await contactService.getContactInfo();

      expect(result['address'], 'Pune, Maharashtra');
      expect(result['phone'], '020-12345678');
      expect(result['email'], 'info@dcs.com');
    });
  });
}