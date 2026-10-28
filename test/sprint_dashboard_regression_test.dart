import 'dart:typed_data';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/errors/error_mapper.dart';
import 'package:saas_platform_client/features/dashboard/presentation/dashboard_page.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'features/feature_fixtures.dart';

class PartialDashboard extends ContractAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) {
    final jobs = options.path.endsWith('/prospecting-jobs');
    status = jobs ? 503 : 200;
    response = jobs
        ? {
            'success': false,
            'error': {'code': 'HTTP_503', 'message': 'unavailable'},
          }
        : {
            'success': true,
            'data': [],
            'meta': {
              'page': 1,
              'limit': 5,
              'total': options.path.endsWith('/campaigns') ? 31 : 47,
              'totalPages': 10,
            },
          };
    return super.fetch(options, stream, cancel);
  }
}

void main() {
  testWidgets('FE-10 populated Jobs render enum status on the dashboard', (
    tester,
  ) async {
    const meta = PaginationMeta(page: 1, limit: 5, total: 1, totalPages: 1);
    final data = DashboardData(
      campaigns: const PaginatedResult<Campaign>(items: [], meta: meta),
      prospects: const PaginatedResult<Prospect>(items: [], meta: meta),
      jobs: PaginatedResult<ProspectingJobSummary>(
        items: [ProspectingJobSummary.fromJson(jobJson)],
        meta: meta,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dashboardProvider.overrideWith((ref) async => data)],
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Trabajo $entityId'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
  });

  testWidgets(
    'FE-05 Jobs failure preserves real campaign and prospect totals and offers retry',
    (tester) async {
      final data = (await tester.runAsync(
        () => ApiDashboardRepository(testApi(PartialDashboard())).load(),
      ))!;
      expect(data.jobs, isNull);
      expect(data.campaigns.meta.total, 31);
      expect(data.prospects.meta.total, 47);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dashboardProvider.overrideWith((ref) async => data)],
          child: const MaterialApp(home: Scaffold(body: DashboardPage())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('31'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('Reintentar trabajos'), findsOneWidget);
      expect(
        find.text('El servicio no está disponible temporalmente.'),
        findsOneWidget,
      );
    },
  );
  test('FE-08 parser diagnostics never expose the response value', () {
    final message = const ErrorMapper().userMessage(
      const FormatException('secret-value-token'),
    );
    expect(
      message,
      'La respuesta del servidor no coincide con el formato esperado.',
    );
    expect(message.contains('secret-value-token'), isFalse);
  });
}
