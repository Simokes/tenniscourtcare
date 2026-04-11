export enum TerrainStatus {
  PLAYABLE = 'playable', // 🟢 Jouable - prêt à jouer
  MAINTENANCE = 'maintenance', // 🔵 Maintenance - en entretien
  UNAVAILABLE = 'unavailable', // ❌ Non jouable - fermé/endommagé
  FROZEN = 'frozen' // 🥶 Gelé - gelé/pluie/neige
}

export const terrainStatusDisplayNames: Record<TerrainStatus, string> = {
  [TerrainStatus.PLAYABLE]: 'Jouable',
  [TerrainStatus.MAINTENANCE]: 'Maintenance',
  [TerrainStatus.UNAVAILABLE]: 'Non jouable',
  [TerrainStatus.FROZEN]: 'Gelé'
};

export const terrainStatusColors: Record<TerrainStatus, string> = {
  [TerrainStatus.PLAYABLE]: '#10B981', // Vert
  [TerrainStatus.MAINTENANCE]: '#0EA5E9', // Bleu ciel
  [TerrainStatus.UNAVAILABLE]: '#6B7280', // Gris
  [TerrainStatus.FROZEN]: '#3B82F6' // Bleu
};
