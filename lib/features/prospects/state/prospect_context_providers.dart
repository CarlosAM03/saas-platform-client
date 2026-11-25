import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/prospect_context_api.dart';
import '../../../platform_api/platform_api.dart' show PaginatedResult;
import '../../auth/state/tenant_permissions.dart';
import '../data/prospect_context_repository.dart';

final prospectContextRepositoryProvider =
    Provider.autoDispose<ProspectContextRepository>((ref) {
      if (ref.watch(sessionScopeProvider)?.tenantId == null) {
        throw StateError('Selecciona una organización');
      }
      return ProspectContextRepository(
        ProspectContextApi(ref.watch(apiClientProvider)),
      );
    });
typedef ProspectContextPage = ({String prospect, int page});
final associatedCampaignsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<AssociatedCampaign>, ProspectContextPage>((
      ref,
      key,
    ) {
      ref.watch(sessionScopeProvider);
      return ref
          .watch(prospectContextRepositoryProvider)
          .campaigns(key.prospect, key.page);
    });
final prospectProvenanceProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ProspectProvenance>, ProspectContextPage>((
      ref,
      key,
    ) {
      ref.watch(sessionScopeProvider);
      return ref
          .watch(prospectContextRepositoryProvider)
          .provenance(key.prospect, key.page);
    });
