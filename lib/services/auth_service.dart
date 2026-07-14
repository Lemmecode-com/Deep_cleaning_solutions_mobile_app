// lib/services/auth_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  static const _storage = FlutterSecureStorage();

  // register मधून mobile काढा — API doc मध्ये नाही
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/register',
      data: {
        'name':                  name,
        'email':                 email,
        'password':              password,
        'password_confirmation': password,
      },
    );
    final data = response.data['data'] ?? response.data;
    if (data['token'] != null) {
      await _storage.write(key: 'auth_token', value: data['token']);
    }
    return data;
  }

  // ✅ Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      data: {
        'email':    email,
        'password': password,
      },
    );

    final data = response.data['data'] ?? response.data;
    if (data['token'] != null) {
      await _storage.write(key: 'auth_token', value: data['token']);
    }

    return data;
  }

  // ✅ Logout
  Future<void> logout() async {
    await _api.post('/auth/logout');
    await _storage.delete(key: 'auth_token');
  }

  // ✅ Get Profile
  // ✅ FIX: API cha actual response shape { status, data: {id, name, email, phone} }
  // ahe — 'user' navाची wrapper key नahi (login/register cha response madhe
  // asते, pan profile cha response madhe नahi). auth_provider.dart मध्ये
  // `response['user']` वापरून user data extract केला जातो, mhणून इथे तोच
  // shape (`{'user': {...}}`) return karणे गरजेचे — नाहीतर app restart
  // झाल्यावर (फक्त getProfile() call होतो, login नाही) user data null येतो.
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get('/auth/profile');
    final data = response.data['data'] ?? response.data;
    return {'user': data};
  }

  // ✅ Update Profile — API report uses 'phone' field
  // ✅ FIX: getProfile() सारखाच issue — API cha response direct data
  // object देतो, 'user' wrapper शिवाय. Same normalization apply केली.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await _api.put(
      '/auth/profile',
      data: {
        'name':  name,
        'email': email,
        'phone': phone,
      },
    );
    final data = response.data['data'] ?? response.data;
    return {'user': data};
  }

  // ✅ FIX: confirm_password field add केला
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _api.put(
      '/auth/password',
      data: {
        'current_password': currentPassword,
        'new_password':     newPassword,
        'confirm_password': newPassword,
      },
    );
    return response.data;
  }

  // ✅ Forgot Password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await _api.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return response.data;
  }

  // ✅ Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _api.post(
      '/auth/reset-password',
      data: {
        'token':        token,
        'new_password': newPassword,
      },
    );
    return response.data;
  }

  // ✅ NEW: Delete Account (DPDPA — schedules deletion after 7-day grace period)
  // Body madhe फक्त password पाठवतो; server verify karto आणि deletion
  // schedule करतो. Response madhe deletion_scheduled_at + (असल्यास)
  // active_order_warning yeतो, दोन्ही AuthNotifier state madhe save होतात.
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
  }) async {
    final response = await _api.delete(
      '/auth/account',
      data: {'password': password},
    );
    final data = response.data['data'] ?? response.data;
    return {
      'message': response.data['message'],
      ...data,
    };
  }

  // ✅ NEW: Cancel a pending deletion request — account परत पूर्ण active होतो
  Future<Map<String, dynamic>> cancelAccountDeletion() async {
    final response = await _api.post('/auth/account/cancel-deletion');
    return response.data;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}