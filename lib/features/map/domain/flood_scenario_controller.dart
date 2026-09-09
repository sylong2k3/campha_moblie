import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_repository.dart';
import 'flood_scenario_model.dart';

class FloodScenarioState {
  const FloodScenarioState({
    this.scenarios = const [],
    this.selectedScenarioId,
    this.loading = false,
    this.error,
  });

  final List<FloodScenarioModel> scenarios;
  final int? selectedScenarioId;
  final bool loading;
  final Object? error;

  FloodScenarioModel? get selectedScenario {
    for (final s in scenarios) {
      if (s.id == selectedScenarioId) return s;
    }
    return null;
  }

  FloodScenarioState copyWith({
    List<FloodScenarioModel>? scenarios,
    int? selectedScenarioId,
    bool clearSelectedScenarioId = false,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) => FloodScenarioState(
    scenarios: scenarios ?? this.scenarios,
    selectedScenarioId: clearSelectedScenarioId
        ? null
        : selectedScenarioId ?? this.selectedScenarioId,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

class FloodScenarioController extends Notifier<FloodScenarioState> {
  int _generation = 0;
  bool _disposed = false;
  bool _autoActivated = false;

  @override
  FloodScenarioState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    Future.microtask(load);
    return const FloodScenarioState(loading: true);
  }

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_generation;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repository = ref.read(mapRepositoryProvider);
      // Chỉ tải các kịch bản ngập đang kích hoạt (activeOnly: true)
      final list = await repository.getFloodScenarios(activeOnly: true);
      debugPrint('[FLOOD] scenarios loaded: ${list.length}, canSelect: ${list.where((s) => s.canSelect).length}');
      if (_disposed || generation != _generation) return;
      int? selected = state.selectedScenarioId;
      if (!list.any((s) => s.id == selected && s.canSelect)) selected = null;
      if (!_autoActivated) {
        _autoActivated = true;
        final candidates = list.where((s) => s.canSelect).toList()
          ..sort((a, b) => (b.minRainfall ?? 0).compareTo(a.minRainfall ?? 0));
        selected = candidates.firstOrNull?.id;
      }
      state = state.copyWith(
        scenarios: list,
        loading: false,
        clearError: true,
        selectedScenarioId: selected,
        clearSelectedScenarioId: selected == null,
      );
    } catch (err) {
      if (!_disposed && generation == _generation) {
        state = state.copyWith(loading: false, error: err);
      }
    }
  }

  void toggleScenario(FloodScenarioModel scenario) {
    if (!scenario.canSelect) return;
    _autoActivated = true;
    // Bấm lại kịch bản đang chọn để tắt; không thay đổi lớp dữ liệu thường.
    state = state.copyWith(
      selectedScenarioId: scenario.id,
      clearSelectedScenarioId: state.selectedScenarioId == scenario.id,
    );
  }

  void deactivate() {
    _autoActivated = true;
    state = state.copyWith(clearSelectedScenarioId: true);
  }

  void resetForIdentityChange() {
    _generation++;
    _autoActivated = true;
    state = const FloodScenarioState();
    Future.microtask(load);
  }
}

final floodScenarioProvider =
    NotifierProvider<FloodScenarioController, FloodScenarioState>(
      FloodScenarioController.new,
    );
