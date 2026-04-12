'use client'
import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { format } from 'date-fns'
import { AppLayout } from '@/components/AppLayout'
import { useMaintenances } from '@/features/maintenance/hooks/useMaintenances'
import { firestoreMaintenanceRepository } from '@/data/repositories/maintenance.repository'
import { Maintenance } from '@/domain/entities/maintenance'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const maintenanceSchema = z.object({
  terrainId: z.number().int().positive(),
  type: z.string().min(1),
  date: z.string().min(1),
  startHour: z.number().int().min(0).max(23).default(8),
  durationMinutes: z.number().int().min(1).default(60),
  commentaire: z.string().optional(),
  sacsMantoUtilises: z.number().int().min(0).default(0),
  sacsSottomantoUtilises: z.number().int().min(0).default(0),
  sacsSiliceUtilises: z.number().int().min(0).default(0),
  terrainGele: z.boolean().default(false),
  terrainImpraticable: z.boolean().default(false)
})

type MaintenanceFormData = z.infer<typeof maintenanceSchema>

export default function MaintenancePage() {
  const {
    terrains,
    overdue,
    upcoming,
    today,
    past,
    isLoading,
    error,
  } = useMaintenances()

  const [activeTab, setActiveTab] = useState<'upcoming' | 'overdue' | 'history'>('upcoming')
  const [isModalOpen, setIsModalOpen] = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm<MaintenanceFormData>({
    resolver: zodResolver(maintenanceSchema) as any,
    defaultValues: {
      startHour: 8,
      durationMinutes: 60,
      sacsMantoUtilises: 0,
      sacsSottomantoUtilises: 0,
      sacsSiliceUtilises: 0,
      terrainGele: false,
      terrainImpraticable: false
    }
  })

  const addMutation = useMutation({
    mutationFn: async (data: MaintenanceFormData) => {
      const dateMs = new Date(data.date).getTime()
      await firestoreMaintenanceRepository.add({
        id: null,
        terrainId: data.terrainId,
        type: data.type,
        commentaire: data.commentaire || null,
        date: dateMs,
        sacsMantoUtilises: data.sacsMantoUtilises,
        sacsSottomantoUtilises: data.sacsSottomantoUtilises,
        sacsSiliceUtilises: data.sacsSiliceUtilises,
        isPlanned: true,
        startHour: data.startHour,
        durationMinutes: data.durationMinutes,
        imagePath: null,
        weather: null,
        terrainGele: data.terrainGele,
        terrainImpraticable: data.terrainImpraticable,
        createdBy: null,
        modifiedBy: null
      })
    },
    onSuccess: () => {
      setIsModalOpen(false)
      reset()
    }
  })

  const completeMutation = useMutation({
    mutationFn: async (firebaseId: string) => {
      await firestoreMaintenanceRepository.update(firebaseId, { isPlanned: false })
    }
  })

  const deleteMutation = useMutation({
    mutationFn: async (firebaseId: string) => {
      await firestoreMaintenanceRepository.remove(firebaseId)
    }
  })

  const handleComplete = (m: Maintenance) => {
    if (m.firebaseId) {
      completeMutation.mutate(m.firebaseId)
    }
  }

  const handleDelete = (m: Maintenance) => {
    if (m.firebaseId && window.confirm('Êtes-vous sûr de vouloir supprimer cette maintenance ?')) {
      deleteMutation.mutate(m.firebaseId)
    }
  }

  const onSubmit = (data: MaintenanceFormData) => {
    addMutation.mutate(data)
  }

  const renderList = (items: Maintenance[]) => {
    if (items.length === 0) {
      return <div className="p-4 text-center text-zinc-500">Aucune maintenance.</div>
    }

    return (
      <div className="space-y-4">
        {items.map(m => {
          const terrain = terrains.find(t => t.id === m.terrainId)
          const isOverdue = m.isPlanned && m.date < Date.now()

          return (
            <div key={m.firebaseId || m.id} className="bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="flex-1 space-y-2">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-semibold text-zinc-900 dark:text-zinc-100">{terrain?.nom || 'Terrain inconnu'}</span>
                  <span className="text-sm text-zinc-500">•</span>
                  <span className="text-sm text-zinc-600 dark:text-zinc-400">{format(new Date(m.date), 'dd/MM/yyyy HH:mm')}</span>
                  {m.isPlanned ? (
                    <span className="px-2 py-0.5 text-xs rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">Planifié</span>
                  ) : (
                    <span className="px-2 py-0.5 text-xs rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200">Effectué</span>
                  )}
                  {isOverdue && (
                    <span className="px-2 py-0.5 text-xs rounded-full bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200">En retard</span>
                  )}
                </div>

                <div className="text-sm font-medium text-zinc-800 dark:text-zinc-200">{m.type}</div>

                <div className="text-sm text-zinc-500 flex items-center gap-4 flex-wrap">
                  <span>Durée : {m.durationMinutes} min</span>
                  {(m.sacsMantoUtilises > 0 || m.sacsSottomantoUtilises > 0 || m.sacsSiliceUtilises > 0) && (
                    <span className="flex items-center gap-2">
                      Sacs :
                      {m.sacsMantoUtilises > 0 && <span>Manto ({m.sacsMantoUtilises})</span>}
                      {m.sacsSottomantoUtilises > 0 && <span>Sottomanto ({m.sacsSottomantoUtilises})</span>}
                      {m.sacsSiliceUtilises > 0 && <span>Silice ({m.sacsSiliceUtilises})</span>}
                    </span>
                  )}
                </div>

                {m.commentaire && (
                  <div className="text-sm text-zinc-600 dark:text-zinc-400 italic mt-2 border-l-2 border-zinc-200 dark:border-zinc-700 pl-2">
                    &quot;{m.commentaire}&quot;
                  </div>
                )}
              </div>

              <div className="flex items-center gap-2">
                {m.isPlanned && (
                  <button
                    onClick={() => handleComplete(m)}
                    className="px-3 py-1.5 text-sm bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200 transition-colors"
                  >
                    Marquer effectué
                  </button>
                )}
                <button
                  onClick={() => handleDelete(m)}
                  className="px-3 py-1.5 text-sm border border-red-200 text-red-600 dark:border-red-900 dark:text-red-400 rounded-lg hover:bg-red-50 dark:hover:bg-red-950 transition-colors"
                >
                  Supprimer
                </button>
              </div>
            </div>
          )
        })}
      </div>
    )
  }

  if (error) {
    return (
      <AppLayout>
        <div className="p-4 text-red-600">Erreur de chargement des maintenances.</div>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">Maintenances</h1>
          <button
            onClick={() => setIsModalOpen(true)}
            className="px-4 py-2 bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200 transition-colors font-medium text-sm"
          >
            Planifier une maintenance
          </button>
        </div>

        {/* KPI Strip */}
        <div className="flex gap-2 flex-wrap">
          <div className={`px-4 py-2 rounded-full border text-sm font-medium flex items-center gap-2 ${overdue.length > 0 ? 'bg-red-50 border-red-200 text-red-700 dark:bg-red-950/50 dark:border-red-900 dark:text-red-300' : 'bg-white border-zinc-200 text-zinc-600 dark:bg-zinc-900 dark:border-zinc-800 dark:text-zinc-400'}`}>
            <span>En retard</span>
            <span className="bg-white/50 dark:bg-black/20 px-2 py-0.5 rounded-full">{overdue.length}</span>
          </div>
          <div className="px-4 py-2 rounded-full border bg-orange-50 border-orange-200 text-orange-700 dark:bg-orange-950/50 dark:border-orange-900 dark:text-orange-300 text-sm font-medium flex items-center gap-2">
            <span>Aujourd&apos;hui</span>
            <span className="bg-white/50 dark:bg-black/20 px-2 py-0.5 rounded-full">{today.length}</span>
          </div>
          <div className="px-4 py-2 rounded-full border bg-blue-50 border-blue-200 text-blue-700 dark:bg-blue-950/50 dark:border-blue-900 dark:text-blue-300 text-sm font-medium flex items-center gap-2">
            <span>À venir</span>
            <span className="bg-white/50 dark:bg-black/20 px-2 py-0.5 rounded-full">{upcoming.length}</span>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-4 border-b border-zinc-200 dark:border-zinc-800">
          <button
            onClick={() => setActiveTab('upcoming')}
            className={`pb-2 text-sm font-medium border-b-2 transition-colors ${activeTab === 'upcoming' ? 'border-zinc-900 text-zinc-900 dark:border-zinc-100 dark:text-zinc-100' : 'border-transparent text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'}`}
          >
            À venir
          </button>
          <button
            onClick={() => setActiveTab('overdue')}
            className={`pb-2 text-sm font-medium border-b-2 transition-colors flex items-center gap-2 ${activeTab === 'overdue' ? 'border-zinc-900 text-zinc-900 dark:border-zinc-100 dark:text-zinc-100' : 'border-transparent text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'}`}
          >
            En retard {overdue.length > 0 && <span className="bg-red-100 text-red-600 dark:bg-red-900/50 dark:text-red-400 px-1.5 py-0.5 rounded-full text-xs">{overdue.length}</span>}
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`pb-2 text-sm font-medium border-b-2 transition-colors ${activeTab === 'history' ? 'border-zinc-900 text-zinc-900 dark:border-zinc-100 dark:text-zinc-100' : 'border-transparent text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'}`}
          >
            Historique
          </button>
        </div>

        {/* List Content */}
        {isLoading ? (
          <div className="p-8 text-center text-zinc-500">Chargement...</div>
        ) : (
          <div>
            {activeTab === 'upcoming' && renderList(upcoming)}
            {activeTab === 'overdue' && renderList(overdue)}
            {activeTab === 'history' && renderList(past)}
          </div>
        )}
      </div>

      {/* Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-xl border border-zinc-200 dark:border-zinc-800">
            <div className="p-6 border-b border-zinc-200 dark:border-zinc-800">
              <h2 className="text-lg font-bold text-zinc-900 dark:text-zinc-100">Planifier une maintenance</h2>
            </div>

            <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Terrain */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Terrain</label>
                  <select
                    {...register('terrainId', { valueAsNumber: true })}
                    className="w-full px-3 py-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-500"
                  >
                    <option value="">Sélectionner un terrain</option>
                    {terrains.map(t => (
                      <option key={t.firebaseId || t.id} value={t.id}>{t.nom}</option>
                    ))}
                  </select>
                  {errors.terrainId && <p className="text-xs text-red-500">{errors.terrainId.message}</p>}
                </div>

                {/* Type */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Type d&apos;intervention</label>
                  <select
                    {...register('type')}
                    className="w-full px-3 py-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-500"
                  >
                    <option value="">Sélectionner un type</option>
                    <option value="Passage tracteur">Passage tracteur</option>
                    <option value="Arrosage">Arrosage</option>
                    <option value="Lissage">Lissage</option>
                    <option value="Inspection">Inspection</option>
                    <option value="Autre">Autre</option>
                  </select>
                  {errors.type && <p className="text-xs text-red-500">{errors.type.message}</p>}
                </div>

                {/* Date */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Date</label>
                  <input
                    type="date"
                    {...register('date')}
                    className="w-full px-3 py-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-500"
                  />
                  {errors.date && <p className="text-xs text-red-500">{errors.date.message}</p>}
                </div>

                {/* Start Hour */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Heure de début (0-23)</label>
                  <input
                    type="number"
                    min="0" max="23"
                    {...register('startHour', { valueAsNumber: true })}
                    className="w-full px-3 py-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-500"
                  />
                  {errors.startHour && <p className="text-xs text-red-500">{errors.startHour.message}</p>}
                </div>

                {/* Duration */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Durée (minutes)</label>
                  <input
                    type="number"
                    min="1"
                    {...register('durationMinutes', { valueAsNumber: true })}
                    className="w-full px-3 py-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-500"
                  />
                  {errors.durationMinutes && <p className="text-xs text-red-500">{errors.durationMinutes.message}</p>}
                </div>
              </div>

              {/* Sacs */}
              <div className="p-4 bg-zinc-50 dark:bg-zinc-950 rounded-xl border border-zinc-200 dark:border-zinc-800 space-y-4">
                <h3 className="text-sm font-bold text-zinc-700 dark:text-zinc-300">Sacs utilisés (optionnel)</h3>
                <div className="grid grid-cols-3 gap-4">
                  <div className="space-y-1">
                    <label className="text-xs text-zinc-500">Manto</label>
                    <input type="number" min="0" {...register('sacsMantoUtilises', { valueAsNumber: true })} className="w-full px-3 py-1.5 rounded-md border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 text-sm" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs text-zinc-500">Sottomanto</label>
                    <input type="number" min="0" {...register('sacsSottomantoUtilises', { valueAsNumber: true })} className="w-full px-3 py-1.5 rounded-md border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 text-sm" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs text-zinc-500">Silice</label>
                    <input type="number" min="0" {...register('sacsSiliceUtilises', { valueAsNumber: true })} className="w-full px-3 py-1.5 rounded-md border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 text-sm" />
                  </div>
                </div>
              </div>

              {/* Comment */}
              <div className="space-y-1">
                <label className="text-sm font-medium text-zinc-700 dark:text-zinc-300">Commentaire</label>
                <textarea
                  {...register('commentaire')}
                  rows={3}
                  className="w-full px-3 py-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-500 resize-none"
                />
              </div>

              {/* Checkboxes */}
              <div className="flex gap-6">
                <label className="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                  <input type="checkbox" {...register('terrainGele')} className="rounded border-zinc-300 text-zinc-900 focus:ring-zinc-500" />
                  Terrain gelé
                </label>
                <label className="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                  <input type="checkbox" {...register('terrainImpraticable')} className="rounded border-zinc-300 text-zinc-900 focus:ring-zinc-500" />
                  Terrain impraticable
                </label>
              </div>

              {/* Actions */}
              <div className="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-800">
                <button
                  type="button"
                  onClick={() => {
                    setIsModalOpen(false)
                    reset()
                  }}
                  className="px-4 py-2 text-sm font-medium text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-100"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={addMutation.isPending}
                  className="px-4 py-2 bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200 transition-colors font-medium text-sm disabled:opacity-50"
                >
                  {addMutation.isPending ? 'Planification...' : 'Planifier'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppLayout>
  )
}