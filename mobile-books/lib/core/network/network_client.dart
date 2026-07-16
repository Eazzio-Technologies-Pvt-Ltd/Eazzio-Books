import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/network/api_client.dart';
import 'package:path_provider/path_provider.dart';

class LazyPersistCookieJar implements CookieJar {
  PersistCookieJar? _delegate;
  final Future<Directory> _dirFuture = getApplicationSupportDirectory();

  Future<PersistCookieJar> _getDelegate() async {
    if (_delegate != null) return _delegate!;
    final dir = await _dirFuture;
    final path = dir.path;
    _delegate = PersistCookieJar(
      storage: FileStorage(path),
    );
    return _delegate!;
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    final jar = await _getDelegate();
    await jar.saveFromResponse(uri, cookies);
  }

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    final jar = await _getDelegate();
    return await jar.loadForRequest(uri);
  }

  @override
  bool get ignoreExpires => false;

  @override
  Future<void> deleteAll() async {
    final jar = await _getDelegate();
    await jar.deleteAll();
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    final jar = await _getDelegate();
    await jar.delete(uri, withDomainSharedCookie);
  }
}

final cookieJarProvider = Provider<CookieJar>((ref) {
  return LazyPersistCookieJar();
});

class SubscriptionLimitNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? val) => super.state = val;
}

final subscriptionLimitProvider = NotifierProvider<SubscriptionLimitNotifier, String?>(() {
  return SubscriptionLimitNotifier();
});

final dioProvider = Provider<Dio>((ref) {
  // Load configuration from environment variables (.env file).
  // Do NOT hardcode the base URL in the source code.
  final String? envUrl = dotenv.env['API_BASE_URL'];
  if (envUrl == null || envUrl.isEmpty) {
    debugPrint('WARNING: API_BASE_URL environment variable is missing from .env file.');
  }
  
  final String defaultUrl = (kReleaseMode || kProfileMode)
      ? 'https://eazzio-books.onrender.com/api'
      : 'http://10.0.2.2:5000/api';
  final String baseUrl = envUrl ?? defaultUrl;

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final cookieJar = ref.watch(cookieJarProvider);
  dio.interceptors.add(CookieManager(cookieJar));

  // Auth interceptor — attach JWT and Cookie to every request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final storage = ref.read(secureStorageProvider);
      final sessionCookie = await storage.read(key: 'session_cookie');
      if (sessionCookie != null && sessionCookie.isNotEmpty) {
        options.headers['Cookie'] = sessionCookie;
        // Parse raw token from cookie to send as Bearer header as well
        final parts = sessionCookie.split(';');
        for (var part in parts) {
          final trimmed = part.trim();
          if (trimmed.startsWith('token=')) {
            final token = trimmed.substring(6);
            options.headers['Authorization'] = 'Bearer $token';
            break;
          }
        }
      }
      handler.next(options);
    },
  ));

  // Centralized HTTP 402/403 limit handler
  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException error, handler) {
      if (error.response?.statusCode == 402) {
        ref.read(authNotifierProvider.notifier).markSubscriptionExpired();
      } else if (error.response?.statusCode == 403 && error.response?.data is Map) {
        final data = error.response?.data as Map;
        if (data.containsKey('upgradeNudge')) {
          final nudgeMessage = data['upgradeNudge'] as String;
          ref.read(subscriptionLimitProvider.notifier).state = nudgeMessage;
        }
      }
      return handler.next(error);
    },
  ));
  
  // Log request and response details in debug mode
  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

class NetworkClient {
  final Dio _dio;

  NetworkClient(this._dio);

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

final networkClientProvider = Provider<NetworkClient>((ref) {
  final dio = ref.watch(dioProvider);
  return NetworkClient(dio);
});
