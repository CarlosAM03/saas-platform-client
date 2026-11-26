import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../tenants/state/tenants_providers.dart';
import '../data/tenant_registration_repository.dart';
import 'registration_validation.dart';

final tenantRegistrationRepositoryProvider =
    Provider<TenantRegistrationRepository>(
      (ref) => ApiTenantRegistrationRepository(ref.watch(platformApiProvider)),
    );

class RegistrationState {
  const RegistrationState({this.busy = false, this.result, this.error});
  final bool busy;
  final TenantRegistrationResult? result;
  final String? error;
}

final registrationControllerProvider =
    StateNotifierProvider.autoDispose<
      RegistrationController,
      RegistrationState
    >((ref) {
      ref.watch(sessionScopeProvider);
      return RegistrationController(ref);
    });

class RegistrationController extends StateNotifier<RegistrationState> {
  RegistrationController(this.ref)
    : _scope = ref.read(sessionScopeProvider),
      super(const RegistrationState());
  final Ref ref;
  final SessionScope? _scope;
  bool get current =>
      mounted && _scope != null && ref.read(sessionScopeProvider) == _scope;
  Future<void> register(RegisterTenantRequest request) async {
    if (state.busy || state.result != null) return;
    state = const RegistrationState(busy: true);
    try {
      final allowed = await ref.read(currentTenantPermissionsProvider.future);
      if (!current) return;
      if (!allowed.canCreateTenants) {
        state = const RegistrationState(
          error: 'No tienes permisos para realizar esta acción.',
        );
        return;
      }
      final result = await ref
          .read(tenantRegistrationRepositoryProvider)
          .register(request);
      if (!current) return;
      ref.invalidate(tenantsListProvider);
      ref.invalidate(tenantDiscoveryProvider);
      state = RegistrationState(result: result);
    } catch (error) {
      if (current) state = RegistrationState(error: registrationError(error));
    }
  }
}

class OnboardingState {
  const OnboardingState({this.busy = false, this.data, this.error});
  final bool busy;
  final TenantOnboarding? data;
  final String? error;
}

final onboardingControllerProvider = StateNotifierProvider.autoDispose
    .family<OnboardingController, OnboardingState, String>((ref, id) {
      ref.watch(sessionScopeProvider);
      return OnboardingController(ref, id);
    });

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this.ref, this.id)
    : _scope = ref.read(sessionScopeProvider),
      super(const OnboardingState()) {
    unawaited(refresh());
  }
  final Ref ref;
  final String id;
  final SessionScope? _scope;
  bool get current =>
      mounted && _scope != null && ref.read(sessionScopeProvider) == _scope;
  Future<void> refresh() => _load(false);
  Future<void> resend() => _load(true);
  Future<void> _load(bool resend) async {
    if (state.busy) return;
    final previous = state.data;
    if (resend &&
        previous?.activationStatus != ActivationStatus.PENDING_FIRST_ACCESS) {
      return;
    }
    state = OnboardingState(data: previous, busy: true);
    try {
      final allowed = await ref.read(currentTenantPermissionsProvider.future);
      if (!current) return;
      if (!allowed.canCreateTenants) {
        state = const OnboardingState(
          error: 'No tienes permisos para realizar esta acción.',
        );
        return;
      }
      final repo = ref.read(tenantRegistrationRepositoryProvider);
      final data = await (resend ? repo.resend(id) : repo.onboarding(id));
      if (current) state = OnboardingState(data: data);
    } catch (error) {
      if (current) {
        state = OnboardingState(
          data: previous,
          error: registrationError(error),
        );
      }
    }
  }
}
