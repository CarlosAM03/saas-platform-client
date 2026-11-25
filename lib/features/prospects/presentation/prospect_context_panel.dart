import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/presentation/participation_panel.dart';
import '../state/prospect_context_providers.dart';

class ProspectContextPanel extends ConsumerWidget {
  const ProspectContextPanel(this.prospect, {super.key});
  final String prospect;
  @override
  Widget build(BuildContext context, WidgetRef ref) => _ProspectContext(
    prospect,
    key: ValueKey((prospect, ref.watch(sessionScopeProvider))),
  );
}

class _ProspectContext extends ConsumerStatefulWidget {
  const _ProspectContext(this.prospect, {super.key});
  final String prospect;
  @override
  ConsumerState<_ProspectContext> createState() => _ProspectContextState();
}

class _ProspectContextState extends ConsumerState<_ProspectContext> {
  int campaignsPage = 1, provenancePage = 1;
  @override
  Widget build(BuildContext context) {
    final campaigns = (prospect: widget.prospect, page: campaignsPage);
    final provenance = (prospect: widget.prospect, page: provenancePage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Campañas asociadas'),
        ParticipationAsync(
          value: ref.watch(associatedCampaignsProvider(campaigns)),
          retry: () => ref.invalidate(associatedCampaignsProvider(campaigns)),
          data: (result) => Column(
            children: [
              if (result.items.isEmpty)
                const Text('No hay campañas asociadas.'),
              for (final c in result.items)
                ListTile(
                  title: Text('${c.name}${c.isOrigin ? ' · Origen' : ''}'),
                  subtitle: Text(
                    '${c.status.name} · ${c.stage.name} · ${c.evaluation.name}\nResponsable: ${c.responsible?.name ?? 'Sin asignar'}${c.responsible?.eligible == false ? ' (pendiente de reasignación)' : ''}\nIncorporación: ${c.addedAt.toLocal()}\nÚltima actividad: ${c.latestActivity?.content ?? c.latestActivity?.type.name ?? 'Sin actividad'}',
                  ),
                  onTap: () => context.go('/campaigns/${c.id}'),
                ),
              ParticipationPagination(
                meta: result.meta,
                change: (p) => setState(() => campaignsPage = p),
              ),
            ],
          ),
        ),
        const Text('Procedencia global'),
        ParticipationAsync(
          value: ref.watch(prospectProvenanceProvider(provenance)),
          retry: () => ref.invalidate(prospectProvenanceProvider(provenance)),
          data: (result) => Column(
            children: [
              if (result.items.isEmpty)
                const Text('No hay eventos de procedencia confirmados.'),
              for (final e in result.items)
                ListTile(
                  title: Text(switch (e.type.name) {
                    'masterUpdated' => 'MASTER_UPDATED',
                    'created' => 'CREATED',
                    'linked' => 'LINKED',
                    _ => 'REAPPEARED',
                  }),
                  subtitle: Text(
                    '${e.recordedAt.toLocal()} · ${e.source}\nAutor: ${e.actorName ?? 'Sistema'}${e.campaignId == null ? '' : '\nCampaña: ${e.campaignId}'}',
                  ),
                ),
              ParticipationPagination(
                meta: result.meta,
                change: (p) => setState(() => provenancePage = p),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
