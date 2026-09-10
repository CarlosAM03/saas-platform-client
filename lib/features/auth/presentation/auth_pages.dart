import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../state/auth_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
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
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) context.go('/dashboard');
    });
    return Scaffold(
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Iniciar sesión', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
          if (auth.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('No se pudo iniciar sesión.', style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 20),
          FilledButton(onPressed: auth.status == AuthStatus.loading ? null : () => ref.read(authControllerProvider.notifier).login(email.text.trim(), password.text), child: auth.status == AuthStatus.loading ? const CircularProgressIndicator() : const Text('Entrar')),
        ]),
      ))),
    );
  }
}

class SelectTenantPage extends ConsumerWidget {
  const SelectTenantPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenants = ref.watch(authControllerProvider).context?.tenants ?? const [];
    return Scaffold(appBar: AppBar(title: const Text('Seleccionar tenant')), body: ListView.builder(itemCount: tenants.length, itemBuilder: (_, index) {
      final tenant = tenants[index];
      return ListTile(title: Text(tenant.name), subtitle: Text(tenant.slug), onTap: () => ref.read(authControllerProvider.notifier).selectTenant(tenant.id));
    }));
  }
}

class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: FilledButton(onPressed: () => context.go('/login'), child: const Text('Sesión expirada: volver a entrar'))));
}

class BackendUnavailablePage extends StatelessWidget {
  const BackendUnavailablePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('El backend no está disponible.')));
}
