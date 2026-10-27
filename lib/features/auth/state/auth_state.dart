import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../shared/models/api_models.dart';
<<<<<<< Updated upstream
import '../../../app/app_providers.dart';
=======
>>>>>>> Stashed changes

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
  sessionExpired,
  backendUnavailable,
  failure
}

class AuthState {
  const AuthState(
      {required this.status, this.context, this.error, this.busy = false});
  const AuthState.unknown() : this(status: AuthStatus.unknown);
  final AuthStatus status;
  final AuthContext? context;
  final Object? error;
<<<<<<< Updated upstream

  AuthState copyWith(
      {AuthStatus? status,
      AuthContext? context,
      Object? error,
      bool clearError = false}) {
    return AuthState(
        status: status ?? this.status,
        context: context ?? this.context,
        error: clearError ? null : error ?? this.error);
  }
}

class AuthController extends Notifier<AuthState> {
  void sessionExpired() {
    state = const AuthState(status: AuthStatus.sessionExpired);
  }

  Future<void> acknowledgeSessionExpired() async {
    await ref.read(secureTokenStorageProvider).clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

=======
  final bool busy;
}

class AuthController extends Notifier<AuthState> {
>>>>>>> Stashed changes
  @override
  AuthState build() {
    Future<void>.microtask(restoreSession);
    return const AuthState.unknown();
  }

  void sessionExpired() =>
      state = const AuthState(status: AuthStatus.sessionExpired);

  Future<void> restoreSession() async {
    if (state.status == AuthStatus.loading) return;
    state = const AuthState(status: AuthStatus.loading);
    try {
      final token = await ref.read(secureTokenStorageProvider).readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final context = await ref.read(authRepositoryProvider).me();
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } on ApiException catch (error) {
      final status = switch (error.kind) {
        ApiErrorKind.unauthorized => AuthStatus.sessionExpired,
<<<<<<< Updated upstream
        ApiErrorKind.serviceUnavailable ||
        ApiErrorKind.network =>
=======
        ApiErrorKind.network ||
        ApiErrorKind.serviceUnavailable =>
>>>>>>> Stashed changes
          AuthStatus.backendUnavailable,
        _ => AuthStatus.failure,
      };
      if (status == AuthStatus.sessionExpired) {
        await ref.read(secureTokenStorageProvider).clearToken();
      }
      state = AuthState(status: status, error: error);
    } catch (error) {
      state = AuthState(status: AuthStatus.failure, error: error);
    }
  }

  Future<void> login(String email, String password) async {
    if (state.busy) return;
    state = const AuthState(status: AuthStatus.unauthenticated, busy: true);
    try {
<<<<<<< Updated upstream
      // A prior session must not be attached to the public login request.
      await ref.read(secureTokenStorageProvider).clearToken();
=======
>>>>>>> Stashed changes
      final context = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(secureTokenStorageProvider)
          .writeToken(context.accessToken);
<<<<<<< Updated upstream
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } catch (error) {
      final status = error is ApiException &&
              (error.kind == ApiErrorKind.serviceUnavailable ||
                  error.kind == ApiErrorKind.network)
          ? AuthStatus.backendUnavailable
          : AuthStatus.failure;
      state = AuthState(status: status, error: error);
    }
  }

  Future<void> selectTenant(String tenantId) async {
    final previousContext = state.context;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final context =
          await ref.read(authRepositoryProvider).selectTenant(tenantId);
      await ref
          .read(secureTokenStorageProvider)
          .writeToken(context.accessToken);
=======
>>>>>>> Stashed changes
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } catch (error) {
      if ((error is ApiException && error.kind == ApiErrorKind.unauthorized) ||
          state.status == AuthStatus.sessionExpired) {
        await ref.read(secureTokenStorageProvider).clearToken();
        state = AuthState(status: AuthStatus.sessionExpired, error: error);
        return;
      }
      state = AuthState(
        status: previousContext == null
            ? AuthStatus.failure
            : AuthStatus.authenticated,
        context: previousContext,
        error: error,
      );
    }
  }

  Future<void> selectTenant(String tenantId) async {
    if (state.busy) return;
    final previous = state.context;
    state = AuthState(
        status: AuthStatus.authenticated, context: previous, busy: true);
    try {
      final context =
          await ref.read(authRepositoryProvider).selectTenant(tenantId);
      await ref
          .read(secureTokenStorageProvider)
          .writeToken(context.accessToken);
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } catch (error) {
      if (state.status == AuthStatus.sessionExpired) return;
      state = AuthState(
          status: AuthStatus.authenticated, context: previous, error: error);
    }
  }

  Future<void> logout() async {
    try {
      if (state.context != null) {
        await ref.read(authRepositoryProvider).logout();
      }
    } catch (_) {
<<<<<<< Updated upstream
      // Remote logout is best effort; local logout is mandatory.
    } finally {
      try {
        await ref.read(secureTokenStorageProvider).clearToken();
      } finally {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
=======
      // Ending the local session must succeed even when the server is offline.
    } finally {
      await ref.read(secureTokenStorageProvider).clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
>>>>>>> Stashed changes
    }
  }
}
