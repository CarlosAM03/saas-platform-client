import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
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
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';
import 'platform_api/fixtures.dart' show dates, userJson;
import 'package:saas_platform_client/shared/models/api_models.dart';
import 'foundation_auth_test.dart' show MemoryTokenStorage, contextFor;
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';

final campaignFixture = <String, dynamic>{
  'id': 'c1',
  'name': 'Campaña verano 2026',
  'description': 'Conecta con nuevos negocios y organiza tus oportunidades.',
  'createdBy': 'user-1',
  'status': 'ACTIVA',
  'createdAt': '2026-09-01T12:00:00Z',
  'updatedAt': '2026-10-05T12:00:00Z',
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
  'campaignId': 'c1',
  'source': 'manual',
  'status': 'ACTIVO',
  'metadata': null,
  'createdAt': '2026-09-01T12:00:00Z',
  'updatedAt': '2026-10-05T12:00:00Z',
};
final organizationFixture = <String, dynamic>{
  'id': 'tenant-1',
  'name': 'ACME Marketing',
  'slug': 'acme-marketing',
  'status': 'ACTIVO',
  ...dates,
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
        currentTenantId: tenantId,
      ),
    );
  }
}

class BetaTestRepository implements HttpClientAdapter {
  String? createdResource;
  Map<String, dynamic>? createdData, updatedData;
  bool archived = false;
  Object? listError;
  final listed = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    final parts = request.path.split('/').where((v) => v.isNotEmpty).toList();
    final resource = parts[2];
    Object data = {};
    Map<String, dynamic>? meta;
    var status = 200;
    if (request.method == 'POST') {
      createdResource = resource;
      createdData = Map<String, dynamic>.from(request.data as Map);
      data = {...campaignFixture, ...createdData!};
    } else if (request.method == 'PATCH') {
      updatedData = Map<String, dynamic>.from(request.data as Map);
      data = {...prospectFixture, ...updatedData!};
    } else if (request.method == 'DELETE') {
      archived = true;
    } else if (parts.length == 3 && resource == 'tenants') {
      data = [organizationFixture];
    } else if (parts.length == 3 ||
        parts.last == 'prospects' && resource == 'campaigns') {
      listed.add(resource);
      if (listError != null) {
        status = 503;
      } else {
        data = resource == 'campaigns' && parts.length == 3
            ? [campaignFixture]
            : resource == 'prospects' || parts.last == 'prospects'
            ? [prospectFixture]
            : [];
        meta = {
          'page': 1,
          'limit': 20,
          'total': resource == 'campaigns'
              ? 12
              : resource == 'prospects'
              ? 1240
              : 0,
          'totalPages': 2,
        };
      }
    } else {
      data = switch (resource) {
        'tenants' => organizationFixture,
        'campaigns' => {
          ...campaignFixture,
          if (archived) 'status': 'ARCHIVADA',
        },
        'prospects' => {...prospectFixture, ...?updatedData},
        'users' => {...userJson, 'id': 'user-1'},
        _ => {},
      };
    }
    return ResponseBody.fromString(
      jsonEncode(
        status == 200
            ? {'success': true, 'data': data, if (meta != null) 'meta': meta}
            : {
                'success': false,
                'error': {'code': 'HTTP_503', 'message': 'offline'},
              },
      ),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> mount(
  WidgetTester tester,
  BetaTestRepository repo, {
  Size size = const Size(1280, 900),
  AuthState? auth,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => BetaTestAuth(
            auth ??
                AuthState(
                  status: AuthStatus.authenticated,
                  context: contextFor(
                    tenantId: 'tenant-1',
                    platformRole: 'ADMIN',
                  ),
                ),
          ),
        ),
        apiClientProvider.overrideWithValue(
          ApiClient(
            config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
            storage: MemoryTokenStorage(token: 'test'),
            dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
              ..httpClientAdapter = repo,
          ),
        ),
        secureTokenStorageProvider.overrideWithValue(
          MemoryTokenStorage(token: 'test'),
        ),
      ],
      child: const RepaintBoundary(
        key: ValueKey('beta-screenshot'),
        child: SaasPlatformApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void navigate(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('BETA_SCREENSHOTS')) return;
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('beta-screenshot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory('build/beta-qa').create(recursive: true);
    await File(
      'build/beta-qa/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets(
    'campaign-scoped prospect links retain typed filtering and can return to all prospects',
    (tester) async {
      final repo = BetaTestRepository();
      await mount(tester, repo);
      navigate(tester, '/prospects?campaignId=c1');
      await tester.pumpAndSettle();
      expect(find.text('Prospectos de la campaña'), findsOneWidget);
      expect(find.text('Estudio Norte'), findsOneWidget);
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();
      expect(find.text('Prospectos de la campaña'), findsNothing);
      expect(find.text('Estudio Norte'), findsOneWidget);
    },
  );
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
      expect(find.text('Prospectos').last, findsOneWidget);
      await screenshot(tester, 'campaign-detail-desktop');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('mobile dashboard and login fit without overflow', (
    tester,
  ) async {
    final repo = BetaTestRepository();
    await mount(tester, repo, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    await screenshot(tester, 'dashboard-mobile');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(
      tester,
      repo,
      size: const Size(390, 844),
      auth: const AuthState(status: AuthStatus.unauthenticated),
    );
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
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Campaña beta');
      await tester.enterText(
        find.byType(TextFormField).last,
        'Objetivo de prueba',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repo.createdData, isNull);
      await screenshot(tester, 'campaign-confirmation-desktop');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(repo.createdResource, 'campaigns');
      expect(repo.createdData, {
        'name': 'Campaña beta',
        'description': 'Objetivo de prueba',
      });
      expect(find.text('Prospectos').last, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'prospect editor clears nullable email with null and preserves other fields',
    (tester) async {
      final repo = BetaTestRepository();
      await mount(tester, repo);
      navigate(tester, '/prospects/p1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar prospecto'));
      await tester.pumpAndSettle();
      final email = find.widgetWithText(TextFormField, 'Correo electrónico');
      await tester.enterText(email, '');
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repo.updatedData, {'email': null});
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('archiving requires confirmation and refreshes detail', (
    tester,
  ) async {
    final repo = BetaTestRepository();
    await mount(tester, repo);
    navigate(tester, '/campaigns/c1');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Archivar campaña'));
    await tester.tap(find.text('Archivar campaña'));
    await tester.pumpAndSettle();
    expect(repo.archived, isFalse);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(repo.archived, isTrue);
    expect(find.text('ARCHIVADA'), findsOneWidget);
  });
  testWidgets('unavailable generation is explicit and does not create a job', (
    tester,
  ) async {
    final repo = BetaTestRepository();
    await mount(tester, repo, size: const Size(390, 844));
    navigate(tester, '/generate');
    await tester.pumpAndSettle();
    expect(find.text('Generación automática no disponible'), findsOneWidget);
    expect(repo.createdResource, isNull);
    await screenshot(tester, 'prospecting-mobile');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'failed list can retry successfully without replacing the session',
    (tester) async {
      final repo = BetaTestRepository()
        ..listError = const ApiException(
          kind: ApiErrorKind.network,
          message: 'offline',
        );
      await mount(tester, repo);
      expect(find.text('Reintentar'), findsOneWidget);
      repo.listError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Campaña verano 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'organization switch updates context and clears cached campaign data',
    (tester) async {
      final repo = BetaTestRepository();
      await mount(
        tester,
        repo,
        auth: AuthState(
          status: AuthStatus.authenticated,
          context: contextFor(platformRole: 'ADMIN', tenants: []),
        ),
      );
      expect(repo.listed, isEmpty);

      await tester.tap(find.text('ACME Marketing'));
      await tester.pumpAndSettle();
      expect(repo.listed, contains('campaigns'));
      expect(find.text('1240'), findsOneWidget);
    },
  );
}
