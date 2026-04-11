import { TerrainType, TerrainStatus } from '../enums';

export interface Terrain {
  id: number;
  nom: string;
  type: TerrainType;
  status: TerrainStatus;

  /** Coordonnées GPS facultatives (pour la météo) */
  latitude: number | null;
  longitude: number | null;
  photoUrl: string | null;
  closureReason: string | null;
  closureUntil: Date | null;

  // Sync fields
  createdAt: Date;
  updatedAt: Date;
  firebaseId: string | null;
  createdBy: string | null;
  modifiedBy: string | null;
}

/**
 * Vrai si le terrain est ferme par un agent (indisponible ou gele).
 */
export function isTerrainClosed(terrain: Terrain): boolean {
  return (
    terrain.status === TerrainStatus.UNAVAILABLE ||
    terrain.status === TerrainStatus.FROZEN
  );
}
