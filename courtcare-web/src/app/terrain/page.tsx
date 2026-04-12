'use client'
import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'

import { AppLayout } from '@/components/AppLayout'
import { useTerrains } from '@/features/terrain/hooks/useTerrains'
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository'
import { TerrainType, terrainTypeDisplayNames } from '@/domain/enums/terrain-type'
import { TerrainStatus, terrainStatusDisplayNames, terrainStatusColors } from '@/domain/enums/terrain-status'
import { Terrain, isTerrainClosed } from '@/domain/entities/terrain'

// Modals component logic

const addTerrainSchema = z.object({
  nom: z.string().min(1, 'Le nom est requis'),
  type: z.nativeEnum(TerrainType, { message: 'Le type est requis' })
})

type AddTerrainForm = z.infer<typeof addTerrainSchema>

export default function TerrainsPage() {
  const { terrains, playable, closed, maintenance, isLoading, error } = useTerrains()

  // Modal states
  const [isAddEditModalOpen, setIsAddEditModalOpen] = useState(false)
  const [editingTerrain, setEditingTerrain] = useState<Terrain | null>(null)

  const [isCloseModalOpen, setIsCloseModalOpen] = useState(false)
  const [closingTerrain, setClosingTerrain] = useState<Terrain | null>(null)

  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [deletingTerrain, setDeletingTerrain] = useState<Terrain | null>(null)

  // Forms
  const { register: registerAddEdit, handleSubmit: handleSubmitAddEdit, reset: resetAddEdit, formState: { errors: errorsAddEdit } } = useForm<AddTerrainForm>({
    resolver: zodResolver(addTerrainSchema),
  })

  const [closeReason, setCloseReason] = useState('Maintenance')
  const [closeUntil, setCloseUntil] = useState('')

  // Mutations
  const addMutation = useMutation({
    mutationFn: (data: AddTerrainForm) => firestoreTerrainRepository.add({
      id: Date.now(), // Use timestamp as temporary ID, will be overwritten by backend or ignored
      ...data,
      status: TerrainStatus.PLAYABLE,
      latitude: null,
      longitude: null,
      photoUrl: null,
      closureReason: null,
      closureUntil: null,
      createdBy: null,
      modifiedBy: null
    }),
    onSuccess: () => {
      setIsAddEditModalOpen(false)
      resetAddEdit()
    }
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string, data: Partial<Terrain> }) => firestoreTerrainRepository.update(id, data),
    onSuccess: () => {
      setIsAddEditModalOpen(false)
      resetAddEdit()
    }
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => firestoreTerrainRepository.remove(id),
    onSuccess: () => setIsDeleteModalOpen(false)
  })

  const closeMutation = useMutation({
    mutationFn: ({ id, reason, until }: { id: string, reason: string, until: Date | null }) =>
      firestoreTerrainRepository.update(id, {
        status: TerrainStatus.UNAVAILABLE,
        closureReason: reason,
        closureUntil: until
      }),
    onSuccess: () => {
      setIsCloseModalOpen(false)
      setCloseReason('Maintenance')
      setCloseUntil('')
    }
  })

  const reopenMutation = useMutation({
    mutationFn: (id: string) => firestoreTerrainRepository.update(id, {
      status: TerrainStatus.PLAYABLE,
      closureReason: null,
      closureUntil: null
    })
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
      if (!editingTerrain.firebaseId) return; // Prevent updating unsynced items
      updateMutation.mutate({ id: editingTerrain.firebaseId, data })
    } else {
      addMutation.mutate(data)
    }
  }

  const handleCloseConfirm = () => {
    if (!closingTerrain || !closingTerrain.firebaseId) return
    const untilDate = closeUntil ? new Date(closeUntil) : null
    closeMutation.mutate({ id: closingTerrain.firebaseId, reason: closeReason, until: untilDate })
  }

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto space-y-6">

        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              Gestion des terrains
            </h1>
          </div>
          <button
            onClick={openAddModal}
            className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors text-sm font-medium"
          >
            Ajouter un terrain
          </button>
        </div>

        {/* KPI Strip */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
           <div className="rounded-xl bg-white dark:bg-zinc-900 border border-emerald-200 dark:border-emerald-900/50 p-4">
             <div className="flex items-center gap-2">
               <div className="w-3 h-3 rounded-full bg-emerald-500"></div>
               <div className="text-sm text-zinc-500 dark:text-zinc-400">Jouables</div>
             </div>
             <div className="text-2xl font-bold text-emerald-600 dark:text-emerald-500 mt-1">
               {isLoading ? '...' : playable.length}
             </div>
           </div>

           <div className="rounded-xl bg-white dark:bg-zinc-900 border border-blue-200 dark:border-blue-900/50 p-4">
             <div className="flex items-center gap-2">
               <div className="w-3 h-3 rounded-full bg-blue-500"></div>
               <div className="text-sm text-zinc-500 dark:text-zinc-400">En maintenance</div>
             </div>
             <div className="text-2xl font-bold text-blue-600 dark:text-blue-500 mt-1">
               {isLoading ? '...' : maintenance.length}
             </div>
           </div>

           <div className="rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4">
             <div className="flex items-center gap-2">
               <div className="w-3 h-3 rounded-full bg-zinc-500"></div>
               <div className="text-sm text-zinc-500 dark:text-zinc-400">Fermés / Gelés</div>
             </div>
             <div className="text-2xl font-bold text-zinc-600 dark:text-zinc-400 mt-1">
               {isLoading ? '...' : closed.length}
             </div>
           </div>
        </div>

        {/* List/States */}
        {error ? (
          <div className="p-4 bg-red-50 text-red-600 rounded-lg border border-red-200">
            Erreur lors du chargement des terrains.
          </div>
        ) : isLoading ? (
          <div className="flex justify-center p-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
          </div>
        ) : terrains.length === 0 ? (
          <div className="p-8 text-center text-zinc-500 bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800">
            Aucun terrain enregistré.
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {terrains.map(terrain => (
              <div key={terrain.firebaseId ?? terrain.id} className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-4 flex flex-col h-full relative">

                {!terrain.firebaseId && (
                  <div className="absolute top-2 right-2 flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-amber-500" title="Sync en cours"></span>
                  </div>
                )}

                <div className="flex justify-between items-start mb-3">
                  <div>
                    <h3 className="font-semibold text-lg text-zinc-900 dark:text-zinc-100">{terrain.nom}</h3>
                    <p className="text-sm text-zinc-500">{terrainTypeDisplayNames[terrain.type]}</p>
                  </div>
                  <span
                    className="rounded-full px-2.5 py-1 text-xs font-medium text-white"
                    style={{ backgroundColor: terrainStatusColors[terrain.status] ?? '#6B7280' }}
                  >
                    {terrainStatusDisplayNames[terrain.status]}
                  </span>
                </div>

                {isTerrainClosed(terrain) && (
                  <div className="bg-zinc-50 dark:bg-zinc-800/50 rounded-lg p-3 mb-4 text-sm mt-auto">
                    <div className="font-medium text-zinc-700 dark:text-zinc-300">Raison: {terrain.closureReason ?? 'Non spécifiée'}</div>
                    {terrain.closureUntil && (
                       <div className="text-zinc-500 mt-1">
                         Jusqu&apos;au {format(new Date(terrain.closureUntil), 'dd MMMM yyyy', { locale: fr })}
                       </div>
                    )}
                  </div>
                )}

                {!isTerrainClosed(terrain) && <div className="mt-auto"></div>}

                <div className="flex gap-2 mt-4 pt-4 border-t border-zinc-100 dark:border-zinc-800">
                  <button
                    onClick={() => openEditModal(terrain)}
                    disabled={!terrain.firebaseId}
                    className="flex-1 px-3 py-1.5 text-xs font-medium text-blue-600 bg-blue-50 hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400 dark:hover:bg-blue-900/40 rounded-md transition-colors disabled:opacity-50"
                  >
                    Modifier
                  </button>

                  {isTerrainClosed(terrain) ? (
                    <button
                      onClick={() => terrain.firebaseId && reopenMutation.mutate(terrain.firebaseId)}
                      disabled={!terrain.firebaseId || reopenMutation.isPending}
                      className="flex-1 px-3 py-1.5 text-xs font-medium text-emerald-600 bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-900/20 dark:text-emerald-400 dark:hover:bg-emerald-900/40 rounded-md transition-colors disabled:opacity-50"
                    >
                      Rouvrir
                    </button>
                  ) : (
                    <button
                      onClick={() => {
                        setClosingTerrain(terrain)
                        setIsCloseModalOpen(true)
                      }}
                      disabled={!terrain.firebaseId}
                      className="flex-1 px-3 py-1.5 text-xs font-medium text-zinc-600 bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-400 dark:hover:bg-zinc-700 rounded-md transition-colors disabled:opacity-50"
                    >
                      Fermer
                    </button>
                  )}

                  <button
                    onClick={() => {
                      setDeletingTerrain(terrain)
                      setIsDeleteModalOpen(true)
                    }}
                    disabled={!terrain.firebaseId}
                    className="flex-1 px-3 py-1.5 text-xs font-medium text-red-600 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/40 rounded-md transition-colors disabled:opacity-50"
                  >
                    Supprimer
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

      </div>

      {/* Add/Edit Modal */}
      {isAddEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-zinc-900 rounded-xl max-w-md w-full p-6 shadow-xl border border-zinc-200 dark:border-zinc-800">
            <h2 className="text-xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">
              {editingTerrain ? 'Modifier le terrain' : 'Ajouter un terrain'}
            </h2>
            <form onSubmit={handleSubmitAddEdit(onSubmitAddEdit)} className="space-y-4">

              <div>
                <label className="block text-sm font-medium mb-1 text-zinc-700 dark:text-zinc-300">Nom</label>
                <input
                  type="text"
                  {...registerAddEdit('nom')}
                  className="w-full px-3 py-2 border rounded-lg bg-zinc-50 dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100"
                />
                {errorsAddEdit.nom && <p className="text-red-500 text-xs mt-1">{errorsAddEdit.nom.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium mb-1 text-zinc-700 dark:text-zinc-300">Type</label>
                <select
                  {...registerAddEdit('type')}
                  className="w-full px-3 py-2 border rounded-lg bg-zinc-50 dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100"
                >
                  <option value={TerrainType.TERRE_BATTUE}>{terrainTypeDisplayNames[TerrainType.TERRE_BATTUE]}</option>
                  <option value={TerrainType.SYNTHETIQUE}>{terrainTypeDisplayNames[TerrainType.SYNTHETIQUE]}</option>
                  <option value={TerrainType.DUR}>{terrainTypeDisplayNames[TerrainType.DUR]}</option>
                </select>
                {errorsAddEdit.type && <p className="text-red-500 text-xs mt-1">{errorsAddEdit.type.message}</p>}
              </div>

              <div className="flex gap-3 justify-end mt-6">
                <button
                  type="button"
                  onClick={() => setIsAddEditModalOpen(false)}
                  className="px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-colors"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={addMutation.isPending || updateMutation.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg transition-colors disabled:opacity-50"
                >
                  {editingTerrain ? 'Sauvegarder' : 'Ajouter'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Close Modal */}
      {isCloseModalOpen && closingTerrain && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-zinc-900 rounded-xl max-w-md w-full p-6 shadow-xl border border-zinc-200 dark:border-zinc-800">
            <h2 className="text-xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">
              Fermer {closingTerrain.nom}
            </h2>
            <div className="space-y-4">

              <div>
                <label className="block text-sm font-medium mb-1 text-zinc-700 dark:text-zinc-300">Raison</label>
                <select
                  value={closeReason}
                  onChange={(e) => setCloseReason(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg bg-zinc-50 dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100"
                >
                  <option value="Maintenance">Maintenance</option>
                  <option value="Intempéries">Intempéries</option>
                  <option value="Travaux">Travaux</option>
                  <option value="Autre">Autre</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1 text-zinc-700 dark:text-zinc-300">Jusqu&apos;au (optionnel)</label>
                <input
                  type="date"
                  value={closeUntil}
                  onChange={(e) => setCloseUntil(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg bg-zinc-50 dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100"
                />
              </div>

              <div className="flex gap-3 justify-end mt-6">
                <button
                  onClick={() => setIsCloseModalOpen(false)}
                  className="px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-colors"
                >
                  Annuler
                </button>
                <button
                  onClick={handleCloseConfirm}
                  disabled={closeMutation.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-zinc-700 hover:bg-zinc-800 rounded-lg transition-colors disabled:opacity-50"
                >
                  Confirmer la fermeture
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Modal */}
      {isDeleteModalOpen && deletingTerrain && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-zinc-900 rounded-xl max-w-md w-full p-6 shadow-xl border border-zinc-200 dark:border-zinc-800">
            <h2 className="text-xl font-bold mb-4 text-red-600">
              Supprimer {deletingTerrain.nom} ?
            </h2>
            <p className="text-sm text-zinc-600 dark:text-zinc-400 mb-6">
              Êtes-vous sûr de vouloir supprimer ce terrain ? Cette action est irréversible.
            </p>
            <div className="flex gap-3 justify-end">
              <button
                onClick={() => setIsDeleteModalOpen(false)}
                className="px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-colors"
              >
                Annuler
              </button>
              <button
                onClick={() => {
                  if (deletingTerrain.firebaseId) {
                    deleteMutation.mutate(deletingTerrain.firebaseId)
                  }
                }}
                disabled={deleteMutation.isPending}
                className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors disabled:opacity-50"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}

    </AppLayout>
  )
}
