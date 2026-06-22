import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/auth/data/models/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final NetworkClient _networkClient;
  final CookieJar _cookieJar;

  AuthService(this._networkClient, this._cookieJar);

  /// Performs user login and sets session cookie.
  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _networkClient.post(
        '/login',
        data: {
          'email': email.trim(),
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['user'] != null) {
        // Persist session cookie from CookieJar to FlutterSecureStorage
        final uri = Uri.parse(_networkClient.dio.options.baseUrl);
        final cookies = await _cookieJar.loadForRequest(uri);
        String? tokenCookie;
        for (var c in cookies) {
          if (c.name == 'token') {
            tokenCookie = c.toString();
            break;
          }
        }
        if (tokenCookie == null && cookies.isNotEmpty) {
          tokenCookie = cookies.first.toString();
        }
        if (tokenCookie != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'session_cookie', value: tokenCookie);
        }

        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw AuthException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Login failed. Please check your network connection.';
      throw AuthException(message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Performs user registration.
  Future<User> register({
    required String email,
    required String password,
    required String companyName,
    required String fullName,
  }) async {
    try {
      final response = await _networkClient.post(
        '/register',
        data: {
          'email': email.trim(),
          'password': password,
          'companyName': companyName.trim(),
          'fullName': fullName.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['user'] != null) {
        // Persist session cookie from CookieJar to FlutterSecureStorage
        final uri = Uri.parse(_networkClient.dio.options.baseUrl);
        final cookies = await _cookieJar.loadForRequest(uri);
        String? tokenCookie;
        for (var c in cookies) {
          if (c.name == 'token') {
            tokenCookie = c.toString();
            break;
          }
        }
        if (tokenCookie == null && cookies.isNotEmpty) {
          tokenCookie = cookies.first.toString();
        }
        if (tokenCookie != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'session_cookie', value: tokenCookie);
        }

        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw AuthException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Registration failed.';
      throw AuthException(message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Fetches the user profile if a valid session exists.
  Future<User> getProfile() async {
    try {
      // Restore cookie from FlutterSecureStorage to CookieJar on startup
      const storage = FlutterSecureStorage();
      final savedCookie = await storage.read(key: 'session_cookie');
      if (savedCookie != null && savedCookie.isNotEmpty) {
        final uri = Uri.parse(_networkClient.dio.options.baseUrl);
        final cookie = Cookie.fromSetCookieValue(savedCookie);
        await _cookieJar.saveFromResponse(uri, [cookie]);
      }

      final response = await _networkClient.get('/profile');
      final data = response.data as Map<String, dynamic>;
      if (data['user'] != null) {
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw AuthException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch user profile.';
      throw AuthException(message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Requests a password reset email.
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _networkClient.post(
        '/forgot-password',
        data: {'email': email.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'If the account exists, a reset link has been sent.';
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to request password reset.';
      throw AuthException(message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Resets password using token.
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _networkClient.post(
        '/reset-password/$token',
        data: {'password': newPassword},
      );
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Password has been reset successfully.';
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to reset password.';
      throw AuthException(message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Performs logout and clears token cookie.
  Future<void> logout() async {
    try {
      await _networkClient.post('/logout');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Logout failed.';
      throw AuthException(message);
    } catch (e) {
      throw AuthException(e.toString());
    } finally {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'session_cookie');
      await _cookieJar.deleteAll();
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  final cookieJar = ref.watch(cookieJarProvider);
  return AuthService(networkClient, cookieJar);
});
