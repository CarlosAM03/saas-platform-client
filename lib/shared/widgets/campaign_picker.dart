import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../platform_api/platform_api.dart';
import '../../features/campaigns/state/campaigns_providers.dart';
import 'feature_widgets.dart';

Future<Campaign?> pickCampaign(BuildContext context, WidgetRef ref) =>
    showDialog<Campaign>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Seleccionar campaña'),
                content: SizedBox(
                    width: 600,
                    height: 420,
                    child: PagedList<Campaign>(
                        load: (ref, key) =>
                            ref.watch(campaignsListProvider(key)),
                        refresh: () => ref.invalidate(campaignsListProvider),
                        item: (campaign) => ListTile(
                            title: Text(campaign.name),
                            subtitle: Text(campaign.status.name),
                            onTap: () => Navigator.pop(dialog, campaign)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Cancelar'))
                ]));
