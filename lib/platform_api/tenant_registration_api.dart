import '../core/network/api_client.dart';
import '../shared/models/api_models.dart' show unwrapObject;
import 'src/api_support.dart';
import 'tenant_registration_models.dart';

class TenantRegistrationApi {
  const TenantRegistrationApi(this._client);
  final ApiClient _client;
  Future<TenantRegistrationResult> register(
    RegisterTenantRequest request,
  ) async => TenantRegistrationResult.fromJson(
    unwrapObject(
      await _client.post('/api/v1/tenants/register', data: request.toJson()),
    ),
  );
  Future<TenantOnboarding> onboarding(String id) async =>
      TenantOnboarding.fromJson(
        unwrapObject(
          await _client.get('${entityPath('tenants', id)}/onboarding'),
        ),
      );
  Future<TenantOnboarding> resend(String id) async => TenantOnboarding.fromJson(
    unwrapObject(
      await _client.post('${entityPath('tenants', id)}/resend-welcome'),
    ),
  );
  Future<FirstAccessRequired> redeem(RedeemFirstAccessRequest request) async =>
      FirstAccessRequired.fromJson(
        unwrapObject(
          await _client.postPublicActivation(
            '/api/v1/auth/redeem-first-access',
            data: request.toJson(),
          ),
        ),
      );
  Future<FirstAccessCompleted> complete(
    CompleteFirstAccessRequest request,
  ) async => FirstAccessCompleted.fromJson(
    unwrapObject(
      await _client.postPublicActivation(
        '/api/v1/auth/complete-first-access',
        data: request.toJson(),
      ),
    ),
  );
}
