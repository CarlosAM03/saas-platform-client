import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../state/auth_state.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/beta_components.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool obscure = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .login(email.text.trim(), password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  color: Color(0xFF2563EB),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PLATAFORMA SaaS · BETA',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                Surface(
                  padding: 28,
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bienvenido de nuevo',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inicia sesión para gestionar tus campañas y tu organización.',
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: email,
                          enabled: !auth.busy,
                          validator: emailField,
                          autofillHints: const [AutofillHints.username],
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'usuario@empresa.com',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: password,
                          enabled: !auth.busy,
                          obscureText: obscure,
                          validator: requiredField,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => auth.busy ? null : submit(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              tooltip: obscure
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (auth.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              const ErrorMapper().userMessage(auth.error!),
                              style: const TextStyle(color: Color(0xFFDC2626)),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: auth.busy ? null : submit,
                          child: Text(
                            auth.busy ? 'Iniciando sesión…' : 'Iniciar sesión',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '¿Necesitas acceso o recuperar tu contraseña? Contacta al administrador de tu organización.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SelectTenantPage extends ConsumerWidget {
  const SelectTenantPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final contextTenants = auth.context?.tenants ?? const [];
    final needsDiscovery = auth.context?.user.platformRole == 'ADMIN';
    final discovery = needsDiscovery
        ? ref.watch(tenantDiscoveryProvider)
        : null;
    final tenants = discovery?.asData?.value ?? contextTenants;
    final errorMapper = ref.watch(errorMapperProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar organización'),
        actions: [
          if (auth.context?.user.platformRole == 'ADMIN')
            TextButton(
              onPressed: auth.busy
                  ? null
                  : () => GoRouter.maybeOf(context)?.go('/tenants/new'),
              child: const Text('Registrar organización'),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: auth.busy
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (discovery?.isLoading == true || auth.status == AuthStatus.loading)
            const LinearProgressIndicator(),
          if (discovery?.hasError == true)
            Column(
              children: [
                Text(errorMapper.userMessage(discovery!.error!)),
                TextButton(
                  onPressed: () => ref.invalidate(tenantDiscoveryProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          if (auth.error != null) Text(errorMapper.userMessage(auth.error!)),
          if (discovery?.isLoading != true &&
              discovery?.hasError != true &&
              tenants.isEmpty)
            const Text('No hay tenants disponibles.'),
          Expanded(
            child: ListView.builder(
              itemCount: tenants.length,
              itemBuilder: (_, index) {
                final tenant = tenants[index];
                return ListTile(
                  title: Text(tenant.name),
                  subtitle: Text(tenant.slug),
                  onTap: auth.status == AuthStatus.loading
                      ? null
                      : () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .selectTenant(tenant.id);
                          if (!context.mounted) return;
                          final state = ref.read(authControllerProvider);
                          if (state.status == AuthStatus.authenticated &&
                              state.context?.currentTenantId == tenant.id &&
                              state.error == null) {
                            GoRouter.maybeOf(context)?.go('/dashboard');
                          }
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SessionExpiredPage extends ConsumerWidget {
  const SessionExpiredPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => ref
            .read(authControllerProvider.notifier)
            .acknowledgeSessionExpired(),
        child: const Text('Sesión expirada: volver a entrar'),
      ),
    ),
  );
}

class BackendUnavailablePage extends ConsumerWidget {
  const BackendUnavailablePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('El backend no está disponible.'),
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).restoreSession(),
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Volver a login'),
          ),
        ],
      ),
    ),
  );
}
