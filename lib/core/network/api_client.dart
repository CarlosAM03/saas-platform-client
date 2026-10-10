import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureTokenStorage storage,
    Future<void> Function()? onUnauthorized,
    Dio? dio,
    Logger? logger,
  })  : _storage = storage,
        _onUnauthorized = onUnauthorized,
        _logger = logger ?? Logger(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: config.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.clearToken();
          if (error.requestOptions.headers['Authorization'] != null) {
            await _onUnauthorized?.call();
          }
          _logger.w(
              'API returned 401 for ${error.requestOptions.method} ${error.requestOptions.path}');
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;
  final SecureTokenStorage _storage;
  final Future<void> Function()? _onUnauthorized;
  final Logger _logger;

  Future<Object?> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _request(
        () => _dio.get<Object?>(path, queryParameters: queryParameters));
    return response.data;
  }

  Future<Object?> post(String path, {Object? data}) async {
    final response = await _request(() => _dio.post<Object?>(path, data: data));
    return response.data;
  }

  Future<Object?> patch(String path, {Object? data}) async {
    final response =
        await _request(() => _dio.patch<Object?>(path, data: data));
    return response.data;
  }

  Future<Object?> delete(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _request(
        () => _dio.delete<Object?>(path, queryParameters: queryParameters));
    return response.data;
  }

  Future<Response<Object?>> download(String path) {
    return _request(() => _dio.get<Object?>(path,
        options: Options(responseType: ResponseType.bytes)));
  }

  Future<Response<Object?>> _request(
      Future<Response<Object?>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final errorBody =
        body is Map && body['error'] is Map ? body['error'] as Map : null;
    final code = errorBody?['code'];
    final message = errorBody?['message'];
    final details = errorBody?['details'];
    final kind = switch (status) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 => ApiErrorKind.conflict,
      429 => ApiErrorKind.rateLimited,
      503 => ApiErrorKind.serviceUnavailable,
      _
          when error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout =>
        ApiErrorKind.network,
      _ => ApiErrorKind.unknown,
    };
    return ApiException(
      kind: kind,
      statusCode: status,
      code: code is String ? code : null,
      message: message is String && message.isNotEmpty
          ? message
          : 'Error de comunicación con el backend.',
      details: details,
    );
  }
}
