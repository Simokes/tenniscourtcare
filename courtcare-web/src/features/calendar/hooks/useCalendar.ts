'use client'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreAppEventRepository } from '@/data/repositories/app-event.repository'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import { AppEvent } from '@/domain/entities/app-event'
import { Terrain } from '@/domain/entities/terrain'

export function useCalendar(): {
  events: AppEvent[]
  terrains: Terrain[]
  isLoading: boolean
  error: Error | null
} {
  const { data: events, isLoading: loadingE, error: errorE } = useFirestoreCollection(
    firestoreAppEventRepository.subscribe
  )
  const { data: terrains, isLoading: loadingT, error: errorT } = useFirestoreCollection(
    firestoreTerrainRepository.subscribe
  )

  return {
    events,
    terrains,
    isLoading: loadingE || loadingT,
    error: errorE || errorT || null,
  }
}
