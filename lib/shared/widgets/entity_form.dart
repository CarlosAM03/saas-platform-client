import 'package:flutter/material.dart';
import '../../core/errors/error_mapper.dart';
import 'beta_components.dart';

class FormFieldSpec {
  const FormFieldSpec(this.key, this.label,
      {this.initial = '',
      this.validator,
      this.options,
      this.secret = false,
      this.lines = 1,
      this.nullable = false,
      this.hint});
  final String key, label, initial;
  final String? hint;
  final String? Function(String?)? validator;
  final Map<String, String>? options;
  final bool secret, nullable;
  final int lines;
}

Future<bool> showEntityForm(BuildContext context,
        {required String title,
        required List<FormFieldSpec> fields,
        required Future<void> Function(Map<String, dynamic>) save,
        String? description,
        bool changedOnly = false}) async =>
    await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EntityFormDialog(
            title: title,
            fields: fields,
            save: save,
            description: description,
            changedOnly: changedOnly)) ??
    false;

class EntityFormDialog extends StatefulWidget {
  const EntityFormDialog(
      {required this.title,
      required this.fields,
      required this.save,
      this.description,
      this.changedOnly = false,
      super.key});
  final String title;
  final String? description;
  final List<FormFieldSpec> fields;
  final Future<void> Function(Map<String, dynamic>) save;
  final bool changedOnly;
  @override
  State<EntityFormDialog> createState() => _EntityFormDialogState();
}

class _EntityFormDialogState extends State<EntityFormDialog> {
  final form = GlobalKey<FormState>();
  late final controllers = {
    for (final field in widget.fields)
      field.key: TextEditingController(text: field.initial)
  };
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    final values = <String, dynamic>{};
    for (final field in widget.fields) {
      final text = field.secret
          ? controllers[field.key]!.text
          : controllers[field.key]!.text.trim();
      if (widget.changedOnly && text == field.initial) continue;
      if (field.secret && text.isEmpty) continue;
      values[field.key] = field.nullable && text.isEmpty ? null : text;
    }
    if (values.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.save(values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.description != null) ...[
                            Text(widget.description!),
                            const SizedBox(height: 20)
                          ],
                          for (final field in widget.fields) ...[
                            if (field.options != null)
                              DropdownButtonFormField<String>(
                                initialValue: field.initial,
                                decoration:
                                    InputDecoration(labelText: field.label),
                                items: field.options!.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.key, child: Text(e.value)))
                                    .toList(),
                                onChanged: busy
                                    ? null
                                    : (value) =>
                                        controllers[field.key]!.text = value!,
                              )
                            else
                              TextFormField(
                                controller: controllers[field.key],
                                enabled: !busy,
                                obscureText: field.secret,
                                maxLines: field.lines,
                                validator: field.validator,
                                keyboardType: field.key == 'email'
                                    ? TextInputType.emailAddress
                                    : field.key == 'phone'
                                        ? TextInputType.phone
                                        : TextInputType.text,
                                decoration: InputDecoration(
                                    labelText: field.label,
                                    helperText: field.hint),
                              ),
                            const SizedBox(height: 16),
                          ],
                          if (error != null)
                            Text(const ErrorMapper().userMessage(error!),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                        ])))),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy ? 'Guardando…' : 'Guardar'))
        ],
      ));
}

List<FormFieldSpec> organizationFields() => [
      const FormFieldSpec('name', 'Nombre de la organización',
          validator: requiredField),
      FormFieldSpec('slug', 'Identificador',
          hint: 'Ejemplo: acme-marketing',
          validator: (value) => value == null ||
                  !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)
              ? 'Usa letras minúsculas, números y guiones.'
              : null),
    ];
