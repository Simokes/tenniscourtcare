'use client'
import { useMemo } from 'react'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import { getPlayableTerrains, getClosedTerrains } from '@/core/selectors/terrain.selectors'
import { TerrainStatus } from '@/domain/enums/terrain-status'
import { Terrain } from '@/domain/entities/terrain'

export function useTerrains(): {
  terrains: Terrain[]
  playable: Terrain[]
  closed: Terrain[]
  maintenance: Terrain[]
  isLoading: boolean
  error: Error | null
} {
  const { data: terrains, isLoading, error } = useFirestoreCollection(
    firestoreTerrainRepository.subscribe
  )

  const playable = useMemo(() => getPlayableTerrains(terrains), [terrains])
  const closed = useMemo(() => getClosedTerrains(terrains), [terrains])
  const maintenance = useMemo(
    () => terrains.filter(t => t.status === TerrainStatus.MAINTENANCE),
    [terrains]
  )

  return { terrains, playable, closed, maintenance, isLoading, error }
}
