import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/prospecting_jobs/presentation/batch_pages.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';

import 'campaigns_fixtures.dart';
import 'feature_fixtures.dart';

void main() {
  testWidgets('OWNER sees the real paginated batch history', (tester) async {
    final adapter = _BatchPagesAdapter();
    await tester.pumpWidget(_screen(const BatchHistoryPage(), adapter));
    await tester.pumpAndSettle();

    expect(adapter.requests, ['GET /api/v1/prospecting-batches']);
    expect(find.text('Mis lotes'), findsOneWidget);
    expect(find.text('Lote lab'), findsOneWidget);
    expect(find.text('Página 1 · 6 lotes'), findsOneWidget);
    expect(find.text('Lote admitido'), findsOneWidget);
  });

  testWidgets('MEMBER cannot read batch history or trigger batch requests', (
    tester,
  ) async {
    final adapter = _BatchPagesAdapter();
    await tester.pumpWidget(
      _screen(const BatchHistoryPage(), adapter, member: true),
    );
    await tester.pumpAndSettle();

    expect(adapter.requests, isEmpty);
    expect(
      find.text('No tienes permisos para realizar esta acción.'),
      findsOneWidget,
    );
  });

  testWidgets('direct batch detail recovers state without a new admission', (
    tester,
  ) async {
    final adapter = _BatchPagesAdapter();
    await tester.pumpWidget(_screen(const BatchDetailPage('lab'), adapter));
    await tester.pumpAndSettle();

    expect(adapter.requests, [
      'POST /api/v1/prospecting-batches/lab/reconcile',
    ]);
    expect(find.text('Lote admitido'), findsOneWidget);
    expect(find.text('Consultar estado'), findsOneWidget);
    expect(find.text('Revisar resultados'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);

    await tester.tap(find.text('Consultar estado'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.where((entry) => entry.startsWith('POST ')),
      [
        'POST /api/v1/prospecting-batches/lab/reconcile',
        'POST /api/v1/prospecting-batches/lab/reconcile',
      ],
    );
  });

  testWidgets('MEMBER direct batch detail makes no batch request', (
    tester,
  ) async {
    final adapter = _BatchPagesAdapter();
    await tester.pumpWidget(
      _screen(const BatchDetailPage('lab'), adapter, member: true),
    );
    await tester.pumpAndSettle();

    expect(adapter.requests, isEmpty);
    expect(
      find.text('No tienes permisos para realizar esta acción.'),
      findsOneWidget,
    );
  });
}

Widget _screen(
  Widget page,
  _BatchPagesAdapter adapter, {
  bool member = false,
}) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(
      () => member ? _MemberAuth() : FeatureAuthController(),
    ),
    platformApiProvider.overrideWithValue(testApi(adapter)),
    campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
  ],
  child: MaterialApp(home: Scaffold(body: page)),
);

class _MemberAuth extends FeatureAuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    context: session(role: RoleName.MEMBER),
  );
}

class _BatchPagesAdapter extends ContractAdapter {
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add('${options.method} ${options.path}');
    final batch = {'id': 'lab', 'campaignId': entityId, 'createdAt': stamp};
    if (options.path.endsWith('/reconcile')) {
      response = envelope({
        ...batch,
        'admission': 'ACCEPTED',
        'remoteObserved': true,
        'jobs': [
          {
            'id': 'job',
            'position': 0,
            'state': 'COMPLETED',
            'availability': 'AVAILABLE',
          },
        ],
      });
    } else {
      response = page({...batch, 'admission': 'ACCEPTED', 'jobs': []});
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}
