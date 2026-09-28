import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_providers.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/auth/state/auth_state.dart';
import '../features/campaigns/presentation/campaigns_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/prospects/presentation/prospects_page.dart';
import '../features/prospecting_jobs/presentation/generate_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => redirectForAuth(auth, state.uri.path),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/select-tenant', builder: (_, __) => const SelectTenantPage()),
      ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
        GoRoute(path: '/campaigns', builder: (_, __) => const CampaignsPage()),
        GoRoute(path: '/prospects', builder: (_, __) => const ProspectsPage()),
        GoRoute(path: '/generate', builder: (_, __) => const GeneratePage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
      ]),
      GoRoute(path: '/session-expired', builder: (_, __) => const SessionExpiredPage()),
      GoRoute(path: '/backend-unavailable', builder: (_, __) => const BackendUnavailablePage()),
    ],
  );
});

String? redirectForAuth(AuthState auth, String path) {
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
  if (path == '/login' || path == '/splash' || path == '/session-expired' || path == '/backend-unavailable') {
    return !hasTenant && auth.context?.user.platformRole != 'ADMIN' ? '/select-tenant' : '/dashboard';
  }
  if (path == '/select-tenant' && hasTenant) return '/dashboard';
  if (!hasTenant && _requiresTenant(path)) return '/select-tenant';
  return null;
}

bool _requiresTenant(String path) => {'/campaigns', '/prospects', '/generate'}.contains(path);

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final destinations = const ['/dashboard', '/campaigns', '/prospects', '/generate'];
    final rawIndex = destinations.indexOf(location);
    final index = rawIndex < 0 ? 0 : rawIndex;
    final wideLayout = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(title: const Text('SaaS Platform')),
      body: wideLayout
          ? Row(children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (value) => context.go(destinations[value]),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.campaign_outlined), label: Text('Campañas')),
                  NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('Prospectos')),
                  NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), label: Text('Generar')),
                ],
              ),
              Expanded(child: child),
            ])
          : child,
      drawer: Drawer(child: ListView(children: [
        const DrawerHeader(child: Text('Cuenta')),
        ListTile(title: const Text('Perfil'), onTap: () => context.go('/profile')),
        ListTile(title: const Text('Administración'), onTap: () => context.go('/admin')),
        ListTile(title: const Text('Cerrar sesión'), onTap: () => ref.read(authControllerProvider.notifier).logout()),
      ])),
      bottomNavigationBar: wideLayout ? null : NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(destinations[value]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Campañas'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Prospectos'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Generar'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Dashboard'));
}
