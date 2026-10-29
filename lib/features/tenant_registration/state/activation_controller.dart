import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/activation/activation_bootstrap.dart';
import '../../../core/errors/api_exception.dart';
import '../data/tenant_registration_repository.dart';
import 'registration_providers.dart';
import 'registration_validation.dart';

final activationBootstrapProvider = Provider<ActivationBootstrap>(
  (ref) => ActivationBootstrap(),
);

enum ActivationPhase {
  initial,
  redeeming,
  password,
  completing,
  failed,
  completed,
}

/// Only non-sensitive presentation data is observable by Riverpod/listeners.
class ActivationViewState {
  const ActivationViewState(this.phase, {this.expiresAt, this.message});
  final ActivationPhase phase;
  final DateTime? expiresAt;
  final String? message;
  bool get busy =>
      phase == ActivationPhase.redeeming || phase == ActivationPhase.completing;
}

final activationControllerProvider =
    StateNotifierProvider.autoDispose<
      ActivationController,
      ActivationViewState
    >(
      (ref) => ActivationController(
        ref.watch(tenantRegistrationRepositoryProvider),
        ref.read(activationBootstrapProvider),
      ),
    );

class ActivationController extends StateNotifier<ActivationViewState> {
  ActivationController(this._repository, this._bootstrap)
    : super(const ActivationViewState(ActivationPhase.initial));
  final TenantRegistrationRepository _repository;
  final ActivationBootstrap _bootstrap;
  String? _challenge;
  bool _started = false;
  int _operation = 0;
  bool _current(int op) => mounted && op == _operation;
  void _clear() {
    _challenge = null;
    _bootstrap.clear();
  }

  void _fail(String message) {
    _clear();
    state = ActivationViewState(ActivationPhase.failed, message: message);
  }

  Future<void> begin() async {
    if (!mounted || _started) return;
    _started = true;
    final code = _bootstrap.takeCode() ?? captureActivationLink().takeCode();
    if (code == null) {
      _fail(invalidActivationMessage);
      return;
    }
    final op = ++_operation;
    state = const ActivationViewState(ActivationPhase.redeeming);
    try {
      final result = await _repository.redeem(code);
      if (!_current(op)) return;
      // expiresAt is server metadata. A device wall clock can be wrong in
      // either direction; only complete-first-access can authorize expiry.
      _challenge = result.firstAccessToken;
      state = ActivationViewState(
        ActivationPhase.password,
        expiresAt: result.expiresAt,
      );
    } catch (error) {
      if (_current(op)) _fail(registrationError(error, activation: true));
    }
  }

  Future<bool> complete(String password) async {
    if (state.phase != ActivationPhase.password || _challenge == null) {
      return false;
    }
    final validation = initialPassword(password);
    if (validation != null) {
      state = ActivationViewState(
        ActivationPhase.password,
        expiresAt: state.expiresAt,
        message: validation,
      );
      return false;
    }
    final op = ++_operation;
    final expiry = state.expiresAt;
    state = ActivationViewState(ActivationPhase.completing, expiresAt: expiry);
    try {
      await _repository.complete(_challenge!, password);
      if (!_current(op)) return false;
      _clear();
      state = const ActivationViewState(ActivationPhase.completed);
      return true;
    } catch (error) {
      if (!_current(op)) return false;
      // Password validation / throttling do not consume a valid challenge.
      final message = registrationError(error, activation: true);
      if (error is ApiException &&
          (error.statusCode == 400 || error.statusCode == 429)) {
        state = ActivationViewState(
          ActivationPhase.password,
          expiresAt: expiry,
          message: message,
        );
      } else {
        _fail(message);
      }
      return false;
    }
  }

  void leave() {
    ++_operation;
    _clear();
  }

  @override
  void dispose() {
    leave();
    super.dispose();
  }
}
