import '../../../platform_api/platform_api.dart';

abstract class TenantRegistrationRepository {
  Future<TenantRegistrationResult> register(RegisterTenantRequest request);
  Future<TenantOnboarding> onboarding(String id);
  Future<TenantOnboarding> resend(String id);
  Future<FirstAccessRequired> redeem(String code);
  Future<void> complete(String challenge, String password);
}

class ApiTenantRegistrationRepository implements TenantRegistrationRepository {
  ApiTenantRegistrationRepository(PlatformApi api)
    : _api = api.tenantRegistration;
  final TenantRegistrationApi _api;
  @override
  Future<TenantRegistrationResult> register(RegisterTenantRequest request) =>
      _api.register(request);
  @override
  Future<TenantOnboarding> onboarding(String id) => _api.onboarding(id);
  @override
  Future<TenantOnboarding> resend(String id) => _api.resend(id);
  @override
  Future<FirstAccessRequired> redeem(String code) =>
      _api.redeem(RedeemFirstAccessRequest(code));
  @override
  Future<void> complete(String challenge, String password) async {
    await _api.complete(
      CompleteFirstAccessRequest(
        firstAccessToken: challenge,
        newPassword: password,
      ),
    );
  }
}
