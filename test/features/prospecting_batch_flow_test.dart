import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/prospecting_jobs/presentation/batch_generation_page.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';

import 'campaigns_fixtures.dart';
import 'feature_fixtures.dart';

void main() {
  testWidgets('MEMBER has no batch form or batch HTTP requests', (
    tester,
  ) async {
    final adapter = _BatchAdapter();
    await tester.pumpWidget(_screen(adapter, _MemberAuth()));
    await tester.pumpAndSettle();

    expect(find.text('Solicitar lote'), findsNothing);
    expect(find.text('Mis lotes'), findsNothing);
    expect(adapter.requests, isEmpty);
  });

  testWidgets(
    'OWNER can reconcile an uncertain batch and see partial results',
    (tester) async {
      final adapter = _BatchAdapter();
      await tester.pumpWidget(_screen(adapter, FeatureAuthController()));
      await tester.pumpAndSettle();

      final pastBatch = find.text('Admisión sin confirmar');
      await tester.ensureVisible(pastBatch);
      await tester.tap(pastBatch);
      await tester.pumpAndSettle();
      expect(find.text('Consultar estado'), findsOneWidget);

      await tester.tap(find.text('Consultar estado'));
      await tester.pumpAndSettle();
      expect(
        adapter.requests,
        contains('POST /api/v1/prospecting-batches/lab/reconcile'),
      );
      await tester.tap(find.text('Revisar resultados'));
      await tester.pumpAndSettle();
      expect(find.text('Negocio sintético'), findsOneWidget);
      expect(find.textContaining('parcial', findRichText: true), findsWidgets);
      expect(adapter.requests.where((entry) => entry.startsWith('POST ')), [
        'POST /api/v1/prospecting-batches/lab/reconcile',
      ]);
    },
  );
}

Widget _screen(_BatchAdapter adapter, FeatureAuthController auth) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        platformApiProvider.overrideWithValue(testApi(adapter)),
        campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
      ],
      child: const MaterialApp(home: Scaffold(body: BatchGenerationPage())),
    );

class _MemberAuth extends FeatureAuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    context: session(role: RoleName.MEMBER),
  );
}

class _BatchAdapter extends ContractAdapter {
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
            'quality': 'PARTIAL',
          },
        ],
      });
    } else if (options.path.endsWith('/results')) {
      response = envelope({
        'snapshotId': 'snapshot',
        'quality': 'PARTIAL',
        'expiresAt': '2099-01-01T00:00:00Z',
        'rows': [
          {
            'index': 0,
            'row': {'name': 'Negocio sintético'},
            'blocked': false,
            'candidates': [],
          },
        ],
      });
    } else {
      response = page({...batch, 'admission': 'UNCERTAIN', 'jobs': []});
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}
