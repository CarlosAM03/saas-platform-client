import 'dart:async';
import 'package:saas_platform_client/features/tenant_registration/data/tenant_registration_repository.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../platform_api/fixtures.dart' show tenantJson, entityId;

// Synthetic values generated only in test memory, never real credentials.
String activationCode() => List.filled(43, 'a').join();
String challengeCode() => List.filled(43, 'b').join();
String passwordValue() => ['Synthetic', '123', '!'].join();
Map<String, dynamic> onboardingJson({
  String delivery = 'ACCEPTED',
  String activation = 'PENDING_FIRST_ACCESS',
}) => {
  'tenantId': entityId,
  'ownerUserId': entityId,
  'ownerEmail': 'owner@example.invalid',
  'activationStatus': activation,
  'deliveryStatus': delivery,
  'createdAt': '2026-10-28T12:00:00Z',
  'lastAttemptAt': '2026-10-28T12:00:00Z',
  'providerAcceptedAt': null,
  'activationLinkExpiresAt': '2026-10-29T12:00:00Z',
  'completedAt': null,
};
TenantOnboarding onboarding({
  String delivery = 'ACCEPTED',
  String activation = 'PENDING_FIRST_ACCESS',
}) => TenantOnboarding.fromJson(
  onboardingJson(delivery: delivery, activation: activation),
);
TenantRegistrationResult registrationResult({String delivery = 'ACCEPTED'}) =>
    TenantRegistrationResult(
      tenant: Tenant.fromJson(tenantJson),
      onboarding: onboarding(delivery: delivery),
    );

class FakeRegistration implements TenantRegistrationRepository {
  int registrations = 0, queries = 0, resends = 0, redeems = 0, completions = 0;
  RegisterTenantRequest? request;
  String? deliveredCode, deliveredChallenge;
  Object? error;
  String delivery = 'ACCEPTED';
  DateTime? expiresAt;
  Completer<TenantRegistrationResult>? pendingRegistration;
  Completer<FirstAccessRequired>? pendingRedeem;
  @override
  Future<TenantRegistrationResult> register(
    RegisterTenantRequest request,
  ) async {
    registrations++;
    this.request = request;
    if (error != null) throw error!;
    return pendingRegistration?.future ??
        registrationResult(delivery: delivery);
  }

  @override
  Future<TenantOnboarding> onboarding(String id) async {
    queries++;
    if (error != null) throw error!;
    return TenantOnboarding.fromJson(onboardingJson(delivery: delivery));
  }

  @override
  Future<TenantOnboarding> resend(String id) async {
    resends++;
    if (error != null) throw error!;
    return TenantOnboarding.fromJson(onboardingJson(delivery: delivery));
  }

  @override
  Future<FirstAccessRequired> redeem(String code) async {
    redeems++;
    deliveredCode = code;
    if (error != null) throw error!;
    return pendingRedeem?.future ??
        FirstAccessRequired(
          firstAccessToken: challengeCode(),
          expiresAt:
              expiresAt ?? DateTime.now().add(const Duration(minutes: 15)),
        );
  }

  @override
  Future<void> complete(String challenge, String password) async {
    completions++;
    deliveredChallenge = challenge;
    if (error != null) throw error!;
  }
}
