import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../shared/models/api_models.dart';
import '../../../app/app_providers.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
  sessionExpired,
  backendUnavailable,
  failure,
}

class AuthState {
  const AuthState({required this.status, this.context, this.error});
  const AuthState.unknown() : this(status: AuthStatus.unknown);
  final AuthStatus status;
  final AuthContext? context;
  final Object? error;
  bool get busy => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthContext? context,
    Object? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      context: context ?? this.context,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  int _operation = 0;
  bool _alive = true;
  bool _current(int operation) => _alive && operation == _operation;
  SecureTokenStorage get _storage => ref.read(secureTokenStorageProvider);
  int _begin() {
    _storage.advanceSession();
    return ++_operation;
  }

  void sessionExpired() {
    final operation = _begin();
    state = const AuthState(status: AuthStatus.sessionExpired);
    unawaited(
      _storage
          .tokenOperation(() async {
            if (_current(operation)) await _storage.clearToken();
          })
          .catchError((Object _) {}),
    );
  }

  Future<void> acknowledgeSessionExpired() async {
    final operation = _begin();
    await _storage.tokenOperation(() async {
      if (!_current(operation)) return;
      await _storage.clearToken();
      if (_current(operation)) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  @override
  AuthState build() {
    ref.onDispose(() {
      _alive = false;
      ++_operation;
    });
    Future<void>.microtask(() {
      if (_alive && state.status == AuthStatus.unknown) restoreSession();
    });
    return const AuthState.unknown();
  }

  Future<void> restoreSession() async {
    if (state.busy) return;
    final operation = _begin();
    state = const AuthState(status: AuthStatus.loading);
    try {
      final token = await _storage.tokenOperation(_storage.readToken);
      if (!_current(operation)) return;
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final context = await ref.read(authRepositoryProvider).me();
      if (_current(operation)) {
        state = AuthState(status: AuthStatus.authenticated, context: context);
      }
    } catch (error) {
      if (!_current(operation)) return;
      final status = error is ApiException
          ? switch (error.kind) {
              ApiErrorKind.unauthorized => AuthStatus.sessionExpired,
              ApiErrorKind.serviceUnavailable ||
              ApiErrorKind.network => AuthStatus.backendUnavailable,
              _ => AuthStatus.failure,
            }
          : AuthStatus.failure;
      if (status == AuthStatus.sessionExpired) {
        await _storage.tokenOperation(() async {
          if (_current(operation)) await _storage.clearToken();
        });
      }
      if (_current(operation)) state = AuthState(status: status, error: error);
    }
  }

  Future<void> login(String email, String password) async {
    if (state.busy) return;
    final operation = _begin();
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _storage.tokenOperation(() async {
        if (_current(operation)) await _storage.clearToken();
      });
      if (!_current(operation)) return;
      final context = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await _storage.tokenOperation(() async {
        if (!_current(operation)) return;
        await _storage.writeToken(context.accessToken);
        if (_current(operation)) {
          state = AuthState(status: AuthStatus.authenticated, context: context);
        }
      });
    } catch (error) {
      if (!_current(operation)) return;
      final status =
          error is ApiException &&
              (error.kind == ApiErrorKind.serviceUnavailable ||
                  error.kind == ApiErrorKind.network)
          ? AuthStatus.backendUnavailable
          : AuthStatus.failure;
      state = AuthState(status: status, error: error);
    }
  }

  Future<void> selectTenant(String tenantId) async {
    if (state.busy) return;
    final previous = state.context;
    if (previous == null || state.status != AuthStatus.authenticated) return;
    final operation = _begin();
    state = AuthState(status: AuthStatus.loading, context: previous);
    try {
      final context = await ref
          .read(authRepositoryProvider)
          .selectTenant(tenantId);
      await _storage.tokenOperation(() async {
        if (!_current(operation)) return;
        await _storage.writeToken(context.accessToken);
        if (_current(operation)) {
          state = AuthState(status: AuthStatus.authenticated, context: context);
        }
      });
    } catch (error) {
      if (!_current(operation)) return;
      if (error is ApiException && error.kind == ApiErrorKind.unauthorized) {
        await _storage.tokenOperation(() async {
          if (_current(operation)) await _storage.clearToken();
        });
        if (_current(operation)) {
          state = AuthState(status: AuthStatus.sessionExpired, error: error);
        }
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        context: previous,
        error: error,
      );
    }
  }

  Future<void> logout() async {
    final hadSession = state.context != null;
    final repository = ref.read(authRepositoryProvider);
    final storage = _storage;
    final operation = _begin();
    state = const AuthState(status: AuthStatus.unauthenticated);
    try {
      if (hadSession) await repository.logout();
    } catch (_) {
      // Remote logout is best effort; local logout is mandatory.
    } finally {
      await storage.tokenOperation(() async {
        if (!_current(operation)) return;
        try {
          await storage.clearToken();
        } finally {
          if (_current(operation)) {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        }
      });
    }
  }
}
