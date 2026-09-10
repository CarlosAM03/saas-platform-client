import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../routes/app_router.dart';
import 'app_providers.dart';

class SaasPlatformApp extends ConsumerWidget {
  const SaasPlatformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SaaS Platform',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
