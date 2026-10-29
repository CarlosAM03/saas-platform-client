import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/registration_providers.dart';
import '../state/registration_validation.dart';

class TenantRegistrationPage extends ConsumerWidget {
  const TenantRegistrationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    return FeaturePage(
      title: 'Registrar organización',
      child: PermissionGate(
        permissions: permissions,
        allowed: permissions.asData?.value.canCreateTenants == true,
        child: const _RegistrationForm(),
      ),
    );
  }
}

class _RegistrationForm extends ConsumerStatefulWidget {
  const _RegistrationForm();
  @override
  ConsumerState<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<_RegistrationForm> {
  final form = GlobalKey<FormState>();
  final tenantName = TextEditingController(),
      tenantSlug = TextEditingController();
  final ownerName = TextEditingController(),
      ownerEmail = TextEditingController();
  final fields = List.generate(4, (_) => GlobalKey<FormFieldState<String>>());
  final focus = List.generate(4, (_) => FocusNode());
  void submit() {
    if (ref.read(registrationControllerProvider).busy) return;
    if (!form.currentState!.validate()) {
      final first = fields.indexWhere((field) => field.currentState!.hasError);
      if (first >= 0) focus[first].requestFocus();
      return;
    }
    ref
        .read(registrationControllerProvider.notifier)
        .register(
          RegisterTenantRequest(
            tenantName: tenantName.text,
            tenantSlug: tenantSlug.text,
            ownerName: ownerName.text,
            ownerEmail: ownerEmail.text,
          ),
        );
  }

  @override
  void dispose() {
    for (final node in focus) {
      node.dispose();
    }
    tenantName.dispose();
    tenantSlug.dispose();
    ownerName.dispose();
    ownerEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final result = state.result;
    if (result != null) {
      return ListView(
        children: [
          const Text(
            'Organización registrada. La activación del OWNER y el correo se muestran por separado.',
          ),
          Text(result.tenant.name),
          Text(result.tenant.slug),
          Text(result.tenant.status.name),
          OnboardingSummary(result.onboarding),
          TextButton(
            onPressed: () => context.go(
              '/tenants/${Uri.encodeComponent(result.tenant.id)}/onboarding',
            ),
            child: const Text('Consultar estado y recuperación'),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Se creará la organización y su primer OWNER. No se envían contraseñas por correo.',
                ),
                for (final entry in [
                  (tenantName, 'Nombre de empresa', registrationName),
                  (tenantSlug, 'Slug', registrationSlug),
                  (ownerName, 'Nombre del OWNER', registrationName),
                  (ownerEmail, 'Correo del OWNER', registrationEmail),
                ].asMap().entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      key: fields[entry.key],
                      focusNode: focus[entry.key],
                      controller: entry.value.$1,
                      enabled: !state.busy,
                      validator: entry.value.$3,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textInputAction: entry.key == 3
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onFieldSubmitted: (_) {
                        if (entry.key == 3) {
                          submit();
                        } else {
                          focus[entry.key + 1].requestFocus();
                        }
                      },
                      keyboardType: entry.value.$1 == ownerEmail
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: entry.value.$2),
                    ),
                  ),
                if (state.error != null)
                  Semantics(liveRegion: true, child: Text(state.error!)),
                if (state.busy) const LinearProgressIndicator(),
                FilledButton(
                  onPressed: state.busy ? null : submit,
                  child: const Text('Registrar organización'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TenantOnboardingPage extends ConsumerWidget {
  const TenantOnboardingPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    return FeaturePage(
      title: 'Activación del primer OWNER',
      child: PermissionGate(
        permissions: permissions,
        allowed: permissions.asData?.value.canCreateTenants == true,
        child: _OnboardingBody(id),
      ),
    );
  }
}

class _OnboardingBody extends ConsumerWidget {
  const _OnboardingBody(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider(id));
    final controller = ref.read(onboardingControllerProvider(id).notifier);
    return ListView(
      children: [
        if (state.busy) const LinearProgressIndicator(),
        if (state.error != null)
          Semantics(liveRegion: true, child: Text(state.error!)),
        if (state.data != null) OnboardingSummary(state.data!),
        TextButton(
          onPressed: state.busy ? null : controller.refresh,
          child: const Text('Actualizar estado'),
        ),
        if (state.data?.activationStatus ==
            ActivationStatus.PENDING_FIRST_ACCESS) ...[
          const Text(
            'Reenviar crea un enlace nuevo e invalida todos los enlaces y desafíos anteriores. Máximo cinco intentos por hora y uno por minuto, incluido el inicial.',
          ),
          FilledButton(
            onPressed: state.busy
                ? null
                : () async {
                    if (!await confirmAction(
                      context,
                      '¿Generar un nuevo enlace? Se invalidarán los enlaces y desafíos anteriores.',
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    await controller.resend();
                  },
            child: const Text('Reenviar enlace de activación'),
          ),
        ],
      ],
    );
  }
}

class OnboardingSummary extends StatelessWidget {
  const OnboardingSummary(this.data, {super.key});
  final TenantOnboarding data;
  String date(DateTime? value) => value?.toLocal().toString() ?? 'Sin registro';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Correo de acceso: ${data.ownerEmail}'),
      Text('Activación: ${data.activationStatus.name}'),
      Text('Entrega: ${data.deliveryStatus.name}'),
      const Text(
        'ACCEPTED significa aceptación por el transporte, no entrega al buzón.',
      ),
      Text('Vencimiento del enlace: ${date(data.activationLinkExpiresAt)}'),
      Text('Último intento: ${date(data.lastAttemptAt)}'),
      Text('Aceptación del transporte: ${date(data.providerAcceptedAt)}'),
      Text('Activación completada: ${date(data.completedAt)}'),
    ],
  );
}
