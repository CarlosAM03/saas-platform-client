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
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/prospects/presentation/prospects_page.dart';
import '../features/prospects/presentation/prospect_import_page.dart';
import '../features/prospecting_jobs/presentation/jobs_pages.dart';
import '../features/prospecting_jobs/presentation/generate_page.dart';
<<<<<<< Updated upstream

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
          featureRoute('/prospects/import', (s) => const ProspectImportPage()),
          featureRoute('/prospects/:id',
              (s) => ProspectDetailPage(s.pathParameters['id']!)),
          featureRoute('/prospects/:id/edit',
              (s) => ProspectFormPage(id: s.pathParameters['id']!)),
          featureRoute('/generate', (s) => const GeneratePage()),
          featureRoute('/jobs', (s) => const JobsPage()),
          featureRoute(
              '/jobs/:id', (s) => JobDetailPage(s.pathParameters['id']!)),
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
=======
import '../features/workspace/data/platform_repository.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectForAuth(ref.read(authControllerProvider), state.uri.path),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
          path: '/select-tenant', builder: (_, __) => const SelectTenantPage()),
      GoRoute(
          path: '/session-expired',
          builder: (_, __) => const SessionExpiredPage()),
      GoRoute(
          path: '/backend-unavailable',
          builder: (_, __) => const BackendUnavailablePage()),
      ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
        GoRoute(
            path: '/campaigns',
            builder: (_, __) => const CampaignsPage(),
            routes: [
              GoRoute(
                  path: 'new', builder: (_, __) => const CreateCampaignPage()),
              GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      CampaignDetailPage(id: state.pathParameters['id']!)),
            ]),
        GoRoute(
            path: '/prospects',
            builder: (_, state) => ProspectsPage(
                campaignId: state.uri.queryParameters['campaignId']),
            routes: [
              GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      ProspectDetailPage(id: state.pathParameters['id']!)),
            ]),
        GoRoute(
            path: '/generate',
            builder: (_, __) => const GeneratePage(),
            routes: [
              GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      JobDetailPage(id: state.pathParameters['id']!)),
            ]),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(
            path: '/organizations',
            builder: (_, __) => const OrganizationPicker()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
      ]),
    ],
    errorBuilder: (context, state) => Scaffold(
        body: Center(
            child: FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Volver al inicio')))),
  );
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
  if (path == '/login' ||
      path == '/splash' ||
      path == '/session-expired' ||
      path == '/backend-unavailable') {
    return hasTenant ? '/dashboard' : '/select-tenant';
=======
  if (const ['/login', '/splash', '/session-expired', '/backend-unavailable']
      .contains(path)) {
    return !hasTenant && auth.context?.user.platformRole != 'ADMIN'
        ? '/select-tenant'
        : '/dashboard';
>>>>>>> Stashed changes
  }
  if (path == '/select-tenant' && hasTenant) return '/dashboard';
  if (!hasTenant &&
      ['/campaigns', '/prospects', '/generate', '/admin']
          .any((p) => path == p || path.startsWith('$p/'))) {
    return '/select-tenant';
  }
  return null;
}

<<<<<<< Updated upstream
bool _requiresTenant(String path) => {
      '/dashboard',
      '/campaigns',
      '/prospects',
      '/generate',
      '/jobs',
      '/users',
    }.any((root) => path == root || path.startsWith('$root/'));

=======
>>>>>>> Stashed changes
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
<<<<<<< Updated upstream
    final destinations = const [
      '/dashboard',
      '/campaigns',
      '/prospects',
      '/jobs'
    ];
=======
<<<<<<< Updated upstream
    final destinations = const ['/dashboard', '/campaigns', '/prospects'];
>>>>>>> Stashed changes
    final rawIndex = destinations.indexWhere(
        (root) => location == root || location.startsWith('$root/'));
    final index = rawIndex < 0 ? 0 : rawIndex;
    final wideLayout = MediaQuery.sizeOf(context).width >= 700;
=======
    const destinations = [
      '/dashboard',
      '/campaigns',
      '/prospects',
      '/generate'
    ];
    const labels = ['Inicio', 'Campañas', 'Prospectos', 'Prospección'];
    const icons = [
      Icons.dashboard_outlined,
      Icons.campaign_outlined,
      Icons.people_outline,
      Icons.travel_explore_outlined
    ];
    var index = destinations
        .indexWhere((p) => location == p || location.startsWith('$p/'));
    if (index < 0) index = 0;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final organization = ref.watch(currentOrganizationProvider).valueOrNull;
    final auth = ref.watch(authControllerProvider);
>>>>>>> Stashed changes
    return Scaffold(
      appBar: AppBar(
        title: TextButton.icon(
            onPressed: auth.busy ? null : () => context.go('/organizations'),
            icon: const Icon(Icons.business_outlined, size: 20),
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                  child: Text(
                      organization?['name']?.toString() ??
                          'Selecciona tu organización',
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18),
            ])),
        actions: [
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                  child: Text('BETA',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          letterSpacing: 1)))),
          PopupMenuButton<String>(
              tooltip: 'Menú de usuario',
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authControllerProvider.notifier).logout();
                } else if (context.mounted) {
                  context.go(value);
                }
              },
              itemBuilder: (_) => [
                    PopupMenuItem(
                        enabled: false,
                        child: Text(auth.context?.user.name ?? 'Mi cuenta')),
                    const PopupMenuItem(
                        value: '/profile', child: Text('Mi perfil')),
                    const PopupMenuItem(
                        value: '/organizations', child: Text('Organizaciones')),
                    const PopupMenuItem(value: '/admin', child: Text('Equipo')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'logout', child: Text('Cerrar sesión')),
                  ]),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                extended: true,
                minExtendedWidth: 208,
                selectedIndex: index,
                onDestinationSelected: (value) =>
                    context.go(destinations[value]),
<<<<<<< Updated upstream
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
<<<<<<< Updated upstream
                  NavigationRailDestination(
                      icon: Icon(Icons.work_outline), label: Text('Trabajos')),
=======
=======
                leading: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.layers_outlined, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Text('Plataforma SaaS',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ])),
                destinations: [
                  for (var i = 0; i < destinations.length; i++)
                    NavigationRailDestination(
                        icon: Icon(icons[i]), label: Text(labels[i]))
>>>>>>> Stashed changes
>>>>>>> Stashed changes
                ],
                trailing: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: TextButton.icon(
                        onPressed: () => context.go('/admin'),
                        icon: const Icon(Icons.group_outlined),
                        label: const Text('Equipo'))),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ])
          : child,
<<<<<<< Updated upstream
      drawer: Drawer(
          child: ListView(children: [
        const DrawerHeader(child: Text('Cuenta')),
        ListTile(
            title: const Text('Buscar prospectos'),
            onTap: () => context.go('/generate')),
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
=======
      bottomNavigationBar: wide
>>>>>>> Stashed changes
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => context.go(destinations[value]),
<<<<<<< Updated upstream
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                NavigationDestination(
                    icon: Icon(Icons.campaign_outlined), label: 'Campañas'),
                NavigationDestination(
                    icon: Icon(Icons.people_outline), label: 'Prospectos'),
                NavigationDestination(
                    icon: Icon(Icons.work_outline), label: 'Trabajos'),
              ],
            ),
=======
              destinations: [
                  for (var i = 0; i < destinations.length; i++)
                    NavigationDestination(
                        icon: Icon(icons[i]), label: labels[i])
                ]),
>>>>>>> Stashed changes
    );
  }
}
