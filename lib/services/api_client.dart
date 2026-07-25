import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ✅ NEW: पूर्वी `throw _handleError(e)` फक्त String throw करायचं — त्यामुळे
// callers ना statusCode कधीच कळायचा नाही (उदा. 403 vs 404 वेगळं ओळखता येत
// नव्हतं, फक्त message string मिळायची). आता ऐवजी हे ApiException throw
// करतो — `toString()` अजूनही तोच message string देतो, त्यामुळे सगळीकडचे
// existing `catch (e) { ...e.toString()... }` code बदलावे लागत नाहीत.
// पण ज्या ठिकाणी statusCode-specific handling हवं (उदा. account-deletion
// 403), तिथे `on ApiException catch (e)` करून `e.statusCode` वापरता येतो.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // ✅ CHANGED: `_storage` आधी `static const` field होतं (क्लासच्या
  // सगळ्या instances मध्ये shared, override करता न येणारं). आता प्रत्येक
  // instance चं स्वतःचं field आहे, आणि production constructor मध्ये तोच
  // खरा `FlutterSecureStorage()` set होतो — वागणूक तशीच राहते.
  ApiClient._internal() : _storage = const FlutterSecureStorage();

  // ✅ NEW (testability साठी): production मध्ये singleton तसाच राहतो —
  // `ApiClient()` नेहमीप्रमाणे तोच cached instance देतो. पण unit tests
  // मध्ये real network किंवा real secure-storage (Keychain/Keystore)
  // लागू नये म्हणून हा वेगळा named constructor — टेस्टमध्ये
  // `ApiClient.test(dio, storage: mockStorage)` करून mock Dio + mock
  // storage दोन्ही इंजेक्ट करता येतात. `storage` न दिल्यास खरा
  // FlutterSecureStorage वापरला जातो (पण दिलेला Dio अजूनही
  // interceptors-विरहित राहतो — ते `buildInterceptors()` द्वारे टेस्टमध्ये
  // वेगळं जोडावं लागतं, बघ खालचा मुद्दा).
  @visibleForTesting
  ApiClient.test(Dio dio, {FlutterSecureStorage? storage})
      : _dio = dio,
        _storage = storage ?? const FlutterSecureStorage();

  late final Dio _dio;
  final FlutterSecureStorage _storage;

  // ✅ 401 वर callback — main.dart मधून set करा
  static void Function()? onUnauthorized;

  // ✅ startup check वेळी 401 redirect बंद ठेवायला
  static bool suppressUnauthorizedRedirect = false;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: Duration(milliseconds: int.parse(dotenv.env['API_TIMEOUT'] ?? '60000')),
        receiveTimeout: Duration(milliseconds: int.parse(dotenv.env['API_TIMEOUT'] ?? '60000')),
        sendTimeout:    Duration(milliseconds: int.parse(dotenv.env['API_TIMEOUT'] ?? '60000')),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );

    _dio.interceptors.add(buildInterceptors());
  }

  // ✅ NEW (testability साठी): आधी हे सगळं `init()` च्या आतच inline
  // लिहिलं होतं — त्यामुळे टेस्टमध्ये dotenv/BaseOptions शिवाय हे
  // इंटरसेप्टर लॉजिकच वेगळं तपासताच येत नव्हतं. आता वेगळ्या method मध्ये
  // काढलंय — production मध्ये `init()` हेच वापरतो (वागणूक तशीच), आणि
  // टेस्टमध्ये एका plain `Dio()` वर हेच इंटरसेप्टर जोडून, fake
  // HttpClientAdapter सोबत behavior तपासता येतं.
  @visibleForTesting
  InterceptorsWrapper buildInterceptors() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          final prefs = await SharedPreferences.getInstance();
          final guestId = prefs.getString('guest_id')
              ?? await _createGuestId(prefs);

          options.headers['X-Guest-Id'] = guestId;
        }
        return handler.next(options);
      },

      onResponse: (response, handler) {
        return handler.next(response);
      },

      onError: (error, handler) async {
        // ✅ Timeout → 1 retry — फक्त GET सारख्या idempotent methods साठी.
        //    POST/PUT/DELETE वर retry केल्यास duplicate order/booking
        //    तयार होण्याचा risk असतो (उदा. checkout वेळी timeout आला
        //    आणि backend ला request आधीच मिळाली असेल, तर retry मुळे
        //    दुसरी order तयार होऊ शकते). त्यामुळे फक्त GET वर retry.
        final isIdempotent = error.requestOptions.method == 'GET';

        // ✅ FIX (production bug): retry स्वतः `_dio.request()` द्वारे
        // परत याच interceptor मधून जातो — त्यामुळे retry सुद्धा timeout
        // झाला तर तो परत retry ट्रिगर करत होता, कुठलीही depth-limit
        // नसल्यामुळे सतत खराब नेटवर्कवर हे अनिश्चित काळ चालू राहू शकत
        // होतं (comment मध्ये "1 retry" म्हटलं होतं, पण प्रत्यक्षात bound
        // नव्हतं). आता retried request ला `extra['_retried'] = true` असा
        // flag लावतो — तोच request परत fail झाला तर हा flag बघून पुन्हा
        // retry करत नाही, थेट original error पुढे जाऊ देतो.
        final alreadyRetried = error.requestOptions.extra['_retried'] == true;

        if (isIdempotent && !alreadyRetried && (
            error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout    ||
                error.type == DioExceptionType.sendTimeout)) {
          try {
            final response = await _dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                extra: {
                  ...error.requestOptions.extra,
                  '_retried': true,
                },
              ),
              data:            error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );
            return handler.resolve(response);
          } catch (_) {
            // Retry पण fail — original error जाऊ दे
          }
        }

        if (error.response?.statusCode == 401) {
          final hadToken = await _storage.read(key: 'auth_token') != null;

          await _storage.delete(key: 'auth_token');

          // ✅ Guest असताना 401 आला तर ignore — फक्त खरा logged-in session expire झाला तरच redirect
          if (hadToken && !suppressUnauthorizedRedirect) {
            onUnauthorized?.call();
          }
        }
        return handler.next(error);
      },
    );
  }

  Future<String> _createGuestId(SharedPreferences prefs) async {
    final id = const Uuid().v4();
    await prefs.setString('guest_id', id);
    return id;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      return await _dio.get(path, queryParameters: queryParams);
    } on DioException catch (e) {
      throw ApiException(_handleError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw ApiException(_handleError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw ApiException(_handleError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw ApiException(_handleError(e), statusCode: e.response?.statusCode);
    }
  }

  // ✅ Backend च्या validation errors मधून FULL message काढतो —
  // आधी फक्त पहिल्या field चा पहिला error दाखवत होता, आता सगळ्या
  // fields चे सगळे errors एकत्र (नवीन ओळीत) दाखवतो. काहीही hardcode
  // केलेलं नाही — जे backend पाठवेल तेच जसंच्या तसं दिसेल.
  String _extractServerMessage(dynamic data) {
    if (data is! Map) return '';

    final List<String> messages = [];

    // Laravel-style: {"errors": {"field": ["msg1", "msg2"], ...}}
    if (data['errors'] is Map) {
      final errors = data['errors'] as Map;
      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      }
    }
    // Some APIs send errors as a flat list: {"errors": ["msg1", "msg2"]}
    else if (data['errors'] is List) {
      messages.addAll((data['errors'] as List).map((e) => e.toString()));
    }

    if (messages.isNotEmpty) {
      // duplicate काढून टाक, प्रत्येक message नव्या ओळीवर
      return messages.toSet().join('\n');
    }

    // fallback: top-level message field
    if (data['message'] != null) return data['message'].toString();

    return '';
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        final message = _extractServerMessage(data);

        if (message.isNotEmpty) return message;

        // ✅ backend ने काहीच message दिला नाही तरच हे generic fallback वापरतो
        if (statusCode == 401) return 'Unauthorized. Please login again.';
        if (statusCode == 403) return 'Access denied.';
        if (statusCode == 404) return 'Not found.';
        if (statusCode == 500) return 'Server error. Please try again later.';
        return 'Something went wrong.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}