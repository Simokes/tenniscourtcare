import { Maintenance } from '../../domain/entities/maintenance';
import { WeatherSnapshot } from '../../domain/entities/weather-snapshot';
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

export function firestoreToMaintenance(id: string, data: Record<string, unknown>): Maintenance {
  return {
    id: null,
    terrainId: Number(data['terrainId'] ?? 0),
    type: String(data['type'] ?? ''),
    commentaire: data['commentaire'] != null ? String(data['commentaire']) : null,
    date: Number(data['date'] ?? 0),
    sacsMantoUtilises: Number(data['sacsMantoUtilises'] ?? 0),
    sacsSottomantoUtilises: Number(data['sacsSottomantoUtilises'] ?? 0),
    sacsSiliceUtilises: Number(data['sacsSiliceUtilises'] ?? 0),
    isPlanned: Boolean(data['isPlanned'] ?? false),
    startHour: Number(data['startHour'] ?? 0),
    durationMinutes: Number(data['durationMinutes'] ?? 0),
    imagePath: data['imagePath'] != null ? String(data['imagePath']) : null,
    weather: data['weather'] != null ? (data['weather'] as WeatherSnapshot) : null,
    terrainGele: data['terrainGele'] != null ? Boolean(data['terrainGele']) : null,
    terrainImpraticable: data['terrainImpraticable'] != null ? Boolean(data['terrainImpraticable']) : null,
    createdAt: parseTimestamp(data['createdAt']),
    updatedAt: parseTimestamp(data['updatedAt']),
    firebaseId: id,
    createdBy: data['createdBy'] != null ? String(data['createdBy']) : null,
    modifiedBy: data['modifiedBy'] != null ? String(data['modifiedBy']) : null,
  };
}

export function maintenanceToFirestore(m: Maintenance): Record<string, unknown> {
  const result: Record<string, unknown> = {
    terrainId: m.terrainId,
    type: m.type,
    date: m.date,
    sacsMantoUtilises: m.sacsMantoUtilises,
    sacsSottomantoUtilises: m.sacsSottomantoUtilises,
    sacsSiliceUtilises: m.sacsSiliceUtilises,
    isPlanned: m.isPlanned,
    startHour: m.startHour,
    durationMinutes: m.durationMinutes,
    createdAt: Timestamp.fromDate(m.createdAt),
    updatedAt: Timestamp.fromDate(m.updatedAt),
    firebaseId: m.firebaseId,
  };

  if (m.commentaire !== null) result['commentaire'] = m.commentaire;
  if (m.imagePath !== null) result['imagePath'] = m.imagePath;
  if (m.weather !== null) result['weather'] = m.weather;
  if (m.terrainGele !== null) result['terrainGele'] = m.terrainGele;
  if (m.terrainImpraticable !== null) result['terrainImpraticable'] = m.terrainImpraticable;
  if (m.createdBy !== null) result['createdBy'] = m.createdBy;
  if (m.modifiedBy !== null) result['modifiedBy'] = m.modifiedBy;

  return result;
}
