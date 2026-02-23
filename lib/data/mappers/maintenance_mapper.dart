import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/entities/maintenance.dart';

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
    );
  }
}
