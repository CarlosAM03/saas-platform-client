import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/feature_widgets.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) => FeaturePage(
      title: 'Administración',
      child: ListView(children: [
        ListTile(
            title: const Text('Organizaciones'),
            onTap: () => context.go('/tenants')),
        ListTile(
            title: const Text('Usuarios'), onTap: () => context.go('/users'))
      ]));
}
