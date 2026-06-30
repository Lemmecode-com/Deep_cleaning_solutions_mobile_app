import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;

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
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
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
          // ✅ Timeout → 1 retry
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout    ||
              error.type == DioExceptionType.sendTimeout) {
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
            final prefs = await SharedPreferences.getInstance();
            final hadToken = prefs.getString('auth_token') != null;

            await prefs.remove('auth_token');

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
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ Improved — Laravel validation errors असतील तर खरा, नेमका मेसेज काढतो
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

        String message = data is Map ? (data['message']?.toString() ?? '') : '';

        if (data is Map && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstFieldErrors = errors.values.first;
            if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
              message = firstFieldErrors.first.toString();
            } else if (firstFieldErrors != null) {
              message = firstFieldErrors.toString();
            }
          }
        }

        if (message.isEmpty) message = 'Something went wrong.';

        if (statusCode == 400) return message;
        if (statusCode == 401) return 'Unauthorized. Please login again.';
        if (statusCode == 403) return 'Access denied.';
        if (statusCode == 404) return 'Not found.';
        if (statusCode == 422) return message;
        if (statusCode == 500) return 'Server error. Please try again later.';
        return message;
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}