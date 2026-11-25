import '../../../platform_api/prospect_context_api.dart';
import '../../../platform_api/platform_api.dart';

class ProspectContextRepository {
  const ProspectContextRepository(this.api);
  final ProspectContextApi api;
  Future<ProspectMatch> match(ProspectIntakeRequest request) =>
      api.match(request);
  Future<Prospect> create(ProspectIntakeRequest request) => api.create(request);
  Future<ProspectResolutionResult> resolve(
    ProspectIntakeRequest request,
    ProspectResolution resolution, {
    String? candidateId,
  }) => api.resolve(request, resolution, candidateId: candidateId);
  Future<PaginatedResult<AssociatedCampaign>> campaigns(String id, int page) =>
      api.campaigns(id, page);
  Future<PaginatedResult<ProspectProvenance>> provenance(String id, int page) =>
      api.provenance(id, page);
  Future<Prospect> update(
    String id,
    UpdateProspectRequest request, {
    String? contextCampaignId,
  }) => api.update(id, request, contextCampaignId: contextCampaignId);
}
