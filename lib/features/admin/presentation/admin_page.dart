import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/feature_widgets.dart';
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/beta_components.dart';
import '../../../shared/widgets/entity_form.dart';
import '../../workspace/data/platform_repository.dart';
>>>>>>> Stashed changes

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});
  @override
<<<<<<< Updated upstream
  Widget build(BuildContext context) => FeaturePage(
      title: 'Administración',
      child: ListView(children: [
        ListTile(
            title: const Text('Organizaciones'),
            onTap: () => context.go('/tenants')),
        ListTile(
            title: const Text('Usuarios'), onTap: () => context.go('/users'))
      ]));
=======
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  final search = TextEditingController();
  ListQuery query = firstPage;
  bool busy = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<FormFieldSpec> userFields([Json? user]) => [
        FormFieldSpec('name', 'Nombre',
            initial: user?['name']?.toString() ?? '', validator: requiredField),
        FormFieldSpec('email', 'Correo electrónico',
            initial: user?['email']?.toString() ?? '', validator: emailField),
        FormFieldSpec('password',
            user == null ? 'Contraseña inicial' : 'Nueva contraseña (opcional)',
            secret: true,
            hint: 'Mínimo 10 caracteres: letra, número y símbolo.',
            validator: (value) =>
                user != null && (value == null || value.isEmpty)
                    ? null
                    : passwordField(value)),
        if (user != null)
          FormFieldSpec('status', 'Estado',
              initial: user['status'] as String,
              options: const {'ACTIVO': 'Activo', 'INACTIVO': 'Inactivo'}),
      ];
  Future<void> editUser([Json? user]) async {
    final saved = await showEntityForm(context,
        title: user == null ? 'Agregar integrante' : 'Editar integrante',
        description: user == null
            ? 'La cuenta se creará como miembro de la organización seleccionada.'
            : 'Los cambios se guardarán en la cuenta del integrante.',
        fields: userFields(user),
        changedOnly: user != null, save: (values) async {
      final repo = ref.read(platformRepositoryProvider);
      if (user == null) {
        await repo.create('users', values);
      } else {
        await repo.update('users', user['id'] as String, values);
      }
    });
    if (saved) {
      ref.invalidate(usersProvider);
      ref.invalidate(currentMembershipProvider);
      if (mounted) showFeedback(context, 'Integrante guardado.');
    }
  }

  Future<void> deactivateMember(Json user) async {
    if (!await confirmAction(context, 'Desactivar integrante',
            '${user['name']} perderá el acceso a la plataforma. Su información se conservará.') ||
        !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(platformRepositoryProvider)
          .deactivateUser(user['id'] as String);
      ref.invalidate(usersProvider);
      if (mounted) showFeedback(context, 'Integrante desactivado.');
    } catch (e) {
      if (mounted) showFeedback(context, const ErrorMapper().userMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(usersProvider(query));
    final manage = ref.watch(canManageUsersProvider);
    final auth = ref.watch(authControllerProvider).context;
    final admin = auth?.user.platformRole == 'ADMIN';
    return PageBody(children: [
      PageHeading(
          'Equipo', 'Personas que pertenecen a la organización seleccionada.',
          action: manage
              ? FilledButton.icon(
                  onPressed: busy ? null : editUser,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Agregar integrante'))
              : null),
      TextField(
          controller: search,
          onSubmitted: (value) =>
              setState(() => query = (page: 1, search: value.trim())),
          decoration: InputDecoration(
              labelText: 'Buscar integrantes',
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
              ErrorPanel(e, () => ref.invalidate(usersProvider(query))),
          data: (page) => Column(children: [
                if (page.items.isEmpty)
                  const StatePanel(
                      title: 'No hay integrantes',
                      message: 'Agrega una persona o prueba otra búsqueda.',
                      icon: Icons.group_outlined)
                else
                  Surface(
                      padding: 0,
                      child: Column(children: [
                        for (var i = 0; i < page.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              isThreeLine: true,
                              title: Text(page.items[i]['name'] as String),
                              subtitle: Text(
                                  '${page.items[i]['email']}\n${page.items[i]['platformRole'] == 'ADMIN' ? 'Administrador' : (page.items[i]['role'] as Map?)?['name'] == 'OWNER' ? 'Responsable' : 'Miembro'} · ${page.items[i]['status'] == 'ACTIVO' ? 'Activo' : 'Inactivo'}'),
                              trailing: !manage
                                  ? null
                                  : PopupMenuButton<String>(
                                      tooltip: 'Acciones del integrante',
                                      enabled: !busy,
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          editUser(page.items[i]);
                                        } else {
                                          deactivateMember(page.items[i]);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                            const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Editar')),
                                            if (admin &&
                                                page.items[i]['id'] !=
                                                    auth?.user.id &&
                                                page.items[i]['status'] ==
                                                    'ACTIVO')
                                              const PopupMenuItem(
                                                  value: 'deactivate',
                                                  child: Text('Desactivar')),
                                          ])),
                        ],
                      ])),
                PaginationBar(
                    page.meta,
                    (number) => setState(
                        () => query = (page: number, search: query.search))),
                OutlinedButton.icon(
                    onPressed: () => ref.invalidate(usersProvider(query)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar')),
              ])),
    ]);
  }
>>>>>>> Stashed changes
}
