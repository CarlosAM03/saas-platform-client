import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../tenants/state/tenants_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).context;
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
  }
}
