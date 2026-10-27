import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
<<<<<<< Updated upstream
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
            data: (c) => DefaultTabController(
                length: 2,
                child: Column(children: [
                  const TabBar(
                      tabs: [Tab(text: 'Detalle'), Tab(text: 'Prospectos')]),
                  Expanded(
                      child: TabBarView(children: [
                    ListView(children: [
                      Text(c.name),
                      if (c.description != null) Text(c.description!),
                      Text(c.status.name),
                      Text('Creada: ${c.createdAt.toLocal()}'),
                      Text('Actualizada: ${c.updatedAt.toLocal()}')
                    ]),
                    PagedList<Prospect>(
                        load: (ref, key) => ref.watch(
                            campaignProspectsProvider((id: id, query: key))),
                        refresh: () =>
                            ref.invalidate(campaignProspectsProvider),
                        item: (p) => ListTile(
                            title: Text(p.name),
                            subtitle:
                                Text('${p.source.name} · ${p.status.name}'),
                            onTap: () => context.go('/prospects/${p.id}')))
                  ]))
                ]))));
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
=======
import '../../../app/app_providers.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/beta_components.dart';
import '../../../shared/widgets/entity_form.dart';
import '../../workspace/data/platform_repository.dart';
import '../widgets/campaign_card.dart';

const campaignStates = {
  'ACTIVA': 'Activa',
  'PAUSADA': 'Pausada',
  'COMPLETADA': 'Completada',
  'ARCHIVADA': 'Archivada'
};

class CampaignsPage extends ConsumerStatefulWidget {
  const CampaignsPage({super.key});
  @override
  ConsumerState<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends ConsumerState<CampaignsPage> {
  final search = TextEditingController();
  ListQuery query = firstPage;
  String? status;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(campaignsProvider(query));
    return PageBody(children: [
      PageHeading(
          'Campañas', 'Organiza tus iniciativas y consulta sus detalles.',
          action: FilledButton.icon(
              onPressed: () => context.go('/campaigns/new'),
              icon: const Icon(Icons.add),
              label: const Text('Crear campaña'))),
      TextField(
          controller: search,
          onSubmitted: (text) =>
              setState(() => query = (page: 1, search: text.trim())),
          decoration: InputDecoration(
              labelText: 'Buscar campañas',
              hintText: 'Nombre o descripción',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => setState(
                      () => query = (page: 1, search: search.text.trim())),
                  icon: const Icon(Icons.arrow_forward)))),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
            label: const Text('Todas'),
            selected: status == null,
            onSelected: (_) => setState(() => status = null)),
        for (final entry in campaignStates.entries)
          ChoiceChip(
              label: Text(entry.value),
              selected: status == entry.key,
              onSelected: (_) => setState(() => status = entry.key)),
      ]),
      if (status != null)
        const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('El filtro de estado se aplica a la página actual.')),
      const SizedBox(height: 24),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(campaignsProvider(query))),
          data: (page) {
            final items = page.items
                .where((c) => status == null || c['status'] == status)
                .toList();
            return Column(children: [
              if (items.isEmpty)
                StatePanel(
                    title: query.search.isEmpty && status == null
                        ? 'No tienes campañas todavía'
                        : 'No hay coincidencias',
                    message: query.search.isEmpty && status == null
                        ? 'Crea tu primera campaña para comenzar.'
                        : 'Prueba otra búsqueda, cambia el filtro o revisa otra página.',
                    action: FilledButton(
                        onPressed: () => context.go('/campaigns/new'),
                        child: const Text('Crear campaña')))
              else
                LayoutBuilder(builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  return Wrap(spacing: 16, runSpacing: 16, children: [
                    for (final item in items)
                      SizedBox(
                          width:
                              (constraints.maxWidth - 16 * (cols - 1)) / cols,
                          child: CampaignCard(
                              campaign: item,
                              onTap: () =>
                                  context.go('/campaigns/${item['id']}'))),
                  ]);
                }),
              PaginationBar(
                  page.meta,
                  (number) => setState(
                      () => query = (page: number, search: query.search))),
              OutlinedButton.icon(
                  onPressed: () => ref.invalidate(campaignsProvider(query)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar')),
            ]);
          }),
    ]);
  }
}

class CreateCampaignPage extends ConsumerStatefulWidget {
  const CreateCampaignPage({super.key});
  @override
  ConsumerState<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends ConsumerState<CreateCampaignPage> {
  final name = TextEditingController(), description = TextEditingController();
  final form = GlobalKey<FormState>();
  bool review = false, busy = false;
  Object? error;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result =
          await ref.read(platformRepositoryProvider).create('campaigns', {
        'name': name.text.trim(),
        'description':
            description.text.trim().isEmpty ? null : description.text.trim()
      });
      ref.invalidate(campaignsProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) {
        showFeedback(context, 'Campaña creada.');
        context.go('/campaigns/${result['id']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(children: [
        TextButton.icon(
            onPressed: busy ? null : () => context.go('/campaigns'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Campañas')),
        const PageHeading(
            'Crear campaña', 'Da un nombre y un propósito a tu nueva campaña.'),
        Wrap(spacing: 12, children: [
          Chip(
              label: const Text('1. Información'),
              backgroundColor: review ? null : const Color(0xFFDBEAFE)),
          Chip(
              label: const Text('2. Confirmación'),
              backgroundColor: review ? const Color(0xFFDBEAFE) : null)
        ]),
        const SizedBox(height: 24),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Surface(
                child: Form(
                    key: form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!review) ...[
                            TextFormField(
                                controller: name,
                                validator: requiredField,
                                decoration: const InputDecoration(
                                    labelText: 'Nombre de campaña',
                                    hintText: 'Campaña verano 2026')),
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: description,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                    labelText: 'Descripción (opcional)')),
                          ] else ...[
                            Text('Revisa tu campaña',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 20),
                            Text(name.text,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(description.text.isEmpty
                                ? 'Sin descripción'
                                : description.text),
                            const SizedBox(height: 20),
                            const Text(
                                'La campaña se creará en la organización seleccionada. Podrás editarla después.'),
                          ],
                          if (error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                    const ErrorMapper().userMessage(error!),
                                    style: const TextStyle(
                                        color: Color(0xFFDC2626)))),
                          const SizedBox(height: 24),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () {
                                        if (review) {
                                          setState(() => review = false);
                                        } else {
                                          context.go('/campaigns');
                                        }
                                      },
                                child: Text(review ? 'Volver' : 'Cancelar')),
                            FilledButton(
                                onPressed: busy
                                    ? null
                                    : () {
                                        if (review) {
                                          save();
                                        } else if (form.currentState!
                                            .validate()) {
                                          setState(() => review = true);
                                        }
                                      },
                                child: Text(busy
                                    ? 'Creando…'
                                    : review
                                        ? 'Crear campaña'
                                        : 'Continuar')),
                          ]),
                        ])))),
      ]);
}

class CampaignDetailPage extends ConsumerStatefulWidget {
  const CampaignDetailPage({required this.id, super.key});
  final String id;
  @override
  ConsumerState<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends ConsumerState<CampaignDetailPage> {
  bool busy = false;
  void refresh() {
    ref.invalidate(campaignProvider(widget.id));
    ref.invalidate(campaignsProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> archive({bool permanent = false}) async {
    final confirmed = await confirmAction(
        context,
        permanent ? 'Eliminar campaña' : 'Archivar campaña',
        permanent
            ? 'La eliminación es permanente. Si hay registros asociados, la operación puede ser rechazada.'
            : 'La campaña pasará a Archivada y conservará su información.');
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(platformRepositoryProvider)
          .archiveCampaign(widget.id, permanent: permanent);
      refresh();
      if (mounted) {
        showFeedback(
            context, permanent ? 'Campaña eliminada.' : 'Campaña archivada.');
        if (permanent) context.go('/campaigns');
      }
    } catch (e) {
      if (mounted) showFeedback(context, const ErrorMapper().userMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(campaignProvider(widget.id));
    final prospects =
        ref.watch(prospectsProvider((query: firstPage, campaignId: widget.id)));
    final admin =
        ref.watch(authControllerProvider).context?.user.platformRole == 'ADMIN';
    return PageBody(children: [
      TextButton.icon(
          onPressed: () => context.go('/campaigns'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Campañas')),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) => ErrorPanel(e, refresh),
          data: (campaign) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                PageHeading(campaign['name'] as String,
                    'Información y prospectos de la campaña.',
                    action: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                final saved = await showEntityForm(context,
                                    title: 'Editar campaña',
                                    changedOnly: true,
                                    fields: [
                                      FormFieldSpec('name', 'Nombre',
                                          initial: campaign['name'] as String,
                                          validator: requiredField),
                                      FormFieldSpec(
                                          'description', 'Descripción',
                                          initial: campaign['description']
                                                  ?.toString() ??
                                              '',
                                          lines: 4,
                                          nullable: true),
                                      FormFieldSpec('status', 'Estado',
                                          initial: campaign['status'] as String,
                                          options: campaignStates),
                                    ], save: (values) async {
                                  await ref
                                      .read(platformRepositoryProvider)
                                      .update('campaigns', widget.id, values);
                                });
                                if (saved) {
                                  refresh();
                                  if (context.mounted) {
                                    showFeedback(context, 'Cambios guardados.');
                                  }
                                }
                              },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'))),
                StatusBadge(campaign['status'] as String),
                const SizedBox(height: 24),
                Surface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Resumen',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text(
                          campaign['description']?.toString().isNotEmpty == true
                              ? campaign['description'] as String
                              : 'Sin descripción'),
                      const SizedBox(height: 24),
                      Text('Creada el ${dateLabel(campaign['createdAt'])}'),
                      const SizedBox(height: 8),
                      Text(
                          'Última actualización: ${dateLabel(campaign['updatedAt'])}'),
                    ])),
                const SizedBox(height: 24),
                prospects.when(
                    loading: () => const LoadingPanel(),
                    error: (e, _) => ErrorPanel(
                        e,
                        () => ref.invalidate(prospectsProvider(
                            (query: firstPage, campaignId: widget.id)))),
                    data: (page) => Surface(
                            child: Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Prospectos asociados',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text('${page.meta.total}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge)
                              ])),
                          TextButton(
                              onPressed: () => context
                                  .go('/prospects?campaignId=${widget.id}'),
                              child: const Text('Ver prospectos')),
                        ]))),
                const SizedBox(height: 24),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  if (campaign['status'] != 'ARCHIVADA')
                    OutlinedButton.icon(
                        onPressed: busy ? null : archive,
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Archivar')),
                  if (admin)
                    TextButton.icon(
                        onPressed: busy ? null : () => archive(permanent: true),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFDC2626)),
                        label: const Text('Eliminar permanentemente',
                            style: TextStyle(color: Color(0xFFDC2626)))),
                ]),
              ])),
    ]);
>>>>>>> Stashed changes
  }
}
