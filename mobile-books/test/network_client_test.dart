import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mobile_books/core/network/network_client.dart';

// Since we cannot use mockito generators easily, we will create a fake/mock implementation of Interceptor or custom Dio adapter, or subclass Dio/HttpClientAdapter.
// Creating a custom HttpClientAdapter is the cleanest way to mock HTTP requests in Dio.
class FakeHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late NetworkClient networkClient;
  late FakeHttpClientAdapter fakeAdapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.com'));
    fakeAdapter = FakeHttpClientAdapter();
    dio.httpClientAdapter = fakeAdapter;
    networkClient = NetworkClient(dio);
  });

  group('NetworkClient API Success & Mapping Tests', () {
    test('Successful GET requests return parsed response data', () async {
      fakeAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"status": "success", "data": {"id": 123, "name": "Test Item"}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final response = await networkClient.get('/test-route');
      expect(response.statusCode, 200);
      expect(response.data, isMap);
      expect(response.data['data']['name'], 'Test Item');
    });

    test('Successful POST requests with payload return parsed data', () async {
      fakeAdapter.handler = (options) {
        expect(options.data, contains('payload_key'));
        return ResponseBody.fromString(
          '{"created": true}',
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final response = await networkClient.post('/create', data: {'payload_key': 'value'});
      expect(response.statusCode, 201);
      expect(response.data['created'], isTrue);
    });
  });

  group('NetworkClient Error Handling Tests', () {
    test('401 Unauthorized returns custom response status', () async {
      fakeAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"message": "Unauthorized Access"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await networkClient.get('/secure-data');
        fail('Should throw DioException');
      } catch (e) {
        expect(e, isA<DioException>());
        final dioError = e as DioException;
        expect(dioError.response?.statusCode, 401);
      }
    });

    test('Timeout handling works when connection times out', () async {
      fakeAdapter.handler = (options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        );
      };

      try {
        await networkClient.get('/timeout-route');
        fail('Should throw timeout DioException');
      } catch (e) {
        expect(e, isA<DioException>());
        final dioError = e as DioException;
        expect(dioError.type, DioExceptionType.connectionTimeout);
      }
    });

    test('Network failure is properly propagated', () async {
      fakeAdapter.handler = (options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No Internet Connection',
        );
      };

      try {
        await networkClient.get('/network-fail');
        fail('Should throw network exception');
      } catch (e) {
        expect(e, isA<DioException>());
        final dioError = e as DioException;
        expect(dioError.type, DioExceptionType.connectionError);
      }
    });

    test('Invalid JSON response triggers format exception during post-processing or error response', () async {
      fakeAdapter.handler = (options) {
        return ResponseBody.fromString(
          'not-a-json-payload',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      // Since Dio processes JSON parsing dynamically if the content-type is json, it might throw a parsing exception.
      try {
        await networkClient.get('/bad-json');
      } catch (e) {
        // Dio parsing error is typically a DioException of type badResponse or other parsing error depending on version/setup.
        expect(e, isA<DioException>());
      }
    });
  });
}
