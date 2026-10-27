import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
<<<<<<< Updated upstream
import '../../../platform_api/platform_api.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../state/prospects_providers.dart';

class ProspectsPage extends ConsumerWidget {
  const ProspectsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
        title: 'Prospectos',
        actions: [
          if (p?.canCreateProspects == true)
            OutlinedButton.icon(
                onPressed: () => context.go('/prospects/import'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Importar CSV')),
          if (p?.canCreateProspects == true)
            FilledButton(
                onPressed: () => context.go('/prospects/new'),
                child: const Text('Crear prospecto'))
        ],
        child: PagedList<Prospect>(
            load: (ref, key) => ref.watch(prospectsListProvider(key)),
            refresh: () => ref.invalidate(prospectsListProvider),
            item: (p) => ListTile(
                title: Text(p.name),
                subtitle:
                    Text('${p.email ?? p.phone ?? ''} · ${p.status.name}'),
                trailing: Chip(label: Text(p.source.name)),
                onTap: () => context.go('/prospects/${p.id}'))));
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
                child: const Text('Editar prospecto'))
        ],
        child: AsyncPanel(
            value: ref.watch(prospectsDetailProvider(id)),
            retry: () => ref.invalidate(prospectsDetailProvider(id)),
            data: (p) => ListView(children: [
                  Text(p.name),
                  Wrap(spacing: 8, children: [
                    Chip(label: Text(p.source.name)),
                    Chip(label: Text(p.status.name))
                  ]),
                  for (final entry in prospectTextValues(p).entries)
                    ListTile(
                        title: Text(prospectFieldLabels[entry.key]!),
                        subtitle: Text(entry.value ?? 'Sin información')),
                  TextButton(
                      onPressed: () => context.go('/campaigns/${p.campaignId}'),
                      child: const Text('Ver campaña de origen')),
                  Text('Creado: ${p.createdAt.toLocal()}'),
                  Text('Actualizado: ${p.updatedAt.toLocal()}'),
                  if (p.metadata != null)
                    SelectableText(
                        const JsonEncoder.withIndent('  ').convert(p.metadata))
                ])));
  }
}

const prospectFieldLabels = {
  'category': 'Categoría',
  'address': 'Dirección',
  'phone': 'Teléfono',
  'email': 'Correo electrónico',
  'website': 'Sitio web',
  'language': 'Idioma'
};
Map<String, String?> prospectTextValues(Prospect p) => {
      'category': p.category,
      'address': p.address,
      'phone': p.phone,
      'email': p.email,
      'website': p.website,
      'language': p.language
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
          : ProspectStatus.values.byName(values['status']!));
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
    final result = await showDialog<Campaign>(
        context: context,
        builder: (c) =>
            AlertDialog(
                title: const Text('Seleccionar campaña'),
                content: SizedBox(
                    width: 600,
                    height: 500,
                    child: PagedList<Campaign>(
                        load: (ref, key) =>
                            ref.watch(campaignsListProvider(key)),
                        refresh: () => ref.invalidate(campaignsListProvider),
                        item: (campaign) => ListTile(
                            title: Text(campaign.name),
                            subtitle: Text(campaign.status.name),
                            onTap: () => Navigator.pop(c, campaign)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancelar'))
                ]));
    if (mounted && result != null) setState(() => selected = result);
  }

  Widget editor(Prospect? p) {
    final originals = p == null ? <String, String?>{} : prospectTextValues(p);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (p == null)
        Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(selected?.name ?? 'Campaña obligatoria'),
              TextButton(
                  onPressed: pickCampaign,
                  child: const Text('Seleccionar campaña'))
            ]),
      Expanded(
          child: EntityEditor(
              key: ValueKey(p?.id ?? 'new'),
              fields: [
                EditorField('name', 'Nombre',
                    initial: p?.name ?? '', required: true),
                for (final entry in prospectFieldLabels.entries)
                  EditorField(entry.key, entry.value,
                      initial: originals[entry.key] ?? ''),
                EditorField('status', 'Estado',
                    initial: p?.status.name ?? 'ACTIVO',
                    options: ProspectStatus.values.map((s) => s.name).toList())
              ],
              save: (v) async {
                final repo = ref.read(prospectsRepositoryProvider);
                late Prospect result;
                if (p == null) {
                  if (selected == null) {
                    throw const ApiException(
                        kind: ApiErrorKind.badRequest,
                        message: 'Selecciona una campaña');
                  }
                  FieldUpdate<String> field(String key) => v[key]!.isEmpty
                      ? const FieldUpdate.omitted()
                      : FieldUpdate.set(v[key]);
                  result = await repo.create(CreateProspectRequest(
                      campaignId: selected!.id,
                      name: v['name']!.trim(),
                      category: field('category'),
                      address: field('address'),
                      phone: field('phone'),
                      email: field('email'),
                      website: field('website'),
                      language: field('language'),
                      status: ProspectStatus.values.byName(v['status']!)));
                } else {
                  final request = prospectUpdate(p, v);
                  final changed = v['name'] != p.name ||
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
              }))
    ]);
=======
import '../../../shared/widgets/beta_components.dart';
import '../../../shared/widgets/entity_form.dart';
import '../../workspace/data/platform_repository.dart';

class ProspectsPage extends ConsumerStatefulWidget {
  const ProspectsPage({this.campaignId, super.key});
  final String? campaignId;
  @override
  ConsumerState<ProspectsPage> createState() => _ProspectsPageState();
}

class _ProspectsPageState extends ConsumerState<ProspectsPage> {
  final search = TextEditingController();
  ListQuery query = firstPage;
  @override
  void didUpdateWidget(covariant ProspectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaignId != widget.campaignId) {
      query = firstPage;
      search.clear();
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
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
                    data: editor)));
=======
    final args = (query: query, campaignId: widget.campaignId);
    final data = ref.watch(prospectsProvider(args));
    return PageBody(children: [
      PageHeading(
          'Prospectos',
          widget.campaignId == null
              ? 'Consulta y actualiza los contactos de tu organización.'
              : 'Contactos asociados a la campaña.',
          action: widget.campaignId == null
              ? null
              : OutlinedButton.icon(
                  onPressed: () => context.go('/prospects'),
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Ver todos'))),
      TextField(
          controller: search,
          onSubmitted: (value) =>
              setState(() => query = (page: 1, search: value.trim())),
          decoration: InputDecoration(
              labelText: 'Buscar prospectos',
              hintText: 'Nombre o correo electrónico',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => setState(
                      () => query = (page: 1, search: search.text.trim())),
                  icon: const Icon(Icons.arrow_forward)))),
      const SizedBox(height: 24),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(prospectsProvider(args))),
          data: (page) => Column(children: [
                if (page.items.isEmpty)
                  StatePanel(
                      title: query.search.isEmpty
                          ? 'No hay prospectos todavía'
                          : 'No hay coincidencias',
                      message: query.search.isEmpty
                          ? 'Aquí aparecerán los contactos guardados en tu organización.'
                          : 'Prueba otro nombre o correo.')
                else
                  Surface(
                      padding: 0,
                      child: Column(children: [
                        for (var i = 0; i < page.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFDBEAFE),
                                  child: Icon(Icons.person_outline)),
                              title: Text(page.items[i]['name'] as String),
                              subtitle: Text([
                                page.items[i]['category'],
                                page.items[i]['email'],
                                page.items[i]['phone']
                              ]
                                  .where((v) =>
                                      v != null && v.toString().isNotEmpty)
                                  .join(' · ')),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context
                                  .go('/prospects/${page.items[i]['id']}')),
                        ],
                      ])),
                PaginationBar(
                    page.meta,
                    (number) => setState(
                        () => query = (page: number, search: query.search))),
                OutlinedButton.icon(
                    onPressed: () => ref.invalidate(prospectsProvider(args)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar')),
              ])),
    ]);
  }
}

class ProspectDetailPage extends ConsumerWidget {
  const ProspectDetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(prospectProvider(id));
    return PageBody(children: [
      TextButton.icon(
          onPressed: () => context.go('/prospects'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Prospectos')),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(prospectProvider(id))),
          data: (prospect) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                PageHeading(prospect['name'] as String,
                    prospect['category']?.toString() ?? 'Detalle del contacto',
                    action: OutlinedButton.icon(
                        onPressed: () async {
                          final saved = await showEntityForm(context,
                              title: 'Editar prospecto',
                              changedOnly: true,
                              fields: [
                                FormFieldSpec('name', 'Nombre',
                                    initial: prospect['name'] as String,
                                    validator: requiredField),
                                for (final entry in {
                                  'category': 'Categoría',
                                  'address': 'Dirección',
                                  'phone': 'Teléfono',
                                  'email': 'Correo',
                                  'website': 'Sitio web',
                                  'language': 'Idioma'
                                }.entries)
                                  FormFieldSpec(entry.key, entry.value,
                                      initial:
                                          prospect[entry.key]?.toString() ?? '',
                                      nullable: true,
                                      validator: entry.key == 'email'
                                          ? (v) => v == null || v.isEmpty
                                              ? null
                                              : emailField(v)
                                          : entry.key == 'website'
                                              ? (v) {
                                                  if (v == null || v.isEmpty) {
                                                    return null;
                                                  }
                                                  final uri = Uri.tryParse(v);
                                                  return uri != null &&
                                                          ['https', 'http']
                                                              .contains(
                                                                  uri.scheme) &&
                                                          uri.host.contains('.')
                                                      ? null
                                                      : 'Usa una URL completa, por ejemplo https://empresa.com.';
                                                }
                                              : null),
                                FormFieldSpec('status', 'Estado',
                                    initial: prospect['status'] as String,
                                    options: const {
                                      'ACTIVO': 'Activo',
                                      'INACTIVO': 'Inactivo'
                                    }),
                              ], save: (values) async {
                            await ref
                                .read(platformRepositoryProvider)
                                .update('prospects', id, values);
                          });
                          if (saved) {
                            ref.invalidate(prospectProvider(id));
                            ref.invalidate(prospectsProvider);
                            ref.invalidate(dashboardProvider);
                            if (context.mounted) {
                              showFeedback(context, 'Prospecto actualizado.');
                            }
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'))),
                StatusBadge(prospect['status'] as String),
                const SizedBox(height: 24),
                Surface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Información de contacto',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      for (final field in [
                        ('Correo', 'email'),
                        ('Teléfono', 'phone'),
                        ('Sitio web', 'website'),
                        ('Dirección', 'address'),
                        ('Idioma', 'language'),
                        ('Origen', 'source')
                      ])
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(field.$1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 4),
                                  SelectableText(prospect[field.$2]
                                              ?.toString()
                                              .isNotEmpty ==
                                          true
                                      ? prospect[field.$2].toString()
                                      : 'Sin información'),
                                ])),
                      Text('Registrado el ${dateLabel(prospect['createdAt'])}'),
                      const SizedBox(height: 8),
                      Text(
                          'Actualizado el ${dateLabel(prospect['updatedAt'])}'),
                    ])),
                if (prospect['metadata'] != null) ...[
                  const SizedBox(height: 24),
                  Surface(
                      child: ExpansionTile(
                          title: const Text('Información adicional'),
                          children: [
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(
                                const JsonEncoder.withIndent('  ')
                                    .convert(prospect['metadata']))),
                      ])),
                ],
              ])),
    ]);
>>>>>>> Stashed changes
  }
}
