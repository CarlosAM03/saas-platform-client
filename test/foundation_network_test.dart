import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/errors/error_mapper.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';
import 'package:saas_platform_client/features/tenants/data/tenants_repository.dart';

class MemoryStorage extends SecureTokenStorage {
  MemoryStorage({this.token}) : super(const FlutterSecureStorage());

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> clearToken() async => token = null;
}

class RecordingAdapter implements HttpClientAdapter {
  int statusCode = 200;
  String body = '{"success":true,"data":{}}';
  DioExceptionType? failureType;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    if (failureType != null) {
      throw DioException(requestOptions: options, type: failureType!);
    }
    return ResponseBody.fromString(body, statusCode, headers: {
      'content-type': ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

ApiClient clientFor(RecordingAdapter adapter, MemoryStorage storage,
    {Future<void> Function()? onUnauthorized}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = adapter;
  return ApiClient(
    config: const AppConfig(apiBaseUrl: 'http://localhost'),
    storage: storage,
    dio: dio,
    onUnauthorized: onUnauthorized,
  );
}

Future<ApiException> failureOf(Future<Object?> request) async {
  try {
    await request;
    throw StateError('Expected ApiException');
  } on ApiException catch (error) {
    return error;
  }
}

void main() {
  test('DELETE passes query parameters and Bearer to Dio', () async {
    final adapter = RecordingAdapter();
    final storage = MemoryStorage(token: 'test-token');
    await clientFor(adapter, storage)
        .delete('/campaigns/one', queryParameters: {'permanent': true});
    expect(adapter.request?.method, 'DELETE');
    expect(adapter.request?.queryParameters, {'permanent': true});
    expect(adapter.request?.headers['Authorization'], 'Bearer test-token');
  });

  test('contract error exposes code and only error.details', () async {
    final adapter = RecordingAdapter()
      ..statusCode = 503
      ..body =
          '{"success":false,"error":{"code":"PROSPECTOR_INTEGRATION_PENDING","message":"Pending","details":{"reason":"PROSPECTOR_INTEGRATION_PENDING"},"timestamp":"2026-10-10T00:00:00Z"}}';
    final error =
        await failureOf(clientFor(adapter, MemoryStorage()).get('/jobs'));
    expect(error.kind, ApiErrorKind.serviceUnavailable);
    expect(error.statusCode, 503);
    expect(error.code, 'PROSPECTOR_INTEGRATION_PENDING');
    expect(error.message, 'Pending');
    expect(error.details, {'reason': 'PROSPECTOR_INTEGRATION_PENDING'});
  });

  test(
      'HTTP statuses map to distinct kinds and malformed body has safe fallback',
      () async {
    final cases = {
      400: ApiErrorKind.badRequest,
      401: ApiErrorKind.unauthorized,
      403: ApiErrorKind.forbidden,
      404: ApiErrorKind.notFound,
      409: ApiErrorKind.conflict,
      429: ApiErrorKind.rateLimited,
      503: ApiErrorKind.serviceUnavailable,
      500: ApiErrorKind.unknown,
    };
    for (final entry in cases.entries) {
      final adapter = RecordingAdapter()
        ..statusCode = entry.key
        ..body = '"not-an-envelope"';
      final error =
          await failureOf(clientFor(adapter, MemoryStorage()).get('/failure'));
      expect(error.kind, entry.value);
      expect(error.code, isNull);
      expect(error.details, isNull);
      expect(error.message, isNotEmpty);
    }
  });

  test('connection and timeout failures map to network', () async {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout
    ]) {
      final adapter = RecordingAdapter()..failureType = type;
      final error =
          await failureOf(clientFor(adapter, MemoryStorage()).get('/failure'));
      expect(error.kind, ApiErrorKind.network);
    }
  });

  test('401 clears token and invokes callback; 403 preserves both', () async {
    final adapter = RecordingAdapter()..statusCode = 401;
    final storage = MemoryStorage(token: 'test-token');
    var callbackCount = 0;
    final client = clientFor(adapter, storage,
        onUnauthorized: () async => callbackCount++);
    await failureOf(client.get('/protected'));
    expect(storage.token, isNull);
    expect(callbackCount, 1);
    storage.token = 'next-token';
    adapter.statusCode = 403;
    final forbidden = await failureOf(client.get('/protected'));
    expect(forbidden.kind, ApiErrorKind.forbidden);
    expect(storage.token, 'next-token');
    expect(callbackCount, 1);
  });

  test('ErrorMapper provides safe messages for every kind', () {
    const mapper = ErrorMapper();
    for (final kind in ApiErrorKind.values) {
      final message = mapper
          .userMessage(ApiException(kind: kind, message: 'internal details'));
      expect(message, isNotEmpty);
      expect(message, isNot(contains('internal details')));
    }
    expect(
        mapper.userMessage(
            const ApiException(kind: ApiErrorKind.unauthorized, message: 'x')),
        contains('Credenciales'));
    expect(
        mapper.userMessage(
            const ApiException(kind: ApiErrorKind.network, message: 'x')),
        contains('conectar'));
    expect(
        mapper.userMessage(
            const ApiException(kind: ApiErrorKind.rateLimited, message: 'x')),
        contains('solicitudes'));
  });

  test('tenant discovery uses GET /tenants and parses a real list wrapper',
      () async {
    final adapter = RecordingAdapter()
      ..body =
          '{"success":true,"data":[{"id":"tenant-1","name":"Demo Norte","slug":"demo-norte","status":"ACTIVO"}]}';
    final repository = TenantsRepository(
        clientFor(adapter, MemoryStorage(token: 'admin-token')));
    final tenants = await repository.discover();
    expect(adapter.request?.path, '/api/v1/tenants');
    expect(adapter.request?.method, 'GET');
    expect(adapter.request?.headers['Authorization'], 'Bearer admin-token');
    expect(tenants.single.name, 'Demo Norte');
  });
}
