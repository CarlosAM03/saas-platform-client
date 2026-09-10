enum ApiErrorKind {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  serviceUnavailable,
  network,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
