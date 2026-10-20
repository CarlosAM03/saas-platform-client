import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/error_mapper.dart';
import '../../platform_api/platform_api.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage(
      {required this.title,
      required this.child,
      this.actions = const [],
      super.key});
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              ...actions
            ]),
        const SizedBox(height: 16),
        Expanded(child: child)
      ]));
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {this.retry, super.key});
  final Object error;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(const ErrorMapper().userMessage(error)),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Reintentar'))
      ]));
}

class AsyncPanel<T> extends StatelessWidget {
  const AsyncPanel(
      {required this.value, required this.data, this.retry, super.key});
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => value.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(e, retry: retry),
      data: data);
}

class PermissionGate extends StatelessWidget {
  const PermissionGate(
      {required this.permissions,
      required this.allowed,
      required this.child,
      super.key});
  final AsyncValue<Object> permissions;
  final bool allowed;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (permissions.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (permissions.hasError) return ErrorView(permissions.error!);
    return allowed
        ? child
        : const Center(
            child: Text('No tienes permisos para realizar esta acción.'));
  }
}

typedef PageKey = ({int page, String search, SortField sort, SortOrder order});
PaginationQuery pageQuery(PageKey key) => PaginationQuery(
    page: key.page,
    limit: 20,
    search: key.search,
    sortBy: key.sort,
    sortOrder: key.order);

class PagedList<T> extends ConsumerStatefulWidget {
  const PagedList(
      {required this.load,
      required this.item,
      required this.refresh,
      this.sorts = const [
        SortField.name,
        SortField.status,
        SortField.createdAt,
        SortField.updatedAt
      ],
      super.key});
  final AsyncValue<PaginatedResult<T>> Function(WidgetRef, PageKey) load;
  final Widget Function(T) item;
  final VoidCallback refresh;
  final List<SortField> sorts;
  @override
  ConsumerState<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends ConsumerState<PagedList<T>> {
  final search = TextEditingController();
  PageKey query =
      (page: 1, search: '', sort: SortField.name, order: SortOrder.asc);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.load(ref, query);
    return Column(children: [
      Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
                width: 240,
                child: TextField(
                    controller: search,
                    decoration: const InputDecoration(labelText: 'Buscar'),
                    onSubmitted: (_) => setState(() => query = (
                          page: 1,
                          search: search.text.trim(),
                          sort: query.sort,
                          order: query.order
                        )))),
            IconButton(
                tooltip: 'Buscar',
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => query = (
                      page: 1,
                      search: search.text.trim(),
                      sort: query.sort,
                      order: query.order
                    ))),
            DropdownButton<SortField>(
                value: query.sort,
                items: widget.sorts
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (s) {
                  if (s != null) {
                    setState(() => query = (
                          page: 1,
                          search: query.search,
                          sort: s,
                          order: query.order
                        ));
                  }
                }),
            IconButton(
                tooltip: 'Cambiar orden',
                icon: Icon(query.order == SortOrder.asc
                    ? Icons.arrow_upward
                    : Icons.arrow_downward),
                onPressed: () => setState(() => query = (
                      page: 1,
                      search: query.search,
                      sort: query.sort,
                      order: query.order == SortOrder.asc
                          ? SortOrder.desc
                          : SortOrder.asc
                    ))),
            IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: widget.refresh)
          ]),
      const SizedBox(height: 12),
      Expanded(
          child: AsyncPanel(
              value: value,
              retry: widget.refresh,
              data: (page) => page.items.isEmpty
                  ? const Center(child: Text('No hay información disponible.'))
                  : ListView(children: page.items.map(widget.item).toList()))),
      if (value.asData != null)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: 'Página anterior',
              onPressed: query.page > 1
                  ? () => setState(() => query = (
                        page: query.page - 1,
                        search: query.search,
                        sort: query.sort,
                        order: query.order
                      ))
                  : null,
              icon: const Icon(Icons.chevron_left)),
          Text(
              'Página ${query.page} · ${value.asData!.value.meta.total} registros'),
          IconButton(
              tooltip: 'Página siguiente',
              onPressed: query.page < value.asData!.value.meta.totalPages
                  ? () => setState(() => query = (
                        page: query.page + 1,
                        search: query.search,
                        sort: query.sort,
                        order: query.order
                      ))
                  : null,
              icon: const Icon(Icons.chevron_right))
        ])
    ]);
  }
}

class EditorField {
  const EditorField(this.name, this.label,
      {this.initial = '',
      this.required = false,
      this.secret = false,
      this.options,
      this.help});
  final String name, label, initial;
  final bool required, secret;
  final List<String>? options;
  final String? help;
}

class EntityEditor extends StatefulWidget {
  const EntityEditor(
      {required this.fields, required this.save, this.notice, super.key});
  final List<EditorField> fields;
  final Future<void> Function(Map<String, String>) save;
  final String? notice;
  @override
  State<EntityEditor> createState() => _EntityEditorState();
}

class _EntityEditorState extends State<EntityEditor> {
  final form = GlobalKey<FormState>();
  late final values = {for (final f in widget.fields) f.name: f.initial};
  bool saving = false;
  Object? error;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                  key: form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.notice != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(widget.notice!)),
                        for (final f in widget.fields)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: f.options == null
                                  ? TextFormField(
                                      initialValue: f.initial,
                                      obscureText: f.secret,
                                      enabled: !saving,
                                      decoration: InputDecoration(
                                          labelText: f.label,
                                          helperText: f.help),
                                      validator: (v) => f.required &&
                                              (v == null || v.trim().isEmpty)
                                          ? 'Campo obligatorio'
                                          : null,
                                      onChanged: (v) => values[f.name] = v)
                                  : DropdownButtonFormField<String>(
                                      initialValue: f.initial,
                                      decoration:
                                          InputDecoration(labelText: f.label),
                                      isExpanded: true,
                                      items: f.options!
                                          .map((v) => DropdownMenuItem(
                                              value: v, child: Text(v)))
                                          .toList(),
                                      onChanged: saving
                                          ? null
                                          : (v) {
                                              if (v != null) values[f.name] = v;
                                            })),
                        if (error != null) ErrorView(error!),
                        FilledButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (!form.currentState!.validate()) return;
                                    setState(() {
                                      saving = true;
                                      error = null;
                                    });
                                    try {
                                      await widget
                                          .save(Map.unmodifiable(values));
                                    } catch (e) {
                                      if (mounted) setState(() => error = e);
                                    } finally {
                                      if (mounted) {
                                        setState(() => saving = false);
                                      }
                                    }
                                  },
                            child: Text(saving ? 'Guardando…' : 'Guardar'))
                      ])))));
}

Future<bool> confirmAction(BuildContext context, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Confirmar'),
                content: Text(message),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Confirmar'))
                ])) ??
    false;

class EntityAction extends StatefulWidget {
  const EntityAction(
      {required this.label, required this.run, this.confirm, super.key});
  final String label;
  final String? confirm;
  final Future<void> Function() run;
  @override
  State<EntityAction> createState() => _EntityActionState();
}

class _EntityActionState extends State<EntityAction> {
  bool busy = false;
  Object? error;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        TextButton(
            onPressed: busy
                ? null
                : () async {
                    if (widget.confirm != null &&
                        !await confirmAction(context, widget.confirm!)) {
                      return;
                    }
                    if (!mounted) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await widget.run();
                    } catch (e) {
                      if (mounted) setState(() => error = e);
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(busy ? 'Procesando…' : widget.label)),
        if (error != null) Text(const ErrorMapper().userMessage(error!))
      ]);
}
