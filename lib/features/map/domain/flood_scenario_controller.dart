import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_repository.dart';
import 'flood_scenario_model.dart';
import 'map_controller.dart';

class FloodScenarioState {
  const FloodScenarioState({
    this.scenarios = const [],
    this.selectedScenarioCode,
    this.loading = false,
    this.error,
  });

  final List<FloodScenarioModel> scenarios;
  final String? selectedScenarioCode;
  final bool loading;
  final Object? error;

  FloodScenarioModel? get selectedScenario {
    for (final s in scenarios) {
      if (s.code == selectedScenarioCode) return s;
    }
    return null;
  }

  FloodScenarioState copyWith({
    List<FloodScenarioModel>? scenarios,
    String? selectedScenarioCode,
    bool clearSelectedScenarioCode = false,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) => FloodScenarioState(
    scenarios: scenarios ?? this.scenarios,
    selectedScenarioCode: clearSelectedScenarioCode
        ? null
        : selectedScenarioCode ?? this.selectedScenarioCode,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

class FloodScenarioController extends Notifier<FloodScenarioState> {
  @override
  FloodScenarioState build() {
    Future.microtask(load);
    return const FloodScenarioState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repository = ref.read(mapRepositoryProvider);
      // Chỉ tải các kịch bản ngập đang kích hoạt (activeOnly: true)
      final list = await repository.getFloodScenarios(activeOnly: true);
      state = state.copyWith(
        scenarios: list,
        loading: false,
        clearError: true,
      );
    } catch (err) {
      state = state.copyWith(loading: false, error: err);
    }
  }

  void toggleScenario(FloodScenarioModel scenario) {
    final catalogNotifier = ref.read(mapCatalogProvider.notifier);
    final catalogState = ref.read(mapCatalogProvider);

    // Tìm layer trùng code với scenario.layerCode hoặc scenario.layer?.code
    final targetCode = scenario.layerCode.isNotEmpty
        ? scenario.layerCode
        : (scenario.layer?.code ?? '');

    String? targetLayerId = scenario.layer?.id;
    if (targetLayerId == null || targetLayerId.isEmpty) {
      for (final layer in catalogState.layers) {
        if (layer.code == targetCode) {
          targetLayerId = layer.id;
          break;
        }
      }
    }

    if (state.selectedScenarioCode == scenario.code) {
      // Tắt kịch bản đang chọn
      if (targetLayerId != null && targetLayerId.isNotEmpty) {
        catalogNotifier.setLayerVisible(targetLayerId, false);
      }
      state = state.copyWith(clearSelectedScenarioCode: true);
    } else {
      // Tắt kịch bản cũ nếu có
      if (state.selectedScenario != null) {
        final currentSelected = state.selectedScenario!;
        final oldCode = currentSelected.layerCode.isNotEmpty
            ? currentSelected.layerCode
            : (currentSelected.layer?.code ?? '');
        for (final layer in catalogState.layers) {
          if (layer.code == oldCode || layer.id == currentSelected.layer?.id) {
            catalogNotifier.setLayerVisible(layer.id, false);
          }
        }
      }

      // Bật kịch bản mới
      if (targetLayerId != null && targetLayerId.isNotEmpty) {
        catalogNotifier.setLayerVisible(targetLayerId, true);
      }

      state = state.copyWith(selectedScenarioCode: scenario.code);
    }
  }
}

final floodScenarioProvider =
    NotifierProvider<FloodScenarioController, FloodScenarioState>(
      FloodScenarioController.new,
    );
