import 'package:flutter/material.dart';
import '../../core/errors/error_mapper.dart';
import '../models/api_models.dart';

String dateLabel(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  return date == null
      ? 'Sin fecha'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class PageBody extends StatelessWidget {
  const PageBody({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding:
            EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            )),
      );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {this.action, super.key});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ]),
          if (action != null) action!
        ],
      ));
}

class Surface extends StatelessWidget {
  const Surface({required this.child, this.padding = 20, super.key});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12)),
        child: child,
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ACTIVA' => ('Activa', const Color(0xFF16A34A)),
      'ACTIVO' => ('Activo', const Color(0xFF16A34A)),
      'PAUSADA' => ('Pausada', const Color(0xFFD97706)),
      'COMPLETADA' || 'COMPLETED' => ('Completada', const Color(0xFF2563EB)),
      'ARCHIVADA' => ('Archivada', const Color(0xFF64748B)),
      'INACTIVO' => ('Inactivo', const Color(0xFF64748B)),
      'QUEUED' => ('En espera', const Color(0xFF64748B)),
      'RUNNING' => ('En curso', const Color(0xFF2563EB)),
      'FAILED' => ('Error', const Color(0xFFDC2626)),
      'CANCELLED' => ('Cancelado', const Color(0xFFD97706)),
      _ => (status, const Color(0xFF64748B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color))
      ]),
    );
  }
}

class StatePanel extends StatelessWidget {
  const StatePanel(
      {required this.title,
      required this.message,
      this.icon = Icons.inbox_outlined,
      this.action,
      super.key});
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Surface(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [
            Icon(icon, size: 40, color: const Color(0xFF64748B)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ])));
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel(this.error, this.retry, {super.key});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => StatePanel(
      title: 'No pudimos cargar la información',
      message: const ErrorMapper().userMessage(error),
      icon: Icons.cloud_off_outlined,
      action: OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar')));
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
          child: Column(children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Cargando información…')
      ])));
}

class PaginationBar extends StatelessWidget {
  const PaginationBar(this.meta, this.onPage, {super.key});
  final PaginationMeta meta;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                '${meta.total} registros · Página ${meta.page} de ${meta.totalPages == 0 ? 1 : meta.totalPages}'),
            IconButton(
                tooltip: 'Página anterior',
                onPressed: meta.page > 1 ? () => onPage(meta.page - 1) : null,
                icon: const Icon(Icons.chevron_left)),
            IconButton(
                tooltip: 'Página siguiente',
                onPressed: meta.page < meta.totalPages
                    ? () => onPage(meta.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right)),
          ]));
}

void showFeedback(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
Future<bool> confirmAction(
        BuildContext context, String title, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirmar'))
              ],
            )) ??
    false;
String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'Completa este campo.' : null;
String? emailField(String? value) => value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Introduce un correo válido.'
    : null;
String? passwordField(String? value) {
  final text = value ?? '';
  return text.length < 10 ||
          !RegExp(r'[a-zA-ZáéíóúñÁÉÍÓÚÑ]').hasMatch(text) ||
          !RegExp(r'\d').hasMatch(text) ||
          !RegExp(r'[^\w\s]').hasMatch(text)
      ? 'Usa 10 caracteres, una letra, un número y un símbolo.'
      : null;
}
