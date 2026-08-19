import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../app/router/route_names.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../tools/domain/field_tools_models.dart';
import '../domain/report_composer_controller.dart';

class CreateFieldReportScreen extends ConsumerStatefulWidget {
  const CreateFieldReportScreen({super.key});
  @override
  ConsumerState<CreateFieldReportScreen> createState() =>
      _CreateFieldReportScreenState();
}

enum _LocationProblem { serviceDisabled, denied, deniedForever }

class _CreateFieldReportScreenState
    extends ConsumerState<CreateFieldReportScreen> {
  final _picker = picker.ImagePicker();
  final _descriptionController = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _truthKey = GlobalKey();
  final _truthFocus = FocusNode();
  bool _descriptionSeeded = false;
  bool _cameraPrimerSeen = false;
  bool _cameraPermissionDenied = false;
  bool _locating = false;
  _LocationProblem? _locationProblem;

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    _truthFocus.dispose();
    super.dispose();
  }

  Future<bool> _confirmPermission({
    required String title,
    required String body,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              key: const ValueKey('permission-primer-cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              key: const ValueKey('permission-primer-continue'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.commonContinue),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _pick(picker.ImageSource source) async {
    if (source == picker.ImageSource.camera && !_cameraPrimerSeen) {
      final proceed = await _confirmPermission(
        title: context.l10n.reportCameraPrimerTitle,
        body: context.l10n.reportCameraPrimerBody,
      );
      if (!proceed || !mounted) return;
      _cameraPrimerSeen = true;
    }
    try {
      if (source == picker.ImageSource.gallery) {
        final remaining = 5 - ref.read(reportComposerProvider).media.length;
        if (remaining <= 0) return;
        final picked = await _picker.pickMultiImage(
          imageQuality: 92,
          requestFullMetadata: false,
        );
        if (!mounted || picked.isEmpty) return;
        for (final image in picked.take(remaining)) {
          await _addMedia(image.path, image.mimeType);
        }
        if (picked.length > remaining && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.reportPhotoLimit)),
          );
        }
        return;
      }

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (mounted) setState(() => _cameraPermissionDenied = false);
      if (picked == null || !mounted) return;
      await _addMedia(picked.path, picked.mimeType);
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (mounted &&
          source == picker.ImageSource.camera &&
          (code.contains('camera') || code.contains('permission'))) {
        setState(() => _cameraPermissionDenied = true);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    }
  }

  Future<void> _addMedia(String path, String? mimeType) async {
    final mime =
        mimeType ??
        switch (path.toLowerCase()) {
          String p when p.endsWith('.png') => 'image/png',
          String p when p.endsWith('.webp') => 'image/webp',
          _ => '',
        };
    await ref.read(reportComposerProvider.notifier).addMedia(path, mime);
  }

  Future<void> _locate() async {
    final l10n = context.l10n;
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => _locationProblem = _LocationProblem.serviceDisabled);
        }
        return;
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        final proceed = await _confirmPermission(
          title: l10n.locationWeatherTitle,
          body: l10n.locationPrimer,
        );
        if (!proceed || !mounted) return;
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationProblem = _LocationProblem.deniedForever);
        }
        return;
      }
      if (permission == geo.LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationProblem = _LocationProblem.denied);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _locating = true;
          _locationProblem = null;
        });
      }
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await ref
          .read(reportComposerProvider.notifier)
          .setLocation(
            GeoCoordinate(position.longitude, position.latitude),
            accuracyMeters: position.accuracy,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _recoverLocation() async {
    switch (_locationProblem) {
      case _LocationProblem.serviceDisabled:
        await geo.Geolocator.openLocationSettings();
        return;
      case _LocationProblem.deniedForever:
        await geo.Geolocator.openAppSettings();
        return;
      case _LocationProblem.denied:
      case null:
        await _locate();
        return;
    }
  }

  Future<void> _next(ReportComposerState state) async {
    try {
      await ref.read(reportComposerProvider.notifier).goToStep(state.step + 1);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    }
  }

  Future<void> _deleteDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.reportDiscardDraftTitle),
        content: Text(context.l10n.reportDiscardDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.reportDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(reportComposerProvider.notifier).clear();
    }
  }

  Future<void> _submit() async {
    final current = ref.read(reportComposerProvider);
    if (current.currentIssue == ReportComposerIssue.descriptionRequired) {
      _descriptionFocus.requestFocus();
      final targetContext = _descriptionFocus.context;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          alignment: 0.25,
        );
      }
      return;
    }
    if (current.currentIssue == ReportComposerIssue.truthConfirmationRequired) {
      _truthFocus.requestFocus();
      final targetContext = _truthKey.currentContext;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          alignment: 0.5,
        );
      }
      return;
    }
    final report = await ref.read(reportComposerProvider.notifier).submit();
    if (report != null && mounted) {
      context.go(RoutePaths.reportDetail(report.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportComposerProvider);
    final l10n = context.l10n;
    if (!_descriptionSeeded && !state.restoring) {
      _descriptionSeeded = true;
      _descriptionController.text = state.description;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportCreate),
        leading: IconButton(
          key: const ValueKey('report-create-close'),
          tooltip: l10n.commonClose,
          onPressed: () => context.go(RoutePaths.reports),
          icon: const Icon(Icons.close),
        ),
      ),
      body: state.restoring
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _StepHeader(step: state.step),
                  if (state.restoredFromDraft)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: AppInlineNotice(
                        message: l10n.reportDraftRestored,
                        icon: Icons.history_outlined,
                        tone: AppFeedbackTone.info,
                        actionLabel: l10n.reportDelete,
                        onAction: _deleteDraft,
                        liveRegion: true,
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      child: switch (state.step) {
                        0 => _EvidenceStep(
                          key: const ValueKey('report-step-evidence'),
                          state: state,
                          cameraPermissionDenied: _cameraPermissionDenied,
                          onCamera: () => _pick(picker.ImageSource.camera),
                          onGallery: () => _pick(picker.ImageSource.gallery),
                          onCameraSettings: geo.Geolocator.openAppSettings,
                        ),
                        1 => _LocationStep(
                          key: const ValueKey('report-step-location'),
                          state: state,
                          locating: _locating,
                          problem: _locationProblem,
                          onLocate: _locate,
                          onRecover: _recoverLocation,
                        ),
                        _ => _DescriptionStep(
                          key: const ValueKey('report-step-description'),
                          state: state,
                          controller: _descriptionController,
                          descriptionFocusNode: _descriptionFocus,
                          truthKey: _truthKey,
                          truthFocusNode: _truthFocus,
                        ),
                      },
                    ),
                  ),
                  _BottomActions(
                    state: state,
                    onBack: () => ref
                        .read(reportComposerProvider.notifier)
                        .goToStep(state.step - 1),
                    onNext: () => _next(state),
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.reportEvidenceStep,
      context.l10n.reportLocationStep,
      context.l10n.reportDescriptionStep,
    ];
    return Semantics(
      container: true,
      label: context.l10n.reportStepProgress(step + 1, 3, labels[step]),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 460 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            if (compact) {
              return ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: (step + 1) / 3),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.reportStepProgress(
                        step + 1,
                        3,
                        labels[step],
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              );
            }
            return ExcludeSemantics(
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          height: 5,
                          margin: EdgeInsets.only(right: index < 2 ? 7 : 0),
                          decoration: BoxDecoration(
                            color: index <= step
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: index == step
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EvidenceStep extends ConsumerWidget {
  const _EvidenceStep({
    super.key,
    required this.state,
    required this.cameraPermissionDenied,
    required this.onCamera,
    required this.onGallery,
    required this.onCameraSettings,
  });
  final ReportComposerState state;
  final bool cameraPermissionDenied;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onCameraSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        context.l10n.reportEvidenceStep,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      Text(context.l10n.reportEvidenceHint),
      if (cameraPermissionDenied) ...[
        const SizedBox(height: 14),
        AppInlineNotice(
          message: context.l10n.reportCameraPermissionDenied,
          icon: Icons.no_photography_outlined,
          tone: AppFeedbackTone.error,
          actionLabel: context.l10n.locationOpenSettings,
          onAction: onCameraSettings,
          liveRegion: true,
        ),
      ],
      if (state.media.length >= 5) ...[
        const SizedBox(height: 14),
        AppInlineNotice(
          message: context.l10n.reportPhotoLimit,
          icon: Icons.photo_library_outlined,
          tone: AppFeedbackTone.neutral,
        ),
      ],
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 390 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final width = stacked
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: OutlinedButton.icon(
                  key: const ValueKey('report-camera'),
                  onPressed: state.media.length >= 5 ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(context.l10n.reportCamera),
                ),
              ),
              SizedBox(
                width: width,
                child: OutlinedButton.icon(
                  key: const ValueKey('report-gallery'),
                  onPressed: state.media.length >= 5 ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.l10n.reportGallery),
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      ...state.media.asMap().entries.map(
        (entry) => Card(
          child: ListTile(
            leading: Semantics(
              label: context.l10n.reportPhotoPosition(
                entry.key + 1,
                state.media.length,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(entry.value.path),
                  width: 52,
                  height: 52,
                  cacheWidth: (52 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  cacheHeight: (52 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            title: Text(
              entry.value.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: entry.value.stage == ReportUploadStage.local
                ? Text(entry.value.mimeType)
                : LinearProgressIndicator(value: entry.value.progress),
            trailing: IconButton(
              key: ValueKey('report-media-remove-${entry.key}'),
              tooltip: context.l10n.reportDelete,
              onPressed: state.submitting
                  ? null
                  : () => ref
                        .read(reportComposerProvider.notifier)
                        .removeMedia(entry.key),
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      ),
    ],
  );
}

class _LocationStep extends ConsumerStatefulWidget {
  const _LocationStep({
    super.key,
    required this.state,
    required this.locating,
    required this.problem,
    required this.onLocate,
    required this.onRecover,
  });
  final ReportComposerState state;
  final bool locating;
  final _LocationProblem? problem;
  final VoidCallback onLocate;
  final VoidCallback onRecover;

  @override
  ConsumerState<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<_LocationStep> {
  PointAnnotationManager? _manager;
  bool _outsideBounds = false;
  Uint8List? _markerImage;
  int _markerRenderVersion = 0;

  Future<void> _render() async {
    final renderVersion = ++_markerRenderVersion;
    final manager = _manager;
    final location = widget.state.location;
    if (manager == null || location == null) return;

    final markerImage = _markerImage ??= await _createMarkerImage();
    if (!mounted || renderVersion != _markerRenderVersion) return;

    await manager.deleteAll();
    if (!mounted || renderVersion != _markerRenderVersion) return;
    await manager.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(location.longitude, location.latitude),
        ),
        image: markerImage,
        iconAnchor: IconAnchor.BOTTOM,
        iconSize: 0.62,
      ),
    );
  }

  Future<Uint8List> _createMarkerImage() async {
    const markerWidth = 96;
    const markerHeight = 120;
    const center = Offset(markerWidth / 2, 48);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(markerWidth / 2, 113),
        width: 50,
        height: 12,
      ),
      Paint()..color = const Color(0x33000000),
    );

    final pin = Path()
      ..moveTo(center.dx, 119)
      ..cubicTo(43, 111, 10, 78, 10, 48)
      ..cubicTo(10, 24, 27, 6, center.dx, 6)
      ..cubicTo(69, 6, 86, 24, 86, 48)
      ..cubicTo(86, 78, 53, 111, center.dx, 119)
      ..close();
    canvas.drawPath(pin, Paint()..color = const Color(0xFFEF4444));
    canvas.drawPath(
      pin,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(center, 17, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
      center,
      9,
      Paint()..color = const Color(0xFF073719),
    );

    final image = await recorder
        .endRecording()
        .toImage(markerWidth, markerHeight);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  Future<void> _selectLocation(GeoCoordinate coordinate) async {
    if (!coordinate.isInCamPhaBounds) {
      if (mounted) setState(() => _outsideBounds = true);
      return;
    }
    if (_outsideBounds && mounted) setState(() => _outsideBounds = false);
    await ref.read(reportComposerProvider.notifier).setLocation(coordinate);
  }

  @override
  void didUpdateWidget(covariant _LocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.location != widget.state.location) {
      unawaited(_render());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.state.accuracyMeters;
    final lowAccuracy =
        accuracy != null && accuracy > ApiConfig.gpsAccuracyThresholdM;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reportLocationStep,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(context.l10n.reportLocationHint),
          if (widget.problem case final problem?) ...[
            const SizedBox(height: 12),
            AppInlineNotice(
              message: _locationProblemMessage(context, problem),
              icon: Icons.location_disabled_outlined,
              tone: AppFeedbackTone.error,
              actionLabel: problem == _LocationProblem.denied
                  ? context.l10n.commonRetry
                  : context.l10n.locationOpenSettings,
              onAction: widget.onRecover,
              liveRegion: true,
            ),
          ],
          if (_outsideBounds) ...[
            const SizedBox(height: 12),
            AppInlineNotice(
              message: context.l10n.locationOutsideBounds,
              icon: Icons.wrong_location_outlined,
              tone: AppFeedbackTone.error,
              liveRegion: true,
            ),
          ],
          if (lowAccuracy) ...[
            const SizedBox(height: 12),
            AppInlineNotice(
              message: context.l10n.locationAccuracyLow(
                accuracy.toStringAsFixed(1),
              ),
              icon: Icons.warning_amber_rounded,
              tone: AppFeedbackTone.warning,
              liveRegion: true,
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('report-use-location'),
            onPressed: widget.locating ? null : widget.onLocate,
            icon: widget.locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              widget.locating
                  ? context.l10n.locationLocating
                  : context.l10n.routeUseGps,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Semantics(
              label: context.l10n.reportLocationHint,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: MapWidget(
                  key: const ValueKey('report-location-map'),
                  viewport: CameraViewportState(
                    center: Point(
                      coordinates: Position(
                        widget.state.location?.longitude ?? 107.33,
                        widget.state.location?.latitude ?? 21.01,
                      ),
                    ),
                    zoom: 12,
                  ),
                  onMapCreated: (map) async {
                    final manager = await map.annotations
                        .createPointAnnotationManager();
                    if (!mounted) return;
                    _manager = manager;
                    map.addInteraction(
                      TapInteraction.onMap((context) {
                        final point = context.point.coordinates;
                        unawaited(
                          _selectLocation(
                            GeoCoordinate(
                              point.lng.toDouble(),
                              point.lat.toDouble(),
                            ),
                          ),
                        );
                      }, stopPropagation: false),
                      interactionID: 'report-location-tap',
                    );
                    await _render();
                  },
                ),
              ),
            ),
          ),
          if (widget.state.location != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${widget.state.location!.latitude.toStringAsFixed(6)}, ${widget.state.location!.longitude.toStringAsFixed(6)}${accuracy == null ? '' : ' • ±${accuracy.round()} m'}',
              ),
            ),
        ],
      ),
    );
  }
}

class _DescriptionStep extends ConsumerWidget {
  const _DescriptionStep({
    super.key,
    required this.state,
    required this.controller,
    required this.descriptionFocusNode,
    required this.truthKey,
    required this.truthFocusNode,
  });
  final ReportComposerState state;
  final TextEditingController controller;
  final FocusNode descriptionFocusNode;
  final GlobalKey truthKey;
  final FocusNode truthFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptionInvalid =
        state.description.trim().length < 10 ||
        state.description.trim().length > 2000;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.l10n.reportDescriptionStep,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(context.l10n.reportDescriptionHint),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('report-description'),
          controller: controller,
          focusNode: descriptionFocusNode,
          minLines: 6,
          maxLines: 12,
          maxLength: 2000,
          onChanged: ref.read(reportComposerProvider.notifier).setDescription,
          decoration: InputDecoration(
            alignLabelWithHint: true,
            labelText: context.l10n.reportDescriptionStep,
            errorText: descriptionInvalid && state.description.trim().isNotEmpty
                ? context.l10n.reportDescriptionRequired
                : null,
          ),
        ),
        KeyedSubtree(
          key: truthKey,
          child: Focus(
            focusNode: truthFocusNode,
            child: CheckboxListTile(
              key: const ValueKey('report-truth-confirm'),
              value: state.truthConfirmed,
              onChanged: (value) => ref
                  .read(reportComposerProvider.notifier)
                  .confirmTruth(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(context.l10n.reportTruthConfirm),
            ),
          ),
        ),
        if (state.error case final error?)
          AppInlineNotice(
            message: error.localizedErrorMessage(context.l10n),
            icon: Icons.error_outline,
            tone: AppFeedbackTone.error,
            liveRegion: true,
          ),
        ...state.media.map(
          (item) => ListTile(
            leading: Icon(_stageIcon(item.stage)),
            title: Text(item.name),
            subtitle: Text(_stageLabel(context, item.stage)),
            trailing: item.stage == ReportUploadStage.uploading
                ? SizedBox(
                    width: 54,
                    child: LinearProgressIndicator(value: item.progress),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.state,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });
  final ReportComposerState state;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ready = switch (state.step) {
      0 => state.evidenceReady,
      1 => state.locationReady,
      _ => state.canSubmit,
    };
    final requirement = ready ? null : state.currentIssue;
    final primaryAction = state.step == 2 ? onSubmit : onNext;
    final primary = FilledButton(
      key: ValueKey(state.step == 2 ? 'report-submit' : 'report-next'),
      onPressed: state.submitting || (state.step < 2 && !ready)
          ? null
          : primaryAction,
      child: state.submitting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              state.step == 2
                  ? context.l10n.reportSubmit
                  : context.l10n.reportNext,
            ),
    );
    final back = OutlinedButton(
      key: const ValueKey('report-back'),
      onPressed: state.submitting ? null : onBack,
      child: Text(context.l10n.reportBack),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (requirement != null) ...[
                AppInlineNotice(
                  key: const ValueKey('report-action-requirement'),
                  message: _issueMessage(context, requirement),
                  icon: Icons.info_outline,
                  tone: AppFeedbackTone.neutral,
                  liveRegion: true,
                ),
                const SizedBox(height: 12),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.step > 0) ...[
                          back,
                          const SizedBox(height: 10),
                        ],
                        primary,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      if (state.step > 0) ...[
                        Expanded(child: back),
                        const SizedBox(width: 12),
                      ],
                      Expanded(flex: 2, child: primary),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _locationProblemMessage(
  BuildContext context,
  _LocationProblem problem,
) => switch (problem) {
  _LocationProblem.serviceDisabled => context.l10n.locationServiceOff,
  _LocationProblem.denied => context.l10n.locationDenied,
  _LocationProblem.deniedForever => context.l10n.locationDeniedForever,
};

String _issueMessage(
  BuildContext context,
  ReportComposerIssue issue,
) => switch (issue) {
  ReportComposerIssue.evidenceRequired => context.l10n.reportEvidenceRequired,
  ReportComposerIssue.locationRequired => context.l10n.reportLocationRequired,
  ReportComposerIssue.descriptionRequired =>
    context.l10n.reportDescriptionRequired,
  ReportComposerIssue.truthConfirmationRequired =>
    context.l10n.reportTruthRequired,
};

IconData _stageIcon(ReportUploadStage stage) => switch (stage) {
  ReportUploadStage.ready => Icons.check_circle,
  ReportUploadStage.failed => Icons.error_outline,
  ReportUploadStage.uploading => Icons.cloud_upload_outlined,
  ReportUploadStage.committing => Icons.shield_outlined,
  _ => Icons.photo_outlined,
};
String _stageLabel(BuildContext context, ReportUploadStage stage) =>
    switch (stage) {
      ReportUploadStage.presigning => context.l10n.reportUploadPresign,
      ReportUploadStage.uploading => context.l10n.reportUploadUploading,
      ReportUploadStage.committing => context.l10n.reportUploadCommit,
      ReportUploadStage.ready => context.l10n.reportUploadReady,
      ReportUploadStage.failed => context.l10n.errorUnknown,
      _ => context.l10n.reportEvidenceStep,
    };
