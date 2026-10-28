import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/activation_controller.dart';
import '../state/registration_validation.dart';

class ActivationPage extends ConsumerStatefulWidget {
  const ActivationPage({super.key});
  @override
  ConsumerState<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends ConsumerState<ActivationPage> {
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  final passwordFocus = FocusNode();
  late final ActivationController controller;
  @override
  void initState() {
    super.initState();
    controller = ref.read(activationControllerProvider.notifier);
    Future<void>.microtask(() => controller.begin());
  }

  @override
  void dispose() {
    password.clear();
    password.dispose();
    passwordFocus.dispose();
    controller.leave();
    super.dispose();
  }

  Future<void> submit() async {
    if (ref.read(activationControllerProvider).busy) return;
    if (!form.currentState!.validate()) {
      passwordFocus.requestFocus();
      return;
    }
    final completion = controller.complete(password.text);
    password.clear();
    if (await completion && mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activationControllerProvider);
    ref.listen(activationControllerProvider, (_, next) {
      if (next.phase == ActivationPhase.failed ||
          next.phase == ActivationPhase.completed) {
        password.clear();
      }
    });
    final canComplete =
        state.phase == ActivationPhase.password ||
        state.phase == ActivationPhase.completing;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Activa tu cuenta',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text(
                  'Este enlace no inicia una sesión. Al terminar deberás usar el login habitual.',
                ),
                if (state.busy) const LinearProgressIndicator(),
                if (state.message != null)
                  Semantics(liveRegion: true, child: Text(state.message!)),
                if (canComplete)
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Vencimiento indicado por el servidor: ${state.expiresAt?.toLocal()}',
                        ),
                        const Text(
                          'Mínimo 10 caracteres Unicode, letra, número y especial; máximo 72 bytes UTF-8.',
                        ),
                        const Text(
                          'El servidor valida el vencimiento al enviar; la hora del dispositivo puede ser diferente.',
                        ),
                        TextFormField(
                          controller: password,
                          focusNode: passwordFocus,
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          enabled: !state.busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: null,
                          validator: initialPassword,
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                          ),
                          onFieldSubmitted: (_) {
                            if (!state.busy) unawaited(submit());
                          },
                        ),
                        FilledButton(
                          onPressed: state.busy ? null : submit,
                          child: const Text('Establecer contraseña'),
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    controller.leave();
                    context.go('/login');
                  },
                  child: const Text('Volver al login'),
                ),
                const Text(
                  'Si perdiste la respuesta o venció el desafío, solicita un nuevo enlace al administrador. No recargues ni reutilices el enlace.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
