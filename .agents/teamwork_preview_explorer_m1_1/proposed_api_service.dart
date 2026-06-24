import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  // Compile-time environment variables
  static const String appMode = String.fromEnvironment('APP_MODE', defaultValue: 'development');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  late final Dio dio;
  late final PersistCookieJar cookieJar;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    dio = Dio();

    // 1. Setup persistent cookie store
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/cookies';
    cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
    dio.interceptors.add(CookieManager(cookieJar));

    // 2. Base URL mapping (handles local Android emulator loopback vs generic desktop/iOS)
    final String defaultBaseUrl = kIsWeb
        ? 'http://localhost:5001/api'
        : (Platform.isAndroid ? 'http://10.0.2.2:5001/api' : 'http://localhost:5001/api');

    dio.options.baseUrl = apiBaseUrl.isNotEmpty ? apiBaseUrl : defaultBaseUrl;

    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Logging interceptor for debugging network logs
    final activeAppMode = appMode.isNotEmpty ? appMode : 'development';
    if (kDebugMode || activeAppMode == 'development' || activeAppMode == 'staging') {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }

    _isInitialized = true;
  }

  void setupAuthInterceptor(VoidCallback onUnauthorized) {
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Clear credentials on unauthorized access
          await cookieJar.deleteAll();
          onUnauthorized();
        }
        return handler.next(e);
      },
    ));
  }

  // Unified Request Wrapper for clean error handling
  Future<Response<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!_isInitialized) {
      throw Exception('ApiService is not initialized. Run init() first.');
    }

    try {
      final response = await dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  // Helper HTTP verbs
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return request<T>(path, method: 'GET', queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return request<T>(path, method: 'POST', data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return request<T>(path, method: 'PUT', data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return request<T>(path, method: 'DELETE');
  }

  ApiException _handleDioError(DioException error) {
    String message = 'Something went wrong';
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else {
        message = 'Server Error (${error.response?.statusCode})';
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection';
          break;
        default:
          message = 'Network error: ${error.message}';
      }
    }
    return ApiException(message: message, statusCode: error.response?.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
