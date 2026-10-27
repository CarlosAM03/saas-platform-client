import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
<<<<<<< Updated upstream
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../tenants/state/tenants_providers.dart';
=======
import '../../../shared/widgets/beta_components.dart';
import '../../workspace/data/platform_repository.dart';
>>>>>>> Stashed changes

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).context;
<<<<<<< Updated upstream
    final tenantId = auth?.currentTenantId;
    final permissions = ref.watch(currentTenantPermissionsProvider);
    return FeaturePage(
        title: 'Perfil',
        child: ListView(children: [
          Text(auth?.user.name ?? ''),
          Text(auth?.user.email ?? ''),
          Text(
              'Rol de plataforma: ${auth?.user.platformRole ?? 'tenant-scoped'}'),
          if (tenantId == null)
            const Text('Sin organización seleccionada')
          else
            AsyncPanel(
                value: ref.watch(tenantDetailProvider(tenantId)),
                data: (t) => Text('Organización: ${t.name}')),
          AsyncPanel(
              value: permissions, data: (p) => Text('Rol actual: ${p.label}')),
          TextButton(
              onPressed: () => context.go('/change-tenant'),
              child: const Text('Cambiar organización')),
          TextButton(
              onPressed: () => context.go('/tenants'),
              child: const Text('Organizaciones')),
          TextButton(
              onPressed: () => context.go('/users'),
              child: const Text('Usuarios')),
          TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Cerrar sesión'))
        ]));
=======
    final user = auth?.user;
    final organization = ref.watch(currentOrganizationProvider);
    final membership = ref.watch(currentMembershipProvider).valueOrNull;
    final role = user?.platformRole == 'ADMIN'
        ? 'Administrador'
        : (membership?['role'] as Map?)?['name'] == 'OWNER'
            ? 'Responsable'
            : 'Miembro';
    return PageBody(children: [
      const PageHeading('Mi perfil', 'Tu cuenta y tu espacio de trabajo.'),
      Surface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFDBEAFE),
            child: Icon(Icons.person_outline, size: 32)),
        const SizedBox(height: 16),
        Text(user?.name ?? '', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SelectableText(user?.email ?? ''),
        const SizedBox(height: 16),
        Text('Perfil: $role'),
        const SizedBox(height: 8),
        Text('Cuenta: ${user?.status == 'ACTIVO' ? 'Activa' : 'Inactiva'}'),
      ])),
      const SizedBox(height: 24),
      organization.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(currentOrganizationProvider)),
          data: (item) => Surface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Organización actual',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(item?['name']?.toString() ??
                        'Aún no has seleccionado una organización'),
                    if (item != null) ...[
                      const SizedBox(height: 8),
                      Text(item['slug'] as String)
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                        onPressed: () => context.go('/organizations'),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Cambiar organización')),
                  ]))),
      const SizedBox(height: 24),
      Surface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Sesión', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
            'Al cerrar sesión, se elimina el acceso guardado en este dispositivo.'),
        const SizedBox(height: 16),
        TextButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFDC2626)))),
      ])),
    ]);
>>>>>>> Stashed changes
  }
}
