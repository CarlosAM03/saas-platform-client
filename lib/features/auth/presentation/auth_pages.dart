import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../state/auth_state.dart';

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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final errorMapper = ref.watch(errorMapperProvider);
    return Scaffold(
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Iniciar sesión',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Correo electrónico')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: password,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Contraseña')),
                  if (auth.error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(errorMapper.userMessage(auth.error!),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: auth.status == AuthStatus.loading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .login(email.text.trim(), password.text),
                      child: auth.status == AuthStatus.loading
                          ? const CircularProgressIndicator()
                          : const Text('Entrar')),
                ]),
              ))),
    );
  }
}

class SelectTenantPage extends ConsumerWidget {
  const SelectTenantPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final contextTenants = auth.context?.tenants ?? const [];
    final needsDiscovery =
        auth.context?.user.platformRole == 'ADMIN' && contextTenants.isEmpty;
    final discovery =
        needsDiscovery ? ref.watch(tenantDiscoveryProvider) : null;
    final tenants = discovery?.valueOrNull ?? contextTenants;
    final errorMapper = ref.watch(errorMapperProvider);

    return Scaffold(
        appBar: AppBar(title: const Text('Seleccionar tenant')),
        body: Column(children: [
          if (discovery?.isLoading == true || auth.status == AuthStatus.loading)
            const LinearProgressIndicator(),
          if (discovery?.hasError == true)
            Column(children: [
              Text(errorMapper.userMessage(discovery!.error!)),
              TextButton(
                  onPressed: () => ref.invalidate(tenantDiscoveryProvider),
                  child: const Text('Reintentar')),
            ]),
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
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .selectTenant(tenant.id),
                    );
                  })),
        ]));
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
        )),
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
      )));
}
