import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/campaigns_providers.dart';

class CampaignsPage extends ConsumerWidget {
  const CampaignsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
        title: 'Campañas',
        actions: [
          if (p?.canManageCampaigns == true)
            FilledButton(
                onPressed: () => context.go('/campaigns/new'),
                child: const Text('Crear campaña'))
        ],
        child: PagedList<Campaign>(
            load: (ref, key) => ref.watch(campaignsListProvider(key)),
            refresh: () => ref.invalidate(campaignsListProvider),
            item: (c) => ListTile(
                title: Text(c.name),
                subtitle: Text(c.description ?? ''),
                trailing: Chip(label: Text(c.status.name)),
                onTap: () => context.go('/campaigns/${c.id}'))));
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
                child: const Text('Editar campaña')),
            EntityAction(
                label: 'Archivar campaña',
                confirm: '¿Archivar esta campaña?',
                run: () async {
                  await ref.read(campaignsRepositoryProvider).archive(id);
                  if (!context.mounted) return;
                  ref.invalidate(campaignsListProvider);
                  ref.invalidate(campaignsDetailProvider(id));
                })
          ],
          if (p?.canDeleteCampaigns == true)
            EntityAction(
                label: 'Eliminar permanentemente',
                confirm:
                    'Esta acción elimina la campaña permanentemente. ¿Continuar?',
                run: () async {
                  await ref
                      .read(campaignsRepositoryProvider)
                      .deletePermanently(id);
                  if (!context.mounted) return;
                  ref.invalidate(campaignsListProvider);
                  ref.invalidate(campaignsDetailProvider(id));
                  context.go('/campaigns');
                })
        ],
        child: AsyncPanel(
            value: ref.watch(campaignsDetailProvider(id)),
            retry: () => ref.invalidate(campaignsDetailProvider(id)),
            data: (c) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name),
                  if (c.description != null) Text(c.description!),
                  Text(c.status.name),
                  Text('Creada: ${c.createdAt.toLocal()}'),
                  Text('Actualizada: ${c.updatedAt.toLocal()}'),
                  const SizedBox(height: 12),
                  Text('Prospectos de la campaña',
                      style: Theme.of(context).textTheme.titleMedium),
                  Expanded(
                      child: PagedList<Prospect>(
                          load: (ref, key) => ref.watch(
                              campaignProspectsProvider((id: id, query: key))),
                          refresh: () =>
                              ref.invalidate(campaignProspectsProvider),
                          item: (p) => ListTile(
                              title: Text(p.name),
                              subtitle:
                                  Text('${p.source.name} · ${p.status.name}'),
                              onTap: () => context.go('/prospects/${p.id}'))))
                ])));
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
          EditorField('description', 'Descripción',
              initial: c?.description ?? ''),
          if (c != null)
            EditorField('status', 'Estado',
                initial: c.status.name,
                options: CampaignStatus.values.map((s) => s.name).toList())
        ],
        save: (v) async {
          final repo = ref.read(campaignsRepositoryProvider);
          final description = v['description']!;
          final result = c == null
              ? await repo.create(CreateCampaignRequest(
                  name: v['name']!.trim(),
                  description: description.isEmpty ? null : description))
              : await repo.update(
                  c.id,
                  UpdateCampaignRequest(
                      name: v['name']!.trim(),
                      description: description == (c.description ?? '')
                          ? const FieldUpdate.omitted()
                          : FieldUpdate.set(
                              description.isEmpty ? null : description),
                      status: CampaignStatus.values.byName(v['status']!)));
          if (!context.mounted) return;
          ref.invalidate(campaignsListProvider);
          ref.invalidate(campaignsDetailProvider(result.id));
          context.go('/campaigns/${result.id}');
        });
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
                    data: editor)));
  }
}
