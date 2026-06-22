import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  // Helper to extract the token from Set-Cookie header
  String? _extractTokenFromCookie(Map<String, List<String>> headers) {
    final cookies = headers['set-cookie'] ?? headers['Set-Cookie'];
    if (cookies != null && cookies.isNotEmpty) {
      for (var cookie in cookies) {
        if (cookie.contains('token=')) {
          final parts = cookie.split(';');
          for (var part in parts) {
            final trimmed = part.trim();
            if (trimmed.startsWith('token=')) {
              return trimmed.substring(6);
            }
          }
        }
      }
    }
    return null;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _apiClient.post(
      '/api/login',
      data: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      },
    );

    // Extract token from Set-Cookie header
    final token = _extractTokenFromCookie(response.headers.map);
    if (token != null) {
      await _apiClient.saveToken(token);
    }

    final userData = response.data['user'];
    return UserModel.fromJson(userData);
  }

  Future<void> register({
    required String email,
    required String password,
    required String companyName,
    String? fullName,
  }) async {
    await _apiClient.post(
      '/api/register',
      data: {
        'email': email,
        'password': password,
        'companyName': companyName,
        'fullName': fullName,
      },
    );
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get('/api/profile');
    final userData = response.data['user'];
    return UserModel.fromJson(userData);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/api/logout');
    } catch (_) {
      // Ignore network errors during logout to allow local cleanup
    } finally {
      await _apiClient.deleteToken();
    }
  }
}
