import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/state/tenant_permissions.dart';

/// Root navigator dialogs must discard their content with the session that opened them.
Future<T?> showSessionDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final initialScope = container.read(sessionScopeProvider);
  if (initialScope == null) return Future.value();
  final navigator = Navigator.of(context, rootNavigator: true);
  var closing = false;
  late final DialogRoute<T> route;
  route = DialogRoute<T>(
    context: context,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (dialog) => UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          if (ref.watch(sessionScopeProvider) != initialScope) {
            if (!closing) {
              closing = true;
              scheduleMicrotask(() {
                if (route.isActive) route.navigator?.removeRoute(route);
              });
            }
            // Hide stale data in the very frame that observes the changed scope.
            return const SizedBox.shrink();
          }
          return builder(context);
        },
      ),
    ),
  );
  return navigator.push(route);
}
