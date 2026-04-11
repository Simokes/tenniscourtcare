import { AppEvent } from '../../domain/entities/app-event';
import { Timestamp } from 'firebase/firestore';

function parseTimestamp(ts: unknown): Date {
  if (ts instanceof Timestamp) {
    return ts.toDate();
  }
  if (typeof ts === 'string') {
    return new Date(ts);
  }
  return new Date();
}

export function firestoreToAppEvent(id: string, data: Record<string, unknown>): AppEvent {
  return {
    id: null,
    title: String(data['title'] ?? ''),
    description: data['description'] != null ? String(data['description']) : null,
    startTime: parseTimestamp(data['startTime']),
    endTime: parseTimestamp(data['endTime']),
    color: Number(data['color'] ?? 0xFFFFFFFF),
    terrainIds: Array.isArray(data['terrainIds']) ? data['terrainIds'].map(Number) : [],
    createdAt: parseTimestamp(data['createdAt']),
    updatedAt: parseTimestamp(data['updatedAt']),
    firebaseId: id,
    createdBy: data['createdBy'] != null ? String(data['createdBy']) : null,
    modifiedBy: data['modifiedBy'] != null ? String(data['modifiedBy']) : null,
  };
}

export function appEventToFirestore(event: AppEvent): Record<string, unknown> {
  const result: Record<string, unknown> = {
    title: event.title,
    startTime: Timestamp.fromDate(event.startTime),
    endTime: Timestamp.fromDate(event.endTime),
    color: event.color,
    terrainIds: event.terrainIds,
    createdAt: Timestamp.fromDate(event.createdAt),
    updatedAt: Timestamp.fromDate(event.updatedAt),
    firebaseId: event.firebaseId,
  };

  if (event.description !== null) result['description'] = event.description;
  if (event.createdBy !== null) result['createdBy'] = event.createdBy;
  if (event.modifiedBy !== null) result['modifiedBy'] = event.modifiedBy;

  return result;
}
