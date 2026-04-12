'use client'

import { useState, useEffect } from 'react'
import { useMutation } from '@tanstack/react-query'
import { doc, updateDoc } from 'firebase/firestore'
import { db } from '@/core/firebase/client'
import { AppLayout } from '@/components/AppLayout'
import { useAdmin } from '@/features/admin/hooks/useAdmin'
import { firestoreUserRepository } from '@/data/repositories/user.repository'
import { Role, roleLabels } from '@/domain/enums/role'
import { UserStatus } from '@/domain/enums/user-status'
import { usePermission } from '@/core/hooks/usePermission'
import { Permission } from '@/domain/enums/permission'
import { useAuthStore } from '@/core/stores/auth.store'
import { useFirestoreDocument } from '@/core/hooks/useFirestoreDocument'
import { ClubInfo } from '@/domain/entities/club-info'
import logger from '@/core/utils/logger'
import { z } from 'zod'
import { useForm as useRHForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useRouter } from 'next/navigation'

const clubInfoSchema = z.object({
  name: z.string().min(1, 'Le nom est requis'),
  street: z.string().optional().nullable(),
  postalCode: z.string().optional().nullable(),
  city: z.string().optional().nullable(),
  latitude: z.number().optional().nullable(),
  longitude: z.number().optional().nullable(),
  phone: z.string().optional().nullable(),
  email: z.union([z.literal(''), z.string().email('Email invalide')]).optional().nullable(),
  openingHour: z.number().optional().nullable(),
  closingHour: z.number().optional().nullable(),
})

type ClubInfoFormValues = z.infer<typeof clubInfoSchema>

export default function AdminPage() {
  const router = useRouter()
  const { user } = useAuthStore()
  const canManage = usePermission(Permission.CAN_MANAGE_USERS)

  const [activeTab, setActiveTab] = useState<'users' | 'clubInfo'>('users')

  const { active, pending, rejected } = useAdmin()

  const updateUserMutation = useMutation({
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    mutationFn: async ({ id, partial }: { id: string, partial: any }) => {
      await firestoreUserRepository.update(id, partial)
    },
    onSuccess: () => logger.info('Admin', 'Utilisateur mis à jour')
  })

  const deleteUserMutation = useMutation({
    mutationFn: async (id: string) => {
      await firestoreUserRepository.remove(id)
    },
    onSuccess: () => logger.info('Admin', 'Utilisateur supprimé')
  })

  // Club Info
  const { data: clubInfo, isLoading: clubInfoLoading } = useFirestoreDocument<ClubInfo>(
    'ClubInfoAdmin',
    doc(db, 'clubInfo', 'main'),
    (id, data) => ({
      id,
      name: data.name as string,
      street: data.street as string | null,
      postalCode: data.postalCode as string | null,
      city: data.city as string | null,
      latitude: data.latitude as number | null,
      longitude: data.longitude as number | null,
      phone: data.phone as string | null,
      email: data.email as string | null,
      openingHour: data.openingHour as number | null,
      closingHour: data.closingHour as number | null,
      updatedAt: data.updatedAt ? new Date(data.updatedAt as string) : new Date(),
      updatedBy: data.updatedBy as string | null,
    })
  )

  const clubInfoForm = useRHForm<ClubInfoFormValues>({
    resolver: zodResolver(clubInfoSchema),
    defaultValues: {
      name: '',
      street: '',
      postalCode: '',
      city: '',
      latitude: null,
      longitude: null,
      phone: '',
      email: '',
      openingHour: null,
      closingHour: null,
    }
  })

  useEffect(() => {
    if (clubInfo) {
      clubInfoForm.reset({
        name: clubInfo.name || '',
        street: clubInfo.street || '',
        postalCode: clubInfo.postalCode || '',
        city: clubInfo.city || '',
        latitude: clubInfo.latitude,
        longitude: clubInfo.longitude,
        phone: clubInfo.phone || '',
        email: clubInfo.email || '',
        openingHour: clubInfo.openingHour,
        closingHour: clubInfo.closingHour,
      })
    }
  }, [clubInfo, clubInfoForm])

  const updateClubInfoMutation = useMutation({
    mutationFn: async (data: ClubInfoFormValues) => {
      const docRef = doc(db, 'clubInfo', 'main')
      await updateDoc(docRef, { ...data, updatedAt: new Date().toISOString(), updatedBy: user?.firebaseId })
    },
    onSuccess: () => logger.info('Admin', 'Club Info mis à jour')
  })

  if (!canManage) {
    return (
      <AppLayout>
        <div className="p-6">
          <p className="text-red-500 font-bold">Accès refusé</p>
          <button onClick={() => router.push('/')} className="text-blue-500 hover:underline">Retour au dashboard</button>
        </div>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="max-w-6xl mx-auto p-6 space-y-6">
        <h1 className="text-3xl font-bold">Administration</h1>

        {/* Onglets */}
        <div className="flex space-x-4 border-b">
          <button
            className={`pb-2 px-4 ${activeTab === 'users' ? 'border-b-2 border-blue-600 font-bold text-blue-600' : 'text-gray-500'}`}
            onClick={() => setActiveTab('users')}
          >
            Utilisateurs
          </button>
          <button
            className={`pb-2 px-4 ${activeTab === 'clubInfo' ? 'border-b-2 border-blue-600 font-bold text-blue-600' : 'text-gray-500'}`}
            onClick={() => setActiveTab('clubInfo')}
          >
            Infos Club
          </button>
        </div>

        {activeTab === 'users' && (
          <div className="space-y-6">
            {/* KPI */}
            <div className="flex gap-4 mb-6">
              <div className="bg-white p-4 rounded shadow flex-1">
                <div className="text-gray-500">Actifs</div>
                <div className="text-2xl font-bold">{active.length}</div>
              </div>
              <div className="bg-white p-4 rounded shadow flex-1">
                <div className="text-gray-500">En attente</div>
                <div className={`text-2xl font-bold ${pending.length > 0 ? 'text-red-500' : ''}`}>{pending.length}</div>
              </div>
              <div className="bg-white p-4 rounded shadow flex-1">
                <div className="text-gray-500">Rejetés</div>
                <div className="text-2xl font-bold">{rejected.length}</div>
              </div>
            </div>

            {/* Pending Users */}
            {pending.length > 0 && (
              <div className="bg-white p-6 rounded shadow space-y-4">
                <h2 className="text-xl font-bold text-red-600">En attente de validation</h2>
                <div className="space-y-4">
                  {pending.map(u => (
                    <div key={u.firebaseId} className="flex items-center justify-between border-b pb-4">
                      <div>
                        <div className="font-bold">{u.name}</div>
                        <div className="text-gray-500">{u.email}</div>
                        <div className="text-sm">Rôle demandé : {roleLabels[u.role]}</div>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => u.firebaseId && updateUserMutation.mutate({ id: u.firebaseId, partial: { status: UserStatus.ACTIVE, approvedAt: new Date().toISOString(), approvedBy: user?.firebaseId } })}
                          className="bg-green-600 text-white px-3 py-1 rounded hover:bg-green-700"
                        >
                          Approuver
                        </button>
                        <button
                          onClick={() => u.firebaseId && updateUserMutation.mutate({ id: u.firebaseId, partial: { status: UserStatus.REJECTED } })}
                          className="bg-red-600 text-white px-3 py-1 rounded hover:bg-red-700"
                        >
                          Rejeter
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Active Users */}
            <div className="bg-white p-6 rounded shadow space-y-4">
              <h2 className="text-xl font-bold">Utilisateurs actifs</h2>
              <div className="space-y-4">
                {active.map(u => (
                  <div key={u.firebaseId} className="flex items-center justify-between border-b pb-4">
                    <div className="flex-1">
                      <div className="font-bold">{u.name}</div>
                      <div className="text-gray-500">{u.email}</div>
                    </div>
                    <div className="flex items-center gap-4">
                      <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-sm whitespace-nowrap">
                        {roleLabels[u.role]}
                      </span>

                      <select
                        value={u.role}
                        onChange={(e) => u.firebaseId && updateUserMutation.mutate({ id: u.firebaseId, partial: { role: e.target.value } })}
                        className="border rounded p-1"
                        disabled={u.firebaseId === user?.firebaseId} // Ne peut pas changer son propre rôle
                      >
                        <option value={Role.ADMIN}>{roleLabels[Role.ADMIN]}</option>
                        <option value={Role.AGENT}>{roleLabels[Role.AGENT]}</option>
                        <option value={Role.SECRETARY}>{roleLabels[Role.SECRETARY]}</option>
                      </select>

                      <button
                        onClick={() => u.firebaseId && updateUserMutation.mutate({ id: u.firebaseId, partial: { status: UserStatus.INACTIVE } })}
                        className="text-orange-500 hover:underline"
                        disabled={u.firebaseId === user?.firebaseId}
                      >
                        Désactiver
                      </button>

                      <button
                        onClick={() => {
                          if (confirm('Voulez-vous vraiment supprimer cet utilisateur ?') && u.firebaseId) {
                            deleteUserMutation.mutate(u.firebaseId)
                          }
                        }}
                        className="text-red-500 hover:underline"
                        disabled={u.firebaseId === user?.firebaseId}
                      >
                        Supprimer
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'clubInfo' && (
          <div className="bg-white p-6 rounded shadow">
            <h2 className="text-xl font-bold mb-4">Informations du Club</h2>
            {clubInfoLoading ? <p>Chargement...</p> : (
              <form onSubmit={clubInfoForm.handleSubmit((d) => updateClubInfoMutation.mutate(d))} className="space-y-4 max-w-lg">
                <div>
                  <label className="block font-medium">Nom</label>
                  <input {...clubInfoForm.register('name')} className="border rounded p-2 w-full" />
                  {clubInfoForm.formState.errors.name && <span className="text-red-500 text-sm">{clubInfoForm.formState.errors.name.message}</span>}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-medium">Email</label>
                    <input {...clubInfoForm.register('email')} className="border rounded p-2 w-full" />
                  </div>
                  <div>
                    <label className="block font-medium">Téléphone</label>
                    <input {...clubInfoForm.register('phone')} className="border rounded p-2 w-full" />
                  </div>
                </div>

                <div>
                  <label className="block font-medium">Rue</label>
                  <input {...clubInfoForm.register('street')} className="border rounded p-2 w-full" />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-medium">Code Postal</label>
                    <input {...clubInfoForm.register('postalCode')} className="border rounded p-2 w-full" />
                  </div>
                  <div>
                    <label className="block font-medium">Ville</label>
                    <input {...clubInfoForm.register('city')} className="border rounded p-2 w-full" />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-medium">Latitude</label>
                    <input type="number" step="any" {...clubInfoForm.register('latitude', { valueAsNumber: true })} className="border rounded p-2 w-full" />
                  </div>
                  <div>
                    <label className="block font-medium">Longitude</label>
                    <input type="number" step="any" {...clubInfoForm.register('longitude', { valueAsNumber: true })} className="border rounded p-2 w-full" />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-medium">Heure d&apos;ouverture (0-23)</label>
                    <input type="number" {...clubInfoForm.register('openingHour', { valueAsNumber: true })} className="border rounded p-2 w-full" />
                  </div>
                  <div>
                    <label className="block font-medium">Heure de fermeture (0-23)</label>
                    <input type="number" {...clubInfoForm.register('closingHour', { valueAsNumber: true })} className="border rounded p-2 w-full" />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={updateClubInfoMutation.isPending}
                  className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
                >
                  {updateClubInfoMutation.isPending ? 'Sauvegarde...' : 'Sauvegarder'}
                </button>
                {updateClubInfoMutation.isSuccess && <p className="text-green-600 text-sm">Informations sauvegardées.</p>}
              </form>
            )}
          </div>
        )}

      </div>
    </AppLayout>
  )
}
