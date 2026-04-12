'use client'
import { useMemo, useState } from 'react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { AppLayout } from '@/components/AppLayout'
import { useAuth } from '@/core/hooks/useAuth'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import { firestoreMaintenanceRepository } from '@/data/repositories/maintenance.repository'
import { firestoreAppEventRepository } from '@/data/repositories/app-event.repository'
import { firestoreStockItemRepository } from '@/data/repositories/stock-item.repository'
import { getPlayableTerrainCount } from '@/core/selectors/terrain.selectors'
import { getMaintenancesForToday, getOverdueMaintenances } from '@/core/selectors/maintenance.selectors'
import { getLowStockItems } from '@/core/selectors/stock.selectors'
import { terrainStatusDisplayNames, terrainStatusColors } from '@/domain/enums/terrain-status'
import { terrainTypeDisplayNames } from '@/domain/enums/terrain-type'

export default function DashboardPage() {
  const { user } = useAuth()

  const { data: terrains, isLoading: loadingTerrains } = useFirestoreCollection(
    firestoreTerrainRepository.subscribe
  )
  const { data: maintenances } = useFirestoreCollection(
    firestoreMaintenanceRepository.subscribe
  )
  const { data: events } = useFirestoreCollection(
    firestoreAppEventRepository.subscribe
  )
  const { data: stockItems } = useFirestoreCollection(
    firestoreStockItemRepository.subscribe
  )

  const playableCount = useMemo(() => getPlayableTerrainCount(terrains), [terrains])

  const [now] = useState<number>(() => Date.now())

  const todayMaintenances = useMemo(() => getMaintenancesForToday(maintenances, now), [maintenances, now])
  const overdueMaintenances = useMemo(() => getOverdueMaintenances(maintenances, now), [maintenances, now])
  const currentEvents = useMemo(() => {
    const dNow = new Date(now)
    return events.filter(e => new Date(e.startTime) <= dNow && new Date(e.endTime) >= dNow)
  }, [events, now])
  const todayEvents = useMemo(() => {
    const today = new Date(now)
    return events
      .filter(e => {
        const d = new Date(e.startTime)
        return d.getFullYear() === today.getFullYear() &&
               d.getMonth() === today.getMonth() &&
               d.getDate() === today.getDate()
      })
      .sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
  }, [events, now])
  const lowStock = useMemo(() => getLowStockItems(stockItems), [stockItems])

  const todayLabel = useMemo(() => format(new Date(now), "EEEE d MMMM yyyy", { locale: fr }), [now])
  const firstName = user?.name?.split(' ')[0] ?? 'vous'

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto space-y-6">

        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
            Bonjour, {firstName} 👋
          </h1>
          <p className="text-sm text-zinc-500 capitalize">{todayLabel}</p>
        </div>

        {/* Alert Strip */}
        {(overdueMaintenances.length > 0 || lowStock.length > 0) && (
          <div className="flex flex-col gap-2">
            {overdueMaintenances.length > 0 && (
              <div className="flex items-center gap-2 rounded-lg bg-orange-50 dark:bg-orange-950 border border-orange-200 dark:border-orange-800 px-4 py-2 text-sm text-orange-700 dark:text-orange-300">
                <span>⚠️</span>
                <span>
                  <strong>{overdueMaintenances.length}</strong>{' '}
                  maintenance{overdueMaintenances.length > 1 ? 's' : ''} en retard
                </span>
              </div>
            )}
            {lowStock.length > 0 && (
              <div className="flex items-center gap-2 rounded-lg bg-red-50 dark:bg-red-950 border border-red-200 dark:border-red-800 px-4 py-2 text-sm text-red-700 dark:text-red-300">
                <span>📦</span>
                <span>
                  <strong>{lowStock.length}</strong>{' '}
                  article{lowStock.length > 1 ? 's' : ''} en stock bas
                </span>
              </div>
            )}
          </div>
        )}

        {/* KPI Strip */}
        <div className="grid grid-cols-3 gap-4">
          <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
            <div className="text-2xl font-bold text-emerald-600">
              {loadingTerrains ? '…' : `${playableCount}/${terrains.length}`}
            </div>
            <div className="text-sm text-zinc-500 mt-1">Courts jouables</div>
          </div>
          <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
            <div className="text-2xl font-bold text-blue-600">{todayMaintenances.length}</div>
            <div className="text-sm text-zinc-500 mt-1">Maintenances aujourd&apos;hui</div>
          </div>
          <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
            <div className="text-2xl font-bold text-purple-600">{currentEvents.length}</div>
            <div className="text-sm text-zinc-500 mt-1">Événements en cours</div>
          </div>
        </div>

        {/* Current Event Banner */}
        {currentEvents[0] && (() => {
          const ev = currentEvents[0]
          const hex = '#' + (ev.color >>> 0).toString(16).padStart(8, '0').slice(2)
          return (
            <div
              className="flex items-center gap-2 rounded-lg px-4 py-3 text-sm font-medium text-white"
              style={{ backgroundColor: hex }}
            >
              <span className="inline-block h-2 w-2 rounded-full bg-white animate-pulse" />
              EN COURS — {ev.title}
            </div>
          )
        })()}

        {/* Court Availability */}
        <div>
          <div className="flex items-center gap-2 mb-3">
            <div className="h-3.5 w-1 rounded-full bg-emerald-500" />
            <h2 className="text-xs font-bold tracking-widest text-zinc-500 uppercase">
              Disponibilité des courts
            </h2>
          </div>
          {loadingTerrains ? (
            <p className="text-sm text-zinc-400">Chargement…</p>
          ) : terrains.length === 0 ? (
            <p className="text-sm text-zinc-400">Aucun terrain enregistré.</p>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {terrains.map(t => (
                <div
                  key={t.firebaseId ?? String(t.id)}
                  className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-3 flex items-center justify-between"
                >
                  <div>
                    <div className="font-medium text-sm text-zinc-900 dark:text-zinc-100">{t.nom}</div>
                    <div className="text-xs text-zinc-400">{terrainTypeDisplayNames[t.type] ?? t.type}</div>
                  </div>
                  <span
                    className="rounded-full px-2 py-0.5 text-xs font-semibold text-white"
                    style={{ backgroundColor: terrainStatusColors[t.status] ?? '#6B7280' }}
                  >
                    {terrainStatusDisplayNames[t.status] ?? t.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Today Timeline */}
        {(todayMaintenances.length > 0 || todayEvents.length > 0) && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <div className="h-3.5 w-1 rounded-full bg-blue-500" />
              <h2 className="text-xs font-bold tracking-widest text-zinc-500 uppercase">
                Planning du jour
              </h2>
            </div>
            <div className="space-y-2">
              {todayMaintenances.map(m => (
                <div
                  key={m.firebaseId ?? String(m.id)}
                  className="flex items-center gap-3 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 px-4 py-2 text-sm"
                >
                  <span>🔧</span>
                  <span className="font-medium text-zinc-900 dark:text-zinc-100">{m.type}</span>
                  <span className="text-zinc-400 text-xs ml-auto">
                    {String(m.startHour).padStart(2, '0')}h00
                  </span>
                </div>
              ))}
              {todayEvents.map(e => (
                <div
                  key={e.firebaseId ?? String(e.id)}
                  className="flex items-center gap-3 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 px-4 py-2 text-sm"
                >
                  <span>📅</span>
                  <span className="font-medium text-zinc-900 dark:text-zinc-100">{e.title}</span>
                  <span className="text-zinc-400 text-xs ml-auto">
                    {format(new Date(e.startTime), 'HH:mm')}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Stock Alerts */}
        {lowStock.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <div className="h-3.5 w-1 rounded-full bg-red-500" />
              <h2 className="text-xs font-bold tracking-widest text-zinc-500 uppercase">
                Alertes stock
              </h2>
            </div>
            <div className="space-y-2">
              {lowStock.slice(0, 5).map(item => (
                <div
                  key={item.firebaseId ?? String(item.id)}
                  className="flex items-center justify-between rounded-lg bg-white dark:bg-zinc-900 border border-red-200 dark:border-red-900 px-4 py-2 text-sm"
                >
                  <span className="font-medium text-zinc-900 dark:text-zinc-100">{item.name}</span>
                  <span className="text-red-600 font-semibold">{item.quantity} {item.unit}</span>
                </div>
              ))}
            </div>
          </div>
        )}

      </div>
    </AppLayout>
  )
}
