'use client'
import { useState, useEffect, useRef } from 'react'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { toast } from 'sonner'

import { AppLayout } from '@/components/AppLayout'
import { useTerrains } from '@/features/terrain/hooks/useTerrains'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import { TerrainType, terrainTypeDisplayNames } from '@/domain/enums/terrain-type'
import { TerrainStatus, terrainStatusDisplayNames } from '@/domain/enums/terrain-status'
import { Terrain, isTerrainClosed } from '@/domain/entities/terrain'

// ── Status design tokens ─────────────────────────────────────────────────────
const statusBorder: Record<TerrainStatus, string> = {
  [TerrainStatus.PLAYABLE]:    'border-l-emerald-500',
  [TerrainStatus.MAINTENANCE]: 'border-l-sky-500',
  [TerrainStatus.UNAVAILABLE]: 'border-l-zinc-400',
  [TerrainStatus.FROZEN]:      'border-l-blue-400',
}
const statusDot: Record<TerrainStatus, string> = {
  [TerrainStatus.PLAYABLE]:    'bg-emerald-500',
  [TerrainStatus.MAINTENANCE]: 'bg-sky-500',
  [TerrainStatus.UNAVAILABLE]: 'bg-zinc-400',
  [TerrainStatus.FROZEN]:      'bg-blue-400',
}
const statusText: Record<TerrainStatus, string> = {
  [TerrainStatus.PLAYABLE]:    'text-emerald-700 dark:text-emerald-400',
  [TerrainStatus.MAINTENANCE]: 'text-sky-700 dark:text-sky-400',
  [TerrainStatus.UNAVAILABLE]: 'text-zinc-500 dark:text-zinc-400',
  [TerrainStatus.FROZEN]:      'text-blue-700 dark:text-blue-400',
}

// ── Inline SVG icons ─────────────────────────────────────────────────────────
const IconPencil = () => (
  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
  </svg>
)
const IconLock = () => (
  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
  </svg>
)
const IconUnlock = () => (
  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
    <path d="M7 11V7a5 5 0 0 1 9.9-1"/>
  </svg>
)
const IconTrash = () => (
  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <polyline points="3 6 5 6 21 6"/>
    <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
    <path d="M10 11v6M14 11v6"/>
    <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
  </svg>
)
const IconPlus = () => (
  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
    <path d="M12 5v14M5 12h14"/>
  </svg>
)
const IconSpinner = () => (
  <svg className="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none">
    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
  </svg>
)
const IconCalendar = () => (
  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
    <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
    <line x1="3" y1="10" x2="21" y2="10"/>
  </svg>
)

// ── Skeleton ─────────────────────────────────────────────────────────────────
function TerrainSkeleton() {
  return (
    <div className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 border-l-4 border-l-zinc-200 dark:border-l-zinc-700 p-5 animate-pulse">
      <div className="flex justify-between items-start mb-4">
        <div className="space-y-2">
          <div className="h-5 w-28 bg-zinc-200 dark:bg-zinc-700 rounded-md"/>
          <div className="h-3.5 w-20 bg-zinc-100 dark:bg-zinc-800 rounded-md"/>
        </div>
        <div className="h-4 w-16 bg-zinc-100 dark:bg-zinc-800 rounded-full"/>
      </div>
      <div className="mt-8 pt-4 border-t border-zinc-100 dark:border-zinc-800 flex gap-2">
        <div className="h-8 flex-1 bg-zinc-100 dark:bg-zinc-800 rounded-lg"/>
        <div className="h-8 flex-1 bg-zinc-100 dark:bg-zinc-800 rounded-lg"/>
        <div className="h-8 flex-1 bg-zinc-100 dark:bg-zinc-800 rounded-lg"/>
      </div>
    </div>
  )
}

// ── Form schema ──────────────────────────────────────────────────────────────
const addTerrainSchema = z.object({
  nom: z.string().min(1, 'Le nom est requis'),
  type: z.nativeEnum(TerrainType, { message: 'Le type est requis' })
})
type AddTerrainForm = z.infer<typeof addTerrainSchema>

// ── Underline input style ────────────────────────────────────────────────────
const inputCls =
  'w-full border-0 border-b-2 border-zinc-200 dark:border-zinc-700 bg-transparent px-0 py-2.5 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:border-emerald-500 dark:focus:border-emerald-400 transition-colors placeholder:text-zinc-400'
const selectCls =
  'w-full border-0 border-b-2 border-zinc-200 dark:border-zinc-700 bg-transparent px-0 py-2.5 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:border-emerald-500 dark:focus:border-emerald-400 transition-colors cursor-pointer'

// ── Page ─────────────────────────────────────────────────────────────────────
export default function TerrainsPage() {
  const { terrains, playable, closed, maintenance, isLoading, error } = useTerrains()

  const [isAddEditModalOpen, setIsAddEditModalOpen] = useState(false)
  const [editingTerrain, setEditingTerrain]         = useState<Terrain | null>(null)
  const [isCloseModalOpen, setIsCloseModalOpen]     = useState(false)
  const [closingTerrain, setClosingTerrain]         = useState<Terrain | null>(null)
  const [isDeleteModalOpen, setIsDeleteModalOpen]   = useState(false)
  const [deletingTerrain, setDeletingTerrain]       = useState<Terrain | null>(null)

  const addEditModalRef = useRef<HTMLDivElement>(null)
  const closeModalRef   = useRef<HTMLDivElement>(null)
  const deleteModalRef  = useRef<HTMLDivElement>(null)

  // A3 — Escape
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return
      if (isAddEditModalOpen) setIsAddEditModalOpen(false)
      else if (isCloseModalOpen) setIsCloseModalOpen(false)
      else if (isDeleteModalOpen) setIsDeleteModalOpen(false)
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [isAddEditModalOpen, isCloseModalOpen, isDeleteModalOpen])

  // A2 — Focus trap
  const trapFocus = (ref: React.RefObject<HTMLDivElement | null>, isOpen: boolean) => {
    if (!isOpen || !ref.current) return
    const sel = 'button:not([disabled]),[href],input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])'
    const els = Array.from(ref.current.querySelectorAll<HTMLElement>(sel))
    if (!els.length) return
    els[0].focus()
    const onTab = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return
      if (e.shiftKey) { if (document.activeElement === els[0]) { e.preventDefault(); els[els.length - 1].focus() } }
      else            { if (document.activeElement === els[els.length - 1]) { e.preventDefault(); els[0].focus() } }
    }
    document.addEventListener('keydown', onTab)
    return () => document.removeEventListener('keydown', onTab)
  }
  useEffect(() => trapFocus(addEditModalRef, isAddEditModalOpen), [isAddEditModalOpen])
  useEffect(() => trapFocus(closeModalRef,   isCloseModalOpen),   [isCloseModalOpen])
  useEffect(() => trapFocus(deleteModalRef,  isDeleteModalOpen),  [isDeleteModalOpen])

  const { register: registerAddEdit, handleSubmit: handleSubmitAddEdit, reset: resetAddEdit, formState: { errors: errorsAddEdit } } = useForm<AddTerrainForm>({ resolver: zodResolver(addTerrainSchema) })
  const [closeReason, setCloseReason] = useState('Maintenance')
  const [closeUntil, setCloseUntil]   = useState('')

  const addMutation = useMutation({
    mutationFn: (data: AddTerrainForm) => firestoreTerrainRepository.add({
      id: Date.now(), ...data, status: TerrainStatus.PLAYABLE,
      latitude: null, longitude: null, photoUrl: null,
      closureReason: null, closureUntil: null, createdBy: null, modifiedBy: null
    }),
    onSuccess: () => { setIsAddEditModalOpen(false); toast.success('Terrain ajouté') },
    onError:   () => toast.error("Échec de l'ajout")
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Terrain> }) => firestoreTerrainRepository.update(id, data),
    onSuccess: () => { setIsAddEditModalOpen(false); toast.success('Terrain mis à jour') },
    onError:   () => toast.error('Échec de la mise à jour')
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => firestoreTerrainRepository.remove(id),
    onSuccess: () => { setIsDeleteModalOpen(false); toast.success('Terrain supprimé') },
    onError:   () => toast.error('Échec de la suppression')
  })

  const closeMutation = useMutation({
    mutationFn: ({ id, reason, until }: { id: string; reason: string; until: Date | null }) =>
      firestoreTerrainRepository.update(id, { status: TerrainStatus.UNAVAILABLE, closureReason: reason, closureUntil: until }),
    onSuccess: () => { setIsCloseModalOpen(false); setCloseReason('Maintenance'); setCloseUntil(''); toast.success('Terrain fermé') },
    onError:   () => toast.error('Échec de la fermeture')
  })

  const reopenMutation = useMutation({
    mutationFn: (id: string) => firestoreTerrainRepository.update(id, { status: TerrainStatus.PLAYABLE, closureReason: null, closureUntil: null }),
    onSuccess: () => toast.success('Terrain rouvert'),
    onError:   () => toast.error('Échec de la réouverture')
  })

  const openAddModal = () => {
    setEditingTerrain(null)
    resetAddEdit({ nom: '', type: TerrainType.TERRE_BATTUE })
    setIsAddEditModalOpen(true)
  }
  const openEditModal = (terrain: Terrain) => {
    setEditingTerrain(terrain)
    resetAddEdit({ nom: terrain.nom, type: terrain.type })
    setIsAddEditModalOpen(true)
  }
  const onSubmitAddEdit = (data: AddTerrainForm) => {
    if (editingTerrain) {
      if (!editingTerrain.firebaseId) return
      updateMutation.mutate({ id: editingTerrain.firebaseId, data })
    } else {
      addMutation.mutate(data)
    }
  }
  const handleCloseConfirm = () => {
    if (!closingTerrain?.firebaseId) return
    closeMutation.mutate({ id: closingTerrain.firebaseId, reason: closeReason, until: closeUntil ? new Date(closeUntil) : null })
  }

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto space-y-8">

        {/* ── Header ─────────────────────────────────────────────────────── */}
        <div className="flex items-end justify-between">
          <div>
            <p className="text-xs font-semibold tracking-widest uppercase text-emerald-600 dark:text-emerald-500 mb-1">
              Club
            </p>
            <h1 className="text-3xl font-black tracking-tight text-zinc-900 dark:text-zinc-50">
              Terrains
            </h1>
          </div>
          <button
            onClick={openAddModal}
            className="cursor-pointer inline-flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white rounded-xl text-sm font-semibold transition-colors shadow-sm shadow-emerald-900/20"
          >
            <IconPlus/>
            Ajouter
          </button>
        </div>

        {/* ── KPI Strip ──────────────────────────────────────────────────── */}
        <div className="grid grid-cols-3 gap-px bg-zinc-200 dark:bg-zinc-800 rounded-xl overflow-hidden border border-zinc-200 dark:border-zinc-800">
          {[
            { label: 'Jouables',      value: playable.length,     color: 'text-emerald-600 dark:text-emerald-400' },
            { label: 'Maintenance',   value: maintenance.length,  color: 'text-sky-600 dark:text-sky-400' },
            { label: 'Fermés / Gelés',value: closed.length,       color: 'text-zinc-500 dark:text-zinc-400' },
          ].map(({ label, value, color }) => (
            <div key={label} className="bg-white dark:bg-zinc-900 px-5 py-4">
              <div className="text-xs font-medium text-zinc-400 dark:text-zinc-500 mb-1">{label}</div>
              <div className={`text-3xl font-mono font-bold tabular-nums ${color}`}>
                {isLoading ? <span className="opacity-30">—</span> : value}
              </div>
            </div>
          ))}
        </div>

        {/* ── Cards ──────────────────────────────────────────────────────── */}
        {error ? (
          <div className="p-4 bg-red-50 dark:bg-red-950/30 text-red-600 dark:text-red-400 rounded-xl border border-red-200 dark:border-red-900 text-sm">
            Erreur lors du chargement des terrains.
          </div>
        ) : isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <TerrainSkeleton/><TerrainSkeleton/><TerrainSkeleton/>
          </div>
        ) : terrains.length === 0 ? (
          <div className="py-16 text-center">
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-zinc-100 dark:bg-zinc-800 mb-4">
              {/* Mini court SVG */}
              <svg className="w-7 h-7 text-zinc-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5}>
                <rect x="2" y="4" width="20" height="16" rx="2"/>
                <line x1="12" y1="4" x2="12" y2="20"/>
                <line x1="2" y1="12" x2="22" y2="12"/>
              </svg>
            </div>
            <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Aucun terrain enregistré</p>
            <p className="text-xs text-zinc-400 dark:text-zinc-600 mt-1">Commencez par en ajouter un.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {terrains.map(terrain => (
              <div
                key={terrain.firebaseId ?? terrain.id}
                className={`relative flex flex-col justify-between bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 border-l-[5px] ${statusBorder[terrain.status]} p-5 transition-shadow hover:shadow-md hover:shadow-zinc-900/5 dark:hover:shadow-zinc-900/40`}
              >
                {/* Sync indicator */}
                {!terrain.firebaseId && (
                  <div className="absolute top-3 right-3 flex h-2.5 w-2.5">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"/>
                    <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-amber-500" title="Sync en cours"/>
                  </div>
                )}

                <div className="space-y-3">
                  {/* Name + type */}
                  <div>
                    <h3 className="font-bold text-lg leading-tight text-zinc-900 dark:text-zinc-50">{terrain.nom}</h3>
                    <p className="text-xs font-medium tracking-wide uppercase text-zinc-400 dark:text-zinc-500 mt-0.5">
                      {terrainTypeDisplayNames[terrain.type]}
                    </p>
                  </div>

                  {/* Status pill */}
                  <div
                    className={`inline-flex items-center gap-1.5 text-xs font-semibold ${statusText[terrain.status]}`}
                    aria-label={`Statut : ${terrainStatusDisplayNames[terrain.status]}`}
                  >
                    <span className={`w-1.5 h-1.5 rounded-full ${statusDot[terrain.status]}`}/>
                    {terrainStatusDisplayNames[terrain.status]}
                  </div>

                  {/* Closure info */}
                  {isTerrainClosed(terrain) && (
                    <div className="bg-zinc-50 dark:bg-zinc-800/60 rounded-lg px-3 py-2.5 text-xs space-y-1 border border-zinc-100 dark:border-zinc-800">
                      <div className="font-semibold text-zinc-700 dark:text-zinc-300 truncate">
                        {terrain.closureReason ?? 'Raison non spécifiée'}
                      </div>
                      {terrain.closureUntil && (
                        <div className="flex items-center gap-1.5 text-zinc-500">
                          <IconCalendar/>
                          Jusqu&apos;au {format(new Date(terrain.closureUntil), 'dd MMM yyyy', { locale: fr })}
                        </div>
                      )}
                    </div>
                  )}
                </div>

                {/* Action row */}
                <div className="flex gap-1.5 mt-5 pt-4 border-t border-zinc-100 dark:border-zinc-800">
                  <button
                    onClick={() => openEditModal(terrain)}
                    disabled={!terrain.firebaseId}
                    title="Modifier"
                    className="cursor-pointer flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-medium text-zinc-600 dark:text-zinc-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    <IconPencil/> Modifier
                  </button>

                  {isTerrainClosed(terrain) ? (
                    <button
                      onClick={() => terrain.firebaseId && reopenMutation.mutate(terrain.firebaseId)}
                      disabled={!terrain.firebaseId || reopenMutation.isPending}
                      title="Rouvrir"
                      className="cursor-pointer flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-medium text-zinc-600 dark:text-zinc-400 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-900/20 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      {reopenMutation.isPending ? <IconSpinner/> : <IconUnlock/>}
                      {reopenMutation.isPending ? 'En cours…' : 'Rouvrir'}
                    </button>
                  ) : (
                    <button
                      onClick={() => { setClosingTerrain(terrain); setIsCloseModalOpen(true) }}
                      disabled={!terrain.firebaseId}
                      title="Fermer"
                      className="cursor-pointer flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      <IconLock/> Fermer
                    </button>
                  )}

                  <button
                    onClick={() => { setDeletingTerrain(terrain); setIsDeleteModalOpen(true) }}
                    disabled={!terrain.firebaseId}
                    title="Supprimer"
                    className="cursor-pointer flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-medium text-zinc-600 dark:text-zinc-400 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    <IconTrash/> Suppr.
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Add/Edit Modal ─────────────────────────────────────────────────── */}
      {isAddEditModalOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md"
          onClick={() => setIsAddEditModalOpen(false)}
        >
          <div
            ref={addEditModalRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby="modal-addedit-title"
            className="bg-white dark:bg-zinc-900 rounded-2xl max-w-md w-full shadow-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal header */}
            <div className="px-6 pt-6 pb-5 border-b border-zinc-100 dark:border-zinc-800">
              <div className="flex items-center gap-3">
                <div className="w-1 h-5 rounded-full bg-emerald-500"/>
                <h2 id="modal-addedit-title" className="text-base font-bold text-zinc-900 dark:text-zinc-50">
                  {editingTerrain ? 'Modifier le terrain' : 'Nouveau terrain'}
                </h2>
              </div>
            </div>

            <form onSubmit={handleSubmitAddEdit(onSubmitAddEdit)} className="px-6 py-5 space-y-6">
              <div>
                <label htmlFor="terrain-nom" className="block text-xs font-semibold uppercase tracking-wider text-zinc-500 dark:text-zinc-400 mb-2">
                  Nom du terrain
                </label>
                <input
                  id="terrain-nom"
                  type="text"
                  {...registerAddEdit('nom')}
                  placeholder="ex. Court n°1"
                  className={inputCls}
                />
                {errorsAddEdit.nom && <p role="alert" className="text-red-500 text-xs mt-1.5">{errorsAddEdit.nom.message}</p>}
              </div>

              <div>
                <label htmlFor="terrain-type" className="block text-xs font-semibold uppercase tracking-wider text-zinc-500 dark:text-zinc-400 mb-2">
                  Type de surface
                </label>
                <select id="terrain-type" {...registerAddEdit('type')} className={selectCls}>
                  <option value={TerrainType.TERRE_BATTUE}>{terrainTypeDisplayNames[TerrainType.TERRE_BATTUE]}</option>
                  <option value={TerrainType.SYNTHETIQUE}>{terrainTypeDisplayNames[TerrainType.SYNTHETIQUE]}</option>
                  <option value={TerrainType.DUR}>{terrainTypeDisplayNames[TerrainType.DUR]}</option>
                </select>
                {errorsAddEdit.type && <p role="alert" className="text-red-500 text-xs mt-1.5">{errorsAddEdit.type.message}</p>}
              </div>

              {(addMutation.isError || updateMutation.isError) && (
                <p role="alert" className="text-red-500 text-xs bg-red-50 dark:bg-red-950/40 px-3 py-2 rounded-lg border border-red-100 dark:border-red-900">
                  Une erreur est survenue. Veuillez réessayer.
                </p>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsAddEditModalOpen(false)}
                  className="cursor-pointer flex-1 py-2.5 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl transition-colors"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={addMutation.isPending || updateMutation.isPending}
                  className="cursor-pointer flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {(addMutation.isPending || updateMutation.isPending) && <IconSpinner/>}
                  {(addMutation.isPending || updateMutation.isPending) ? 'En cours…' : (editingTerrain ? 'Sauvegarder' : 'Ajouter')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Close Modal ────────────────────────────────────────────────────── */}
      {isCloseModalOpen && closingTerrain && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md"
          onClick={() => setIsCloseModalOpen(false)}
        >
          <div
            ref={closeModalRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby="modal-close-title"
            className="bg-white dark:bg-zinc-900 rounded-2xl max-w-md w-full shadow-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="px-6 pt-6 pb-5 border-b border-zinc-100 dark:border-zinc-800">
              <div className="flex items-center gap-3">
                <div className="w-1 h-5 rounded-full bg-zinc-400"/>
                <h2 id="modal-close-title" className="text-base font-bold text-zinc-900 dark:text-zinc-50">
                  Fermer <span className="text-emerald-600 dark:text-emerald-400">{closingTerrain.nom}</span>
                </h2>
              </div>
            </div>

            <div className="px-6 py-5 space-y-6">
              <div>
                <label htmlFor="close-reason" className="block text-xs font-semibold uppercase tracking-wider text-zinc-500 dark:text-zinc-400 mb-2">
                  Raison de fermeture
                </label>
                <select
                  id="close-reason"
                  value={closeReason}
                  onChange={(e) => setCloseReason(e.target.value)}
                  className={selectCls}
                >
                  <option value="Maintenance">Maintenance</option>
                  <option value="Intempéries">Intempéries</option>
                  <option value="Travaux">Travaux</option>
                  <option value="Autre">Autre</option>
                </select>
              </div>

              <div>
                <label htmlFor="close-until" className="block text-xs font-semibold uppercase tracking-wider text-zinc-500 dark:text-zinc-400 mb-2">
                  Jusqu&apos;au <span className="normal-case font-normal tracking-normal">(optionnel)</span>
                </label>
                <input
                  id="close-until"
                  type="date"
                  value={closeUntil}
                  onChange={(e) => setCloseUntil(e.target.value)}
                  className={inputCls}
                />
              </div>

              {closeMutation.isError && (
                <p role="alert" className="text-red-500 text-xs bg-red-50 dark:bg-red-950/40 px-3 py-2 rounded-lg border border-red-100 dark:border-red-900">
                  Une erreur est survenue. Veuillez réessayer.
                </p>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsCloseModalOpen(false)}
                  className="cursor-pointer flex-1 py-2.5 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl transition-colors"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={handleCloseConfirm}
                  disabled={closeMutation.isPending}
                  className="cursor-pointer flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-semibold text-white bg-zinc-800 hover:bg-zinc-900 dark:bg-zinc-700 dark:hover:bg-zinc-600 rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {closeMutation.isPending && <IconSpinner/>}
                  {closeMutation.isPending ? 'En cours…' : 'Confirmer la fermeture'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Delete Modal ────────────────────────────────────────────────────── */}
      {isDeleteModalOpen && deletingTerrain && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md"
          onClick={() => setIsDeleteModalOpen(false)}
        >
          <div
            ref={deleteModalRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby="modal-delete-title"
            className="bg-white dark:bg-zinc-900 rounded-2xl max-w-md w-full shadow-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="px-6 pt-6 pb-5 border-b border-zinc-100 dark:border-zinc-800">
              <div className="flex items-center gap-3">
                <div className="w-1 h-5 rounded-full bg-red-500"/>
                <h2 id="modal-delete-title" className="text-base font-bold text-zinc-900 dark:text-zinc-50">
                  Supprimer <span className="text-red-600 dark:text-red-400">{deletingTerrain.nom}</span> ?
                </h2>
              </div>
            </div>

            <div className="px-6 py-5">
              <p className="text-sm text-zinc-500 dark:text-zinc-400 mb-5 leading-relaxed">
                Cette action est <strong className="font-semibold text-zinc-700 dark:text-zinc-300">irréversible</strong>.
                Le terrain sera définitivement supprimé.
              </p>

              {deleteMutation.isError && (
                <p role="alert" className="text-red-500 text-xs bg-red-50 dark:bg-red-950/40 px-3 py-2 rounded-lg border border-red-100 dark:border-red-900 mb-4">
                  Une erreur est survenue. Veuillez réessayer.
                </p>
              )}

              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setIsDeleteModalOpen(false)}
                  className="cursor-pointer flex-1 py-2.5 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl transition-colors"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={() => { if (deletingTerrain.firebaseId) deleteMutation.mutate(deletingTerrain.firebaseId) }}
                  disabled={deleteMutation.isPending}
                  className="cursor-pointer flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-semibold text-white bg-red-600 hover:bg-red-700 rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {deleteMutation.isPending && <IconSpinner/>}
                  {deleteMutation.isPending ? 'En cours…' : 'Supprimer'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </AppLayout>
  )
}
