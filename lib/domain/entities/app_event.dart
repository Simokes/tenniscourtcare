// lib/domain/entities/app_event.dart

import 'sync_status.dart';

class AppEvent {
  final int? id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final int color;
  final List<int> terrainIds;

  // Sync fields
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  AppEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.terrainIds,
    this.syncStatus = SyncStatus.local,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppEvent copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? color,
    List<int>? terrainIds,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? createdBy,
    String? modifiedBy,
  }) {
    return AppEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      terrainIds: terrainIds ?? this.terrainIds,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
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
          _listEquals(terrainIds, other.terrainIds) &&
          syncStatus == other.syncStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          firebaseId == other.firebaseId &&
          createdBy == other.createdBy &&
          modifiedBy == other.modifiedBy;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      color.hashCode ^
      terrainIds.hashCode ^
      syncStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      firebaseId.hashCode ^
      createdBy.hashCode ^
      modifiedBy.hashCode;

  @override
  String toString() {
    return 'AppEvent{id: $id, title: $title, description: $description, startTime: $startTime, endTime: $endTime, color: $color, terrainIds: $terrainIds, syncStatus: $syncStatus, createdAt: $createdAt, updatedAt: $updatedAt}';
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
