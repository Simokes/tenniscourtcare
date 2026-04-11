export enum TerrainType {
  TERRE_BATTUE = 'terreBattue',
  SYNTHETIQUE = 'synthetique',
  DUR = 'dur'
}

export const terrainTypeDisplayNames: Record<TerrainType, string> = {
  [TerrainType.TERRE_BATTUE]: 'Terre battue',
  [TerrainType.SYNTHETIQUE]: 'Synthétique',
  [TerrainType.DUR]: 'Dur'
};
