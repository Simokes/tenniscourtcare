export enum TerrainClosureReason {
  RAIN = 'rain',
  FROST = 'frost',
  OTHER = 'other'
}

export const terrainClosureReasonDisplayNames: Record<TerrainClosureReason, string> = {
  [TerrainClosureReason.RAIN]: 'Pluie',
  [TerrainClosureReason.FROST]: 'Gele',
  [TerrainClosureReason.OTHER]: 'Autre'
};
