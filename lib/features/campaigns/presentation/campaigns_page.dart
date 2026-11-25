import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/campaign_participation_models.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/campaigns_providers.dart';
import '../widgets/campaign_catalog.dart';
import 'campaign_dashboard_panel.dart';
import 'campaign_prospects_panel.dart';

class CampaignsPage extends ConsumerStatefulWidget {
  const CampaignsPage({super.key});
  @override
  ConsumerState<CampaignsPage> createState() => _CampaignsState();
}

class _CampaignsState extends ConsumerState<CampaignsPage> {
  CampaignStatus? status;
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
      title: 'Campañas',
      actions: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: status == null,
          onSelected: (_) => setState(() => status = null),
        ),
        for (final value in CampaignStatus.values)
          ChoiceChip(
            label: Text(value.name),
            selected: status == value,
            onSelected: (_) => setState(() => status = value),
          ),
        if (status != null)
          const Text('El filtro de estado se aplica a la página actual.'),
        if (p?.canManageCampaigns == true)
          FilledButton.icon(
            onPressed: () => context.go('/campaigns/new'),
            icon: const Icon(Icons.add),
            label: const Text('Crear campaña'),
          ),
      ],
      child: PagedList<Campaign>(
        filter: (campaign) => status == null || campaign.status == status,
        pageContent: (items) => CampaignCatalog(
          campaigns: items,
          onSelected: (campaign) => context.go('/campaigns/${campaign.id}'),
        ),
        load: (ref, key) => ref.watch(campaignsListProvider(key)),
        refresh: () => ref.invalidate(campaignsListProvider),
      ),
    );
  }
}

class CampaignDetailPage extends ConsumerWidget {
  const CampaignDetailPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
      title: 'Campaña',
      actions: [
        if (p?.canManageCampaigns == true) ...[
          TextButton(
            onPressed: () => context.go('/campaigns/$id/edit'),
            child: const Text('Editar campaña'),
          ),
          EntityAction(
            label: 'Archivar campaña',
            confirm: '¿Archivar esta campaña?',
            run: () async {
              await ref.read(campaignsRepositoryProvider).archive(id);
              if (!context.mounted) return;
              ref.invalidate(campaignsListProvider);
              ref.invalidate(campaignsDetailProvider(id));
            },
          ),
        ],
        if (p?.canDeleteCampaigns == true)
          EntityAction(
            label: 'Eliminar permanentemente',
            confirm:
                'Esta acción elimina la campaña permanentemente. ¿Continuar?',
            run: () async {
              await ref.read(campaignsRepositoryProvider).deletePermanently(id);
              if (!context.mounted) return;
              ref.invalidate(campaignsListProvider);
              ref.invalidate(campaignsDetailProvider(id));
              context.go('/campaigns');
            },
          ),
      ],
      child: AsyncPanel(
        value: ref.watch(campaignsDetailProvider(id)),
        retry: () => ref.invalidate(campaignsDetailProvider(id)),
        data: (c) => DefaultTabController(
          length: 3,
          child: _CampaignDetailTabs(
            c,
            key: ValueKey((id, ref.watch(sessionScopeProvider))),
          ),
        ),
      ),
    );
  }
}

class _CampaignDetailTabs extends StatefulWidget {
  const _CampaignDetailTabs(this.campaign, {super.key});

  final Campaign campaign;

  @override
  State<_CampaignDetailTabs> createState() => _CampaignDetailTabsState();
}

class _CampaignDetailTabsState extends State<_CampaignDetailTabs> {
  CampaignProspectFilters? _summaryFilters;
  Key? _summarySelection;

  void _showProspects(CampaignProspectFilters filters) {
    setState(() {
      _summaryFilters = filters;
      _summarySelection = UniqueKey();
    });
    DefaultTabController.of(context).animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    return Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Detalle'),
            Tab(text: 'Prospectos'),
            Tab(text: 'Resumen comercial'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              ListView(
                children: [
                  Text(campaign.name),
                  if (campaign.description != null) Text(campaign.description!),
                  Text(campaign.status.name),
                  Text('Creada: ${campaign.createdAt.toLocal()}'),
                  Text('Actualizada: ${campaign.updatedAt.toLocal()}'),
                ],
              ),
              CampaignProspectsPanel(
                campaign.id,
                key: _summarySelection,
                initialFilters: _summaryFilters,
              ),
              CampaignDashboardPanel(
                campaign.id,
                onShowProspects: _showProspects,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CampaignFormPage extends ConsumerWidget {
  const CampaignFormPage({this.id, super.key});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider);
    Widget editor(Campaign? c) => EntityEditor(
      key: ValueKey(c?.id ?? 'new'),
      fields: [
        EditorField('name', 'Nombre', initial: c?.name ?? '', required: true),
        EditorField(
          'description',
          'Descripción',
          initial: c?.description ?? '',
        ),
        if (c != null)
          EditorField(
            'status',
            'Estado',
            initial: c.status.name,
            options: CampaignStatus.values.map((s) => s.name).toList(),
          ),
      ],
      save: (v) async {
        if (c == null &&
            !await confirmAction(
              context,
              '¿Crear la campaña con estos datos?',
            )) {
          return;
        }
        if (!context.mounted) return;
        final repo = ref.read(campaignsRepositoryProvider);
        final description = v['description']!;
        final result = c == null
            ? await repo.create(
                CreateCampaignRequest(
                  name: v['name']!.trim(),
                  description: description.isEmpty ? null : description,
                ),
              )
            : await repo.update(
                c.id,
                UpdateCampaignRequest(
                  name: v['name']!.trim(),
                  description: description == (c.description ?? '')
                      ? const FieldUpdate.omitted()
                      : FieldUpdate.set(
                          description.isEmpty ? null : description,
                        ),
                  status: CampaignStatus.values.byName(v['status']!),
                ),
              );
        if (!context.mounted) return;
        ref.invalidate(campaignsListProvider);
        ref.invalidate(campaignsDetailProvider(result.id));
        context.go('/campaigns/${result.id}');
      },
    );
    return FeaturePage(
      title: id == null ? 'Crear campaña' : 'Editar campaña',
      child: PermissionGate(
        permissions: p,
        allowed: p.asData?.value.canManageCampaigns == true,
        child: id == null
            ? editor(null)
            : AsyncPanel(
                value: ref.watch(campaignsDetailProvider(id!)),
                retry: () => ref.invalidate(campaignsDetailProvider(id!)),
                data: editor,
              ),
      ),
    );
  }
}
