import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedTerrainsNotifier extends StateNotifier<Set<int>> {
  SelectedTerrainsNotifier() : super({});

  void toggleTerrain(int terrainId) {
    state = Set.from(state);
    if (state.contains(terrainId)) {
      state.remove(terrainId);
    } else {
      state.add(terrainId);
    }
    state = Set.from(state); // Nouvelle instance pour déclencher la mise à jour
  }

  void selectAll(List<int> allTerrainIds) {
    state = Set.from(allTerrainIds);
  }

  void clearSelection() {
    state = {};
  }

  bool isSelected(int terrainId) {
    return state.contains(terrainId);
  }
}

final selectedTerrainsProvider =
    StateNotifierProvider<SelectedTerrainsNotifier, Set<int>>((ref) {
  return SelectedTerrainsNotifier();
});
