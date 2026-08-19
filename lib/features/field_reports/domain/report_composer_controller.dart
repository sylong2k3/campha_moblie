import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tools/domain/field_tools_models.dart';
import '../data/field_report_repository.dart';
import '../data/report_media_store.dart';
import 'field_report_models.dart';

enum ReportUploadStage {
  local,
  presigning,
  uploading,
  committing,
  ready,
  failed,
}

class ReportMediaItem {
  const ReportMediaItem({
    required this.path,
    required this.mimeType,
    this.stage = ReportUploadStage.local,
    this.progress = 0,
    this.uploadId,
    this.error,
  });
  final String path;
  final String mimeType;
  final ReportUploadStage stage;
  final double progress;
  final String? uploadId;
  final Object? error;
  String get name => path.split(RegExp(r'[/\\]')).last;

  ReportMediaItem copyWith({
    ReportUploadStage? stage,
    double? progress,
    String? uploadId,
    Object? error,
    bool clearError = false,
  }) => ReportMediaItem(
    path: path,
    mimeType: mimeType,
    stage: stage ?? this.stage,
    progress: progress ?? this.progress,
    uploadId: uploadId ?? this.uploadId,
    error: clearError ? null : error ?? this.error,
  );

  Map<String, dynamic> toLocalJson() => {'path': path, 'mimeType': mimeType};
  factory ReportMediaItem.fromLocalJson(Map<String, dynamic> json) =>
      ReportMediaItem(
        path: json['path'].toString(),
        mimeType: json['mimeType'].toString(),
      );
}

enum ReportComposerIssue {
  evidenceRequired,
  locationRequired,
  descriptionRequired,
  truthConfirmationRequired,
}

class ReportComposerState {
  const ReportComposerState({
    this.step = 0,
    this.media = const [],
    this.location,
    this.accuracyMeters,
    this.geometry,
    this.description = '',
    this.truthConfirmed = false,
    this.restoring = true,
    this.restoredFromDraft = false,
    this.submitting = false,
    this.error,
  });
  final int step;
  final List<ReportMediaItem> media;
  final GeoCoordinate? location;
  final double? accuracyMeters;
  final GeoJsonGeometry? geometry;
  final String description;
  final bool truthConfirmed;
  final bool restoring;
  final bool restoredFromDraft;
  final bool submitting;
  final Object? error;

  bool get evidenceReady => media.isNotEmpty && media.length <= 5;
  bool get locationReady => location?.isInCamPhaBounds == true;
  bool get descriptionReady =>
      description.trim().length >= 10 &&
      description.trim().length <= 2000 &&
      truthConfirmed;
  bool get canSubmit =>
      evidenceReady && locationReady && descriptionReady && !submitting;

  ReportComposerIssue? get currentIssue {
    if (!evidenceReady) return ReportComposerIssue.evidenceRequired;
    if (step > 0 && !locationReady) {
      return ReportComposerIssue.locationRequired;
    }
    if (step > 1 &&
        (description.trim().length < 10 || description.trim().length > 2000)) {
      return ReportComposerIssue.descriptionRequired;
    }
    if (step > 1 && !truthConfirmed) {
      return ReportComposerIssue.truthConfirmationRequired;
    }
    return null;
  }

  ReportComposerState copyWith({
    int? step,
    List<ReportMediaItem>? media,
    GeoCoordinate? location,
    double? accuracyMeters,
    GeoJsonGeometry? geometry,
    String? description,
    bool? truthConfirmed,
    bool? restoring,
    bool? restoredFromDraft,
    bool? submitting,
    Object? error,
    bool clearError = false,
    bool clearGeometry = false,
  }) => ReportComposerState(
    step: step ?? this.step,
    media: media ?? this.media,
    location: location ?? this.location,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    geometry: clearGeometry ? null : geometry ?? this.geometry,
    description: description ?? this.description,
    truthConfirmed: truthConfirmed ?? this.truthConfirmed,
    restoring: restoring ?? this.restoring,
    restoredFromDraft: restoredFromDraft ?? this.restoredFromDraft,
    submitting: submitting ?? this.submitting,
    error: clearError ? null : error ?? this.error,
  );
}

class ReportComposerController extends Notifier<ReportComposerState> {
  static const _draftKey = 'field_report_unsent_v1';
  int _generation = 0;

  @override
  ReportComposerState build() {
    Future.microtask(_restore);
    return const ReportComposerState();
  }

  Future<void> _restore() async {
    final generation = _generation;
    final raw = (await SharedPreferences.getInstance()).getString(_draftKey);
    if (generation != _generation) return;
    if (raw == null) {
      state = state.copyWith(restoring: false);
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final rawMedia = json['media'] as List? ?? const [];
      final media = <ReportMediaItem>[];
      for (final item in rawMedia) {
        final parsed = ReportMediaItem.fromLocalJson(
          Map<String, dynamic>.from(item as Map),
        );
        if (await File(parsed.path).exists()) {
          media.add(parsed);
        }
      }
      if (generation != _generation) return;
      final longitude = (json['longitude'] as num?)?.toDouble();
      final latitude = (json['latitude'] as num?)?.toDouble();
      final description = json['description']?.toString() ?? '';
      final truthConfirmed = json['truthConfirmed'] == true;
      final step = (json['step'] as num?)?.toInt().clamp(0, 2) ?? 0;
      final geometry = json['geometry'] == null
          ? null
          : GeoJsonGeometry.fromJson(
              Map<String, dynamic>.from(json['geometry'] as Map),
            );
      final location = longitude == null || latitude == null
          ? null
          : GeoCoordinate(longitude, latitude);
      if (generation != _generation) return;
      state = ReportComposerState(
        step: step,
        media: media,
        location: location,
        accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
        geometry: geometry,
        description: description,
        truthConfirmed: truthConfirmed,
        restoring: false,
        restoredFromDraft:
            step > 0 ||
            media.isNotEmpty ||
            location != null ||
            geometry != null ||
            description.trim().isNotEmpty ||
            truthConfirmed,
      );
    } catch (_) {
      if (generation == _generation) await clear();
    }
  }

  Future<void> addMedia(String filePath, String mimeType) async {
    if (state.media.length >= 5) throw StateError('Maximum 5 photos');
    final durablePath = await ReportMediaStore().importAsPng(filePath);
    state = state.copyWith(
      media: [
        ...state.media,
        ReportMediaItem(path: durablePath, mimeType: 'image/png'),
      ],
      clearError: true,
    );
    await _persist();
  }

  Future<void> removeMedia(int index) async {
    final removed = state.media[index];
    state = state.copyWith(media: [...state.media]..removeAt(index));
    await _persist();
    await ReportMediaStore().delete(removed.path);
  }

  Future<void> setLocation(
    GeoCoordinate location, {
    double? accuracyMeters,
  }) async {
    if (!location.isInCamPhaBounds) {
      throw ArgumentError('Location outside Cam Pha');
    }
    state = state.copyWith(location: location, accuracyMeters: accuracyMeters);
    await _persist();
  }

  Future<void> setDescription(String value) async {
    state = state.copyWith(description: value);
    await _persist();
  }

  Future<void> confirmTruth(bool value) async {
    state = state.copyWith(truthConfirmed: value);
    await _persist();
  }

  Future<void> setGeometry(GeoJsonGeometry? value) async {
    state = state.copyWith(geometry: value, clearGeometry: value == null);
    await _persist();
  }

  Future<void> goToStep(int step) async {
    if (step > 0 && !state.evidenceReady) throw StateError('Evidence required');
    if (step > 1 && !state.locationReady) throw StateError('Location required');
    state = state.copyWith(step: step.clamp(0, 2));
    await _persist();
  }

  Future<FieldReport?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final ids = <String>[];
      for (var index = 0; index < state.media.length; index++) {
        final item = state.media[index];
        if (item.stage == ReportUploadStage.ready && item.uploadId != null) {
          ids.add(item.uploadId!);
          continue;
        }
        _updateMedia(
          index,
          item.copyWith(
            stage: ReportUploadStage.presigning,
            progress: 0,
            clearError: true,
          ),
        );
        final grant = await ref
            .read(fieldReportRepositoryProvider)
            .presign(originalName: item.name, contentType: item.mimeType);
        _updateMedia(
          index,
          state.media[index].copyWith(
            stage: ReportUploadStage.uploading,
            uploadId: grant.id,
          ),
        );
        await ref
            .read(fieldReportRepositoryProvider)
            .uploadFile(
              grant: grant,
              file: File(item.path),
              contentType: item.mimeType,
              onProgress: (sent, total) => _updateMedia(
                index,
                state.media[index].copyWith(
                  progress: total <= 0 ? 0 : sent / total,
                ),
              ),
            );
        _updateMedia(
          index,
          state.media[index].copyWith(
            stage: ReportUploadStage.committing,
            progress: 1,
          ),
        );
        final ready = await ref
            .read(fieldReportRepositoryProvider)
            .commit(grant.id);
        ids.add(ready.id);
        _updateMedia(
          index,
          state.media[index].copyWith(
            stage: ReportUploadStage.ready,
            uploadId: ready.id,
          ),
        );
      }
      final created = await ref
          .read(fieldReportRepositoryProvider)
          .create(
            description: state.description,
            location: state.location!,
            measuredGeometry: state.geometry,
            photoIds: ids,
          );
      final localMedia = state.media;
      await (await SharedPreferences.getInstance()).remove(_draftKey);
      state = const ReportComposerState(restoring: false);
      for (final item in localMedia) {
        await ReportMediaStore().delete(item.path);
      }
      return created;
    } catch (error) {
      final failed = state.media.indexWhere(
        (item) => item.stage != ReportUploadStage.ready,
      );
      if (kDebugMode) {
        final stage = failed >= 0
            ? state.media[failed].stage.name
            : 'creating_report';
        debugPrint(
          'Field report submission failed at $stage '
          '(${error.runtimeType})',
        );
        if (error is DioException) {
          debugPrint('  DioException.type: ${error.type}');
          debugPrint('  DioException.message: ${error.message}');
          debugPrint('  response.status: ${error.response?.statusCode}');
          debugPrint('  response.data: ${error.response?.data}');
          if (error.error != null) debugPrint('  inner: ${error.error}');
          final uri = error.requestOptions.uri;
          debugPrint('  request.url: ${uri.scheme}://${uri.host}:${uri.port}${uri.path}');
        }
      }
      if (failed >= 0) {
        _updateMedia(
          failed,
          state.media[failed].copyWith(
            stage: ReportUploadStage.failed,
            error: error,
          ),
        );
      }
      state = state.copyWith(submitting: false, error: error);
      await _persist();
      return null;
    }
  }

  void _updateMedia(int index, ReportMediaItem item) {
    if (index >= state.media.length) return;
    final updated = [...state.media];
    updated[index] = item;
    state = state.copyWith(media: updated);
  }

  Future<void> _persist() async {
    final location = state.location;
    await (await SharedPreferences.getInstance()).setString(
      _draftKey,
      jsonEncode({
        'step': state.step,
        'media': state.media
            .map((item) => item.toLocalJson())
            .toList(growable: false),
        'longitude': location?.longitude,
        'latitude': location?.latitude,
        'accuracyMeters': state.accuracyMeters,
        'geometry': state.geometry?.toJson(),
        'description': state.description,
        'truthConfirmed': state.truthConfirmed,
      }),
    );
  }

  Future<void> clear() async {
    _generation++;
    final localMedia = state.media;
    await (await SharedPreferences.getInstance()).remove(_draftKey);
    state = const ReportComposerState(restoring: false);
    for (final item in localMedia) {
      await ReportMediaStore().delete(item.path);
    }
  }
}

final reportComposerProvider =
    NotifierProvider<ReportComposerController, ReportComposerState>(
      ReportComposerController.new,
    );
