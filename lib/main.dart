import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/activation/activation_bootstrap.dart';
import 'features/tenant_registration/state/activation_controller.dart';

void main() {
  // Must precede even binding creation: GoRouter never receives the raw code.
  final bootstrap = captureActivationLink();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [activationBootstrapProvider.overrideWithValue(bootstrap)],
      child: const SaasPlatformApp(),
    ),
  );
}
