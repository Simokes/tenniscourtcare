import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/entities/sync_status.dart';

extension MaintenanceRowToDomain on MaintenanceRow {
  Maintenance toDomain() {
    return Maintenance(
      id: id,
      terrainId: terrainId,
      type: type,
      commentaire: commentaire,
      date: date,
      sacsMantoUtilises: sacsMantoUtilises,
      sacsSottomantoUtilises: sacsSottomantoUtilises,
      sacsSiliceUtilises: sacsSiliceUtilises,
      imagePath: imagePath,
      // Sync mappings
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(date), // Fallback to operation date
      updatedAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(date), // Fallback
      firebaseId: remoteId,
      createdBy: createdBy,
      modifiedBy: null, // Not in DB yet
      syncStatus: remoteId != null ? SyncStatus.synced : SyncStatus.local,
    );
  }
}

extension MaintenanceToCompanion on Maintenance {
  MaintenancesCompanion toCompanion() {
    return MaintenancesCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      terrainId: Value(terrainId),
      type: Value(type),
      date: Value(date),
      commentaire: Value(commentaire),
      sacsMantoUtilises: Value(sacsMantoUtilises),
      sacsSottomantoUtilises: Value(sacsSottomantoUtilises),
      sacsSiliceUtilises: Value(sacsSiliceUtilises),
      imagePath: Value(imagePath),
      // Sync mappings
      createdAt: Value(createdAt),
      remoteId: Value(firebaseId),
      createdBy: Value(createdBy),
    );
  }
}
