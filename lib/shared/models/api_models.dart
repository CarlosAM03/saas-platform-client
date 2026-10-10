import 'package:json_annotation/json_annotation.dart';

part 'api_models.g.dart';

// These values match the API status literals.
// ignore: constant_identifier_names
enum ProspectingJobStatus { QUEUED, RUNNING, COMPLETED, FAILED, CANCELLED }

class ApiResponse<T> {
  const ApiResponse({required this.success, required this.data, this.meta});
  final bool success;
  final T data;
  final Map<String, dynamic>? meta;
}

class ApiErrorResponse {
  const ApiErrorResponse({required this.success, required this.error});
  final bool success;
  final ApiErrorBody error;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      ApiErrorResponse(
        success: json['success'] == true,
        error: ApiErrorBody.fromJson(
            Map<String, dynamic>.from(json['error'] as Map)),
      );
}

class ApiErrorBody {
  const ApiErrorBody(
      {required this.code,
      required this.message,
      required this.details,
      required this.timestamp});
  final String code;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) => ApiErrorBody(
        code: json['code'] as String,
        message: json['message'] as String,
        details:
            Map<String, dynamic>.from((json['details'] as Map?) ?? const {}),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class PaginationMeta {
  const PaginationMeta(
      {required this.page,
      required this.limit,
      required this.total,
      required this.totalPages});
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    int field(String name, {required int minimum, int? maximum}) {
      final value = json[name];
      if (value is! int ||
          value < minimum ||
          (maximum != null && value > maximum)) {
        throw FormatException('Invalid pagination field: $name');
      }
      return value;
    }

    return PaginationMeta(
      page: field('page', minimum: 1),
      limit: field('limit', minimum: 1, maximum: 100),
      total: field('total', minimum: 0),
      totalPages: field('totalPages', minimum: 0),
    );
  }
}

class PaginatedResult<T> {
  const PaginatedResult({required this.items, required this.meta});

  final List<T> items;
  final PaginationMeta meta;
}

@JsonSerializable(createToJson: false)
class AuthUser {
  const AuthUser(
      {required this.id,
      required this.name,
      required this.email,
      this.platformRole,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String name;
  final String email;
  final String? platformRole;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}

@JsonSerializable(createToJson: false)
class AuthTenant {
  const AuthTenant(
      {required this.id,
      required this.name,
      required this.slug,
      required this.status});
  final String id;
  final String name;
  final String slug;
  final String status;
  factory AuthTenant.fromJson(Map<String, dynamic> json) =>
      _$AuthTenantFromJson(json);
}

class AuthContext {
  const AuthContext(
      {required this.accessToken,
      required this.user,
      required this.tenants,
      this.currentTenantId});
  final String accessToken;
  final AuthUser user;
  final List<AuthTenant> tenants;
  final String? currentTenantId;
  factory AuthContext.fromJson(Map<String, dynamic> json) => AuthContext(
        accessToken: json['accessToken'] as String,
        user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
        tenants: (json['tenants'] as List<dynamic>? ?? const [])
            .map((item) =>
                AuthTenant.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(growable: false),
        currentTenantId: json['currentTenantId'] as String?,
      );
}

class User {
  const User(
      {required this.id,
      required this.name,
      required this.email,
      this.platformRole,
      this.role,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String name;
  final String email;
  final String? platformRole;
  final Role? role;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Role {
  const Role(
      {required this.id, required this.name, this.tenantId, this.description});
  final String id;
  final String name;
  final String? tenantId;
  final String? description;
}

class Tenant {
  const Tenant(
      {required this.id,
      required this.name,
      required this.slug,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String name;
  final String slug;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

Map<String, dynamic> _stringMap(Object? value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('Expected $label object');
  }
  return Map<String, dynamic>.from(value);
}

Map<String, dynamic> _envelope(Object? response) {
  final map = _stringMap(response, 'response');
  if (map['success'] != true || !map.containsKey('data')) {
    throw const FormatException('Invalid success response envelope');
  }
  return map;
}

Map<String, dynamic> unwrapObject(Object? response) =>
    _stringMap(_envelope(response)['data'], 'data');

List<T> unwrapList<T>(
    Object? response, T Function(Map<String, dynamic>) fromJson) {
  final data = _envelope(response)['data'];
  if (data is! List) throw const FormatException('Expected data list');
  return List<T>.unmodifiable(
      data.map((item) => fromJson(_stringMap(item, 'list item'))));
}

PaginatedResult<T> unwrapPaginated<T>(
  Object? response,
  T Function(Map<String, dynamic>) fromJson,
) {
  final envelope = _envelope(response);
  final data = envelope['data'];
  if (data is! List) throw const FormatException('Expected data list');
  final meta = _stringMap(envelope['meta'], 'meta');
  return PaginatedResult<T>(
    items: List<T>.unmodifiable(
        data.map((item) => fromJson(_stringMap(item, 'list item')))),
    meta: PaginationMeta.fromJson(meta),
  );
}

// Existing Auth callers keep the same public API while object/list parsing is explicit.
Map<String, dynamic> unwrapData(Object? response) => unwrapObject(response);
