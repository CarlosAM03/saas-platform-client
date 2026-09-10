import 'package:flutter/material.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({required this.loading, required this.empty, required this.error, required this.success, super.key});
  final bool loading;
  final bool empty;
  final Object? error;
  final Widget success;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('No fue posible cargar la información.'));
    if (empty) return const Center(child: Text('No hay información disponible.'));
    return success;
  }
}
