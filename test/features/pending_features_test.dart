import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/shared/services/file_service.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'package:saas_platform_client/features/dashboard/presentation/dashboard_page.dart';
import 'package:saas_platform_client/features/prospects/data/prospect_import_repository.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospect_import_page.dart';
import 'package:saas_platform_client/features/prospecting_jobs/data/prospecting_jobs_repository.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/prospecting_jobs_providers.dart';
import 'package:saas_platform_client/features/prospecting_jobs/presentation/generate_page.dart';
import 'feature_fixtures.dart';
import 'campaigns_fixtures.dart';

class FakeFiles implements FileService {
  final file = ApiUploadFile(
      filename: 'businesses.csv', bytes: 'name\nBusiness\n'.codeUnits);
  @override
  Future<ApiUploadFile?> pickCsv() async => file;
  @override
  Future<bool> save(String filename, List<int> bytes) async => true;
}

class FakeImports implements ProspectImportRepository {
  bool expired = false;
  int confirms = 0;
  Object? failure;
  ApiUploadFile? previewFile, confirmedFile;
  List<ProspectImportDecision>? decisions;
  @override
  Future<ProspectImportPreview> preview(
      String campaignId, ApiUploadFile upload) async {
    previewFile = upload;
    return ProspectImportPreview.fromJson({
      'previewReference': 'reference.signature',
      'expiresAt': DateTime.now()
          .add(Duration(hours: expired ? -1 : 1))
          .toIso8601String(),
      'summary': {
        'total': 1,
        'new': 1,
        'matches': 0,
        'invalid': 0,
        'conflicts': 0
      },
      'rows': [
        {
          'record': 1,
          'classification': 'NEW',
          'values': {'name': 'Business'},
          'errors': [],
          'matches': []
        }
      ]
    });
  }

  @override
  Future<ProspectImportResult> confirm(String campaignId, ApiUploadFile upload,
      String reference, List<ProspectImportDecision> decisions) async {
    confirms++;
    confirmedFile = upload;
    this.decisions = decisions;
    if (failure != null) throw failure!;
    return ProspectImportResult.fromJson({
      'summary': {
        'total': 1,
        'created': 1,
        'linked': 0,
        'updated': 0,
        'skipped': 0,
        'rejected': 0
      },
      'rows': [
        {'record': 1, 'action': 'CREATE', 'prospectId': entityId}
      ]
    });
  }
}

class FakeJobs implements ProspectingJobsRepository {
  int reads = 0;
  final keys = <String>[];
  List<ProspectingJobStatus> statuses = [
    ProspectingJobStatus.RUNNING,
    ProspectingJobStatus.COMPLETED
  ];
  @override
  Future<ProspectingJobDetail> get(String id) async {
    final index = reads < statuses.length ? reads : statuses.length - 1;
    reads++;
    return ProspectingJobDetail.fromJson(
        {...detailJson, 'status': statuses[index].name});
  }

  @override
  Future<ProspectingJobDetail> create(
      CreateProspectingJobRequest request, String key) async {
    keys.add(key);
    throw const ApiException(
        kind: ApiErrorKind.serviceUnavailable, message: 'unavailable');
  }

  @override
  Future<PaginatedResult<ProspectingJobSummary>> list(PaginationQuery query) =>
      throw UnimplementedError();
  @override
  Future<ProspectingJobDetail> cancel(String id) => throw UnimplementedError();
  @override
  Future<PersistResultsResult> persist(String id) => throw UnimplementedError();
  @override
  Future<ApiDownload> export(String id, ExportFormat format) =>
      throw UnimplementedError();
}

Future<void> importSetup(WidgetTester tester, FakeImports imports) async {
  await tester.pumpWidget(ProviderScope(overrides: [
    authControllerProvider.overrideWith(FeatureAuthController.new),
    currentTenantPermissionsProvider.overrideWith((ref) async =>
        const TenantPermissions(role: RoleName.OWNER, hasTenant: true)),
    campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
    fileServiceProvider.overrideWithValue(FakeFiles()),
    prospectImportRepositoryProvider.overrideWithValue(imports)
  ], child: const MaterialApp(home: Scaffold(body: ProspectImportPage()))));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Seleccionar campaña'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Campaign'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Seleccionar CSV'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Generar vista previa'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'CSV previews before writing, reuses the same file, and blocks resubmission after success',
      (tester) async {
    final imports = FakeImports();
    await importSetup(tester, imports);
    expect(imports.confirms, 0);
    expect(find.text('1. Business'), findsOneWidget);
    await tester.tap(find.text('Confirmar importación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Importar ahora'));
    await tester.pumpAndSettle();
    expect(imports.confirms, 1);
    expect(identical(imports.previewFile, imports.confirmedFile), isTrue);
    expect(imports.decisions!.single.action, ProspectImportAction.CREATE);
    expect(find.text('Importación terminada'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmar importación'))
            .onPressed,
        isNull);
  });
  testWidgets('expired CSV preview cannot write', (tester) async {
    final imports = FakeImports()..expired = true;
    await importSetup(tester, imports);
    await tester.tap(find.text('Confirmar importación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(imports.confirms, 0);
    expect(find.text('La vista previa venció. Genérala nuevamente.'),
        findsOneWidget);
  });
  testWidgets('stale CSV confirmation forces a new preview', (tester) async {
    final imports = FakeImports()
      ..failure =
          const ApiException(kind: ApiErrorKind.conflict, message: 'stale');
    await importSetup(tester, imports);
    await tester.tap(find.text('Confirmar importación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Importar ahora'));
    await tester.pumpAndSettle();
    expect(imports.confirms, 1);
    expect(find.text('Generar vista previa'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmar importación'))
            .onPressed,
        isNull);
  });
  testWidgets('CSV direct route closes for MEMBER', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      currentTenantPermissionsProvider.overrideWith((ref) async =>
          const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
    ], child: const MaterialApp(home: Scaffold(body: ProspectImportPage()))));
    await tester.pumpAndSettle();
    expect(find.text('Seleccionar CSV'), findsNothing);
    expect(find.text('No tienes permisos para realizar esta acción.'),
        findsOneWidget);
  });
  testWidgets('job monitor stops at terminal state and on disposal',
      (tester) async {
    final jobs = FakeJobs();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          prospectingJobsRepositoryProvider.overrideWithValue(jobs)
        ],
        child: MaterialApp(
            home: Consumer(
                builder: (context, ref, _) => Text(ref
                        .watch(jobMonitorProvider(entityId))
                        .asData
                        ?.value
                        .status
                        .name ??
                    'loading')))));
    await tester.pump();
    await tester.pump();
    expect(jobs.reads, 1);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(jobs.reads, 2);
    await tester.pump(const Duration(seconds: 12));
    expect(jobs.reads, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('job polling stops when its page loses all listeners',
      (tester) async {
    final jobs = FakeJobs()..statuses = [ProspectingJobStatus.RUNNING];
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(FeatureAuthController.new),
      prospectingJobsRepositoryProvider.overrideWithValue(jobs)
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: Consumer(
                builder: (context, ref, _) => Text(
                    ref.watch(jobMonitorProvider(entityId)).asData?.value.id ??
                        'loading')))));
    await tester.pump();
    await tester.pump();
    expect(jobs.reads, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(jobs.reads, 1);
  });
  testWidgets(
      'new search preserves idempotency on retry and validates Engine limits',
      (tester) async {
    final jobs = FakeJobs();
    await tester.pumpWidget(ProviderScope(overrides: [
      authControllerProvider.overrideWith(FeatureAuthController.new),
      campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
      prospectingJobsRepositoryProvider.overrideWithValue(jobs),
      currentTenantPermissionsProvider.overrideWith((ref) async =>
          const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
    ], child: const MaterialApp(home: Scaffold(body: GeneratePage()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar campaña'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campaign'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'cafes');
    await tester.enterText(find.byType(TextFormField).at(1), 'Tijuana');
    await tester.enterText(find.byType(TextFormField).at(2), '101');
    await tester.tap(find.text('Iniciar búsqueda'));
    await tester.pumpAndSettle();
    expect(jobs.keys, isEmpty);
    await tester.enterText(find.byType(TextFormField).at(2), '5');
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Iniciar búsqueda'));
      await tester.pumpAndSettle();
    }
    expect(jobs.keys, hasLength(2));
    expect(jobs.keys[0], jobs.keys[1]);
    expect(
        find.textContaining('El servicio de prospección no está disponible.'),
        findsOneWidget);
  });
  testWidgets(
      'dashboard totals come from server metadata rather than the visible rows',
      (tester) async {
    PaginatedResult<T> result<T>(List<T> items, int total) => PaginatedResult(
        items: items,
        meta: PaginationMeta(
            page: 1, limit: 5, total: total, totalPages: (total / 5).ceil()));
    await tester.pumpWidget(ProviderScope(overrides: [
      dashboardProvider.overrideWith((ref) async => DashboardData(
          campaigns: result([Campaign.fromJson(campaignJson)], 41),
          prospects: result([], 203),
          jobs: result([], 17)))
    ], child: const MaterialApp(home: Scaffold(body: DashboardPage()))));
    await tester.pumpAndSettle();
    for (final count in ['41', '203', '17']) {
      expect(find.text(count), findsOneWidget);
    }
    expect(find.text('Campaign'), findsOneWidget);
  });
}
