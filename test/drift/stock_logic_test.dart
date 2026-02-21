import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart' as domm;

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    // Trigger database creation and seeding
    await database.getAllTerrains();
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> setStock(String name, int quantity) async {
    final items = await database.watchAllStockItems().first;
    final item = items.firstWhere((i) => i.name == name);
    await database.updateStockItem(item.copyWith(quantity: quantity));
  }

  Future<int> getStock(String name) async {
    final items = await database.watchAllStockItems().first;
    return items.firstWhere((i) => i.name == name).quantity;
  }

  test('Insertion déduit le stock correctement', () async {
    await setStock('Manto', 100);

    final maintenance = domm.Maintenance(
      terrainId: 1,
      type: 'Entretien',
      date: DateTime.now().millisecondsSinceEpoch,
      sacsMantoUtilises: 5,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
    );

    await database.insertMaintenanceWithStockCheck(maintenance);

    expect(await getStock('Manto'), 95);
  });

  test('Insertion échoue si stock insuffisant', () async {
    await setStock('Manto', 4);

    final maintenance = domm.Maintenance(
      terrainId: 1,
      type: 'Entretien',
      date: DateTime.now().millisecondsSinceEpoch,
      sacsMantoUtilises: 5,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
    );

    expect(
      () => database.insertMaintenanceWithStockCheck(maintenance),
      throwsException,
    );

    expect(await getStock('Manto'), 4); // Stock ne doit pas avoir changé
  });

  test('Suppression restaure le stock', () async {
    await setStock('Manto', 100);

    final maintenance = domm.Maintenance(
      terrainId: 1,
      type: 'Entretien',
      date: DateTime.now().millisecondsSinceEpoch,
      sacsMantoUtilises: 10,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
    );

    await database.insertMaintenanceWithStockCheck(maintenance);
    expect(await getStock('Manto'), 90);

    // Récupérer l'ID généré
    final inserted = (await database.getMaintenancesForTerrain(1)).first;

    await database.deleteMaintenanceWithStockRestoration(inserted.id!);

    expect(await getStock('Manto'), 100);
  });

  test('Mise à jour augmente la consommation (déduit stock)', () async {
    await setStock('Manto', 100);

    // 1. Insert avec 10 sacs
    final maintenance = domm.Maintenance(
      terrainId: 1,
      type: 'Entretien',
      date: DateTime.now().millisecondsSinceEpoch,
      sacsMantoUtilises: 10,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
    );
    await database.insertMaintenanceWithStockCheck(maintenance);
    expect(await getStock('Manto'), 90);

    final inserted = (await database.getMaintenancesForTerrain(1)).first;

    // 2. Update à 15 sacs (+5 consommés)
    final updated = inserted.copyWith(sacsMantoUtilises: 15);
    await database.updateMaintenanceWithStockAdjustment(updated);

    expect(await getStock('Manto'), 85);
  });

  test('Mise à jour diminue la consommation (restaure stock)', () async {
    await setStock('Manto', 100);

    // 1. Insert avec 10 sacs
    final maintenance = domm.Maintenance(
      terrainId: 1,
      type: 'Entretien',
      date: DateTime.now().millisecondsSinceEpoch,
      sacsMantoUtilises: 10,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
    );
    await database.insertMaintenanceWithStockCheck(maintenance);
    expect(await getStock('Manto'), 90);

    final inserted = (await database.getMaintenancesForTerrain(1)).first;

    // 2. Update à 5 sacs (-5 consommés -> +5 stock)
    final updated = inserted.copyWith(sacsMantoUtilises: 5);
    await database.updateMaintenanceWithStockAdjustment(updated);

    expect(await getStock('Manto'), 95);
  });

  test('Mise à jour échoue si stock insuffisant pour augmentation', () async {
    await setStock('Manto', 10);

    // 1. Insert avec 5 sacs -> Reste 5
    final maintenance = domm.Maintenance(
      terrainId: 1,
      type: 'Entretien',
      date: DateTime.now().millisecondsSinceEpoch,
      sacsMantoUtilises: 5,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
    );
    await database.insertMaintenanceWithStockCheck(maintenance);
    expect(await getStock('Manto'), 5);

    final inserted = (await database.getMaintenancesForTerrain(1)).first;

    // 2. Update à 15 sacs (+10 requis, mais seulement 5 dispos)
    final updated = inserted.copyWith(sacsMantoUtilises: 15);

    expect(
      () => database.updateMaintenanceWithStockAdjustment(updated),
      throwsException,
    );

    expect(await getStock('Manto'), 5); // Inchangé
  });
}
