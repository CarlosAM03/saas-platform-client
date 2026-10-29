// Wire names follow the approved ADR-006 contract.
// ignore_for_file: constant_identifier_names
import 'models.dart';
import 'src/json_fields.dart';

enum ActivationStatus { PENDING_FIRST_ACCESS, COMPLETED }

enum DeliveryStatus { PENDING, SENDING, ACCEPTED, FAILED, UNKNOWN }

class RegisterTenantRequest {
  const RegisterTenantRequest({
    required this.tenantName,
    required this.tenantSlug,
    required this.ownerName,
    required this.ownerEmail,
  });
  final String tenantName, tenantSlug, ownerName, ownerEmail;
  Map<String, dynamic> toJson() => {
    'tenantName': tenantName.trim(),
    'tenantSlug': tenantSlug,
    'ownerName': ownerName.trim(),
    'ownerEmail': ownerEmail.trim().toLowerCase(),
  };
}

class TenantOnboarding {
  const TenantOnboarding({
    required this.tenantId,
    required this.ownerUserId,
    required this.ownerEmail,
    required this.activationStatus,
    required this.deliveryStatus,
    required this.createdAt,
    required this.lastAttemptAt,
    required this.providerAcceptedAt,
    required this.activationLinkExpiresAt,
    required this.completedAt,
  });
  final String tenantId, ownerUserId, ownerEmail;
  final ActivationStatus activationStatus;
  final DeliveryStatus deliveryStatus;
  final DateTime createdAt;
  final DateTime? lastAttemptAt,
      providerAcceptedAt,
      activationLinkExpiresAt,
      completedAt;
  factory TenantOnboarding.fromJson(Map<String, dynamic> json) =>
      TenantOnboarding(
        tenantId: requiredValue<String>(json, 'tenantId'),
        ownerUserId: requiredValue<String>(json, 'ownerUserId'),
        ownerEmail: requiredValue<String>(json, 'ownerEmail'),
        activationStatus: _safeEnum(
          json['activationStatus'],
          ActivationStatus.values,
        ),
        deliveryStatus: _safeEnum(
          json['deliveryStatus'],
          DeliveryStatus.values,
        ),
        createdAt: dateValue(json, 'createdAt'),
        lastAttemptAt: nullableDate(json, 'lastAttemptAt'),
        providerAcceptedAt: nullableDate(json, 'providerAcceptedAt'),
        activationLinkExpiresAt: nullableDate(json, 'activationLinkExpiresAt'),
        completedAt: nullableDate(json, 'completedAt'),
      );
}

T _safeEnum<T extends Enum>(Object? value, List<T> values) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  throw const FormatException('Invalid onboarding status');
}

class TenantRegistrationResult {
  const TenantRegistrationResult({
    required this.tenant,
    required this.onboarding,
  });
  final Tenant tenant;
  final TenantOnboarding onboarding;
  factory TenantRegistrationResult.fromJson(Map<String, dynamic> json) =>
      TenantRegistrationResult(
        tenant: Tenant.fromJson(jsonObject(json['tenant'])),
        onboarding: TenantOnboarding.fromJson(jsonObject(json['onboarding'])),
      );
}

// No generated diagnostics/toString or persistence for secret-bearing DTOs.
class RedeemFirstAccessRequest {
  const RedeemFirstAccessRequest(this.activationToken);
  final String activationToken;
  Map<String, dynamic> toJson() => {'activationToken': activationToken};
  @override
  String toString() => 'RedeemFirstAccessRequest([redacted])';
}

class CompleteFirstAccessRequest {
  const CompleteFirstAccessRequest({
    required this.firstAccessToken,
    required this.newPassword,
  });
  final String firstAccessToken, newPassword;
  Map<String, dynamic> toJson() => {
    'firstAccessToken': firstAccessToken,
    'newPassword': newPassword,
  };
  @override
  String toString() => 'CompleteFirstAccessRequest([redacted])';
}

class FirstAccessRequired {
  const FirstAccessRequired({
    required this.firstAccessToken,
    required this.expiresAt,
  });
  final String firstAccessToken;
  final DateTime expiresAt;
  factory FirstAccessRequired.fromJson(Map<String, dynamic> json) {
    if (json['action'] != 'CHANGE_PASSWORD_REQUIRED') {
      throw const FormatException('Invalid activation response');
    }
    final token = requiredValue<String>(json, 'firstAccessToken');
    final expiry = DateTime.tryParse(
      json['expiresAt'] is String ? json['expiresAt'] as String : '',
    );
    if (token.isEmpty || expiry == null) {
      throw const FormatException('Invalid activation response');
    }
    return FirstAccessRequired(firstAccessToken: token, expiresAt: expiry);
  }
  @override
  String toString() => 'FirstAccessRequired([redacted])';
}

class FirstAccessCompleted {
  const FirstAccessCompleted();
  factory FirstAccessCompleted.fromJson(Map<String, dynamic> json) {
    if (json['action'] != 'LOGIN_REQUIRED') {
      throw const FormatException('Invalid activation response');
    }
    return const FirstAccessCompleted();
  }
}
