import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
<<<<<<< Updated upstream
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../state/auth_state.dart';
=======
import '../../../app/app_providers.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/beta_components.dart';
import '../../../shared/widgets/entity_form.dart';
import '../../workspace/data/platform_repository.dart';
>>>>>>> Stashed changes

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
<<<<<<< Updated upstream
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
=======
  Widget build(BuildContext context) => const Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.layers_outlined, size: 56, color: Color(0xFF2563EB)),
        SizedBox(height: 16),
        Text('Plataforma SaaS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        SizedBox(height: 32),
        CircularProgressIndicator(),
      ])));
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======

  void submit() {
    if (form.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .login(email.text.trim(), password.text);
    }
  }
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
<<<<<<< Updated upstream
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
=======
    return Scaffold(
        body: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(children: [
                    const Icon(Icons.layers_outlined,
                        color: Color(0xFF2563EB), size: 48),
                    const SizedBox(height: 16),
                    const Text('PLATAFORMA SaaS · BETA',
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 32),
                    Surface(
                        padding: 28,
                        child: Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Bienvenido de nuevo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Inicia sesión para gestionar tus campañas y tu organización.'),
                                  const SizedBox(height: 28),
                                  TextFormField(
                                      controller: email,
                                      enabled: !auth.busy,
                                      validator: emailField,
                                      autofillHints: const [
                                        AutofillHints.username
                                      ],
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                          labelText: 'Correo electrónico',
                                          hintText: 'usuario@empresa.com')),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                      controller: password,
                                      enabled: !auth.busy,
                                      obscureText: obscure,
                                      validator: requiredField,
                                      autofillHints: const [
                                        AutofillHints.password
                                      ],
                                      onFieldSubmitted: (_) =>
                                          auth.busy ? null : submit(),
                                      decoration: InputDecoration(
                                          labelText: 'Contraseña',
                                          suffixIcon: IconButton(
                                              tooltip: obscure
                                                  ? 'Mostrar contraseña'
                                                  : 'Ocultar contraseña',
                                              onPressed: () => setState(
                                                  () => obscure = !obscure),
                                              icon: Icon(obscure
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined)))),
                                  if (auth.error != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                            const ErrorMapper()
                                                .userMessage(auth.error!),
                                            style: const TextStyle(
                                                color: Color(0xFFDC2626)))),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                      onPressed: auth.busy ? null : submit,
                                      child: Text(auth.busy
                                          ? 'Iniciando sesión…'
                                          : 'Iniciar sesión')),
                                  const SizedBox(height: 16),
                                  const Text(
                                      '¿Necesitas acceso o recuperar tu contraseña? Contacta al administrador de tu organización.',
                                      textAlign: TextAlign.center),
                                ]))),
                  ]),
                ))));
>>>>>>> Stashed changes
  }
}

class SelectTenantPage extends ConsumerWidget {
  const SelectTenantPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Tu espacio de trabajo'), actions: [
          TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Perfil')),
        ]),
        body: const OrganizationPicker(),
      );
}

class OrganizationPicker extends ConsumerWidget {
  const OrganizationPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
<<<<<<< Updated upstream
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
                  })),
        ]));
=======
    final data = ref.watch(organizationsProvider);
    final admin = auth.context?.user.platformRole == 'ADMIN';
    return PageBody(children: [
      PageHeading(
          'Organizaciones', 'Selecciona el espacio en el que quieres trabajar.',
          action: admin
              ? FilledButton.icon(
                  onPressed: auth.busy
                      ? null
                      : () async {
                          final saved = await showEntityForm(context,
                              title: 'Crear organización',
                              fields: organizationFields(),
                              save: (values) async {
                            await ref
                                .read(platformRepositoryProvider)
                                .create('tenants', values);
                          });
                          if (saved) {
                            ref.invalidate(organizationsProvider);
                            if (context.mounted) {
                              showFeedback(context,
                                  'Organización creada. Ya puedes seleccionarla.');
                            }
                          }
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear organización'))
              : null),
      if (auth.error != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(const ErrorMapper().userMessage(auth.error!),
                style: const TextStyle(color: Color(0xFFDC2626)))),
      if (auth.busy) const LinearProgressIndicator(),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(organizationsProvider)),
          data: (items) {
            if (items.isEmpty) {
              return const StatePanel(
                  title: 'Todavía no hay organizaciones',
                  message:
                      'Un administrador puede crear un espacio de trabajo para comenzar.',
                  icon: Icons.business_outlined);
            }
            return Column(children: [
              for (final item in items)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Surface(
                        padding: 4,
                        child: ListTile(
                          leading: const CircleAvatar(
                              backgroundColor: Color(0xFFDBEAFE),
                              child: Icon(Icons.business_outlined)),
                          title: Text(item['name'] as String),
                          subtitle: Text(item['slug'] as String),
                          trailing: item['status'] != 'ACTIVO'
                              ? const Text('Inactiva')
                              : Icon(auth.context?.currentTenantId == item['id']
                                  ? Icons.check_circle_outline
                                  : Icons.chevron_right),
                          onTap: auth.busy || item['status'] != 'ACTIVO'
                              ? null
                              : () async {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .selectTenant(item['id'] as String);
                                  if (context.mounted &&
                                      ref
                                              .read(authControllerProvider)
                                              .context
                                              ?.currentTenantId ==
                                          item['id']) {
                                    context.go('/dashboard');
                                  }
                                },
                        )))
            ]);
          }),
    ]);
>>>>>>> Stashed changes
  }
}

class SessionExpiredPage extends ConsumerWidget {
  const SessionExpiredPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
<<<<<<< Updated upstream
        body: Center(
            child: FilledButton(
          onPressed: () => ref
              .read(authControllerProvider.notifier)
              .acknowledgeSessionExpired(),
          child: const Text('Sesión expirada: volver a entrar'),
        )),
      );
=======
          body: PageBody(children: [
        StatePanel(
            title: 'Tu sesión ha expirado',
            message: 'Inicia sesión nuevamente para continuar.',
            icon: Icons.lock_clock_outlined,
            action: FilledButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Volver a iniciar sesión'))),
      ]));
>>>>>>> Stashed changes
}

class BackendUnavailablePage extends ConsumerWidget {
  const BackendUnavailablePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
<<<<<<< Updated upstream
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
=======
          body: PageBody(children: [
        StatePanel(
            title: 'No pudimos conectar',
            message:
                'Tu sesión se conserva. Puedes intentar nuevamente cuando se restablezca la conexión.',
            icon: Icons.cloud_off_outlined,
            action: Wrap(spacing: 12, children: [
              FilledButton(
                  onPressed: () => ref
                      .read(authControllerProvider.notifier)
                      .restoreSession(),
                  child: const Text('Reintentar')),
              OutlinedButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Volver al inicio')),
            ])),
      ]));
>>>>>>> Stashed changes
}
