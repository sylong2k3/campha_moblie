import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/map_controller.dart';

class BasemapSelectionSheet extends ConsumerWidget {
  const BasemapSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapCatalogProvider);
    final controller = ref.read(mapCatalogProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.mapBasemapTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.basemaps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(context.l10n.mapBasemapEmpty),
                )
              else
                RadioGroup<String>(
                  groupValue: state.selectedBasemapCode,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectBasemap(value);
                      Navigator.pop(context);
                    }
                  },
                  child: Column(
                    children: [
                      for (final basemap in state.basemaps)
                        RadioListTile<String>(
                          value: basemap.code,
                          title: Text(
                            basemap.nameVi,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(basemap.provider.toUpperCase()),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
