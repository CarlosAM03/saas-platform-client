// Wire enum names are intentionally identical to the backend contract.
// ignore_for_file: constant_identifier_names

import 'src/json_fields.dart';
export '../shared/models/api_models.dart'
    show AuthContext, AuthUser, AuthTenant, PaginationMeta, PaginatedResult;

enum TenantStatus { ACTIVO, SUSPENDIDO }

enum UserStatus { ACTIVO, INACTIVO }

enum RoleName { OWNER, MEMBER }

enum PlatformRole { ADMIN }

enum CampaignStatus { ACTIVA, PAUSADA, COMPLETADA, ARCHIVADA }

enum ProspectStatus { ACTIVO, INACTIVO }

enum ProspectSource { google_maps }

enum ProspectingJobStatus { QUEUED, RUNNING, COMPLETED, FAILED, CANCELLED }

enum ExportFormat { csv, xlsx }

enum HealthStatus { ok }

enum DatabaseStatus { up }

class Health {
  const Health({required this.status, this.database});
  final HealthStatus status;
  final DatabaseStatus? database;
  factory Health.fromJson(Map<String, dynamic> json) => Health(
        status: enumValue(json['status'], HealthStatus.values),
        database: json['database'] == null
            ? null
            : enumValue(json['database'], DatabaseStatus.values),
      );
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
  final TenantStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: requiredValue<String>(json, 'id'),
        name: requiredValue<String>(json, 'name'),
        slug: requiredValue<String>(json, 'slug'),
        status: enumValue(json['status'], TenantStatus.values),
        createdAt: dateValue(json, 'createdAt'),
        updatedAt: dateValue(json, 'updatedAt'),
      );
}

class Role {
  const Role(
      {required this.id, required this.name, this.tenantId, this.description});
  final String id;
  final RoleName name;
  final String? tenantId;
  final String? description;
  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: requiredValue<String>(json, 'id'),
        name: enumValue(json['name'], RoleName.values),
        tenantId: optionalValue<String>(json, 'tenantId'),
        description: optionalValue<String>(json, 'description'),
      );
}

class UserMembership {
  const UserMembership(
      {required this.tenantId,
      required this.tenantName,
      required this.tenantSlug,
      required this.role});
  final String tenantId;
  final String tenantName;
  final String tenantSlug;
  final Role role;
  factory UserMembership.fromJson(Map<String, dynamic> json) => UserMembership(
        tenantId: requiredValue<String>(json, 'tenantId'),
        tenantName: requiredValue<String>(json, 'tenantName'),
        tenantSlug: requiredValue<String>(json, 'tenantSlug'),
        role: Role.fromJson(jsonObject(json['role'])),
      );
}

class User {
  const User(
      {required this.id,
      required this.name,
      required this.email,
      this.platformRole,
      this.role,
      required this.tenants,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String name;
  final String email;
  final PlatformRole? platformRole;
  final Role? role;
  final List<UserMembership> tenants;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: requiredValue<String>(json, 'id'),
        name: requiredValue<String>(json, 'name'),
        email: requiredValue<String>(json, 'email'),
        platformRole: json['platformRole'] == null
            ? null
            : enumValue(json['platformRole'], PlatformRole.values),
        role: nullableValue<Map<dynamic, dynamic>>(json, 'role') == null
            ? null
            : Role.fromJson(jsonObject(json['role'])),
        tenants: List<UserMembership>.unmodifiable(
            (optionalValue<List<dynamic>>(json, 'tenants') ?? const [])
                .map((item) => UserMembership.fromJson(jsonObject(item)))),
        status: enumValue(json['status'], UserStatus.values),
        createdAt: dateValue(json, 'createdAt'),
        updatedAt: dateValue(json, 'updatedAt'),
      );
}

class Campaign {
  const Campaign(
      {required this.id,
      required this.name,
      this.description,
      required this.status,
      this.createdBy,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String name;
  final String? description;
  final CampaignStatus status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: requiredValue<String>(json, 'id'),
        name: requiredValue<String>(json, 'name'),
        description: optionalValue<String>(json, 'description'),
        status: enumValue(json['status'], CampaignStatus.values),
        createdBy: optionalValue<String>(json, 'createdBy'),
        createdAt: dateValue(json, 'createdAt'),
        updatedAt: dateValue(json, 'updatedAt'),
      );
}

class ProspectingQuery {
  const ProspectingQuery(
      {required this.keyword,
      required this.location,
      required this.source,
      required this.limit});
  final String keyword;
  final String location;
  final ProspectSource source;
  final int limit;
  factory ProspectingQuery.fromJson(Map<String, dynamic> json) =>
      ProspectingQuery(
        keyword: requiredValue<String>(json, 'keyword'),
        location: requiredValue<String>(json, 'location'),
        source: enumValue(json['source'], ProspectSource.values),
        limit: requiredValue<int>(json, 'limit'),
      );
  Map<String, dynamic> toJson() => {
        'keyword': keyword,
        'location': location,
        'source': source.name,
        'limit': limit
      };
}

class PipelineProgress {
  const PipelineProgress(
      {required this.source,
      required this.stage,
      required this.message,
      required this.percentage});
  final ProspectSource source;
  final String stage;
  final String message;
  final num percentage;
  factory PipelineProgress.fromJson(Map<String, dynamic> json) =>
      PipelineProgress(
        source: enumValue(json['source'], ProspectSource.values),
        stage: requiredValue<String>(json, 'stage'),
        message: requiredValue<String>(json, 'message'),
        percentage: requiredValue<num>(json, 'percentage'),
      );
}

class PersistResultsResult {
  const PersistResultsResult({required this.persisted, required this.skipped});
  final int persisted;
  final int skipped;
  factory PersistResultsResult.fromJson(Map<String, dynamic> json) =>
      PersistResultsResult(
        persisted: requiredValue<int>(json, 'persisted'),
        skipped: requiredValue<int>(json, 'skipped'),
      );
}

class BusinessResult {
  const BusinessResult(
      {required this.name,
      this.category,
      this.address,
      this.phone,
      this.email,
      this.website,
      required this.source,
      this.sourceIdentifier,
      this.language,
      this.metadata});
  final String name;
  final String? category;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final ProspectSource source;
  final String? sourceIdentifier;
  final String? language;
  final Map<String, dynamic>? metadata;
  factory BusinessResult.fromJson(Map<String, dynamic> json) => BusinessResult(
        name: requiredValue<String>(json, 'name'),
        category: optionalValue<String>(json, 'category'),
        address: optionalValue<String>(json, 'address'),
        phone: optionalValue<String>(json, 'phone'),
        email: optionalValue<String>(json, 'email'),
        website: optionalValue<String>(json, 'website'),
        source: enumValue(json['source'], ProspectSource.values),
        sourceIdentifier: optionalValue<String>(json, 'sourceIdentifier'),
        language: optionalValue<String>(json, 'language'),
        metadata:
            json['metadata'] == null ? null : jsonObject(json['metadata']),
      );
}

class Prospect {
  const Prospect(
      {required this.id,
      required this.campaignId,
      required this.name,
      this.category,
      this.address,
      this.phone,
      this.email,
      this.website,
      required this.source,
      this.sourceIdentifier,
      this.language,
      this.metadata,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String campaignId;
  final String name;
  final String? category;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final ProspectSource source;
  final String? sourceIdentifier;
  final String? language;
  final Map<String, dynamic>? metadata;
  final ProspectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory Prospect.fromJson(Map<String, dynamic> json) => Prospect(
        id: requiredValue<String>(json, 'id'),
        campaignId: requiredValue<String>(json, 'campaignId'),
        name: requiredValue<String>(json, 'name'),
        category: optionalValue<String>(json, 'category'),
        address: optionalValue<String>(json, 'address'),
        phone: optionalValue<String>(json, 'phone'),
        email: optionalValue<String>(json, 'email'),
        website: optionalValue<String>(json, 'website'),
        source: enumValue(json['source'], ProspectSource.values),
        sourceIdentifier: optionalValue<String>(json, 'sourceIdentifier'),
        language: optionalValue<String>(json, 'language'),
        metadata:
            json['metadata'] == null ? null : jsonObject(json['metadata']),
        status: enumValue(json['status'], ProspectStatus.values),
        createdAt: dateValue(json, 'createdAt'),
        updatedAt: dateValue(json, 'updatedAt'),
      );
}

class ProspectingJobSummary {
  const ProspectingJobSummary(
      {required this.id,
      required this.campaignId,
      required this.status,
      required this.createdAt,
      this.startedAt,
      this.completedAt});
  final String id;
  final String campaignId;
  final ProspectingJobStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  factory ProspectingJobSummary.fromJson(Map<String, dynamic> json) =>
      ProspectingJobSummary(
        id: requiredValue<String>(json, 'id'),
        campaignId: requiredValue<String>(json, 'campaignId'),
        status: enumValue(json['status'], ProspectingJobStatus.values),
        createdAt: dateValue(json, 'createdAt'),
        startedAt: nullableDate(json, 'startedAt'),
        completedAt: nullableDate(json, 'completedAt'),
      );
}

class ProspectingJobDetail {
  const ProspectingJobDetail(
      {required this.id,
      required this.campaignId,
      required this.status,
      required this.createdAt,
      this.startedAt,
      this.completedAt,
      required this.tenantId,
      required this.requestedBy,
      required this.query,
      this.requestedLimit,
      this.error,
      required this.updatedAt,
      required this.resultsAvailable,
      this.results,
      this.progress});
  final String id;
  final String campaignId;
  final ProspectingJobStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String tenantId;
  final String requestedBy;
  final ProspectingQuery query;
  final int? requestedLimit;
  final String? error;
  final DateTime updatedAt;
  final bool resultsAvailable;
  final List<BusinessResult>? results;
  final PipelineProgress? progress;
  factory ProspectingJobDetail.fromJson(Map<String, dynamic> json) =>
      ProspectingJobDetail(
        id: requiredValue<String>(json, 'id'),
        campaignId: requiredValue<String>(json, 'campaignId'),
        status: enumValue(json['status'], ProspectingJobStatus.values),
        createdAt: dateValue(json, 'createdAt'),
        startedAt: nullableDate(json, 'startedAt'),
        completedAt: nullableDate(json, 'completedAt'),
        tenantId: requiredValue<String>(json, 'tenantId'),
        requestedBy: requiredValue<String>(json, 'requestedBy'),
        query: ProspectingQuery.fromJson(jsonObject(json['query'])),
        requestedLimit: nullableValue<int>(json, 'requestedLimit'),
        error: nullableValue<String>(json, 'error'),
        updatedAt: dateValue(json, 'updatedAt'),
        resultsAvailable: requiredValue<bool>(json, 'resultsAvailable'),
        results: nullableValue<List<dynamic>>(json, 'results')
            ?.map((item) => BusinessResult.fromJson(jsonObject(item)))
            .toList(growable: false),
        progress: nullableValue<Map<dynamic, dynamic>>(json, 'progress') == null
            ? null
            : PipelineProgress.fromJson(jsonObject(json['progress'])),
      );
}
