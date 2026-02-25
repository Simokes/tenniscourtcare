enum SyncStatus {
  local, // 🟢 En LOCAL, pas encore syncé
  syncing, // 🔵 En cours de sync
  synced, // ✅ Syncé avec Firestore
  error; // ❌ Erreur lors du sync

  String get displayName {
    switch (this) {
      case SyncStatus.local:
        return 'Local';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }

  String get value => name.toUpperCase();

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value.toLowerCase(),
      orElse: () => SyncStatus.local,
    );
  }
}
