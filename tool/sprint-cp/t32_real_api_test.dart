import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaign_prospects_panel.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaign_dashboard_panel.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaigns_page.dart';
import 'package:saas_platform_client/features/campaigns/presentation/participation_panel.dart';
import 'package:saas_platform_client/features/campaigns/state/participation_providers.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospects_page.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospect_import_page.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospect_context_panel.dart';
import 'package:saas_platform_client/platform_api/campaign_participation_api.dart';
import 'package:saas_platform_client/platform_api/prospect_context_api.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/shared/services/file_service.dart';
import '../../test/platform_api/fixtures.dart' show TestTokenStorage;

class RealHttp extends HttpOverrides {}

class LiveAuth extends AuthController {
  LiveAuth(this.context);
  final AuthContext context;
  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, context: context);
  void replace(AuthContext value) =>
      state = AuthState(status: AuthStatus.authenticated, context: value);
}

// Only the operating-system file chooser is replaced with an explicit synthetic file.
// Every repository, request, authorization check, transaction and response is real.
class SyntheticCsvPicker implements FileService {
  SyntheticCsvPicker(this.name);
  final String name;
  @override
  Future<ApiUploadFile?> pickCsv() async => ApiUploadFile(
    filename: 'synthetic-t32.csv',
    bytes: Uint8List.fromList(
      utf8.encode('name,category\n$name CSV,Cafe\n$name CSV Two,Cafe\n'),
    ),
  );
  @override
  Future<bool> save(String filename, List<int> bytes) async => false;
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw StateError('T32 widget condition did not become visible: $finder');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<T> real<T>(WidgetTester tester, Future<T> Function() action) async {
  var done = false;
  T? result;
  Object? failure;
  StackTrace? trace;
  action().then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object error, StackTrace stack) {
      failure = error;
      trace = stack;
      done = true;
    },
  );
  for (var i = 0; !done && i < 400; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (!done) throw StateError('T32 real HTTP did not complete');
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return result as T;
}

void main() {
  const enabled = bool.fromEnvironment('CP_REAL_API');
  testWidgets(
    'T32 real Flutter widgets -> NestJS -> PostgreSQL16, synthetic fixtures',
    (tester) async {
      final env = {
        for (final line in File(
          'codex/frontend-cp/.local/lab.env',
        ).readAsLinesSync())
          line.split('=').first: line.substring(line.indexOf('=') + 1),
      };
      final backendSha = File(
        'codex/frontend-cp/.local/backend-sha.txt',
      ).readAsStringSync().trim();
      expect(backendSha, '779fc7885faefdfe9e3cb0f3fee86810d96d2711');
      final font = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
      await real(tester, font.load);
      final storage = TestTokenStorage(token: null);
      final requests = <Map<String, Object?>>[];
      final receiptDirectory = Directory('codex/frontend-cp/.local/recibos');
      const filterKeys = ['stage', 'responsibleId', 'evaluation', 'page'];
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:18741'))
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => RealHttp().createHttpClient(null),
        );
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (r, h) {
            requests.add({
              'method': r.requestOptions.method,
              'path': r.requestOptions.uri.path,
              if (r.requestOptions.uri.path.endsWith('/prospects'))
                'filters': {
                  for (final key in filterKeys)
                    if (r.requestOptions.uri.queryParameters.containsKey(key))
                      key: r.requestOptions.uri.queryParameters[key],
                },
              'status': r.statusCode,
            });
            h.next(r);
          },
          onError: (e, h) {
            requests.add({
              'method': e.requestOptions.method,
              'path': e.requestOptions.uri.path,
              'status': e.response?.statusCode,
            });
            h.next(e);
          },
        ),
      );
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'http://127.0.0.1:18741'),
        storage: storage,
        dio: dio,
      );
      final api = PlatformApi(client);
      final cp = CampaignParticipationApi(client);
      final contextApi = ProspectContextApi(client);
      final runId = 'Synthetic T32 ${DateTime.now().microsecondsSinceEpoch}';
      var displayedName = '$runId Manual';
      final cases = <Map<String, Object?>>[];
      var completed = false;
      void passed(String id, String observed) {
        cases.add({
          'id': id,
          'expected': observed,
          'observed': observed,
          'status': 'PASS',
        });
        debugPrint('T32 completed: $id');
      }

      final owner = (await real(tester, () async {
        final login = await api.auth.login(
          LoginRequest(
            email: 'owner.demo-norte@demo.example',
            password: env['CP_SEED_PASSWORD']!,
          ),
        );
        await storage.writeToken(login.accessToken);
        final selected = await api.auth.selectTenant(
          const SelectTenantRequest(tenantId: 'demo-tenant-norte'),
        );
        await storage.writeToken(selected.accessToken);
        return selected;
      }));
      final campaign = (await real(
        tester,
        () => api.campaigns.create(CreateCampaignRequest(name: runId)),
      ));
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          authControllerProvider.overrideWith(() => LiveAuth(owner)),
          fileServiceProvider.overrideWithValue(SyntheticCsvPicker(runId)),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> mount(Widget page) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(fontFamily: 'Inter'),
              home: Scaffold(
                body: RepaintBoundary(
                  key: const ValueKey('t32-frame'),
                  child: Material(color: Colors.white, child: page),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      Future<void> capture(String name) async {
        await settle(tester);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('t32-frame')),
        );
        final bytes = await real(tester, () async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return data!;
        });
        receiptDirectory.createSync(recursive: true);
        File(
          '${receiptDirectory.path}/$name.png',
        ).writeAsBytesSync(bytes.buffer.asUint8List());
      }

      try {
        await mount(ProspectFormPage(onSaved: () {}));
        await waitFor(tester, find.text('Seleccionar campaña'));
        await tap(tester, find.text('Seleccionar campaña'));
        await waitFor(tester, find.byTooltip('Buscar'));
        await tester.enterText(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextField),
              )
              .first,
          runId,
        );
        await tap(tester, find.byTooltip('Buscar'));
        await waitFor(tester, find.widgetWithText(ListTile, runId));
        await tap(tester, find.widgetWithText(ListTile, runId));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre'),
          '$runId Manual',
        );
        await tap(tester, find.text('Guardar'));
        await waitFor(tester, find.text('Verificación de coincidencias'));
        await tap(tester, find.text('Crear prospecto').last);
        await waitFor(tester, find.text('Guardar'));
        final prospects = (await real(
          tester,
          () => api.campaigns.prospects(campaign.id),
        ));
        final prospect = prospects.items.single;
        passed(
          'T32-P1',
          'UI match and explicit create persisted one manual prospect',
        );

        final key = (campaign: campaign.id, prospect: prospect.id);
        await mount(ParticipationPanel(key));
        await waitFor(tester, find.text('Etapa comercial: Sin gestionar'));
        await tap(tester, find.byType(DropdownButton<CommercialStage>));
        await settle(tester);
        await tap(tester, find.text('Contactado').last);
        await waitFor(tester, find.text('Etapa comercial: Contactado'));
        expect(
          (await real(tester, () => cp.get(campaign.id, prospect.id))).stage,
          CommercialStage.CONTACTADO,
        );
        passed('T32-C1', 'UI stage update persisted CONTACTADO');

        await tap(tester, find.text('Cambiar evaluación'));
        await settle(tester);
        await tap(tester, find.byType(DropdownButtonFormField<String>));
        await settle(tester);
        await tap(tester, find.text('NO_APTO').last);
        await tap(tester, find.text('Guardar'));
        await waitFor(tester, find.textContaining('VALIDATION_ERROR'));
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Motivo (obligatorio para NO_APTO)',
          ),
          'Synthetic qualification',
        );
        await tap(tester, find.text('Guardar'));
        await waitFor(tester, find.text('Evaluación: NO_APTO'));
        passed(
          'T32-C2',
          'UI displays real 400 then persists NO_APTO with a reason',
        );

        final eligible = (await real(
          tester,
          () => cp.responsibles(campaign.id, prospect.id),
        )).first;
        await tap(tester, find.byType(DropdownButton<String>));
        await settle(tester);
        await tap(tester, find.text(eligible.name).last);
        await waitFor(tester, find.text('Responsable: ${eligible.name}'));
        expect(
          (await real(
            tester,
            () => cp.get(campaign.id, prospect.id),
          )).responsibleId,
          eligible.id,
        );
        await tap(tester, find.byType(DropdownButton<String>));
        await settle(tester);
        await tap(tester, find.text('Sin asignar').last);
        await waitFor(tester, find.text('Responsable: Sin asignar'));
        expect(
          (await real(
            tester,
            () => cp.get(campaign.id, prospect.id),
          )).responsibleId,
          isNull,
        );
        passed(
          'T32-C4',
          'UI assigns an eligible member with PUT and unassigns with DELETE',
        );

        await tap(tester, find.text('Registrar actividad'));
        await settle(tester);
        await tap(tester, find.byType(DropdownButtonFormField<String>));
        await settle(tester);
        await tap(tester, find.text('CALL').last);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contenido'),
          'Synthetic call recorded',
        );
        await tap(tester, find.text('Guardar'));
        await waitFor(
          tester,
          find.descendant(
            of: find.byType(ListTile),
            matching: find.textContaining('Synthetic call recorded'),
          ),
        );
        await tap(tester, find.text('Corregir').first);
        await settle(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contenido'),
          'Synthetic correction',
        );
        await tap(tester, find.text('Guardar'));
        await waitFor(
          tester,
          find.descendant(
            of: find.byType(ListTile),
            matching: find.textContaining('Synthetic correction'),
          ),
        );
        final activities = (await real(
          tester,
          () => cp.activities(campaign.id, prospect.id),
        ));
        expect(
          activities.items.where((e) => e.content == 'Synthetic call recorded'),
          hasLength(1),
        );
        expect(
          activities.items
              .singleWhere((e) => e.content == 'Synthetic correction')
              .isManual,
          true,
        );
        passed(
          'T32-C3',
          'UI correction appends a manual event and preserves the original',
        );
        await capture('participacion');
        await tap(tester, find.text('Editar maestro compartido'));
        await waitFor(tester, find.widgetWithText(TextFormField, 'Nombre'));
        displayedName = '$runId Renamed';
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre'),
          displayedName,
        );
        await tap(tester, find.text('Guardar'));
        await tap(tester, find.text('Confirmar').last);
        await waitFor(tester, find.text('Editar maestro compartido'));
        expect(
          (await real(
            tester,
            () => contextApi.provenance(prospect.id, 1),
          )).items.any(
            (e) =>
                e.type == ProvenanceType.masterUpdated &&
                e.campaignId == campaign.id,
          ),
          true,
        );
        passed(
          'T32-P3-EDIT',
          'UI warns about shared master edits and persists MASTER_UPDATED in the current campaign',
        );

        await mount(ProspectImportPage());
        await waitFor(tester, find.text('Seleccionar campaña'));
        await tap(tester, find.text('Seleccionar campaña'));
        await waitFor(tester, find.byTooltip('Buscar'));
        await tester.enterText(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextField),
              )
              .first,
          runId,
        );
        await tap(tester, find.byTooltip('Buscar'));
        await waitFor(tester, find.widgetWithText(ListTile, runId));
        await tap(tester, find.widgetWithText(ListTile, runId));
        await tap(tester, find.text('Seleccionar CSV'));
        await waitFor(tester, find.text('synthetic-t32.csv'));
        await tap(tester, find.text('Generar vista previa'));
        await waitFor(tester, find.textContaining('2 filas'));
        expect(
          (await real(
            tester,
            () => api.campaigns.prospects(campaign.id),
          )).meta.total,
          1,
        );
        await tap(tester, find.text('Confirmar importación'));
        await settle(tester);
        await tap(tester, find.text('Importar ahora'));
        await waitFor(tester, find.text('Importación terminada'));
        expect(
          (await real(
            tester,
            () => api.campaigns.prospects(campaign.id),
          )).meta.total,
          3,
        );
        passed(
          'T32-P4',
          'UI preview writes nothing; UI confirmation persists two CSV rows',
        );
        await capture('importacion');

        await mount(CampaignDashboardPanel(campaign.id));
        container.invalidate(campaignDashboardProvider(campaign.id));
        await waitFor(tester, find.text('Total de participaciones: 3'));
        final summary = (await real(tester, () => cp.dashboard(campaign.id)));
        expect(summary.activityTotal, summary.manual + summary.events);
        expect(summary.manual, 2);
        passed(
          'T32-C8',
          'UI renders one server snapshot with two manual activities including correction',
        );
        await capture('resumen');
        await mount(CampaignDetailPage(campaign.id));
        await waitFor(tester, find.text('Resumen comercial'));
        for (final (action, parameter, value, chip, count) in [
          ('Contactado', 'stage', 'CONTACTADO', 'Contactado', 1),
          (
            'Asignar responsables',
            'responsibleId',
            'UNASSIGNED',
            'Sin responsable',
            summary.responsibility['SIN_ASIGNAR']!,
          ),
          (
            'Revisar prospectos sin evaluar',
            'evaluation',
            'SIN_EVALUAR',
            'Sin evaluar',
            summary.evaluations['SIN_EVALUAR']!,
          ),
        ]) {
          await tap(tester, find.text('Resumen comercial'));
          await waitFor(tester, find.text('Total de participaciones: 3'));
          final target = find.text(action).first;
          await tester.ensureVisible(target);
          await tap(tester, target);
          await waitFor(tester, find.widgetWithText(Chip, chip));
          await waitFor(tester, find.text('Página 1 · $count registros'));
          expect(
            requests.lastWhere(
              (request) =>
                  request['path'] ==
                  '/api/v1/campaigns/${campaign.id}/prospects',
            )['filters'],
            {'page': '1', parameter: value},
          );
        }
        passed(
          'T32-C8-FILTERS',
          'Summary drills down into stage, responsibility and evaluation using page one and real server counts',
        );
        expect(
          (await real(
            tester,
            () => contextApi.campaigns(prospect.id, 1),
          )).items.single.isOrigin,
          true,
        );
        expect(
          (await real(
            tester,
            () => contextApi.provenance(prospect.id, 1),
          )).items,
          isNotEmpty,
        );
        passed(
          'T32-P2-P3',
          'Real contextual campaigns and provenance responses parse successfully',
        );
        await mount(
          SingleChildScrollView(child: ProspectContextPanel(prospect.id)),
        );
        await waitFor(tester, find.text('MASTER_UPDATED'));
        await waitFor(tester, find.text('$runId · Origen'));

        final member = (await real(tester, () async {
          final login = await api.auth.login(
            LoginRequest(
              email: 'member.demo-norte@demo.example',
              password: env['CP_SEED_PASSWORD']!,
            ),
          );
          await storage.writeToken(login.accessToken);
          final selected = await api.auth.selectTenant(
            const SelectTenantRequest(tenantId: 'demo-tenant-norte'),
          );
          await storage.writeToken(selected.accessToken);
          return selected;
        }));
        (container.read(authControllerProvider.notifier) as LiveAuth).replace(
          member,
        );
        await mount(CampaignProspectsPanel(campaign.id));
        await waitFor(tester, find.text(displayedName));
        expect(find.text('Nuevo prospecto'), findsNothing);
        expect(find.text('Importar CSV'), findsNothing);
        await tap(tester, find.text('Filtrar prospectos'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Nombre o correo'),
          displayedName,
        );
        await tap(tester, find.text('Aplicar filtros'));
        await waitFor(tester, find.text('Página 1 · 1 registros'));
        passed(
          'T32-C6',
          'UI filter requests the server and renders one matching participation',
        );
        await real(
          tester,
          () => expectLater(
            contextApi.create(
              ProspectIntakeRequest(
                CreateProspectRequest(
                  campaignId: campaign.id,
                  name: '$runId Forbidden',
                ),
              ),
            ),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 403),
            ),
          ),
        );
        passed(
          'T32-ROLES',
          'MEMBER has no create/import actions and API rejects creation with 403',
        );
        final forbiddenFile = await SyntheticCsvPicker(runId).pickCsv();
        await real(
          tester,
          () => expectLater(
            api.prospects.previewImport(
              campaignId: campaign.id,
              upload: forbiddenFile!,
            ),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 403),
            ),
          ),
        );
        final south = (await real(tester, () async {
          final login = await api.auth.login(
            LoginRequest(
              email: 'owner.demo-sur@demo.example',
              password: env['CP_SEED_PASSWORD']!,
            ),
          );
          await storage.writeToken(login.accessToken);
          final selected = await api.auth.selectTenant(
            const SelectTenantRequest(tenantId: 'demo-tenant-sur'),
          );
          await storage.writeToken(selected.accessToken);
          return selected;
        }));
        (container.read(authControllerProvider.notifier) as LiveAuth).replace(
          south,
        );
        await tester.pump();
        expect(find.text(displayedName), findsNothing);
        await waitFor(
          tester,
          find.text('No encontrado o fuera de tu organización'),
        );
        passed(
          'T32-ISOLATION',
          'Tenant switch immediately removes prior data and real foreign campaign returns 404',
        );
        expect(tester.takeException(), isNull);
        expect(cases, hasLength(13));
        completed = true;
      } finally {
        dio.close(force: true);
        receiptDirectory.createSync(recursive: true);
        File('${receiptDirectory.path}/T32.json').writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({
            'date': DateTime.now().toUtc().toIso8601String(),
            'backendSha': backendSha,
            'frontendSha': Process.runSync('git', ['rev-parse', 'HEAD']).stdout.toString().trim(),
            'workingTree': true,
            'command': 'flutter test --no-pub tool/sprint-cp/t32_real_api_test.dart --dart-define=CP_REAL_API=true',
            'fixture': 'Isolated PostgreSQL16 demo seed; synthetic T32 campaign, manual prospect and two CSV records',
            'boundary': 'Real Flutter test widgets, repositories, HTTP NestJS and PostgreSQL. Only OS file chooser receives an explicit synthetic fixture; no API mocks.',
            'cases': cases,
            'requests': requests,
            'status': completed ? 'PASS' : 'FAIL',
            'limitations': 'Not a Chromium browser run. Disposable database is removed by Stop-Lab.',
          })}\n',
        );
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
