import '../core/network/api_client.dart';
import 'auth_api.dart';
import 'health_api.dart';
import 'tenants_api.dart';
import 'users_api.dart';
import 'campaigns_api.dart';
import 'prospects_api.dart';
import 'prospecting_jobs_api.dart';
import 'tenant_registration_api.dart';
export 'tenant_registration_api.dart';
export 'tenant_registration_models.dart';
export 'auth_api.dart';
export 'health_api.dart';
export 'tenants_api.dart';
export 'users_api.dart';
export 'campaigns_api.dart';
export 'prospects_api.dart';
export 'prospecting_jobs_api.dart';
export 'models.dart';
export 'requests.dart';
export 'prospect_import_models.dart';
export '../core/network/api_upload_file.dart';
export 'pagination_query.dart';
export '../core/network/api_download.dart';

class PlatformApi {
  PlatformApi(ApiClient client)
    : health = HealthApi(client),
      auth = AuthApi(client),
      tenants = TenantsApi(client),
      users = UsersApi(client),
      campaigns = CampaignsApi(client),
      prospects = ProspectsApi(client),
      prospectingJobs = ProspectingJobsApi(client),
      tenantRegistration = TenantRegistrationApi(client);
  final HealthApi health;
  final AuthApi auth;
  final TenantsApi tenants;
  final UsersApi users;
  final CampaignsApi campaigns;
  final ProspectsApi prospects;
  final ProspectingJobsApi prospectingJobs;
  final TenantRegistrationApi tenantRegistration;
}
