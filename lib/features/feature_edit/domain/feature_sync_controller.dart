import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/domain/session_controller.dart';
import '../data/feature_edit_repository.dart';
import '../data/offline_edit_queue.dart';
import 'feature_edit_models.dart';

class FeatureSyncState {
  const FeatureSyncState({
    this.items = const [],
    this.syncing = false,
    this.error,
  });
  final List<OfflineFeatureChange> items;
  final bool syncing;
  final Object? error;
  int get pending => items
      .where(
        (item) =>
            item.status == OfflineChangeStatus.pending ||
            item.status == OfflineChangeStatus.syncing,
      )
      .length;
  int get conflicts =>
      items.where((item) => item.status == OfflineChangeStatus.conflict).length;
  int get rejected =>
      items.where((item) => item.status == OfflineChangeStatus.rejected).length;

  FeatureSyncState copyWith({
    List<OfflineFeatureChange>? items,
    bool? syncing,
    Object? error,
    bool clearError = false,
  }) => FeatureSyncState(
    items: items ?? this.items,
    syncing: syncing ?? this.syncing,
    error: clearError ? null : error ?? this.error,
  );
}

class FeatureSyncController extends Notifier<FeatureSyncState> {
  String? get _owner => ref.read(sessionControllerProvider).user?.id;
  Future<OfflineEditQueue> get _queue =>
      ref.read(offlineEditQueueProvider.future);

  @override
  FeatureSyncState build() {
    final owner = ref.watch(
      sessionControllerProvider.select((value) => value.user?.id),
    );
    if (owner != null) Future.microtask(refresh);
    return const FeatureSyncState();
  }

  Future<void> refresh() async {
    final owner = _owner;
    if (owner == null) return;
    final items = await (await _queue).list(owner);
    if (owner == _owner) state = state.copyWith(items: items);
  }

  Future<void> syncNow() async {
    final owner = _owner;
    if (owner == null || state.syncing) return;
    final changes = await (await _queue).ready(owner);
    if (changes.isEmpty) {
      await refresh();
      return;
    }
    state = state.copyWith(syncing: true, clearError: true);
    await (await _queue).markSyncing(
      owner,
      changes.map((item) => item.clientChangeId),
    );
    try {
      final result = await ref
          .read(featureEditRepositoryProvider)
          .sync(clientId: changes.first.clientId, changes: changes);
      if (owner != _owner) return;
      await (await _queue).markApplied(
        owner,
        result.applied.map((item) => item.clientChangeId),
      );
      for (final item in result.conflicts) {
        final current = item.current;
        if (current == null) {
          await (await _queue).markRejected(
            owner,
            item.clientChangeId,
            'INVALID_CONFLICT_RESPONSE',
          );
        } else {
          await (await _queue).markConflict(
            owner,
            item.clientChangeId,
            current,
          );
        }
      }
      for (final item in result.rejected) {
        await (await _queue).markRejected(
          owner,
          item.clientChangeId,
          item.code ?? 'CHANGE_REJECTED',
        );
      }
      await refresh();
      state = state.copyWith(syncing: false);
    } catch (error) {
      if (owner == _owner) {
        if (error is NetworkException) {
          for (final item in changes) {
            await (await _queue).retryLater(item);
          }
        } else {
          await (await _queue).resetPending(
            owner,
            changes.map((item) => item.clientChangeId),
            _batchErrorCode(error),
          );
        }
        await refresh();
        state = state.copyWith(syncing: false, error: error);
      }
    }
  }

  Future<void> discard(String id) async {
    final owner = _owner;
    if (owner == null) return;
    await (await _queue).discard(owner, id);
    await refresh();
  }
}

String _batchErrorCode(Object error) => switch (error) {
  UnauthorizedException _ => 'SYNC_AUTH_REQUIRED',
  ForbiddenException _ => 'SYNC_FORBIDDEN',
  ValidationException _ ||
  SemanticValidationException _ => 'SYNC_INVALID_BATCH',
  _ => 'SYNC_BATCH_FAILED',
};

final featureSyncProvider =
    NotifierProvider<FeatureSyncController, FeatureSyncState>(
      FeatureSyncController.new,
    );
