import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/app_event.dart';
import '../../domain/models/repository_exception.dart';
import '../../domain/repositories/event_repository.dart';
import '../database/app_database.dart';
import '../mappers/event_mapper.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl({
    required AppDatabase db,
    required FirebaseFirestore fs,
  })  : _db = db,
        _fs = fs;

  final AppDatabase _db;
  final FirebaseFirestore _fs;

  @override
  Future<List<AppEvent>> getEvents({DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.events);

    if (start != null) {
      query.where((t) => t.startTime.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((t) => t.endTime.isSmallerOrEqualValue(end));
    }

    final rows = await query.get();
    return rows.map((row) => _toDomain(row)).toList();
  }

  @override
  Future<String> addEvent(AppEvent event) async {
    try {
      final docRef = await _fs
          .collection('events')
          .add(EventMapper.toFirestore(event));
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('❌ EventRepository: Failed to add event: ${e.message}');
      throw RepositoryException('Failed to add event: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> updateEvent(AppEvent event) async {
    if (event.firebaseId == null) {
      throw const RepositoryException('Cannot update event without a firebaseId');
    }

    try {
      await _fs
          .collection('events')
          .doc(event.firebaseId)
          .update(EventMapper.toFirestore(event));
    } on FirebaseException catch (e) {
      debugPrint('❌ EventRepository: Failed to update event: ${e.message}');
      throw RepositoryException('Failed to update event: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> deleteEvent(String firebaseId) async {
    try {
      await _fs.collection('events').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      debugPrint('❌ EventRepository: Failed to delete event: ${e.message}');
      throw RepositoryException('Failed to delete event: ${e.message}', cause: e);
    }
  }

  AppEvent _toDomain(EventRow row) {
    return AppEvent(
      id: row.id,
      title: row.title,
      description: row.description,
      startTime: row.startTime,
      endTime: row.endTime,
      color: row.color,
      terrainIds: row.terrainIds,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      firebaseId: row.firebaseId,
      createdBy: row.createdBy,
      modifiedBy: row.modifiedBy,
    );
  }
}
