import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../../shared/widgets/feature_widgets.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
    title: 'Administración',
    child: ListView(
      children: [
        if (ref
                .watch(currentTenantPermissionsProvider)
                .asData
                ?.value
                .canCreateTenants ==
            true)
          ListTile(
            title: const Text('Registrar organización'),
            onTap: () => context.go('/tenants/new'),
          ),
        ListTile(
          title: const Text('Organizaciones'),
          onTap: () => context.go('/tenants'),
        ),
        ListTile(
          title: const Text('Usuarios'),
          onTap: () => context.go('/users'),
        ),
      ],
    ),
  );
}
