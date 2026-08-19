import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../map/domain/feature_detail_model.dart';
import '../../map/domain/map_controller.dart';
import '../../map/presentation/feature_detail_screen.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../tools/domain/field_tools_models.dart';
import '../data/feature_edit_repository.dart';
import '../data/offline_edit_queue.dart';
import '../domain/feature_sync_controller.dart';

class FeatureEditScreen extends ConsumerStatefulWidget {
  const FeatureEditScreen({
    super.key,
    required this.layerId,
    required this.featureId,
  });
  final String layerId;
  final String featureId;
  @override
  ConsumerState<FeatureEditScreen> createState() => _FeatureEditScreenState();
}

class _FeatureEditScreenState extends ConsumerState<FeatureEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dirtyFields = <String>{};
  late Future<FeatureDetailModel> _future;
  GeoJsonGeometry? _geometry;
  bool _geometryDirty = false;
  bool _submitting = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _future = ref.read(
      mapFeatureProvider((
        layerId: widget.layerId,
        featureId: widget.featureId,
      )).future,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _dirty => _geometryDirty || _dirtyFields.isNotEmpty;

  Future<bool> _canLeave() async {
    if (!_dirty || _submitting) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.featureUnsavedTitle),
            content: Text(context.l10n.featureUnsavedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.featureDiscard),
              ),
            ],
          ),
        ) ??
        false;
  }

  Map<String, dynamic> _attributes(FeatureDetailModel feature) {
    final output = <String, dynamic>{};
    for (final key in _dirtyFields) {
      final controller = _controllers[key];
      if (controller == null) continue;
      final source = feature.attributes[key];
      final text = controller.text.trim();
      output[key] = switch (source) {
        bool _ => text.isEmpty ? null : text.toLowerCase() == 'true',
        int _ => text.isEmpty ? null : int.parse(text),
        double _ => text.isEmpty ? null : double.parse(text),
        _ => text.isEmpty ? null : text,
      };
    }
    return output;
  }

  String? _validateValue(String? value, Object? source) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > 2000) {
      return context.l10n.featureInvalidValue;
    }
    if (source is bool && !{'true', 'false'}.contains(value.toLowerCase())) {
      return context.l10n.featureInvalidValue;
    }
    if (source is int && int.tryParse(value) == null) {
      return context.l10n.featureInvalidValue;
    }
    if (source is double && double.tryParse(value) == null) {
      return context.l10n.featureInvalidValue;
    }
    return null;
  }

  String _fieldLabel(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Future<void> _enqueueOffline(
    FeatureDetailModel feature,
    Map<String, dynamic> attributes,
  ) async {
    final owner = ref.read(sessionControllerProvider).user!.id;
    await (await ref.read(offlineEditQueueProvider.future)).enqueue(
      ownerId: owner,
      layerId: widget.layerId,
      featureId: widget.featureId,
      baseVersion: feature.version!,
      attributes: attributes,
      geometry: _geometryDirty ? _geometry : null,
    );
    await ref.read(featureSyncProvider.notifier).refresh();
  }

  Future<void> _save(
    FeatureDetailModel feature, {
    required bool offline,
  }) async {
    if (!(_formKey.currentState?.validate() ?? false) || _submitting) {
      return;
    }
    final attributes = _attributes(feature);
    if (attributes.isEmpty && !_geometryDirty) {
      setState(() => _saveErrorMessage = context.l10n.featureNoChanges);
      return;
    }
    setState(() {
      _submitting = true;
      _saveErrorMessage = null;
    });
    try {
      if (offline) {
        await _enqueueOffline(feature, attributes);
      } else {
        await ref
            .read(featureEditRepositoryProvider)
            .update(
              layerId: widget.layerId,
              featureId: widget.featureId,
              baseVersion: feature.version!,
              attributes: attributes,
              geometry: _geometryDirty ? _geometry : null,
            );
        ref.invalidate(
          mapFeatureProvider((
            layerId: widget.layerId,
            featureId: widget.featureId,
          )),
        );
      }
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (error is ConflictException &&
          error.errors?.contains('FEATURE_VERSION_CONFLICT') == true &&
          mounted) {
        final choice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.featureConflictTitle),
            content: Text(context.l10n.featureConflictBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.featureReloadServer),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.featureSaveOffline),
              ),
            ],
          ),
        );
        if (choice == true && mounted) {
          await _enqueueOffline(feature, attributes);
          if (mounted) context.pop();
        } else if (choice == false && mounted) {
          for (final controller in _controllers.values) {
            controller.dispose();
          }
          setState(() {
            _controllers.clear();
            _dirtyFields.clear();
            _geometry = null;
            _geometryDirty = false;
            _future = ref.read(
              mapFeatureProvider((
                layerId: widget.layerId,
                featureId: widget.featureId,
              )).future,
            );
          });
        }
      } else if (mounted) {
        setState(
          () => _saveErrorMessage = error.localizedErrorMessage(context.l10n),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).user;
    final catalog = ref.watch(mapCatalogProvider);
    final layer = catalog.layers
        .where((item) => item.id == widget.layerId)
        .firstOrNull;
    if (layer == null && catalog.loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (layer == null ||
        user?.roleCode != 'so_tnmt' ||
        !user!.hasPermission('map_feature', 'update') ||
        !layer.canEdit) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.featureEditForbidden)),
      );
    }
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _canLeave() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.featureEditTitle)),
        body: FutureBuilder<FeatureDetailModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error!.localizedErrorMessage(context.l10n),
                ),
              );
            }
            final feature = snapshot.requireData;
            _geometry ??= feature.geometry == null
                ? null
                : GeoJsonGeometry.fromJson(feature.geometry!);
            if (feature.version == null || _geometry == null) {
              return Center(child: Text(context.l10n.featureEditUnavailable));
            }
            final editable = feature.attributes.entries
                .where((entry) => layer.editableFields.contains(entry.key))
                .toList(growable: false);
            return Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      children: [
                        Text(
                          context.l10n.mapAttributesTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        for (final entry in editable) ...[
                          TextFormField(
                            controller: _controllers.putIfAbsent(
                              entry.key,
                              () => TextEditingController(
                                text: entry.value?.toString() ?? '',
                              ),
                            ),
                            decoration: InputDecoration(
                              labelText: _fieldLabel(entry.key),
                            ),
                            validator: (value) =>
                                _validateValue(value, entry.value),
                            onChanged: (_) => setState(() {
                              _dirtyFields.add(entry.key);
                              _saveErrorMessage = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          context.l10n.mapGeometryTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        _GeometryEditor(
                          geometry: _geometry!,
                          onChanged: (value) => setState(() {
                            _geometry = value;
                            _geometryDirty = true;
                            _saveErrorMessage = null;
                          }),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${context.l10n.featureVersion} ${feature.version}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_saveErrorMessage case final message?)
                            AppInlineNotice(
                              message: message,
                              icon: Icons.error_outline,
                              tone: AppFeedbackTone.error,
                              liveRegion: true,
                            )
                          else if (!_dirty)
                            AppInlineNotice(
                              message: context.l10n.featureNoChanges,
                              icon: Icons.info_outline,
                              tone: AppFeedbackTone.neutral,
                            ),
                          const SizedBox(height: 10),
                          OverflowBar(
                            alignment: MainAxisAlignment.end,
                            overflowAlignment: OverflowBarAlignment.end,
                            spacing: 8,
                            overflowSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: !_dirty || _submitting
                                    ? null
                                    : () => _save(feature, offline: true),
                                icon: const Icon(Icons.save_outlined),
                                label: Text(context.l10n.featureSaveOffline),
                              ),
                              FilledButton.icon(
                                onPressed: !_dirty || _submitting
                                    ? null
                                    : () => _save(feature, offline: false),
                                icon: _submitting
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload_outlined),
                                label: Text(context.l10n.featureSaveNow),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GeometryEditor extends StatelessWidget {
  const _GeometryEditor({required this.geometry, required this.onChanged});
  final GeoJsonGeometry geometry;
  final ValueChanged<GeoJsonGeometry> onChanged;

  List<GeoCoordinate> get _vertices {
    final coordinates = geometry.coordinates as List;
    final raw = switch (geometry.type) {
      'Point' => <Object?>[coordinates],
      'Polygon' => coordinates.first as List,
      _ => coordinates,
    };
    final vertices = raw.map(GeoCoordinate.fromJson).toList();
    if (geometry.type == 'Polygon' && vertices.length > 1) {
      vertices.removeLast();
    }
    return vertices;
  }

  String? _validateCoordinate(
    BuildContext context,
    int index,
    String? value,
    bool longitude,
  ) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return context.l10n.featureInvalidValue;
    final old = _vertices[index];
    final next = GeoCoordinate(
      longitude ? parsed : old.longitude,
      longitude ? old.latitude : parsed,
    );
    return next.isInCamPhaBounds
        ? null
        : context.l10n.featureCoordinateOutOfBounds;
  }

  void _replace(int index, String value, bool longitude) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    final vertices = _vertices;
    final old = vertices[index];
    final next = GeoCoordinate(
      longitude ? parsed : old.longitude,
      longitude ? old.latitude : parsed,
    );
    if (!next.isInCamPhaBounds) return;
    vertices[index] = next;
    onChanged(switch (geometry.type) {
      'Point' => GeoJsonGeometry.point(vertices.single),
      'LineString' => GeoJsonGeometry.line(vertices),
      'Polygon' => GeoJsonGeometry.polygon(vertices),
      _ => geometry,
    });
  }

  @override
  Widget build(BuildContext context) {
    final vertices = _vertices;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              '${geometry.type} · ${vertices.length} ${context.l10n.featureVertices}',
            ),
            for (var index = 0; index < vertices.length; index++)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked =
                        constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final longitude = TextFormField(
                      initialValue: '${vertices[index].longitude}',
                      decoration: InputDecoration(
                        labelText: context.l10n.featureLongitude,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) =>
                          _validateCoordinate(context, index, value, true),
                      onChanged: (value) => _replace(index, value, true),
                    );
                    final latitude = TextFormField(
                      initialValue: '${vertices[index].latitude}',
                      decoration: InputDecoration(
                        labelText: context.l10n.featureLatitude,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) =>
                          _validateCoordinate(context, index, value, false),
                      onChanged: (value) => _replace(index, value, false),
                    );
                    if (stacked) {
                      return Column(
                        children: [
                          longitude,
                          const SizedBox(height: 10),
                          latitude,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: longitude),
                        const SizedBox(width: 8),
                        Expanded(child: latitude),
                      ],
                    );
                  },
                ),
              ),
            if (geometry.type != 'Point' &&
                vertices.length > (geometry.type == 'Polygon' ? 3 : 2))
              TextButton.icon(
                onPressed: () {
                  final next = [...vertices]..removeLast();
                  onChanged(
                    geometry.type == 'Polygon'
                        ? GeoJsonGeometry.polygon(next)
                        : GeoJsonGeometry.line(next),
                  );
                },
                icon: const Icon(Icons.undo),
                label: Text(context.l10n.featureUndo),
              ),
          ],
        ),
      ),
    );
  }
}
