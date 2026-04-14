'use client'
import { useMemo, useState } from 'react'
import FullCalendar from '@fullcalendar/react'
import dayGridPlugin from '@fullcalendar/daygrid'
import timeGridPlugin from '@fullcalendar/timegrid'
import interactionPlugin from '@fullcalendar/interaction'
import { EventInput, DateSelectArg, EventClickArg } from '@fullcalendar/core'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { format } from 'date-fns'
import frLocale from '@fullcalendar/core/locales/fr'
import { AppLayout } from '@/components/AppLayout'
import { useCalendar } from '@/features/calendar/hooks/useCalendar'
import { firestoreAppEventRepository } from '@/data/repositories/app-event.repository'
import { AppEvent } from '@/domain/entities/app-event'

// Convertit un int ARGB Flutter en string hex CSS (#RRGGBB)
function argbToHex(argb: number): string {
  const r = (argb >> 16) & 0xff
  const g = (argb >> 8) & 0xff
  const b = argb & 0xff
  return '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('')
}

function hexToArgb(hex: string): number {
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return (0xff << 24) | (r << 16) | (g << 8) | b
}

const eventSchema = z.object({
  title: z.string().min(1, 'Le titre est requis'),
  description: z.string().optional(),
  startTime: z.string().min(1, 'La date de début est requise'),
  endTime: z.string().min(1, 'La date de fin est requise'),
  color: z.string().default('#2196F3'),
  terrainIds: z.array(z.number()).default([]),
})

type EventFormData = z.infer<typeof eventSchema>

const EVENT_COLORS = [
  { label: 'Bleu', value: '#2196F3' },
  { label: 'Vert', value: '#4CAF50' },
  { label: 'Rouge', value: '#F44336' },
  { label: 'Orange', value: '#FF9800' },
  { label: 'Violet', value: '#9C27B0' },
]

export default function CalendarPage() {
  const { events, terrains, isLoading, error } = useCalendar()

  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingEvent, setEditingEvent] = useState<AppEvent | null>(null)

  const { register, handleSubmit, reset, setValue, watch, formState: { errors } } = useForm<EventFormData>({
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    resolver: zodResolver(eventSchema) as any,
    defaultValues: {
      title: '',
      description: '',
      startTime: '',
      endTime: '',
      color: '#2196F3',
      terrainIds: [],
    }
  })

  const selectedTerrainIds = watch('terrainIds')

  const addEventMutation = useMutation({
    mutationFn: async (data: EventFormData) => {
      await firestoreAppEventRepository.add({
        title: data.title,
        description: data.description || null,
        startTime: new Date(data.startTime),
        endTime: new Date(data.endTime),
        color: hexToArgb(data.color),
        terrainIds: data.terrainIds,
        id: null, // Firebase sets this
        createdBy: null,
        modifiedBy: null,
      })
    },
    onSuccess: () => {
      closeModal()
    }
  })

  const updateEventMutation = useMutation({
    mutationFn: async (data: EventFormData) => {
      if (!editingEvent?.firebaseId) return
      await firestoreAppEventRepository.update(editingEvent.firebaseId, {
        title: data.title,
        description: data.description || null,
        startTime: new Date(data.startTime),
        endTime: new Date(data.endTime),
        color: hexToArgb(data.color),
        terrainIds: data.terrainIds,
      })
    },
    onSuccess: () => {
      closeModal()
    }
  })

  const deleteEventMutation = useMutation({
    mutationFn: async () => {
      if (!editingEvent?.firebaseId) return
      await firestoreAppEventRepository.remove(editingEvent.firebaseId)
    },
    onSuccess: () => {
      closeModal()
    }
  })

  const calendarEvents = useMemo<EventInput[]>(() => {
    return events.map(e => ({
      id: e.firebaseId ?? String(e.id),
      title: e.title,
      start: e.startTime,
      end: e.endTime,
      backgroundColor: argbToHex(e.color),
      borderColor: argbToHex(e.color),
      extendedProps: { appEvent: e },
    }))
  }, [events])

  const handleDateSelect = (selectInfo: DateSelectArg) => {
    const startStr = format(selectInfo.start, "yyyy-MM-dd'T'HH:mm")
    const endStr = format(selectInfo.end, "yyyy-MM-dd'T'HH:mm")

    setEditingEvent(null)
    reset({
      title: '',
      description: '',
      startTime: startStr,
      endTime: endStr,
      color: '#2196F3',
      terrainIds: [],
    })
    setIsModalOpen(true)
  }

  const handleEventClick = (clickInfo: EventClickArg) => {
    const appEvent = clickInfo.event.extendedProps.appEvent as AppEvent
    setEditingEvent(appEvent)
    reset({
      title: appEvent.title,
      description: appEvent.description || '',
      startTime: format(appEvent.startTime, "yyyy-MM-dd'T'HH:mm"),
      endTime: format(appEvent.endTime, "yyyy-MM-dd'T'HH:mm"),
      color: argbToHex(appEvent.color).toUpperCase(), // normalize to upper for matching dropdown values if needed
      terrainIds: appEvent.terrainIds,
    })
    setIsModalOpen(true)
  }

  const onSubmit = (data: EventFormData) => {
    if (editingEvent) {
      updateEventMutation.mutate(data)
    } else {
      addEventMutation.mutate(data)
    }
  }

  const handleDelete = () => {
    if (confirm('Voulez-vous vraiment supprimer cet événement ?')) {
      deleteEventMutation.mutate()
    }
  }

  const closeModal = () => {
    setIsModalOpen(false)
    setEditingEvent(null)
    reset()
  }

  const handleTerrainToggle = (terrainId: number) => {
    const current = new Set(selectedTerrainIds)
    if (current.has(terrainId)) {
      current.delete(terrainId)
    } else {
      current.add(terrainId)
    }
    setValue('terrainIds', Array.from(current))
  }

  return (
    <AppLayout>
      <div className="max-w-6xl mx-auto space-y-6 relative">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">Calendrier</h1>
        </div>

        {error && (
          <div className="rounded-lg bg-red-50 p-4 text-red-700">
            Erreur de chargement des données.
          </div>
        )}

        <div className="bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-xl p-4 shadow-sm relative">
          {isLoading && (
            <div className="absolute inset-0 bg-white/50 dark:bg-zinc-900/50 flex items-center justify-center z-10 rounded-xl">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-zinc-900 dark:border-zinc-100"></div>
            </div>
          )}

          <FullCalendar
            plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
            initialView="dayGridMonth"
            locale={frLocale}
            headerToolbar={{
              left: 'prev,next today',
              center: 'title',
              right: 'dayGridMonth,timeGridWeek,timeGridDay'
            }}
            selectable={true}
            select={handleDateSelect}
            eventClick={handleEventClick}
            events={calendarEvents}
            height="auto"
          />
        </div>

        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
            <div className="bg-white dark:bg-zinc-900 rounded-xl shadow-xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
              <h2 className="text-xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">
                {editingEvent ? 'Modifier l\'événement' : 'Ajouter un événement'}
              </h2>

              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Titre *</label>
                  <input
                    {...register('title')}
                    className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  {errors.title && <p className="text-red-500 text-sm mt-1">{errors.title.message}</p>}
                </div>

                <div>
                  <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Description</label>
                  <textarea
                    {...register('description')}
                    rows={3}
                    className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Début *</label>
                    <input
                      type="datetime-local"
                      {...register('startTime')}
                      className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    {errors.startTime && <p className="text-red-500 text-sm mt-1">{errors.startTime.message}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Fin *</label>
                    <input
                      type="datetime-local"
                      {...register('endTime')}
                      className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    {errors.endTime && <p className="text-red-500 text-sm mt-1">{errors.endTime.message}</p>}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Couleur</label>
                  <select
                    {...register('color')}
                    className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {EVENT_COLORS.map(c => (
                      <option key={c.value} value={c.value}>{c.label}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">Terrains associés</label>
                  <div className="flex flex-wrap gap-2">
                    {terrains.map(t => {
                      const isSelected = selectedTerrainIds.includes(t.id)
                      return (
                        <button
                          key={t.firebaseId ?? String(t.id)}
                          type="button"
                          onClick={() => handleTerrainToggle(t.id)}
                          className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-colors ${
                            isSelected
                              ? 'bg-blue-100 dark:bg-blue-900/30 border-blue-500 text-blue-700 dark:text-blue-300'
                              : 'bg-zinc-50 dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 hover:border-zinc-300 dark:hover:border-zinc-600'
                          }`}
                        >
                          {t.nom}
                        </button>
                      )
                    })}
                  </div>
                </div>

                {editingEvent && editingEvent.terrainIds.length > 0 && (
                  <div>
                    <label className="block text-xs font-bold tracking-widest text-zinc-500 uppercase mb-2">Terrains actuels</label>
                    <div className="flex flex-wrap gap-2">
                      {editingEvent.terrainIds.map(tid => {
                        const terrain = terrains.find(t => t.id === tid)
                        if (!terrain) return null
                        return (
                          <span key={tid} className="inline-flex items-center rounded-full bg-zinc-100 dark:bg-zinc-800 px-2.5 py-0.5 text-xs font-medium text-zinc-800 dark:text-zinc-200 border border-zinc-200 dark:border-zinc-700">
                            {terrain.nom}
                          </span>
                        )
                      })}
                    </div>
                  </div>
                )}

                <div className="pt-4 border-t border-zinc-200 dark:border-zinc-800 flex justify-between gap-3">
                  {editingEvent ? (
                    <button
                      type="button"
                      onClick={handleDelete}
                      disabled={deleteEventMutation.isPending || editingEvent.firebaseId === null}
                      className="px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg disabled:opacity-50"
                    >
                      {editingEvent.firebaseId === null ? 'Sync en cours...' : 'Supprimer'}
                    </button>
                  ) : (
                    <div></div>
                  )}

                  <div className="flex gap-3">
                    <button
                      type="button"
                      onClick={closeModal}
                      className="px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 dark:hover:bg-zinc-700 rounded-lg"
                    >
                      Annuler
                    </button>
                    <button
                      type="submit"
                      disabled={addEventMutation.isPending || updateEventMutation.isPending || (editingEvent ? editingEvent.firebaseId === null : false)}
                      className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg disabled:opacity-50"
                    >
                      {(editingEvent && editingEvent.firebaseId === null) ? 'Sync en cours...' : 'Sauvegarder'}
                    </button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  )
}
