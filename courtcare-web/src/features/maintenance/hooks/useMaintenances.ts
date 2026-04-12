'use client'
import { useMemo, useState } from 'react'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreMaintenanceRepository } from '@/data/repositories/maintenance.repository'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import {
  getOverdueMaintenances,
  getUpcomingMaintenances,
  getMaintenancesForToday
} from '@/core/selectors/maintenance.selectors'
import { Maintenance } from '@/domain/entities/maintenance'
import { Terrain } from '@/domain/entities/terrain'

export function useMaintenances(): {
  maintenances: Maintenance[]
  terrains: Terrain[]
  overdue: Maintenance[]
  upcoming: Maintenance[]
  today: Maintenance[]
  past: Maintenance[]
  isLoading: boolean
  error: Error | null
} {
  const { data: maintenances, isLoading: loadingM, error: errorM } = useFirestoreCollection(
    firestoreMaintenanceRepository.subscribe
  )
  const { data: terrains, isLoading: loadingT, error: errorT } = useFirestoreCollection(
    firestoreTerrainRepository.subscribe
  )

  const [now] = useState<number>(() => Date.now())

  const overdue = useMemo(() => getOverdueMaintenances(maintenances, now), [maintenances, now])
  const upcoming = useMemo(() => getUpcomingMaintenances(maintenances, now), [maintenances, now])
  const today = useMemo(() => getMaintenancesForToday(maintenances, now), [maintenances, now])
  const past = useMemo(
    () => maintenances.filter(m => !m.isPlanned && m.date < now).sort((a, b) => b.date - a.date),
    [maintenances, now]
  )

  return {
    maintenances,
    terrains,
    overdue,
    upcoming,
    today,
    past,
    isLoading: loadingM || loadingT,
    error: errorM || errorT || null,
  }
}