import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/users_providers.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
        title: 'Usuarios',
        actions: [
          if (p?.canManageUsers == true)
            FilledButton(
                onPressed: () => context.go('/users/new'),
                child: const Text('Crear usuario'))
        ],
        child: PagedList<User>(
            sorts: const [
              SortField.name,
              SortField.email,
              SortField.status,
              SortField.createdAt,
              SortField.updatedAt
            ],
            load: (ref, key) => ref.watch(usersListProvider(key)),
            refresh: () => ref.invalidate(usersListProvider),
            item: (u) => ListTile(
                title: Text(u.name),
                subtitle: Text('${u.email} · ${u.status.name}'),
                onTap: () => context.go('/users/${u.id}'))));
  }
}

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider).asData?.value;
    return FeaturePage(
        title: 'Usuario',
        actions: [
          if (p?.canManageUsers == true)
            TextButton(
                onPressed: () => context.go('/users/$id/edit'),
                child: const Text('Editar usuario')),
          if (p?.canDeactivateUsers == true)
            EntityAction(
                label: 'Desactivar usuario',
                confirm: '¿Desactivar este usuario?',
                run: () async {
                  await ref.read(usersRepositoryProvider).deactivate(id);
                  if (!context.mounted) return;
                  ref.invalidate(usersListProvider);
                  ref.invalidate(usersDetailProvider(id));
                })
        ],
        child: AsyncPanel(
            value: ref.watch(usersDetailProvider(id)),
            retry: () => ref.invalidate(usersDetailProvider(id)),
            data: (u) => ListView(children: [
                  Text(u.name),
                  Text(u.email),
                  Text(u.status.name),
                  Text(
                      'Rol: ${u.role?.name.name ?? u.platformRole?.name ?? 'Sin rol'}'),
                  Text('Creado: ${u.createdAt.toLocal()}'),
                  Text('Actualizado: ${u.updatedAt.toLocal()}')
                ])));
  }
}

class UserFormPage extends ConsumerWidget {
  const UserFormPage({this.id, super.key});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentTenantPermissionsProvider);
    Widget editor(User? u) => EntityEditor(
        key: ValueKey(u?.id ?? 'new'),
        notice: u == null ? 'El usuario se crea como MEMBER' : null,
        fields: [
          EditorField('name', 'Nombre', initial: u?.name ?? '', required: true),
          EditorField('email', 'Correo electrónico',
              initial: u?.email ?? '', required: true),
          EditorField('password',
              u == null ? 'Contraseña' : 'Nueva contraseña (opcional)',
              secret: true,
              required: u == null,
              help: 'Mínimo 10 caracteres, letra, número y carácter especial.'),
          if (u != null)
            EditorField('status', 'Estado',
                initial: u.status.name,
                options: UserStatus.values.map((s) => s.name).toList())
        ],
        save: (v) async {
          final repo = ref.read(usersRepositoryProvider);
          final result = u == null
              ? await repo.create(CreateUserRequest(
                  name: v['name']!.trim(),
                  email: v['email']!.trim(),
                  password: v['password']!))
              : await repo.update(
                  u.id,
                  UpdateUserRequest(
                      name: v['name']!.trim(),
                      email: v['email']!.trim(),
                      password: v['password']!.isEmpty ? null : v['password'],
                      status: UserStatus.values.byName(v['status']!)));
          if (!context.mounted) return;
          ref.invalidate(usersListProvider);
          ref.invalidate(usersDetailProvider(result.id));
          ref.invalidate(currentTenantPermissionsProvider);
          context.go('/users/${result.id}');
        });
    return FeaturePage(
        title: id == null ? 'Crear usuario' : 'Editar usuario',
        child: PermissionGate(
            permissions: p,
            allowed: p.asData?.value.canManageUsers == true,
            child: id == null
                ? editor(null)
                : AsyncPanel(
                    value: ref.watch(usersDetailProvider(id!)),
                    retry: () => ref.invalidate(usersDetailProvider(id!)),
                    data: editor)));
  }
}
