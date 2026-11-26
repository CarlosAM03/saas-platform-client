import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/dashboard/presentation/dashboard_page.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/batch_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';

import 'feature_fixtures.dart';

void main() {
  const meta = PaginationMeta(page: 1, limit: 20, total: 7, totalPages: 1);
  final batch = BatchSummary.fromJson({
    'id': 'lab',
    'campaignId': entityId,
    'admission': 'ACCEPTED',
    'createdAt': stamp,
    'jobs': <Object?>[],
  });
  final data = DashboardData(
    campaigns: const PaginatedResult<Campaign>(items: [], meta: meta),
    prospects: const PaginatedResult<Prospect>(items: [], meta: meta),
    batches: PaginatedResult<BatchSummary>(items: [batch], meta: meta),
  );

  testWidgets('Batch mode OWNER sees the real batch metric and access', (
    tester,
  ) async {
    expect(prospectingBatchEnabled, isTrue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          dashboardProvider.overrideWith((ref) async => data),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lotes'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('Lotes recientes'), findsOneWidget);
    expect(find.text('Lote lab'), findsOneWidget);
    expect(find.text('Trabajos recientes'), findsNothing);
  });

  testWidgets('Batch mode MEMBER receives no batch metric or access', (
    tester,
  ) async {
    expect(prospectingBatchEnabled, isTrue);
    final memberData = DashboardData(
      campaigns: data.campaigns,
      prospects: data.prospects,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_MemberAuth.new),
          dashboardProvider.overrideWith((ref) async => memberData),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buscar prospectos'), findsNothing);
    expect(find.text('Lotes'), findsNothing);
    expect(find.text('Lotes recientes'), findsNothing);
    expect(find.text('Ver lotes'), findsNothing);
  });
}

class _MemberAuth extends FeatureAuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    context: session(role: RoleName.MEMBER),
  );
}
