import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).context?.user;
    return Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(user?.name ?? 'Perfil', style: Theme.of(context).textTheme.headlineSmall),
      Text(user?.email ?? ''),
      Text('Rol de plataforma: ${user?.platformRole ?? 'tenant-scoped'}'),
    ]));
  }
}
