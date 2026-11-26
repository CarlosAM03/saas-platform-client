import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/campaign_participation_api.dart';
import '../../../platform_api/platform_api.dart'
    show PaginationQuery, PaginatedResult;
import '../../auth/state/tenant_permissions.dart';
import '../data/participation_repository.dart';

final participationRepositoryProvider =
    Provider.autoDispose<ParticipationRepository>((ref) {
      if (ref.watch(sessionScopeProvider)?.tenantId == null) {
        throw StateError('Selecciona una organización');
      }
      return ParticipationRepository(
        CampaignParticipationApi(ref.watch(apiClientProvider)),
      );
    });
typedef ParticipationKey = ({String campaign, String prospect});
typedef CampaignListKey = ({
  String campaign,
  PaginationQuery query,
  CampaignProspectFilters filters,
});
final participationProvider = FutureProvider.autoDispose
    .family<CampaignParticipation, ParticipationKey>((ref, key) {
      ref.watch(sessionScopeProvider);
      return ref
          .watch(participationRepositoryProvider)
          .get(key.campaign, key.prospect);
    });
final responsibleOptionsProvider = FutureProvider.autoDispose
    .family<List<ParticipationResponsible>, ParticipationKey>((ref, key) {
      ref.watch(sessionScopeProvider);
      return ref
          .watch(participationRepositoryProvider)
          .responsibles(key.campaign, key.prospect);
    });
final participationActivitiesProvider = FutureProvider.autoDispose
    .family<
      PaginatedResult<CampaignActivity>,
      ({ParticipationKey participation, int page})
    >((ref, key) {
      ref.watch(sessionScopeProvider);
      return ref
          .watch(participationRepositoryProvider)
          .activities(
            key.participation.campaign,
            key.participation.prospect,
            key.page,
          );
    });
final campaignDashboardProvider = FutureProvider.autoDispose
    .family<CampaignDashboard, String>((ref, campaign) {
      ref.watch(sessionScopeProvider);
      return ref.watch(participationRepositoryProvider).dashboard(campaign);
    });
final filteredCampaignProspectsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<CampaignProspect>, CampaignListKey>((ref, key) {
      ref.watch(sessionScopeProvider);
      return ref
          .watch(participationRepositoryProvider)
          .prospects(key.campaign, key.query, key.filters);
    });
