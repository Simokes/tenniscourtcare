class AppEvent {
  final int? id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final int color;
  final List<int> terrainIds;

  const AppEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.terrainIds,
  });

  AppEvent copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? color,
    List<int>? terrainIds,
  }) {
    return AppEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      terrainIds: terrainIds ?? this.terrainIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          color == other.color &&
          _listEquals(terrainIds, other.terrainIds);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      color.hashCode ^
      terrainIds.hashCode;

  @override
  String toString() {
    return 'AppEvent{id: $id, title: $title, description: $description, startTime: $startTime, endTime: $endTime, color: $color, terrainIds: $terrainIds}';
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
