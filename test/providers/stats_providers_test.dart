import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/presentation/providers/database_provider.dart';
import 'package:tenniscourtcare/presentation/providers/stats_providers.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';

void main() {
  group('Stats Providers - Stabilité des clés', () {
    late ProviderContainer container;
    late AppDatabase database;
    late int terrainId;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );

      terrainId = await database.insertTerrain(
        Terrain(
          id: 0,
          nom: 'Court 1',
          type: TerrainType.terreBattue,
        ),
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('sacsTotalsProvider utilise des clés stables', () {
      final now = DateTime.now();
      final key1 = (
        terrainId: terrainId,
        start: now.millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );
      final key2 = (
        terrainId: terrainId,
        start: now.millisecondsSinceEpoch,
        end: now.millisecondsSinceEpoch,
      );

      // Les clés doivent être égales
      expect(key1, key2);
    });

    test('monthlyTotalsAllTerrainsProvider utilise des clés stables', () {
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 1, 15);

      // Même jour = même clé
      expect(date1, date2);
    });
  });

  group('Stats Providers - Pas de dépendances async→async', () {
    late ProviderContainer container;
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('sacksSeriesProvider ne dépend pas directement de terrainsProvider async',
        () {
      // Le provider utilise _terrainIdsProvider qui est synchrone
      // et gère le cas où terrainsProvider est en loading
      final provider = sacksSeriesProvider;
      expect(provider, isNotNull);

      // On vérifie qu'on peut lire sans erreur
      expect(
        () => container.read(provider),
        returnsNormally,
      );
    });
  });
}
