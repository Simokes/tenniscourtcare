'use client'
import { useMemo } from 'react'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreMaintenanceRepository } from '@/data/repositories/maintenance.repository'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import { useStatsStore } from '@/core/stores/stats.store'
import { Maintenance } from '@/domain/entities/maintenance'
import { Terrain } from '@/domain/entities/terrain'
import { startOfWeek, startOfMonth, startOfYear, subWeeks } from 'date-fns'

// Types de sortie
export interface SacksSeries {
  dateLabel: string  // ex: "12/04", "Semaine 15"
  manto: number
  sottomanto: number
  silice: number
}

export interface MaintenanceTypeCount {
  type: string
  count: number
}

export interface StatsSummary {
  totalMaintenances: number
  totalMantoSacs: number
  totalSottomantoSacs: number
  totalSiliceSacs: number
  avgMaintenancesPerTerrain: number
  mostUsedType: string | null
}

export function useStats(): {
  maintenances: Maintenance[]
  terrains: Terrain[]
  filtered: Maintenance[]
  sacksSeries: SacksSeries[]
  typeDistribution: MaintenanceTypeCount[]
  summary: StatsSummary
  isLoading: boolean
  error: Error | null
} {
  const { data: maintenances, isLoading: loadingM, error: errorM } = useFirestoreCollection(
    firestoreMaintenanceRepository.subscribe
  )
  const { data: terrains, isLoading: loadingT, error: errorT } = useFirestoreCollection(
    firestoreTerrainRepository.subscribe
  )

  // Lire le store UI (period, selectedTerrainIds sont des UI states -- OK dans Zustand)
  const period = useStatsStore(s => s.period)
  const selectedTerrainIds = useStatsStore(s => s.selectedTerrainIds)
  const customStart = useStatsStore(s => s.customStart)
  const customEnd = useStatsStore(s => s.customEnd)

  // Calculer la plage de dates selon la periode
  const dateRange = useMemo((): { start: number; end: number } => {
    const now = new Date()
    const end = now.getTime()
    if (period === 'week') return { start: startOfWeek(subWeeks(now, 0), { weekStartsOn: 1 }).getTime(), end }
    if (period === 'month') return { start: startOfMonth(now).getTime(), end }
    if (period === 'year') return { start: startOfYear(now).getTime(), end }
    if (period === 'custom' && customStart && customEnd) return { start: customStart.getTime(), end: customEnd.getTime() }
    return { start: startOfMonth(now).getTime(), end }
  }, [period, customStart, customEnd])

  // Filtrer par periode ET par terrains selectionnes
  const filtered = useMemo(() => {
    let result = maintenances.filter(m => !m.isPlanned && m.date >= dateRange.start && m.date <= dateRange.end)
    if (selectedTerrainIds.length > 0) {
      result = result.filter(m => selectedTerrainIds.includes(m.terrainId))
    }
    return result
  }, [maintenances, dateRange, selectedTerrainIds])

  // Serie temporelle sacs (grouper par jour : format 'dd/MM')
  const sacksSeries = useMemo((): SacksSeries[] => {
    const byDay: Record<string, SacksSeries> = {}
    for (const m of filtered) {
      const label = new Date(m.date).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' })
      if (!byDay[label]) byDay[label] = { dateLabel: label, manto: 0, sottomanto: 0, silice: 0 }
      byDay[label].manto += m.sacsMantoUtilises
      byDay[label].sottomanto += m.sacsSottomantoUtilises
      byDay[label].silice += m.sacsSiliceUtilises
    }
    return Object.values(byDay).sort((a, b) => a.dateLabel.localeCompare(b.dateLabel))
  }, [filtered])

  // Distribution par type de maintenance
  const typeDistribution = useMemo((): MaintenanceTypeCount[] => {
    const counts: Record<string, number> = {}
    for (const m of filtered) {
      counts[m.type] = (counts[m.type] ?? 0) + 1
    }
    return Object.entries(counts)
      .map(([type, count]) => ({ type, count }))
      .sort((a, b) => b.count - a.count)
  }, [filtered])

  // Summary KPIs
  const summary = useMemo((): StatsSummary => {
    const totalManto = filtered.reduce((s, m) => s + m.sacsMantoUtilises, 0)
    const totalSottomanto = filtered.reduce((s, m) => s + m.sacsSottomantoUtilises, 0)
    const totalSilice = filtered.reduce((s, m) => s + m.sacsSiliceUtilises, 0)
    const terrainCount = selectedTerrainIds.length > 0 ? selectedTerrainIds.length : terrains.length
    return {
      totalMaintenances: filtered.length,
      totalMantoSacs: totalManto,
      totalSottomantoSacs: totalSottomanto,
      totalSiliceSacs: totalSilice,
      avgMaintenancesPerTerrain: terrainCount > 0 ? Math.round((filtered.length / terrainCount) * 10) / 10 : 0,
      mostUsedType: typeDistribution[0]?.type ?? null,
    }
  }, [filtered, terrains, selectedTerrainIds, typeDistribution])

  return {
    maintenances, terrains, filtered,
    sacksSeries, typeDistribution, summary,
    isLoading: loadingM || loadingT,
    error: errorM || errorT || null,
  }
}
