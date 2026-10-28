import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/activation/activation_bootstrap.dart';
import 'history_stub.dart'
    if (dart.library.js_interop) 'history_web.dart'
    as history;
import 'fixtures.dart' show activationCode;

void main() {
  test(
    'browser history replaces activation entry and clears state before router',
    () {
      final original = history.location();
      try {
        final base = Uri.parse(original).replace(fragment: '').toString();
        history.replace('$base#/activate?code=${activationCode()}');
        final length = history.length();
        final captured = captureActivationLink();
        expect(history.location().contains(activationCode()), isFalse);
        expect(Uri.parse(history.location()).fragment, '/activate');
        expect(history.length(), length);
        expect(history.hasState(), isFalse);
        expect(captured.takeCode() == activationCode(), isTrue);
        expect(captured.takeCode(), isNull);
      } finally {
        history.replace(original);
      }
    },
    skip: !kIsWeb
        ? 'Run with flutter test --platform chrome (browser history)'
        : false,
  );
}
