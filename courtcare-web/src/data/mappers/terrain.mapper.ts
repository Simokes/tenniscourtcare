import { Terrain } from '../../domain/entities/terrain';
import { TerrainStatus, TerrainType } from '../../domain/enums';
import { Timestamp } from 'firebase/firestore';

const TERRAIN_TYPE_BY_INDEX = [TerrainType.TERRE_BATTUE, TerrainType.SYNTHETIQUE, TerrainType.DUR];

function parseTimestamp(ts: unknown): Date {
  if (ts instanceof Timestamp) {
    return ts.toDate();
  }
  if (typeof ts === 'string') {
    return new Date(ts);
  }
  return new Date();
}

export function firestoreToTerrain(id: string, data: Record<string, unknown>): Terrain {
  return {
    id: Number(data['id'] ?? 0),
    nom: String(data['nom'] ?? ''),
    type: TERRAIN_TYPE_BY_INDEX[data['type'] as number] ?? TerrainType.TERRE_BATTUE,
    status: Object.values(TerrainStatus).includes(data['status'] as TerrainStatus)
      ? (data['status'] as TerrainStatus)
      : TerrainStatus.UNAVAILABLE,
    latitude: data['latitude'] != null ? Number(data['latitude']) : null,
    longitude: data['longitude'] != null ? Number(data['longitude']) : null,
    photoUrl: data['photoUrl'] != null ? String(data['photoUrl']) : null,
    closureReason: data['closureReason'] != null ? String(data['closureReason']) : null,
    closureUntil: data['closureUntil'] != null ? parseTimestamp(data['closureUntil']) : null,
    createdAt: parseTimestamp(data['createdAt']),
    updatedAt: parseTimestamp(data['updatedAt']),
    firebaseId: id,
    createdBy: data['createdBy'] != null ? String(data['createdBy']) : null,
    modifiedBy: data['modifiedBy'] != null ? String(data['modifiedBy']) : null,
  };
}

export function terrainToFirestore(terrain: Terrain): Record<string, unknown> {
  const result: Record<string, unknown> = {
    nom: terrain.nom,
    type: terrain.type,
    status: terrain.status,
    createdAt: terrain.createdAt.toISOString(),
    updatedAt: terrain.updatedAt.toISOString(),
    firebaseId: terrain.firebaseId,
  };

  if (terrain.latitude !== null) result['latitude'] = terrain.latitude;
  if (terrain.longitude !== null) result['longitude'] = terrain.longitude;
  if (terrain.photoUrl !== null) result['photoUrl'] = terrain.photoUrl;
  if (terrain.closureReason !== null) result['closureReason'] = terrain.closureReason;
  if (terrain.closureUntil !== null) result['closureUntil'] = terrain.closureUntil.toISOString();
  if (terrain.createdBy !== null) result['createdBy'] = terrain.createdBy;
  if (terrain.modifiedBy !== null) result['modifiedBy'] = terrain.modifiedBy;

  return result;
}
