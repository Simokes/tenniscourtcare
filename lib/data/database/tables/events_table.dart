import 'dart:convert';
import 'package:drift/drift.dart';

class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(fromDb);
      return list.cast<int>();
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<int> value) {
    return jsonEncode(value);
  }
}

@DataClassName('EventRow')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get color => integer()(); // ARGB

  // Storing list of terrain IDs
  TextColumn get terrainIds => text().map(const IntListConverter())();
}
