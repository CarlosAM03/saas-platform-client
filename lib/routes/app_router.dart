import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_providers.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/tenants/presentation/tenants_pages.dart';
import '../features/users/presentation/users_pages.dart';
import '../features/tenants/state/tenants_providers.dart';
import '../features/auth/state/tenant_permissions.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/auth/state/auth_state.dart';
import '../features/campaigns/presentation/campaigns_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/prospects/presentation/prospects_page.dart';
import '../features/prospects/presentation/prospect_import_page.dart';
import '../features/prospecting_jobs/presentation/jobs_pages.dart';
import '../features/prospecting_jobs/presentation/generate_page.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/tenant_registration/presentation/registration_pages.dart';
import '../features/tenant_registration/presentation/activation_page.dart';
import '../features/tenant_registration/state/activation_controller.dart';

/// Scope sits inside the route Navigator: its global key must not preserve old forms.
class ScopedFeaturePage extends ConsumerWidget {
  const ScopedFeaturePage({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => KeyedSubtree(
    key: ValueKey(ref.watch(sessionScopeProvider)),
    child: child,
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  Uri? restoringLocation;
  bool activationLoginRequired = false;
  ref.listen(authControllerProvider, (_, next) {
    if (next.status == AuthStatus.loading) activationLoginRequired = false;
    refresh.value++;
  });
  GoRoute featureRoute(String path, Widget Function(GoRouterState) page) =>
      GoRoute(
        path: path,
        builder: (_, state) => ScopedFeaturePage(child: page(state)),
      );
  final router = GoRouter(
    initialLocation: ref.read(activationBootstrapProvider).isActivation
        ? '/activate'
        : '/splash',
    overridePlatformDefaultLocation: ref
        .read(activationBootstrapProvider)
        .isActivation,
    refreshListenable: refresh,
    redirect: (_, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;
      if (path == '/activate') {
        restoringLocation = null;
        return state.uri.hasQuery ? '/activate' : null;
      }
      if (path == '/login') {
        if (ref.read(activationControllerProvider).phase ==
            ActivationPhase.completed) {
          activationLoginRequired = true;
        }
        // Existing sessions survive activation; still show login after completion.
        // Normal login submission resets this exception on AuthStatus.loading.
        if (activationLoginRequired) return null;
      }
      if ((auth.status == AuthStatus.unknown ||
              auth.status == AuthStatus.loading) &&
          auth.context == null &&
          path != '/splash') {
        // Keep only the current router's internal location during restoration.
        restoringLocation ??= state.uri;
      }
      if (auth.status == AuthStatus.unauthenticated ||
          auth.status == AuthStatus.sessionExpired ||
          auth.status == AuthStatus.failure) {
        restoringLocation = null;
      }
      if (auth.status == AuthStatus.authenticated &&
          restoringLocation != null) {
        final intended = restoringLocation!;
        restoringLocation = null;
        if (path == '/splash') {
          return redirectForAuth(auth, intended.path) ?? intended.toString();
        }
      }
      return redirectForAuth(auth, path);
    },
    routes: [
      GoRoute(path: '/activate', builder: (_, __) => const ActivationPage()),
      GoRoute(path: '/organizations', redirect: (_, __) => '/change-tenant'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/select-tenant',
        builder: (_, __) => const SelectTenantPage(),
      ),
      GoRoute(
        path: '/change-tenant',
        builder: (_, __) => const SelectTenantPage(),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          featureRoute('/dashboard', (s) => const DashboardPage()),
          featureRoute('/campaigns', (s) => const CampaignsPage()),
          featureRoute('/campaigns/new', (s) => const CampaignFormPage()),
          featureRoute(
            '/campaigns/:id',
            (s) => CampaignDetailPage(s.pathParameters['id']!),
          ),
          featureRoute(
            '/campaigns/:id/edit',
            (s) => CampaignFormPage(id: s.pathParameters['id']!),
          ),
          featureRoute('/users', (s) => const UsersPage()),
          featureRoute('/users/new', (s) => const UserFormPage()),
          featureRoute(
            '/users/:id',
            (s) => UserDetailPage(s.pathParameters['id']!),
          ),
          featureRoute(
            '/users/:id/edit',
            (s) => UserFormPage(id: s.pathParameters['id']!),
          ),
          featureRoute(
            '/prospects',
            (s) =>
                ProspectsPage(campaignId: s.uri.queryParameters['campaignId']),
          ),
          featureRoute('/prospects/new', (s) => const ProspectFormPage()),
          featureRoute('/prospects/import', (s) => const ProspectImportPage()),
          featureRoute(
            '/prospects/:id',
            (s) => ProspectDetailPage(s.pathParameters['id']!),
          ),
          featureRoute(
            '/prospects/:id/edit',
            (s) => ProspectFormPage(id: s.pathParameters['id']!),
          ),
          featureRoute('/generate', (s) => const GeneratePage()),
          featureRoute('/jobs', (s) => const JobsPage()),
          featureRoute(
            '/jobs/:id',
            (s) => JobDetailPage(s.pathParameters['id']!),
          ),
          featureRoute('/profile', (s) => const ProfilePage()),
          featureRoute('/admin', (s) => const AdminPage()),
          featureRoute('/tenants', (s) => const TenantsPage()),
          featureRoute('/tenants/new', (s) => const TenantRegistrationPage()),
          featureRoute(
            '/tenants/:id/onboarding',
            (s) => TenantOnboardingPage(s.pathParameters['id']!),
          ),
          featureRoute(
            '/tenants/:id',
            (s) => TenantDetailPage(s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/session-expired',
        builder: (_, __) => const SessionExpiredPage(),
      ),
      GoRoute(
        path: '/backend-unavailable',
        builder: (_, __) => const BackendUnavailablePage(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

String? redirectForAuth(AuthState auth, String path) {
  if (path == '/activate') return null;
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
    final destinations = const [
      '/dashboard',
      '/campaigns',
      '/prospects',
      '/jobs',
    ];
    final rawIndex = destinations.indexWhere(
      (root) => location == root || location.startsWith('$root/'),
    );
    final index = rawIndex < 0 ? 0 : rawIndex;
    final wideLayout = MediaQuery.sizeOf(context).width >= 700;
    final tenantId = ref.watch(sessionScopeProvider)?.tenantId;
    final organization = tenantId == null
        ? null
        : ref.watch(tenantDetailProvider(tenantId)).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROSPECTOR'),
            if (tenantId != null)
              Text(
                organization?.name ?? 'Organización seleccionada',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar organización',
            onPressed: () => context.go('/change-tenant'),
            icon: const Icon(Icons.business_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: wideLayout
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      context.go(destinations[value]),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.campaign_outlined),
                      label: Text('Campañas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      label: Text('Prospectos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.work_outline),
                      label: Text('Trabajos'),
                    ),
                  ],
                ),
                Expanded(child: child),
              ],
            )
          : child,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Cuenta')),
            ListTile(
              title: const Text('Buscar prospectos'),
              onTap: () => context.go('/generate'),
            ),
            ListTile(
              title: const Text('Organizaciones'),
              onTap: () => context.go('/tenants'),
            ),
            ListTile(
              title: const Text('Usuarios'),
              onTap: () => context.go('/users'),
            ),
            ListTile(
              title: const Text('Perfil'),
              onTap: () => context.go('/profile'),
            ),
            ListTile(
              title: const Text('Cerrar sesión'),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wideLayout
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => context.go(destinations[value]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  label: 'Campañas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'Prospectos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.work_outline),
                  label: 'Trabajos',
                ),
              ],
            ),
    );
  }
}
