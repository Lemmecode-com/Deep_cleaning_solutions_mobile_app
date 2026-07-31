// test/services/enquiry_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dcs_app/services/api_client.dart';
import 'package:dcs_app/services/enquiry_service.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<T> _fakeResponse<T>(T data, {String path = '/enquiry'}) {
  return Response<T>(
    data: data,
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

void main() {
  late MockApiClient mockApiClient;
  late EnquiryService enquiryService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = MockApiClient();
    enquiryService = EnquiryService(apiClient: mockApiClient);
  });

  group('submitEnquiry', () {
    test(
        'sends the correct payload with required fields + default orderInspection(false)',
            () async {
          when(() => mockApiClient.post(any(), data: any(named: 'data')))
              .thenAnswer((_) async => _fakeResponse({'status': true}));

          await enquiryService.submitEnquiry(
            firstName: 'Rahul',
            lastName:  'Shinde',
            email:     'rahul@example.com',
            mobile:    '9876543210',
            address:   'Baner Road',
            state:     'Maharashtra',
            city:      'Pune',
            service:   'deep-cleaning',
          );

          final captured = verify(
                () => mockApiClient.post('/enquiry', data: captureAny(named: 'data')),
          ).captured.single as Map<String, dynamic>;

          expect(captured['first_name'], 'Rahul');
          expect(captured['last_name'], 'Shinde');
          expect(captured['email'], 'rahul@example.com');
          expect(captured['mobile'], '9876543210');
          expect(captured['address'], 'Baner Road');
          expect(captured['state'], 'Maharashtra');
          expect(captured['city'], 'Pune');
          expect(captured['service'], 'deep-cleaning');
          expect(captured['order_inspection'], 0);
          expect(captured.containsKey('inspection_date'), false);
          expect(captured.containsKey('inspection_time'), false);
        });

    test('when orderInspection true + inspection date/time are given, they land in the payload',
            () async {
          when(() => mockApiClient.post(any(), data: any(named: 'data')))
              .thenAnswer((_) async => _fakeResponse({'status': true}));

          await enquiryService.submitEnquiry(
            firstName: 'Priya',
            lastName:  'Kulkarni',
            email:     'priya@example.com',
            mobile:    '9123456780',
            address:   'FC Road',
            state:     'Maharashtra',
            city:      'Pune',
            service:   'sofa-cleaning',
            orderInspection: true,
            inspectionDate:  '2026-08-01',
            inspectionTime:  '10:00 AM',
          );

          final captured = verify(
                () => mockApiClient.post('/enquiry', data: captureAny(named: 'data')),
          ).captured.single as Map<String, dynamic>;

          expect(captured['order_inspection'], 1);
          expect(captured['inspection_date'], '2026-08-01');
          expect(captured['inspection_time'], '10:00 AM');
        });

    test('when only inspectionDate is given (no time), only date goes into the payload',
            () async {
          when(() => mockApiClient.post(any(), data: any(named: 'data')))
              .thenAnswer((_) async => _fakeResponse({'status': true}));

          await enquiryService.submitEnquiry(
            firstName: 'Sneha',
            lastName:  'Patil',
            email:     'sneha@example.com',
            mobile:    '9000011122',
            address:   'Aundh',
            state:     'Maharashtra',
            city:      'Pune',
            service:   'bathroom-cleaning',
            inspectionDate: '2026-08-05',
          );

          final captured = verify(
                () => mockApiClient.post('/enquiry', data: captureAny(named: 'data')),
          ).captured.single as Map<String, dynamic>;

          expect(captured.containsKey('inspection_date'), true);
          expect(captured['inspection_date'], '2026-08-05');
          expect(captured.containsKey('inspection_time'), false);
        });

    test('returns response.data as-is', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _fakeResponse({
        'status':     true,
        'enquiry_id': 42,
      }));

      final result = await enquiryService.submitEnquiry(
        firstName: 'Amit',
        lastName:  'Joshi',
        email:     'amit@example.com',
        mobile:    '9988776655',
        address:   'Kothrud',
        state:     'Maharashtra',
        city:      'Pune',
        service:   'carpet-cleaning',
      );

      expect(result['status'], true);
      expect(result['enquiry_id'], 42);
    });
  });

  group('getEnquiryPaymentStatus', () {
    test('does a GET with the correct enquiryId and returns response.data',
            () async {
          when(() => mockApiClient.get('/enquiry/42/payment-status')).thenAnswer(
                (_) async => _fakeResponse({'paid': true, 'amount': 999}),
          );

          final result = await enquiryService.getEnquiryPaymentStatus(42);

          expect(result['paid'], true);
          expect(result['amount'], 999);
          verify(() => mockApiClient.get('/enquiry/42/payment-status')).called(1);
        });
  });
}
