import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/map_repository.dart';
import 'forest_classification_model.dart';

class ForestClassificationState {
  const ForestClassificationState({
    this.snapshot,
    this.history = const [],
    this.isVisible = true,
    this.opacity = 0.85,
    this.loading = false,
    this.loaded = false,
    this.error,
  });
  final ForestSnapshot? snapshot;
  final List<ForestSnapshot> history;
  final bool isVisible;
  final double opacity;
  final bool loading;
  final bool loaded;
  final Object? error;

  ForestClassificationState copyWith({
    ForestSnapshot? snapshot,
    bool clearSnapshot = false,
    List<ForestSnapshot>? history,
    bool? isVisible,
    double? opacity,
    bool? loading,
    bool? loaded,
    Object? error,
  }) => ForestClassificationState(
    snapshot: clearSnapshot ? null : snapshot ?? this.snapshot,
    history: history ?? this.history,
    isVisible: isVisible ?? this.isVisible,
    opacity: opacity ?? this.opacity,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    error: error,
  );
}

class ForestClassificationController
    extends Notifier<ForestClassificationState> {
  int _generation = 0;
  bool _disposed = false;
  @override
  ForestClassificationState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    return const ForestClassificationState();
  }

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    final repository = ref.read(mapRepositoryProvider);
    try {
      final latest = await repository.getForestClassificationLatest();
      if (_disposed || generation != _generation) return;
      state = state.copyWith(
        snapshot: latest,
        clearSnapshot: latest == null,
        loaded: true,
      );
      final history = await repository.getForestClassificationHistory();
      if (_disposed || generation != _generation) return;
      state = state.copyWith(history: history, loading: false);
    } catch (error) {
      if (!_disposed && generation == _generation) {
        state = state.copyWith(loading: false, error: error);
      }
    }
  }

  Future<void> selectSnapshot(int id) async {
    if (_disposed || !state.history.any((s) => s.id == id)) return;
    final generation = ++_generation;
    // Bỏ ảnh kỳ cũ trước khi chờ API; lỗi không được hiển thị ảnh sai kỳ.
    state = state.copyWith(clearSnapshot: true, loading: true);
    try {
      final snapshot = await ref
          .read(mapRepositoryProvider)
          .getForestClassificationSnapshot(id);
      if (_disposed || generation != _generation) return;
      state = state.copyWith(
        snapshot: snapshot,
        clearSnapshot: snapshot == null,
        loading: false,
      );
    } catch (error) {
      if (!_disposed && generation == _generation) {
        state = state.copyWith(loading: false, error: error);
      }
    }
  }

  void setVisible(bool value) => state = state.copyWith(isVisible: value);
  void setOpacity(double value) {
    if (value.isFinite) state = state.copyWith(opacity: value.clamp(0, 1));
  }
}

final forestClassificationProvider =
    NotifierProvider<ForestClassificationController, ForestClassificationState>(
      ForestClassificationController.new,
    );
