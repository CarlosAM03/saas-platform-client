import 'package:flutter/material.dart';

Future<void> showRegisterDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const RegisterDialog(),
  );
}

class RegisterDialog extends StatefulWidget {
  const RegisterDialog({super.key});

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Correo no válido';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Campo obligatorio';
    if (v.length < 10) return 'Mínimo 10 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Debe incluir una letra';
    if (!RegExp(r'\d').hasMatch(v)) return 'Debe incluir un número';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Debe incluir un carácter especial';
    return null;
  }

  String? _validateConfirm(String? v) =>
      v != _password.text ? 'Las contraseñas no coinciden' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: conectar con el backend cuando exista el endpoint de registro.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario válido (registro aún sin backend).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Crear cuenta',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellido,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: _required,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hidePassword,
                  decoration: const InputDecoration(labelText: 'Repite la contraseña'),
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _submit, child: const Text('Registrarme')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}