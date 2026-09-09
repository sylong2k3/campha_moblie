import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/map_repository.dart';
import 'flood_hydrology_model.dart';

class FloodHydrologyState {
  const FloodHydrologyState({
    this.runs = const [],
    this.artifacts = const [],
    this.legends = const [],
    this.selectedRunId,
    this.visibleIds = const {},
    this.loading = false,
    this.loaded = false,
    this.error,
  });
  final List<FloodRun> runs;
  final List<FloodArtifact> artifacts;
  final List<FloodHydrologyLegend> legends;
  final int? selectedRunId;
  final Set<int> visibleIds;
  final bool loading;
  final bool loaded;
  final Object? error;
  FloodRun? get selectedRun =>
      runs.where((r) => r.id == selectedRunId).firstOrNull;
  List<FloodArtifact> get currentArtifacts => artifacts
      .where((a) => a.analysisRunId == selectedRunId && a.module == 'trend')
      .toList();

  FloodHydrologyState copyWith({
    List<FloodRun>? runs,
    List<FloodArtifact>? artifacts,
    List<FloodHydrologyLegend>? legends,
    int? selectedRunId,
    bool clearRun = false,
    Set<int>? visibleIds,
    bool? loading,
    bool? loaded,
    Object? error,
  }) => FloodHydrologyState(
    runs: runs ?? this.runs,
    artifacts: artifacts ?? this.artifacts,
    legends: legends ?? this.legends,
    selectedRunId: clearRun ? null : selectedRunId ?? this.selectedRunId,
    visibleIds: visibleIds ?? this.visibleIds,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    error: error,
  );
}

class FloodHydrologyController extends Notifier<FloodHydrologyState> {
  bool _disposed = false;
  int _generation = 0;
  @override
  FloodHydrologyState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    return const FloodHydrologyState();
  }

  Future<void> load() async {
    if (_disposed || state.loading) return;
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    final repository = ref.read(mapRepositoryProvider);
    try {
      final results = await Future.wait<Object>([
        repository.getFloodRuns(),
        repository.getFloodArtifacts(),
        repository.getFloodLegends(),
      ]);
      if (_disposed || generation != _generation) return;
      final runs = results[0] as List<FloodRun>;
      final artifacts = results[1] as List<FloodArtifact>;
      final selected = runs.any((r) => r.id == state.selectedRunId)
          ? state.selectedRunId
          : runs.firstOrNull?.id;
      state = state.copyWith(
        runs: runs,
        artifacts: artifacts,
        legends: results[2] as List<FloodHydrologyLegend>,
        selectedRunId: selected,
        clearRun: selected == null,
        visibleIds: state.visibleIds.intersection(
          artifacts
              .where(
                (a) => a.analysisRunId == selected && a.registryLayerId != null,
              )
              .map((a) => a.id)
              .toSet(),
        ),
        loading: false,
        loaded: true,
      );
    } catch (error) {
      if (!_disposed && generation == _generation) {
        state = state.copyWith(loading: false, error: error);
      }
    }
  }

  void selectRun(int id) {
    if (id == state.selectedRunId || !state.runs.any((r) => r.id == id)) return;
    state = state.copyWith(selectedRunId: id, visibleIds: {});
  }

  void toggleArtifact(FloodArtifact artifact) {
    if (artifact.registryLayerId == null ||
        !state.currentArtifacts.any((a) => a.id == artifact.id)) {
      return;
    }
    final ids = {...state.visibleIds};
    if (!ids.remove(artifact.id)) ids.add(artifact.id);
    state = state.copyWith(visibleIds: ids);
  }

  void hideArtifact(int id) =>
      state = state.copyWith(visibleIds: {...state.visibleIds}..remove(id));
  void clearArtifacts() => state = state.copyWith(visibleIds: {});
  void resetForIdentityChange() {
    _generation++;
    state = const FloodHydrologyState();
  }
}

final floodHydrologyProvider =
    NotifierProvider<FloodHydrologyController, FloodHydrologyState>(
      FloodHydrologyController.new,
    );
