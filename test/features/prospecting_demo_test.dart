import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/features/prospecting_jobs/presentation/prospecting_demo_panel.dart';

void main() {
  testWidgets(
    'visual demo never claims a job or extraction and is always labelled',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProspectingDemoPanel())),
      );
      for (var i = 0; i < 3; i++) {
        expect(find.text('DEMO — SIN EJECUCIÓN REAL'), findsOneWidget);
        expect(find.textContaining('Sin búsquedas'), findsOneWidget);
        if (i < 2) {
          await tester.tap(find.text('Siguiente paso visual'));
          await tester.pump();
        }
      }
      expect(find.textContaining('No se creó ningún trabajo'), findsOneWidget);
      await tester.tap(find.text('Reiniciar demostración'));
      await tester.pump();
      expect(find.textContaining('Ejemplo visual'), findsOneWidget);
    },
  );
}
