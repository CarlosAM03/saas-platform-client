import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/beta_components.dart' show dateLabel;
import '../../../shared/widgets/catalog_list.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../../prospects/state/prospects_providers.dart';
import '../state/batch_providers.dart';
import 'batch_detail_view.dart';
import 'batch_labels.dart';

class BatchHistoryPage extends ConsumerStatefulWidget {
  const BatchHistoryPage({super.key});

  @override
  ConsumerState<BatchHistoryPage> createState() => _BatchHistoryPageState();
}

class _BatchHistoryPageState extends ConsumerState<BatchHistoryPage> {
  int page = 1;

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    final allowed = permissions.asData?.value.canCreateProspects == true;
    return FeaturePage(
      title: 'Lotes de prospección',
      actions: [
        IconButton(
          tooltip: 'Actualizar lotes',
          onPressed: () => ref.invalidate(batchHistoryProvider(page)),
          icon: const Icon(Icons.refresh),
        ),
        if (allowed)
          FilledButton(
            onPressed: () => context.go('/generate'),
            child: const Text('Nueva solicitud'),
          ),
      ],
      child: PermissionGate(
        permissions: permissions,
        allowed: allowed,
        child: _BatchHistoryBody(
          page: page,
          onPage: (value) => setState(() => page = value),
        ),
      ),
    );
  }
}

class _BatchHistoryBody extends ConsumerWidget {
  const _BatchHistoryBody({required this.page, required this.onPage});

  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(batchHistoryProvider(page));
    return Column(
      children: [
        Expanded(
          child: AsyncPanel(
            value: value,
            retry: () => ref.invalidate(batchHistoryProvider(page)),
            data: (history) => history.items.isEmpty
                ? const Center(
                    child: Text('Aún no hay lotes de prospección.'),
                  )
                : ListView(
                    children: [
                      CatalogList(
                        windowTitle: 'Mis lotes',
                        titleLabel: 'Lote',
                        columns: const ['Admisión', 'Creado'],
                        records: [
                          for (final batch in history.items)
                            CatalogRecord(
                              title: 'Lote ${batch.id}',
                              description: batch.remoteObserved == false
                                  ? 'Service aún no confirma la existencia del lote.'
                                  : null,
                              cells: [
                                Text(batchAdmissionLabel(batch.admission)),
                                Text(
                                  '${dateLabel(batch.createdAt)} · '
                                  '${TimeOfDay.fromDateTime(batch.createdAt.toLocal()).format(context)}',
                                ),
                              ],
                              open: () => context.go('/jobs/${batch.id}'),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        if (value.asData case final data?)
          Row(
            children: [
              IconButton(
                tooltip: 'Lotes anteriores',
                onPressed: page > 1 ? () => onPage(page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  'Página $page · ${data.value.meta.total} lotes',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: 'Lotes siguientes',
                onPressed: page < data.value.meta.totalPages
                    ? () => onPage(page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class BatchDetailPage extends ConsumerWidget {
  const BatchDetailPage(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    final allowed = permissions.asData?.value.canCreateProspects == true;
    return FeaturePage(
      title: 'Detalle del lote',
      actions: [
        TextButton(
          onPressed: () => context.go('/jobs'),
          child: const Text('Ver lotes'),
        ),
        IconButton(
          tooltip: 'Actualizar lote',
          onPressed: () => ref.invalidate(batchDetailProvider(id)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: PermissionGate(
        permissions: permissions,
        allowed: allowed,
        child: _BatchDetailBody(id: id),
      ),
    );
  }
}

class _BatchDetailBody extends ConsumerWidget {
  const _BatchDetailBody({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(batchDetailProvider(id));
    return AsyncPanel(
      value: value,
      retry: () => ref.invalidate(batchDetailProvider(id)),
      data: (batch) => SingleChildScrollView(
        child: BatchDetailView(
          key: ValueKey(batch.id),
          batch: batch,
          onMutated: () {
            ref.invalidate(batchHistoryProvider);
            ref.invalidate(dashboardProvider);
            ref.invalidate(prospectsListProvider);
            ref.invalidate(campaignProspectsProvider);
          },
        ),
      ),
    );
  }
}
