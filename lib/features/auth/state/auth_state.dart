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

  AuthState copyWith({AuthStatus? status, AuthContext? context, Object? error, bool clearError = false}) {
    return AuthState(status: status ?? this.status, context: context ?? this.context, error: clearError ? null : error ?? this.error);
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future<void>.microtask(restoreSession);
    return const AuthState.unknown();
  }

  Future<void> restoreSession() async {
    if (state.status == AuthStatus.loading) return;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final token = await ref.read(secureTokenStorageProvider).readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final context = await ref.read(authRepositoryProvider).me();
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } on ApiException catch (error) {
      await ref.read(secureTokenStorageProvider).clearToken();
      final status = error.kind == ApiErrorKind.serviceUnavailable || error.kind == ApiErrorKind.network
          ? AuthStatus.backendUnavailable
          : AuthStatus.sessionExpired;
      state = AuthState(status: status, error: error);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final context = await ref.read(authRepositoryProvider).login(email: email, password: password);
      await ref.read(secureTokenStorageProvider).writeToken(context.accessToken);
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } catch (error) {
      final status = error is ApiException &&
              (error.kind == ApiErrorKind.serviceUnavailable || error.kind == ApiErrorKind.network)
          ? AuthStatus.backendUnavailable
          : AuthStatus.failure;
      state = AuthState(status: status, error: error);
    }
  }

  Future<void> selectTenant(String tenantId) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final context = await ref.read(authRepositoryProvider).selectTenant(tenantId);
      await ref.read(secureTokenStorageProvider).writeToken(context.accessToken);
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } catch (error) {
      state = AuthState(status: AuthStatus.failure, error: error);
    }
  }

  Future<void> logout() async {
    try {
      if (state.context != null) await ref.read(authRepositoryProvider).logout();
    } finally {
      await ref.read(secureTokenStorageProvider).clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
