import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/activation/activation_bootstrap.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/features/tenant_registration/state/activation_controller.dart';
import 'package:saas_platform_client/features/tenant_registration/state/registration_validation.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'fixtures.dart';

void main() {
  test(
    'bootstrap replaces current URL/history before handing a one-shot code to Flutter',
    () {
      final history = [
        'http://localhost:4200/?managerUrl=ws%3A%2F%2Flocalhost%2Ftest#'
            '/activate?code=${activationCode()}',
      ];
      var replaced = false;
      final bootstrap = captureActivationLocation(() => history.last, (clean) {
        history[history.length - 1] = clean;
        replaced = true;
      });
      expect(replaced, isTrue);
      expect(history.length, 1);
      expect(history.last.contains(activationCode()), isFalse);
      expect(Uri.parse(history.last).fragment, '/activate');
      expect(
        Uri.parse(history.last).queryParameters['managerUrl'],
        'ws://localhost/test',
      );
      expect(bootstrap.isActivation, isTrue);
      expect(bootstrap.takeCode() == activationCode(), isTrue);
      expect(bootstrap.takeCode(), isNull);
      expect(bootstrap.toString().contains(activationCode()), isFalse);
    },
  );
  test(
    'non-activation deep links are untouched; duplicate/malformed codes are scrubbed and unusable',
    () {
      var replaces = 0;
      expect(
        captureActivationLocation(
          () => 'http://localhost/#/users/example?review=core',
          (_) => replaces++,
        ).isActivation,
        isFalse,
      );
      expect(replaces, 0);
      for (final suffix in ['code=one&code=two', 'code=%ZZ', 'code=']) {
        final bootstrap = captureActivationLocation(
          () => 'http://localhost/#/activate?$suffix',
          (_) => replaces++,
        );
        expect(bootstrap.takeCode(), isNull);
      }
      expect(replaces, 3);
    },
  );
  test('failure to replace history fails closed before router creation', () {
    expect(
      () => captureActivationLocation(
        () => 'http://localhost/#/activate?code=${activationCode()}',
        (_) => throw StateError('unsafe'),
      ),
      throwsStateError,
    );
  });
  test('Unicode password UX counts code points and limits UTF-8 bytes', () {
    expect(
      initialPassword(['密' * 23, '1!a'].join()),
      isNull,
    ); // exactly 72 bytes
    expect(initialPassword(['密' * 24, '1!'].join()), isNotNull);
    expect(initialPassword(['Árbol', 'Seguro', '12!'].join()), isNull);
    expect(
      initialPassword(['𐐀' * 7, '1!'].join()),
      isNotNull,
    ); // 9, not 16 UTF-16 units
    expect(initialPassword(['𐐀' * 8, '1!'].join()), isNull);
    for (final value in ['a' * 10, '1' * 10, '!' * 10]) {
      expect(initialPassword(value), isNotNull);
    }
  });
  test(
    'successful activation consumes memory, no automatic login, cannot reuse link',
    () async {
      final repo = FakeRegistration();
      final bootstrap = ActivationBootstrap(
        isActivation: true,
        code: activationCode(),
      );
      final controller = ActivationController(repo, bootstrap);
      addTearDown(controller.dispose);
      await controller.begin();
      await controller.begin();
      expect(repo.redeems, 1);
      expect(bootstrap.takeCode(), isNull);
      expect(controller.state.phase, ActivationPhase.password);
      expect(await controller.complete('short'), isFalse);
      expect(repo.completions, 0);
      expect(await controller.complete(passwordValue()), isTrue);
      expect(controller.state.phase, ActivationPhase.completed);
      expect(controller.state.expiresAt, isNull);
      expect(await controller.complete(passwordValue()), isFalse);
      expect(repo.completions, 1);
    },
  );
  test('lost redemption response is terminal and not retried', () async {
    final repo = FakeRegistration()
      ..error = const ApiException(
        kind: ApiErrorKind.network,
        message: 'unsafe',
      );
    final bootstrap = ActivationBootstrap(
      isActivation: true,
      code: activationCode(),
    );
    final controller = ActivationController(repo, bootstrap);
    addTearDown(controller.dispose);
    await controller.begin();
    await controller.begin();
    expect(repo.redeems, 1);
    expect(bootstrap.takeCode(), isNull);
    expect(controller.state.phase, ActivationPhase.failed);
    expect(controller.state.message!.contains('unsafe'), isFalse);
  });
  test(
    'late redemption cannot repopulate secrets after leaving activation',
    () async {
      final repo = FakeRegistration()
        ..pendingRedeem = Completer<FirstAccessRequired>();
      final controller = ActivationController(
        repo,
        ActivationBootstrap(isActivation: true, code: activationCode()),
      );
      final pending = controller.begin();
      controller.dispose();
      repo.pendingRedeem!.complete(
        FirstAccessRequired(
          firstAccessToken: challengeCode(),
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        ),
      );
      await pending;
      expect(repo.completions, 0);
    },
  );
  test(
    'backend password rejection preserves challenge; unauthorized destroys it',
    () async {
      final repo = FakeRegistration();
      final controller = ActivationController(
        repo,
        ActivationBootstrap(isActivation: true, code: activationCode()),
      );
      addTearDown(controller.dispose);
      await controller.begin();
      repo.error = const ApiException(
        kind: ApiErrorKind.badRequest,
        statusCode: 400,
        message: 'unsafe',
      );
      expect(await controller.complete(passwordValue()), isFalse);
      expect(controller.state.phase, ActivationPhase.password);
      repo.error = const ApiException(
        kind: ApiErrorKind.unauthorized,
        statusCode: 401,
        message: 'unsafe',
      );
      expect(await controller.complete(passwordValue()), isFalse);
      expect(controller.state.phase, ActivationPhase.failed);
      expect(controller.state.message, invalidActivationMessage);
      repo.error = null;
      expect(await controller.complete(passwordValue()), isFalse);
      expect(repo.completions, 2);
    },
  );
  testWidgets('challenge expiry clears memory and prevents completion', (
    tester,
  ) async {
    final repo = FakeRegistration()
      ..expiresAt = DateTime.now().add(const Duration(seconds: 1));
    final controller = ActivationController(
      repo,
      ActivationBootstrap(isActivation: true, code: activationCode()),
    );
    addTearDown(controller.dispose);
    await controller.begin();
    await tester.pump(const Duration(seconds: 2));
    expect(controller.state.phase, ActivationPhase.failed);
    expect(await controller.complete(passwordValue()), isFalse);
    expect(repo.completions, 0);
  });
  test(
    'all error messages ignore provider messages, tokens, passwords and URLs',
    () {
      for (final status in [400, 401, 403, 404, 409, 429, 503, 500]) {
        final error = ApiException(
          kind: ApiErrorKind.unknown,
          statusCode: status,
          message: activationCode(),
          details: passwordValue(),
        );
        for (final message in [
          registrationError(error),
          registrationError(error, activation: true),
        ]) {
          expect(message.contains(activationCode()), isFalse);
          expect(message.contains(passwordValue()), isFalse);
          expect(message.contains('http'), isFalse);
        }
      }
    },
  );
}
