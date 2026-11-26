import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/activation/activation_bootstrap.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/features/tenant_registration/state/activation_controller.dart';
import 'fixtures.dart';

void main() {
  for (final expiry in [DateTime.utc(2000), DateTime.utc(2100)]) {
    test(
      'server accepts challenge independent of device clock ($expiry)',
      () async {
        final repo = FakeRegistration()..expiresAt = expiry;
        final controller = ActivationController(
          repo,
          ActivationBootstrap(isActivation: true, code: activationCode()),
        );
        addTearDown(controller.dispose);
        await controller.begin();
        expect(controller.state.phase, ActivationPhase.password);
        expect(await controller.complete(passwordValue()), isTrue);
        expect(repo.completions, 1);
      },
    );
  }

  test(
    'server expiration wins even when device shows future deadline',
    () async {
      final repo = FakeRegistration()..expiresAt = DateTime.utc(2100);
      final controller = ActivationController(
        repo,
        ActivationBootstrap(isActivation: true, code: activationCode()),
      );
      addTearDown(controller.dispose);
      await controller.begin();
      repo.error = const ApiException(
        kind: ApiErrorKind.unauthorized,
        statusCode: 401,
        message: 'private',
      );
      expect(await controller.complete(passwordValue()), isFalse);
      expect(controller.state.phase, ActivationPhase.failed);
      expect(await controller.complete(passwordValue()), isFalse);
      expect(repo.completions, 1);
    },
  );
}
