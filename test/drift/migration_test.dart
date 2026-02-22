import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'dart:io';

void main() {
  test('Migration to v4 adds missing columns to StockItems', () async {
    final dbFile = File('migration_test.db');
    if (dbFile.existsSync()) dbFile.deleteSync();

    // 1. Manually create a v3 database (broken state)
    final rawDb = sqlite3.sqlite3.open(dbFile.path);
    rawDb.execute('PRAGMA user_version = 3;');

    // Create tables as they were in v3 (users + stock_items without new columns)
    rawDb.execute('''
      CREATE TABLE users (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        email VARCHAR(255) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        last_login_at INTEGER,
        created_at INTEGER NOT NULL
      );
    ''');

    rawDb.execute('''
      CREATE TABLE stock_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(100) NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        unit VARCHAR(20) NOT NULL,
        comment TEXT,
        is_custom INTEGER NOT NULL,
        min_threshold INTEGER,
        updated_at INTEGER NOT NULL
      );
    ''');

    // Create other tables needed to avoid schema mismatch errors if drift checks all tables
    rawDb.execute('CREATE TABLE terrains (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, court_type TEXT NOT NULL, is_covered INTEGER NOT NULL, maintenance_schedule TEXT);');
    rawDb.execute('CREATE TABLE maintenances (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, terrain_id INTEGER NOT NULL, type TEXT NOT NULL, date INTEGER NOT NULL, commentaire TEXT, sacs_manto_utilises INTEGER NOT NULL DEFAULT 0, sacs_sottomanto_utilises INTEGER NOT NULL DEFAULT 0, sacs_silice_utilises INTEGER NOT NULL DEFAULT 0);');

    // Insert a dummy stock item
    rawDb.execute("INSERT INTO stock_items (name, quantity, unit, is_custom, updated_at) VALUES ('Test Item', 10, 'pcs', 0, 1234567890)");

    rawDb.dispose();

    // 2. Open with AppDatabase (which will be v4 after modification)
    final db = AppDatabase(NativeDatabase(dbFile));

    // 3. Verify columns exist after migration
    try {
      // Trigger migration by accessing database
      final items = await db.watchAllStockItems().first;
      final item = items.firstWhere((i) => i.name == 'Test Item');

      // If migration worked, we should be able to read category and sortOrder (they will be null/default)
      expect(item.category, isNull);
      expect(item.sortOrder, 0); // Default value
    } finally {
      await db.close();
      if (dbFile.existsSync()) dbFile.deleteSync();
    }
  });
}
