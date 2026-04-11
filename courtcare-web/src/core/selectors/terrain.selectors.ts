import { Terrain } from '@/domain/entities/terrain';
import { TerrainStatus } from '@/domain/enums/terrain-status';

export function getPlayableTerrains(terrains: Terrain[]): Terrain[] {
  return terrains.filter((t) => t.status === TerrainStatus.PLAYABLE);
}

export function getTerrainsByStatus(terrains: Terrain[], status: TerrainStatus): Terrain[] {
  return terrains.filter((t) => t.status === status);
}

export function getClosedTerrains(terrains: Terrain[]): Terrain[] {
  const now = new Date();
  return terrains.filter((t) => t.closureUntil !== null && t.closureUntil > now);
}

export function getPlayableTerrainCount(terrains: Terrain[]): number {
  return getPlayableTerrains(terrains).length;
}

export function getTerrainById(terrains: Terrain[], id: number): Terrain | undefined {
  return terrains.find((t) => t.id === id);
}
