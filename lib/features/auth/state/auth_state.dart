import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../shared/models/api_models.dart';
import '../../../app/app_providers.dart';


//PROVICIONAL SOLO PARA PASAR EL LOGIN PROVICIONAL
import '../data/dev_user.dart';

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
  void sessionExpired() {
    state = const AuthState(status: AuthStatus.sessionExpired);
  }

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
      //REMOVER CUANDO YA SE HAYAN CONECTADO EL BACKEND Y EL FRONTEND, ES PROVISIONAL
            if (DevUser.isToken(token)) {
        state = AuthState(status: AuthStatus.authenticated, context: DevUser.context());
        return;
      }
      final context = await ref.read(authRepositoryProvider).me();
      state = AuthState(status: AuthStatus.authenticated, context: context);
    } on ApiException catch (error) {
      final status = switch (error.kind) {
        ApiErrorKind.unauthorized => AuthStatus.sessionExpired,
        ApiErrorKind.serviceUnavailable || ApiErrorKind.network => AuthStatus.backendUnavailable,
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
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      //PROVISIONAAAAAAAAAAL , 
      if (DevUser.matches(email, password)) {
        final dev = DevUser.context();
        await ref.read(secureTokenStorageProvider).writeToken(dev.accessToken);
        state = AuthState(status: AuthStatus.authenticated, context: dev);
        return;
      }


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
     
     //PROVICIONAAAAAAAAAAAAAAAAL
      final ctx = state.context;
      if (ctx != null && !DevUser.isToken(ctx.accessToken)) {
        await ref.read(authRepositoryProvider).logout();
      }
   
   //Este es el original para conectar con el backend 
    /*try 
    {
      
      if (state.context != null) await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // The local session must end even when the backend cannot be reached.
    } finally {
      await ref.read(secureTokenStorageProvider).clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }*/
  }
}
