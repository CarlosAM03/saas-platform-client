import '../../../shared/widgets/session_dialog.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/platform_api.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../../shared/widgets/beta_components.dart' show emailField;
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../state/prospects_providers.dart';

class ProspectsPage extends ConsumerWidget {
  const ProspectsPage({this.campaignId, super.key});
  final String? campaignId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
      title: campaignId == null ? 'Prospectos' : 'Prospectos de la campaña',
      actions: [
        if (campaignId != null)
          TextButton(
            onPressed: () => context.go('/prospects'),
            child: const Text('Ver todos'),
          ),
        if (p?.canCreateProspects == true)
          OutlinedButton.icon(
            onPressed: () => context.go('/prospects/import'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar CSV'),
          ),
        if (p?.canCreateProspects == true)
          FilledButton(
            onPressed: () => context.go('/prospects/new'),
            child: const Text('Crear prospecto'),
          ),
      ],
      child: PagedList<Prospect>(
        key: ValueKey(campaignId),
        load: (ref, key) => campaignId == null
            ? ref.watch(prospectsListProvider(key))
            : ref.watch(
                campaignProspectsProvider((id: campaignId!, query: key)),
              ),
        refresh: () {
          ref.invalidate(prospectsListProvider);
          ref.invalidate(campaignProspectsProvider);
        },
        item: (p) => ListTile(
          title: Text(p.name),
          subtitle: Text('${p.email ?? p.phone ?? ''} · ${p.status.name}'),
          trailing: Chip(label: Text(p.source.name)),
          onTap: () => context.go('/prospects/${p.id}'),
        ),
      ),
    );
  }
}

class ProspectDetailPage extends ConsumerWidget {
  const ProspectDetailPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
      title: 'Prospecto',
      actions: [
        if (p?.canEditProspects == true)
          TextButton(
            onPressed: () => context.go('/prospects/$id/edit'),
            child: const Text('Editar prospecto'),
          ),
      ],
      child: AsyncPanel(
        value: ref.watch(prospectsDetailProvider(id)),
        retry: () => ref.invalidate(prospectsDetailProvider(id)),
        data: (p) => ListView(
          children: [
            Text(p.name),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(p.source.name)),
                Chip(label: Text(p.status.name)),
              ],
            ),
            for (final entry in prospectTextValues(p).entries)
              ListTile(
                title: Text(prospectFieldLabels[entry.key]!),
                subtitle: Text(entry.value ?? 'Sin información'),
              ),
            TextButton(
              onPressed: () => context.go('/campaigns/${p.campaignId}'),
              child: const Text('Ver campaña de origen'),
            ),
            Text('Creado: ${p.createdAt.toLocal()}'),
            Text('Actualizado: ${p.updatedAt.toLocal()}'),
            if (p.metadata != null)
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(p.metadata),
              ),
          ],
        ),
      ),
    );
  }
}

String? optionalWebsite(String? value) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  return uri != null &&
          ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty
      ? null
      : 'Introduce una URL HTTP/HTTPS válida.';
}

const prospectFieldLabels = {
  'category': 'Categoría',
  'address': 'Dirección',
  'phone': 'Teléfono',
  'email': 'Correo electrónico',
  'website': 'Sitio web',
  'language': 'Idioma',
};
Map<String, String?> prospectTextValues(Prospect p) => {
  'category': p.category,
  'address': p.address,
  'phone': p.phone,
  'email': p.email,
  'website': p.website,
  'language': p.language,
};

/// Only changed fields are sent; clearing a previously populated field is explicit null.
UpdateProspectRequest prospectUpdate(Prospect p, Map<String, String> values) {
  final original = prospectTextValues(p);
  FieldUpdate<String> field(String key) {
    final value = values[key]!;
    return value == (original[key] ?? '')
        ? const FieldUpdate.omitted()
        : FieldUpdate.set(value.isEmpty ? null : value);
  }

  return UpdateProspectRequest(
    name: values['name'] == p.name ? null : values['name'],
    category: field('category'),
    address: field('address'),
    phone: field('phone'),
    email: field('email'),
    website: field('website'),
    language: field('language'),
    status: values['status'] == p.status.name
        ? null
        : ProspectStatus.values.byName(values['status']!),
  );
}

class ProspectFormPage extends ConsumerStatefulWidget {
  const ProspectFormPage({this.id, super.key});
  final String? id;
  @override
  ConsumerState<ProspectFormPage> createState() => _ProspectFormPageState();
}

class _ProspectFormPageState extends ConsumerState<ProspectFormPage> {
  Campaign? selected;
  Future<void> pickCampaign() async {
    final result = await showSessionDialog<Campaign>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Seleccionar campaña'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: PagedList<Campaign>(
            load: (ref, key) => ref.watch(campaignsListProvider(key)),
            refresh: () => ref.invalidate(campaignsListProvider),
            item: (campaign) => ListTile(
              title: Text(campaign.name),
              subtitle: Text(campaign.status.name),
              onTap: () => Navigator.pop(c, campaign),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (mounted && result != null) setState(() => selected = result);
  }

  Widget editor(Prospect? p) {
    final originals = p == null ? <String, String?>{} : prospectTextValues(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p == null)
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(selected?.name ?? 'Campaña obligatoria'),
              TextButton(
                onPressed: pickCampaign,
                child: const Text('Seleccionar campaña'),
              ),
            ],
          ),
        Expanded(
          child: EntityEditor(
            key: ValueKey(p?.id ?? 'new'),
            fields: [
              EditorField(
                'name',
                'Nombre',
                initial: p?.name ?? '',
                required: true,
              ),
              for (final entry in prospectFieldLabels.entries)
                EditorField(
                  entry.key,
                  entry.value,
                  initial: originals[entry.key] ?? '',
                  validator: entry.key == 'email'
                      ? (value) => value == null || value.isEmpty
                            ? null
                            : emailField(value)
                      : entry.key == 'website'
                      ? optionalWebsite
                      : null,
                ),
              EditorField(
                'status',
                'Estado',
                initial: p?.status.name ?? 'ACTIVO',
                options: ProspectStatus.values.map((s) => s.name).toList(),
              ),
            ],
            save: (v) async {
              final repo = ref.read(prospectsRepositoryProvider);
              late Prospect result;
              if (p == null) {
                if (selected == null) {
                  throw const ApiException(
                    kind: ApiErrorKind.badRequest,
                    message: 'Selecciona una campaña',
                  );
                }
                FieldUpdate<String> field(String key) => v[key]!.isEmpty
                    ? const FieldUpdate.omitted()
                    : FieldUpdate.set(v[key]);
                result = await repo.create(
                  CreateProspectRequest(
                    campaignId: selected!.id,
                    name: v['name']!.trim(),
                    category: field('category'),
                    address: field('address'),
                    phone: field('phone'),
                    email: field('email'),
                    website: field('website'),
                    language: field('language'),
                    status: ProspectStatus.values.byName(v['status']!),
                  ),
                );
              } else {
                final request = prospectUpdate(p, v);
                final changed =
                    v['name'] != p.name ||
                    v['status'] != p.status.name ||
                    originals.entries.any((e) => v[e.key] != (e.value ?? ''));
                if (!changed) {
                  if (context.mounted) context.go('/prospects/${p.id}');
                  return;
                }
                result = await repo.update(p.id, request);
              }
              if (!mounted) return;
              ref.invalidate(prospectsListProvider);
              ref.invalidate(prospectsDetailProvider(result.id));
              ref.invalidate(campaignProspectsProvider);
              context.go('/prospects/${result.id}');
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    final p = permissions.asData?.value;
    return FeaturePage(
      title: widget.id == null ? 'Crear prospecto' : 'Editar prospecto',
      child: PermissionGate(
        permissions: permissions,
        allowed: widget.id == null
            ? p?.canCreateProspects == true
            : p?.canEditProspects == true,
        child: widget.id == null
            ? editor(null)
            : AsyncPanel(
                value: ref.watch(prospectsDetailProvider(widget.id!)),
                retry: () =>
                    ref.invalidate(prospectsDetailProvider(widget.id!)),
                data: editor,
              ),
      ),
    );
  }
}
