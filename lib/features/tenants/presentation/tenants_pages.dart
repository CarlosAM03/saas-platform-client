import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../tenant_registration/presentation/registration_pages.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/tenants_providers.dart';

class TenantsPage extends ConsumerWidget {
  const TenantsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    return FeaturePage(
      title: 'Organizaciones',
      actions: [
        if (permissions.asData?.value.canCreateTenants == true)
          FilledButton(
            onPressed: () => context.go('/tenants/new'),
            child: const Text('Registrar organización'),
          ),
        TextButton(
          onPressed: () => context.go('/change-tenant'),
          child: const Text('Cambiar organización'),
        ),
      ],
      child: AsyncPanel(
        value: ref.watch(tenantsListProvider),
        retry: () => ref.invalidate(tenantsListProvider),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No hay organizaciones disponibles.'))
            : ListView(
                children: items
                    .map(
                      (t) => ListTile(
                        title: Text(t.name),
                        subtitle: Text('${t.slug} · ${t.status.name}'),
                        trailing:
                            t.id == ref.watch(sessionScopeProvider)?.tenantId
                            ? const Chip(label: Text('Actual'))
                            : null,
                        onTap: () => context.go('/tenants/${t.id}'),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}

class TenantDetailPage extends ConsumerWidget {
  const TenantDetailPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
    title: 'Organización',
    child: AsyncPanel(
      value: ref.watch(tenantDetailProvider(id)),
      retry: () => ref.invalidate(tenantDetailProvider(id)),
      data: (t) => ListView(
        children: [
          Text(t.name),
          Text(t.slug),
          Text(t.status.name),
          Text('Creada: ${t.createdAt.toLocal()}'),
          if (ref
                  .watch(currentTenantPermissionsProvider)
                  .asData
                  ?.value
                  .canCreateTenants ==
              true)
            TextButton(
              onPressed: () => context.go(
                '/tenants/${Uri.encodeComponent(t.id)}/onboarding',
              ),
              child: const Text('Consultar onboarding'),
            ),
          EntityAction(
            label: 'Usar organización',
            run: () async {
              final controller = ref.read(authControllerProvider.notifier);
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final router = GoRouter.of(context);
              await controller.selectTenant(t.id);
              final auth = container.read(authControllerProvider);
              if (auth.error != null) {
                router.go('/change-tenant');
                return;
              }
              if (auth.context?.currentTenantId == t.id) {
                router.go('/dashboard');
              }
            },
          ),
        ],
      ),
    ),
  );
}

/// Kept as a source-compatible page name; visible business creation uses ADR-006.
class TenantCreatePage extends StatelessWidget {
  const TenantCreatePage({super.key});
  @override
  Widget build(BuildContext context) => const TenantRegistrationPage();
}
