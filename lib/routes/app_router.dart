import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_providers.dart';
import '../core/theme/catalog_palette.dart';
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
import '../features/prospecting_jobs/presentation/batch_pages.dart';
import '../features/prospecting_jobs/state/batch_providers.dart';

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
          featureRoute(
            '/jobs',
            (s) => prospectingBatchEnabled
                ? const BatchHistoryPage()
                : const JobsPage(),
          ),
          featureRoute(
            '/jobs/:id',
            (s) => prospectingBatchEnabled
                ? BatchDetailPage(s.pathParameters['id']!)
                : JobDetailPage(s.pathParameters['id']!),
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

  static const _dashboard = (
    path: '/dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
  );
  static const _campaigns = (
    path: '/campaigns',
    label: 'Campañas',
    icon: Icons.campaign_outlined,
  );
  static const _prospects = (
    path: '/prospects',
    label: 'Prospectos',
    icon: Icons.people_outline,
  );

  static const _selectionShape = RoundedRectangleBorder(
    side: BorderSide(color: CatalogPalette.outlineStrong),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final canUseProspecting = ref
        .watch(currentTenantPermissionsProvider)
        .asData
        ?.value
        .canCreateProspects;
    final destinations = [
      _dashboard,
      _campaigns,
      _prospects,
      if (!prospectingBatchEnabled || canUseProspecting == true)
        (
          path: '/jobs',
          label: prospectingBatchEnabled ? 'Lotes' : 'Trabajos',
          icon: Icons.work_outline,
        ),
    ];
    final rawIndex = destinations.indexWhere(
      (destination) =>
          location == destination.path ||
          location.startsWith('${destination.path}/'),
    );
    final index = rawIndex < 0 ? 0 : rawIndex;
    final wideLayout = MediaQuery.sizeOf(context).width >= 700;
    final tenantId = ref.watch(sessionScopeProvider)?.tenantId;
    final organization = tenantId == null
        ? null
        : ref.watch(tenantDetailProvider(tenantId)).asData?.value;
    final organizationName = tenantId == null
        ? null
        : organization?.name ?? 'Organización seleccionada';

    void navigate(int destinationIndex) =>
        context.go(destinations[destinationIndex].path);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CatalogPalette.cobalt,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: CatalogPalette.cobaltDark),
        ),
        toolbarHeight: 64,
        leadingWidth: 48,
        titleSpacing: 6,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: CatalogPalette.lime,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(2, 2),
                    color: CatalogPalette.cobaltDark,
                  ),
                ],
              ),
              child: const Icon(
                Icons.grid_on_rounded,
                size: 17,
                color: CatalogPalette.cobaltDark,
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROSPECTOR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.15,
                    ),
                  ),
                  if (!wideLayout && organizationName != null)
                    Text(
                      organizationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (wideLayout && organizationName != null)
            Tooltip(
              message: 'Cambiar organización',
              child: TextButton.icon(
                onPressed: () => context.go('/change-tenant'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.business_outlined, size: 19),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    organizationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
          else
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
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CatalogPalette.outline),
                    ),
                  ),
                  child: NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: navigate,
                    extended: true,
                    scrollable: true,
                    labelType: NavigationRailLabelType.none,
                    minWidth: 56,
                    minExtendedWidth: 156,
                    backgroundColor: CatalogPalette.rail,
                    useIndicator: true,
                    indicatorColor: CatalogPalette.lime,
                    indicatorShape: _selectionShape,
                    selectedIconTheme: const IconThemeData(
                      color: CatalogPalette.cobaltDark,
                      size: 20,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      color: CatalogPalette.muted,
                      size: 20,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: CatalogPalette.cobaltDark,
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: CatalogPalette.ink,
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            )
          : child,
      drawer: Drawer(
        backgroundColor: CatalogPalette.rail,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: CatalogPalette.cobalt),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (canUseProspecting == true) ...[
              ListTile(
                leading: const Icon(Icons.travel_explore),
                title: const Text('Buscar prospectos'),
                onTap: () => context.go('/generate'),
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(prospectingBatchEnabled ? 'Lotes' : 'Trabajos'),
                onTap: () => context.go('/jobs'),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Organizaciones'),
              onTap: () => context.go('/tenants'),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Usuarios'),
              onTap: () => context.go('/users'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () => context.go('/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wideLayout
          ? null
          : DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CatalogPalette.outline)),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 11,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: CatalogPalette.ink,
                    ),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      size: 20,
                      color: states.contains(WidgetState.selected)
                          ? CatalogPalette.cobaltDark
                          : CatalogPalette.muted,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: navigate,
                  height: 64,
                  backgroundColor: CatalogPalette.rail,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: CatalogPalette.lime,
                  indicatorShape: _selectionShape,
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
