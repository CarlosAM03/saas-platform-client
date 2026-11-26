import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_api/campaign_participation_models.dart';
import '../state/participation_providers.dart';
import 'commercial_stage_labels.dart';
import 'participation_panel.dart';

class CampaignDashboardPanel extends ConsumerWidget {
  const CampaignDashboardPanel(
    this.campaign, {
    this.onShowProspects,
    super.key,
  });

  final String campaign;
  final ValueChanged<CampaignProspectFilters>? onShowProspects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = campaignDashboardProvider(campaign);
    final theme = Theme.of(context);
    return ParticipationAsync(
      value: ref.watch(provider),
      retry: () => ref.invalidate(provider),
      data: (dashboard) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total de participaciones: ${dashboard.total}',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar resumen',
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (dashboard.total == 0)
            const Text('Esta campaña todavía no tiene participaciones.'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stages = _SummaryCard(
                title: 'Etapas comerciales',
                children: [
                  if (onShowProspects != null && dashboard.total > 0)
                    const Text('Selecciona una etapa para ver sus prospectos.'),
                  const SizedBox(height: 8),
                  for (final stage in CommercialStage.values)
                    _StageBar(
                      stage: stage,
                      count: dashboard.stages[stage.name] ?? 0,
                      total: dashboard.total,
                      onTap: onShowProspects == null
                          ? null
                          : () => onShowProspects!(
                              CampaignProspectFilters(stage: stage),
                            ),
                    ),
                ],
              );
              final attention = _AttentionCard(
                unassigned: dashboard.responsibility['SIN_ASIGNAR'] ?? 0,
                unevaluated: dashboard.evaluations['SIN_EVALUAR'] ?? 0,
                onShowProspects: onShowProspects,
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [stages, const SizedBox(height: 16), attention],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: stages),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: attention),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            title: 'Otros indicadores',
            children: [
              const SizedBox(height: 8),
              Text(
                'Evaluaciones: ${dashboard.evaluations['APTO'] ?? 0} aptos · '
                '${dashboard.evaluations['NO_APTO'] ?? 0} no aptos · '
                '${dashboard.evaluations['SIN_EVALUAR'] ?? 0} sin evaluar',
              ),
              const SizedBox(height: 6),
              Text(
                'Actividad total: ${dashboard.activityTotal} · '
                'Manual: ${dashboard.manual} · Automática: ${dashboard.events}',
              ),
              const Text('Las correcciones cuentan como actividad manual.'),
              const SizedBox(height: 6),
              Text(
                'Incorporación: ${dashboard.newCount} nuevas · '
                '${dashboard.reused} reutilizadas · '
                '${dashboard.unknownLegacy} de origen desconocido',
              ),
              if (dashboard.responsibility.isNotEmpty)
                ExpansionTile(
                  title: const Text('Distribución por responsable'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    for (final entry in dashboard.responsibility.entries)
                      ListTile(
                        title: Text(switch (entry.key) {
                          'SIN_ASIGNAR' => 'Sin responsable',
                          final key when key.startsWith('NO_ELEGIBLE:') =>
                            'No elegible: ${key.substring('NO_ELEGIBLE:'.length)}',
                          final key => key,
                        }),
                        trailing: Text('${entry.value}'),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar({
    required this.stage,
    required this.count,
    required this.total,
    required this.onTap,
  });

  final CommercialStage stage;
  final int count;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(8);
    final fraction = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Semantics(
      button: onTap != null,
      label: '${stage.label}, $count de $total prospectos',
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(stage.label)),
                    Text('$count', style: theme.textTheme.labelLarge),
                    if (onTap != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    borderRadius: borderRadius,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.unassigned,
    required this.unevaluated,
    required this.onShowProspects,
  });

  final int unassigned;
  final int unevaluated;
  final ValueChanged<CampaignProspectFilters>? onShowProspects;

  @override
  Widget build(BuildContext context) => _SummaryCard(
    title: 'Necesita atención',
    children: [
      const SizedBox(height: 12),
      if (unassigned == 0 && unevaluated == 0)
        const Text('No hay prospectos pendientes de asignar o evaluar.'),
      if (unassigned > 0)
        _AttentionItem(
          icon: Icons.person_add_alt_outlined,
          title: 'Asignar responsables',
          detail: unassigned == 1
              ? '1 prospecto sin responsable'
              : '$unassigned prospectos sin responsable',
          onTap: onShowProspects == null
              ? null
              : () => onShowProspects!(
                  CampaignProspectFilters(responsibleId: 'UNASSIGNED'),
                ),
        ),
      if (unassigned > 0 && unevaluated > 0) const SizedBox(height: 8),
      if (unevaluated > 0)
        _AttentionItem(
          icon: Icons.fact_check_outlined,
          title: 'Revisar prospectos sin evaluar',
          detail: unevaluated == 1
              ? '1 prospecto pendiente de evaluación'
              : '$unevaluated prospectos pendientes de evaluación',
          onTap: onShowProspects == null
              ? null
              : () => onShowProspects!(
                  CampaignProspectFilters(
                    evaluation: CommercialEvaluation.SIN_EVALUAR,
                  ),
                ),
        ),
    ],
  );
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon),
        iconColor: colors.onSecondaryContainer,
        textColor: colors.onSecondaryContainer,
        title: Text(title),
        subtitle: Text(detail),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
