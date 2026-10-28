import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../auth/state/tenant_permissions.dart';

abstract interface class ProspectImportRepository {
  Future<ProspectImportPreview> preview(
      String campaignId, ApiUploadFile upload);
  Future<ProspectImportResult> confirm(String campaignId, ApiUploadFile upload,
      String reference, List<ProspectImportDecision> decisions);
}

class ApiProspectImportRepository implements ProspectImportRepository {
  ApiProspectImportRepository(PlatformApi api) : _api = api.prospects;
  final ProspectsApi _api;
  @override
  Future<ProspectImportPreview> preview(
          String campaignId, ApiUploadFile upload) =>
      _api.previewImport(campaignId: campaignId, upload: upload);
  @override
  Future<ProspectImportResult> confirm(String campaignId, ApiUploadFile upload,
          String reference, List<ProspectImportDecision> decisions) =>
      _api.confirmImport(
          campaignId: campaignId,
          upload: upload,
          previewReference: reference,
          decisions: decisions);
}

final prospectImportRepositoryProvider =
    Provider.autoDispose<ProspectImportRepository>((ref) {
  if (ref.watch(sessionScopeProvider)?.tenantId == null) {
    throw StateError('Selecciona una organización');
  }
  return ApiProspectImportRepository(ref.watch(platformApiProvider));
});
