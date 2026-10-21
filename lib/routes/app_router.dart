import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_providers.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/tenants/presentation/tenants_pages.dart';
import '../features/users/presentation/users_pages.dart';
import '../features/auth/state/tenant_permissions.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/auth/state/auth_state.dart';
import '../features/campaigns/presentation/campaigns_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/prospects/presentation/prospects_page.dart';
import '../features/prospecting_jobs/presentation/generate_page.dart';

import '../features/dashboard/presentation/dashboard_page.dart';

/// Scope sits inside the route Navigator: its global key must not preserve old forms.
class ScopedFeaturePage extends ConsumerWidget {
  const ScopedFeaturePage({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => KeyedSubtree(
      key: ValueKey(ref.watch(sessionScopeProvider)), child: child);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  GoRoute featureRoute(String path, Widget Function(GoRouterState) page) =>
      GoRoute(
          path: path,
          builder: (_, state) => ScopedFeaturePage(child: page(state)));
  final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: refresh,
      redirect: (_, state) =>
          redirectForAuth(ref.read(authControllerProvider), state.uri.path),
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(
            path: '/select-tenant',
            builder: (_, __) => const SelectTenantPage()),
        GoRoute(
            path: '/change-tenant',
            builder: (_, __) => const SelectTenantPage()),
        ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
          featureRoute('/dashboard', (s) => const DashboardPage()),
          featureRoute('/campaigns', (s) => const CampaignsPage()),
          featureRoute('/campaigns/new', (s) => const CampaignFormPage()),
          featureRoute('/campaigns/:id',
              (s) => CampaignDetailPage(s.pathParameters['id']!)),
          featureRoute('/campaigns/:id/edit',
              (s) => CampaignFormPage(id: s.pathParameters['id']!)),
          featureRoute('/users', (s) => const UsersPage()),
          featureRoute('/users/new', (s) => const UserFormPage()),
          featureRoute(
              '/users/:id', (s) => UserDetailPage(s.pathParameters['id']!)),
          featureRoute('/users/:id/edit',
              (s) => UserFormPage(id: s.pathParameters['id']!)),
          featureRoute('/prospects', (s) => const ProspectsPage()),
          featureRoute('/prospects/new', (s) => const ProspectFormPage()),
          featureRoute('/prospects/:id',
              (s) => ProspectDetailPage(s.pathParameters['id']!)),
          featureRoute('/prospects/:id/edit',
              (s) => ProspectFormPage(id: s.pathParameters['id']!)),
          featureRoute('/generate', (s) => const GeneratePage()),
          featureRoute('/profile', (s) => const ProfilePage()),
          featureRoute('/admin', (s) => const AdminPage()),
          featureRoute('/tenants', (s) => const TenantsPage()),
          featureRoute('/tenants/new', (s) => const TenantCreatePage()),
          featureRoute(
              '/tenants/:id', (s) => TenantDetailPage(s.pathParameters['id']!)),
        ]),
        GoRoute(
            path: '/session-expired',
            builder: (_, __) => const SessionExpiredPage()),
        GoRoute(
            path: '/backend-unavailable',
            builder: (_, __) => const BackendUnavailablePage()),
      ]);
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

String? redirectForAuth(AuthState auth, String path) {
  // Keep the tenant selector mounted while replacing an existing context so
  // recoverable switch errors remain visible. Feature state is cleared by scope.
  if (auth.status == AuthStatus.loading && auth.context != null) return null;
  if (auth.status == AuthStatus.unknown || auth.status == AuthStatus.loading) {
    return path == '/splash' ? null : '/splash';
  }
  if (auth.status == AuthStatus.sessionExpired) {
    return path == '/session-expired' ? null : '/session-expired';
  }
  if (auth.status == AuthStatus.backendUnavailable) {
    return path == '/backend-unavailable' ? null : '/backend-unavailable';
  }
  if (auth.status != AuthStatus.authenticated) {
    return path == '/login' ? null : '/login';
  }
  final hasTenant = auth.context?.currentTenantId != null;
  if (path == '/login' ||
      path == '/splash' ||
      path == '/session-expired' ||
      path == '/backend-unavailable') {
    return hasTenant ? '/dashboard' : '/select-tenant';
  }
  if (path == '/select-tenant' && hasTenant) return '/dashboard';
  if (!hasTenant && _requiresTenant(path)) return '/select-tenant';
  return null;
}

bool _requiresTenant(String path) => {
      '/dashboard',
      '/campaigns',
      '/prospects',
      '/generate',
      '/jobs',
      '/users',
    }.any((root) => path == root || path.startsWith('$root/'));

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final destinations = const ['/dashboard', '/campaigns', '/prospects'];
    final rawIndex = destinations.indexWhere(
        (root) => location == root || location.startsWith('$root/'));
    final index = rawIndex < 0 ? 0 : rawIndex;
    final wideLayout = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(title: const Text('SaaS Platform')),
      body: wideLayout
          ? Row(children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (value) =>
                    context.go(destinations[value]),
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: Text('Dashboard')),
                  NavigationRailDestination(
                      icon: Icon(Icons.campaign_outlined),
                      label: Text('Campañas')),
                  NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      label: Text('Prospectos')),
                ],
              ),
              Expanded(child: child),
            ])
          : child,
      drawer: Drawer(
          child: ListView(children: [
        const DrawerHeader(child: Text('Cuenta')),
        ListTile(
            title: const Text('Organizaciones'),
            onTap: () => context.go('/tenants')),
        ListTile(
            title: const Text('Usuarios'), onTap: () => context.go('/users')),
        ListTile(
            title: const Text('Perfil'), onTap: () => context.go('/profile')),
        ListTile(
            title: const Text('Cerrar sesión'),
            onTap: () => ref.read(authControllerProvider.notifier).logout()),
      ])),
      bottomNavigationBar: wideLayout
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => context.go(destinations[value]),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                NavigationDestination(
                    icon: Icon(Icons.campaign_outlined), label: 'Campañas'),
                NavigationDestination(
                    icon: Icon(Icons.people_outline), label: 'Prospectos'),
              ],
            ),
    );
  }
}
