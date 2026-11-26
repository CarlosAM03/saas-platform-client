import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../auth/state/tenant_permissions.dart';

/// The production image enables Batch v1 by default; CI builds may omit it.
const prospectingBatchEnabled = bool.fromEnvironment('PROSPECTOR_BATCH_ENABLED');

final batchApiProvider = Provider.autoDispose<ProspectingBatchesApi>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(platformApiProvider).batches;
});

final batchHistoryProvider = FutureProvider.autoDispose
    .family<PaginatedResult<BatchSummary>, int>((ref, page) {
      final scope = ref.watch(sessionScopeProvider);
      if (scope?.tenantId == null) {
        throw StateError('Se requiere una organización activa');
      }
      return ref.watch(batchApiProvider).list(page);
    });

/// A direct URL or refresh reconciles the existing batch; it never admits a new one.
final batchDetailProvider = FutureProvider.autoDispose
    .family<BatchSummary, String>((ref, id) {
      final scope = ref.watch(sessionScopeProvider);
      if (scope?.tenantId == null) {
        throw StateError('Se requiere una organización activa');
      }
      return ref.watch(batchApiProvider).reconcile(id);
    });
