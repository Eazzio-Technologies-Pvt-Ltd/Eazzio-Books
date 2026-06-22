import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioException(DioException dioException) {
    String message = 'An unexpected error occurred. Please try again.';
    int? statusCode = dioException.response?.statusCode;

    if (dioException.response != null && dioException.response!.data != null) {
      final data = dioException.response!.data;
      if (data is Map && data.containsKey('message')) {
        message = data['message'].toString();
      } else if (data is Map && data.containsKey('error')) {
        message = data['error'].toString();
      } else {
        message = dioException.response!.statusMessage ?? message;
      }
    } else {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Send timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Receive timeout. Please try again.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Secure connection failed.';
          break;
        case DioExceptionType.badResponse:
          message = 'Bad response from server.';
          break;
        case DioExceptionType.cancel:
          message = 'Request cancelled.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection. Please verify your network settings.';
          break;
        case DioExceptionType.unknown:
          message = 'Network error. Please try again.';
          break;
      }
    }

    return ApiException(message: message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
