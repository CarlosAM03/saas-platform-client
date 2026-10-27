import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saas_platform_client/app/app.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/workspace/data/platform_repository.dart';
import 'package:saas_platform_client/shared/models/api_models.dart';
import 'foundation_auth_test.dart' show MemoryTokenStorage, contextFor;
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';

final campaignFixture = <String, dynamic>{
  'id': 'c1',
  'name': 'Campaña verano 2026',
  'description': 'Conecta con nuevos negocios y organiza tus oportunidades.',
  'status': 'ACTIVA',
  'createdAt': '2026-09-01T12:00:00Z',
  'updatedAt': '2026-10-05T12:00:00Z'
};
final prospectFixture = <String, dynamic>{
  'id': 'p1',
  'name': 'Estudio Norte',
  'email': 'hola@norte.test',
  'phone': '664 555 0101',
  'category': 'Servicios profesionales',
  'address': 'Tijuana, México',
  'website': 'https://norte.test',
  'language': 'es',
  'source': 'MANUAL',
  'status': 'ACTIVO',
  'metadata': null,
  'createdAt': '2026-09-01T12:00:00Z',
  'updatedAt': '2026-10-05T12:00:00Z'
};
final organizationFixture = <String, dynamic>{
  'id': 'tenant-1',
  'name': 'ACME Marketing',
  'slug': 'acme-marketing',
  'status': 'ACTIVO'
};

class BetaTestAuth extends AuthController {
  BetaTestAuth(this.initial);
  final AuthState initial;
  @override
  AuthState build() => initial;
  @override
  Future<void> selectTenant(String tenantId) async {
    final current = state.context!;
    state = AuthState(
        status: AuthStatus.authenticated,
        context: AuthContext(
            accessToken: current.accessToken,
            user: current.user,
            tenants: current.tenants,
            currentTenantId: tenantId));
  }
}

class BetaTestRepository extends PlatformRepository {
  BetaTestRepository()
      : super(ApiClient(
            config: const AppConfig(apiBaseUrl: 'http://localhost'),
            storage: MemoryTokenStorage()));
  String? createdResource;
  Json? createdData, updatedData;
  bool archived = false;
  Object? listError;
  final listed = <String>[];
  @override
  Future<List<Json>> organizations() async => [organizationFixture];
  @override
  Future<PageResult> list(String resource, ListQuery query,
      {int limit = 20}) async {
    listed.add(resource);
    if (listError != null) throw listError!;
    return PageResult(
        resource == 'campaigns'
            ? [campaignFixture]
            : resource == 'prospects' || resource.endsWith('/prospects')
                ? [prospectFixture]
                : [],
        PaginationMeta(
            page: 1,
            limit: limit,
            total: resource == 'campaigns'
                ? 12
                : resource.contains('prospects')
                    ? 1240
                    : 0,
            totalPages: resource == 'campaigns'
                ? 2
                : resource.contains('prospects')
                    ? 62
                    : 0));
  }

  @override
  Future<Json> detail(String resource, String id) async => switch (resource) {
        'tenants' => organizationFixture,
        'campaigns' => {
            ...campaignFixture,
            if (archived) 'status': 'ARCHIVADA'
          },
        'prospects' => {...prospectFixture, ...?updatedData},
        'users' => {
            'id': 'user-1',
            'role': {'name': 'OWNER'}
          },
        _ => {},
      };
  @override
  Future<Json> create(String resource, Json data) async {
    createdResource = resource;
    createdData = data;
    return {...campaignFixture, ...data};
  }

  @override
  Future<Json> update(String resource, String id, Json data) async {
    updatedData = data;
    return {...prospectFixture, ...data};
  }

  @override
  Future<void> archiveCampaign(String id, {bool permanent = false}) async {
    archived = true;
  }
}

Future<void> mount(WidgetTester tester, BetaTestRepository repo,
    {Size size = const Size(1280, 900), AuthState? auth}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => BetaTestAuth(auth ??
            AuthState(
                status: AuthStatus.authenticated,
                context:
                    contextFor(tenantId: 'tenant-1', platformRole: 'ADMIN')))),
        platformRepositoryProvider.overrideWithValue(repo),
      ],
      child: const RepaintBoundary(
          key: ValueKey('beta-screenshot'), child: SaasPlatformApp())));
  await tester.pumpAndSettle();
}

void navigate(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('BETA_SCREENSHOTS')) return;
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('beta-screenshot')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory('build/beta-qa').create(recursive: true);
    await File('build/beta-qa/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets(
      'desktop dashboard shows real totals, organization and campaign detail link',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo);
    expect(find.text('ACME Marketing'), findsOneWidget);
    expect(find.text('1240'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    await screenshot(tester, 'dashboard-desktop');
    await tester.tap(find.text('Ver detalles'));
    await tester.pumpAndSettle();
    expect(find.text('Prospectos asociados'), findsOneWidget);
    await screenshot(tester, 'campaign-detail-desktop');
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile dashboard and login fit without overflow',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    await screenshot(tester, 'dashboard-mobile');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, repo,
        size: const Size(390, 844),
        auth: const AuthState(status: AuthStatus.unauthenticated));
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Regístrate'), findsNothing);
    await screenshot(tester, 'login-mobile');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Introduce un correo válido.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'campaign creation validates and sends only supported fields after confirmation',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo);
    navigate(tester, '/campaigns/new');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Completa este campo.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Campaña beta');
    await tester.enterText(
        find.byType(TextFormField).last, 'Objetivo de prueba');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(repo.createdData, isNull);
    await screenshot(tester, 'campaign-confirmation-desktop');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear campaña'));
    await tester.pumpAndSettle();
    expect(repo.createdResource, 'campaigns');
    expect(repo.createdData,
        {'name': 'Campaña beta', 'description': 'Objetivo de prueba'});
    expect(find.text('Prospectos asociados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'prospect editor clears nullable email with null and preserves other fields',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo);
    navigate(tester, '/prospects/p1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    final email = find.widgetWithText(TextFormField, 'Correo');
    await tester.enterText(email, '');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.updatedData, {'email': null});
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('archiving requires confirmation and refreshes detail',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo);
    navigate(tester, '/campaigns/c1');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Archivar'));
    await tester.tap(find.text('Archivar'));
    await tester.pumpAndSettle();
    expect(repo.archived, isFalse);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(repo.archived, isTrue);
    expect(find.text('Archivada'), findsOneWidget);
  });
  testWidgets('unavailable generation is explicit and does not create a job',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo, size: const Size(390, 844));
    navigate(tester, '/generate');
    await tester.pumpAndSettle();
    expect(find.text('Generación automática próximamente'), findsOneWidget);
    expect(repo.createdResource, isNull);
    await screenshot(tester, 'prospecting-mobile');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'failed list can retry successfully without replacing the session',
      (tester) async {
    final repo = BetaTestRepository()
      ..listError =
          const ApiException(kind: ApiErrorKind.network, message: 'offline');
    await mount(tester, repo);
    expect(find.text('Reintentar'), findsOneWidget);
    repo.listError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Campaña verano 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'organization switch updates context and clears cached campaign data',
      (tester) async {
    final repo = BetaTestRepository();
    await mount(tester, repo,
        auth: AuthState(
            status: AuthStatus.authenticated,
            context: contextFor(platformRole: 'ADMIN')));
    expect(repo.listed, isEmpty);
    await tester.tap(find.text('Elegir organización'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACME Marketing'));
    await tester.pumpAndSettle();
    expect(repo.listed, contains('campaigns'));
    expect(find.text('1240'), findsOneWidget);
  });
}
