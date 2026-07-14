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
  ApiClient._internal();

  late final Dio _dio;
  static const _storage = FlutterSecureStorage();

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

    _dio.interceptors.add(
      InterceptorsWrapper(
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

          if (isIdempotent && (
              error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout    ||
                  error.type == DioExceptionType.sendTimeout)) {
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                options: Options(method: error.requestOptions.method),
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
      ),
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