import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/catalog_palette.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/widgets/campaign_status_badge.dart';
import '../../prospecting_jobs/presentation/batch_labels.dart';
import '../../prospecting_jobs/state/batch_providers.dart';
import '../state/dashboard_providers.dart';
import 'catalog_dashboard_hero.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void refresh() => ref.invalidate(dashboardProvider);
    final canProspect = ref
        .watch(currentTenantPermissionsProvider)
        .asData
        ?.value
        .canCreateProspects;

    return FeaturePage(
      title: 'Dashboard',
      actions: [
        IconButton(
          tooltip: 'Actualizar dashboard',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
        if (canProspect == true)
          OutlinedButton.icon(
            onPressed: () => context.go('/generate'),
            icon: const Icon(Icons.travel_explore),
            label: const Text('Buscar prospectos'),
          ),
      ],
      child: AsyncPanel(
        value: ref.watch(dashboardProvider),
        retry: refresh,
        data: (data) => _DashboardContent(data: data, refresh: refresh),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.data, required this.refresh});

  final DashboardData data;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManageCampaigns = ref
        .watch(currentTenantPermissionsProvider)
        .asData
        ?.value
        .canManageCampaigns;
    final canProspect = ref
        .watch(currentTenantPermissionsProvider)
        .asData
        ?.value
        .canCreateProspects;
    final jobs = data.jobs;
    final batches = data.batches;
    final prospectingTotal = prospectingBatchEnabled
        ? batches?.meta.total
        : jobs?.meta.total;
    final prospectingError = prospectingBatchEnabled
        ? data.batchesError
        : data.jobsError;

    final campaignsPanel = _RecentWindow(
      title: 'Campañas recientes',
      action: 'Ver campañas',
      onAction: () => context.go('/campaigns'),
      empty: 'Aún no hay campañas.',
      rows: [
        for (final campaign in data.campaigns.items)
          _RecentRow(
            title: campaign.name,
            subtitle: campaign.description,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampaignStatusBadge(campaign.status),
                Text(
                  'Ver detalles',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: CatalogPalette.link),
                ),
              ],
            ),
            onTap: () => context.go('/campaigns/${campaign.id}'),
          ),
      ],
    );
    final prospectsPanel = _RecentWindow(
      title: 'Prospectos recientes',
      action: 'Ver prospectos',
      onAction: () => context.go('/prospects'),
      empty: 'Aún no hay prospectos.',
      rows: [
        for (final prospect in data.prospects.items)
          _RecentRow(
            title: prospect.name,
            subtitle: prospect.email ?? prospect.phone ?? 'Sin contacto',
            onTap: () => context.go('/prospects/${prospect.id}'),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CatalogDashboardHero(
              onCreateCampaign: canManageCampaigns == true
                  ? () => context.go('/campaigns/new')
                  : null,
            ),
            const SizedBox(height: 13),
            _Metrics(
              items: [
                ('Campañas', data.campaigns.meta.total, '/campaigns'),
                ('Prospectos', data.prospects.meta.total, '/prospects'),
                if (prospectingTotal != null &&
                    (!prospectingBatchEnabled || canProspect == true))
                  (
                    prospectingBatchEnabled ? 'Lotes' : 'Trabajos',
                    prospectingTotal,
                    '/jobs',
                  ),
              ],
            ),
            const SizedBox(height: 13),
            if (constraints.maxWidth >= 580)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: campaignsPanel),
                  const SizedBox(width: 13),
                  Expanded(child: prospectsPanel),
                ],
              )
            else ...[
              campaignsPanel,
              const SizedBox(height: 13),
              prospectsPanel,
            ],
            const SizedBox(height: 13),
            if (!prospectingBatchEnabled || canProspect == true)
              _RecentWindow(
                title: prospectingBatchEnabled
                    ? 'Lotes recientes'
                    : 'Trabajos recientes',
                action: prospectingBatchEnabled ? 'Ver lotes' : 'Ver trabajos',
                onAction: () => context.go('/jobs'),
                empty: prospectingTotal == null
                    ? null
                    : prospectingBatchEnabled
                    ? 'Aún no hay lotes de prospección.'
                    : 'Aún no hay trabajos de prospección.',
                rows: [
                  if (prospectingError case final error?)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ErrorView(error),
                          TextButton(
                            onPressed: refresh,
                            child: Text(
                              prospectingBatchEnabled
                                  ? 'Reintentar lotes'
                                  : 'Reintentar trabajos',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (prospectingBatchEnabled && batches != null)
                    for (final batch in batches.items.take(5))
                      _RecentRow(
                        title: 'Lote ${batch.id}',
                        subtitle: batch.createdAt.toLocal().toString(),
                        trailing: Text(batchAdmissionLabel(batch.admission)),
                        onTap: () => context.go('/jobs/${batch.id}'),
                      ),
                  if (!prospectingBatchEnabled && jobs != null)
                    for (final job in jobs.items)
                      _RecentRow(
                        title: 'Trabajo ${job.id}',
                        subtitle: job.createdAt.toLocal().toString(),
                        trailing: Text(job.status.name),
                        onTap: () => context.go('/jobs/${job.id}'),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.items});

  final List<(String, int, String)> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 10.0;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
      final oneColumn =
          constraints.maxWidth < 240 ||
          (largeText && constraints.maxWidth < 460);
      final itemWidth = oneColumn
          ? constraints.maxWidth
          : (constraints.maxWidth - gap * (items.length - 1)) / items.length;
      final text = Theme.of(context).textTheme;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final (label, count, route) in items)
            SizedBox(
              width: itemWidth,
              child: Card(
                color: CatalogPalette.surface,
                margin: EdgeInsets.zero,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: CatalogPalette.outline),
                ),
                child: InkWell(
                  onTap: () => context.go(route),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: oneColumn || constraints.maxWidth > 420
                          ? 12
                          : 7,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: CatalogPalette.ink,
                          ),
                        ),
                        Text(
                          label,
                          style: text.bodySmall?.copyWith(
                            color: CatalogPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _RecentWindow extends StatelessWidget {
  const _RecentWindow({
    required this.title,
    required this.action,
    required this.onAction,
    required this.rows,
    this.empty,
  });

  final String title;
  final String action;
  final VoidCallback onAction;
  final List<Widget> rows;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: CatalogPalette.surface,
        border: Border.fromBorderSide(
          BorderSide(color: CatalogPalette.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: CatalogPalette.header,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: text.labelMedium?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    child: Text(action),
                  ),
                ],
              ),
            ),
          ),
          if (rows.isEmpty && empty != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(empty!, style: text.bodySmall),
            ),
          Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: CatalogPalette.outline),
                  rows[index],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final details = subtitle?.trim();

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final description = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.bodyMedium?.copyWith(
                      color: CatalogPalette.link,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (details != null && details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                ],
              );
              final status = trailing;
              if (status == null) return description;
              if (constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(14) > 19) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [description, const SizedBox(height: 3), status],
                );
              }
              return Row(
                children: [
                  Expanded(child: description),
                  const SizedBox(width: 8),
                  status,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
