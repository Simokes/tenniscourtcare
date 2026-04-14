'use client'

import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { AppLayout } from '@/components/AppLayout'
import { useStats } from '@/features/stats/hooks/useStats'
import { useStatsStore } from '@/core/stores/stats.store'

export default function StatsPage() {
  const {
    terrains,
    filtered,
    sacksSeries,
    typeDistribution,
    summary,
    isLoading,
    error
  } = useStats()

  const period = useStatsStore(s => s.period)
  const setPeriod = useStatsStore(s => s.setPeriod)
  const selectedTerrainIds = useStatsStore(s => s.selectedTerrainIds)
  const toggleTerrainId = useStatsStore(s => s.toggleTerrainId)
  const customStart = useStatsStore(s => s.customStart)
  const customEnd = useStatsStore(s => s.customEnd)
  const setCustomRange = useStatsStore(s => s.setCustomRange)

  const handleExportCSV = () => {
    const rows = [
      ['Date', 'Terrain ID', 'Type', 'Sacs Manto', 'Sacs Sottomanto', 'Sacs Silice', 'Duree (min)', 'Commentaire'],
      ...filtered.map(m => [
        new Date(m.date).toLocaleDateString('fr-FR'),
        String(m.terrainId),
        m.type,
        String(m.sacsMantoUtilises),
        String(m.sacsSottomantoUtilises),
        String(m.sacsSiliceUtilises),
        String(m.durationMinutes),
        m.commentaire ?? '',
      ])
    ]
    const csv = rows.map(r => r.join(';')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'stats_export.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  const handleCustomRangeStart = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newStart = new Date(e.target.value)
    if (!isNaN(newStart.getTime())) {
      setCustomRange(newStart, customEnd || new Date())
    }
  }

  const handleCustomRangeEnd = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newEnd = new Date(e.target.value)
    if (!isNaN(newEnd.getTime())) {
      setCustomRange(customStart || new Date(), newEnd)
    }
  }

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto space-y-6">

        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">Statistiques</h1>
            <p className="text-sm text-zinc-500">Analyse de la consommation et des maintenances</p>
          </div>
          <button
            onClick={handleExportCSV}
            className="rounded-lg bg-zinc-900 dark:bg-zinc-100 px-4 py-2 text-sm font-medium text-white dark:text-zinc-900 hover:bg-zinc-800 dark:hover:bg-zinc-200"
          >
            Exporter CSV
          </button>
        </div>

        {/* Filters */}
        <div className="flex flex-col gap-4 p-4 bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-xl">
          {/* Period Selection */}
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
            <span className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Période :</span>
            <div className="flex flex-wrap gap-2">
              {(['week', 'month', 'year', 'custom'] as const).map((p) => (
                <button
                  key={p}
                  onClick={() => setPeriod(p)}
                  className={`px-3 py-1.5 text-sm rounded-lg border font-medium ${
                    period === p
                      ? 'bg-emerald-50 border-emerald-200 text-emerald-700 dark:bg-emerald-900/30 dark:border-emerald-800 dark:text-emerald-400'
                      : 'bg-zinc-50 border-zinc-200 text-zinc-600 hover:bg-zinc-100 dark:bg-zinc-800 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-700'
                  }`}
                >
                  {p === 'week' && 'Semaine'}
                  {p === 'month' && 'Mois'}
                  {p === 'year' && 'Année'}
                  {p === 'custom' && 'Personnalisé'}
                </button>
              ))}
            </div>

            {period === 'custom' && (
              <div className="flex items-center gap-2">
                <input
                  type="date"
                  value={customStart ? customStart.toISOString().split('T')[0] : ''}
                  onChange={handleCustomRangeStart}
                  className="px-2 py-1.5 text-sm rounded-lg border border-zinc-200 bg-white text-zinc-900 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-100"
                />
                <span className="text-zinc-500">au</span>
                <input
                  type="date"
                  value={customEnd ? customEnd.toISOString().split('T')[0] : ''}
                  onChange={handleCustomRangeEnd}
                  className="px-2 py-1.5 text-sm rounded-lg border border-zinc-200 bg-white text-zinc-900 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-100"
                />
              </div>
            )}
          </div>

          {/* Terrain Selection */}
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
            <span className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Terrains :</span>
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => selectedTerrainIds.forEach(id => toggleTerrainId(id))}
                className={`px-3 py-1.5 text-sm rounded-full border font-medium ${
                  selectedTerrainIds.length === 0
                    ? 'bg-emerald-50 border-emerald-200 text-emerald-700 dark:bg-emerald-900/30 dark:border-emerald-800 dark:text-emerald-400'
                    : 'bg-zinc-50 border-zinc-200 text-zinc-600 hover:bg-zinc-100 dark:bg-zinc-800 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-700'
                }`}
              >
                Tous
              </button>
              {terrains.map((t) => (
                <button
                  key={t.firebaseId ?? String(t.id)}
                  onClick={() => toggleTerrainId(t.id)}
                  className={`px-3 py-1.5 text-sm rounded-full border font-medium ${
                    selectedTerrainIds.includes(t.id)
                      ? 'bg-emerald-50 border-emerald-200 text-emerald-700 dark:bg-emerald-900/30 dark:border-emerald-800 dark:text-emerald-400'
                      : 'bg-zinc-50 border-zinc-200 text-zinc-600 hover:bg-zinc-100 dark:bg-zinc-800 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-700'
                  }`}
                >
                  {t.nom}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Status Handling */}
        {error && (
          <div className="rounded-xl bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900 p-4 text-red-600 dark:text-red-400">
            Une erreur est survenue lors du chargement des données.
          </div>
        )}

        {isLoading ? (
          <div className="animate-pulse space-y-6">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {[1, 2, 3, 4].map(i => <div key={i} className="h-24 bg-zinc-200 dark:bg-zinc-800 rounded-xl"></div>)}
            </div>
            <div className="h-72 bg-zinc-200 dark:bg-zinc-800 rounded-xl"></div>
            <div className="h-72 bg-zinc-200 dark:bg-zinc-800 rounded-xl"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-12 rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900">
            <p className="text-zinc-500 dark:text-zinc-400">Aucune maintenance pour la période sélectionnée.</p>
          </div>
        ) : (
          <>
            {/* KPI Grid */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
                <div className="text-sm text-zinc-500 mb-1">Maintenances</div>
                <div className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{summary.totalMaintenances}</div>
              </div>
              <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
                <div className="text-sm text-zinc-500 mb-1">Total Manto</div>
                <div className="text-2xl font-bold text-emerald-600">{summary.totalMantoSacs} <span className="text-sm font-normal text-zinc-400">sacs</span></div>
              </div>
              <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
                <div className="text-sm text-zinc-500 mb-1">Total Sottomanto</div>
                <div className="text-2xl font-bold text-blue-600">{summary.totalSottomantoSacs} <span className="text-sm font-normal text-zinc-400">sacs</span></div>
              </div>
              <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
                <div className="text-sm text-zinc-500 mb-1">Total Silice</div>
                <div className="text-2xl font-bold text-amber-600">{summary.totalSiliceSacs} <span className="text-sm font-normal text-zinc-400">sacs</span></div>
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Line Chart */}
              <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
                <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-6">Consommation dans le temps</h2>
                {sacksSeries.length > 0 ? (
                  <div className="h-[300px] w-full">
                    <ResponsiveContainer width="100%" height="100%" minWidth={0}>
                      <LineChart data={sacksSeries} margin={{ top: 5, right: 20, bottom: 5, left: 0 }}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e4e4e7" />
                        <XAxis dataKey="dateLabel" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                        <YAxis stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                        <Tooltip
                          contentStyle={{ backgroundColor: '#18181b', borderColor: '#27272a', borderRadius: '8px' }}
                          itemStyle={{ color: '#e4e4e7' }}
                        />
                        <Legend />
                        <Line type="monotone" dataKey="manto" name="Manto" stroke="#10b981" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }} />
                        <Line type="monotone" dataKey="sottomanto" name="Sottomanto" stroke="#3b82f6" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }} />
                        <Line type="monotone" dataKey="silice" name="Silice" stroke="#f59e0b" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <div className="h-[300px] flex items-center justify-center text-zinc-400">
                    Aucune donnée pour la période
                  </div>
                )}
              </div>

              {/* Bar Chart */}
              <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
                <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-6">Types de maintenance</h2>
                {typeDistribution.length > 0 ? (
                  <div className="h-[300px] w-full">
                    <ResponsiveContainer width="100%" height="100%" minWidth={0}>
                      <BarChart data={typeDistribution} layout="vertical" margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e4e4e7" horizontal={true} vertical={false} />
                        <XAxis type="number" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                        <YAxis dataKey="type" type="category" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} width={100} />
                        <Tooltip
                          contentStyle={{ backgroundColor: '#18181b', borderColor: '#27272a', borderRadius: '8px', color: '#e4e4e7' }}
                          cursor={{ fill: '#f4f4f5' }}
                        />
                        <Bar dataKey="count" name="Nombre" fill="#10b981" radius={[0, 4, 4, 0]} barSize={24} />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <div className="h-[300px] flex items-center justify-center text-zinc-400">
                    Aucune maintenance pour la période
                  </div>
                )}
              </div>
            </div>
          </>
        )}
      </div>
    </AppLayout>
  )
}
