'use client'

import { useState, useEffect } from 'react'
import { updatePassword, EmailAuthProvider, reauthenticateWithCredential } from 'firebase/auth'
import { FirebaseError } from 'firebase/app'
import { useMutation } from '@tanstack/react-query'
import { auth, db } from '@/core/firebase/client'
import { doc } from 'firebase/firestore'
import { AppLayout } from '@/components/AppLayout'
import { useAuthStore } from '@/core/stores/auth.store'
import { firestoreUserRepository } from '@/data/repositories/user.repository'
import { roleLabels } from '@/domain/enums/role'
import { useFirestoreDocument } from '@/core/hooks/useFirestoreDocument'
import { ClubInfo } from '@/domain/entities/club-info'
import logger from '@/core/utils/logger'

// Mapping weathercode
const getWeatherDescription = (code: number): string => {
  if (code === 0) return 'Ciel dégagé'
  if (code >= 1 && code <= 3) return 'Partiellement nuageux'
  if (code >= 45 && code <= 48) return 'Brouillard'
  if (code >= 51 && code <= 67) return 'Pluie'
  if (code >= 71 && code <= 77) return 'Neige'
  if (code >= 80 && code <= 82) return 'Averses'
  if (code >= 95 && code <= 99) return 'Orage'
  return 'N/A'
}

export default function SettingsPage() {
  const { user } = useAuthStore()

  // Section Profil
  const [nameInput, setNameInput] = useState(user?.name || '')

  // Update name
  const updateNameMutation = useMutation({
    mutationFn: async (newName: string) => {
      if (!user?.firebaseId) throw new Error('Utilisateur non synchronisé')
      await firestoreUserRepository.update(user.firebaseId, { name: newName })
    },
    onSuccess: () => {
      logger.info('Settings', 'Nom modifié avec succès')
    }
  })

  // Section MDP
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordError, setPasswordError] = useState<string | null>(null)
  const [passwordSuccess, setPasswordSuccess] = useState<string | null>(null)

  const updatePasswordMutation = useMutation({
    mutationFn: async () => {
      setPasswordError(null)
      setPasswordSuccess(null)

      if (newPassword !== confirmPassword) {
        throw new Error('Les mots de passe ne correspondent pas.')
      }

      const currentUser = auth.currentUser
      if (!currentUser || !currentUser.email) throw new Error('Non connecté')

      try {
        // Optionnel : Réauthentification si 'auth/requires-recent-login'
        const credential = EmailAuthProvider.credential(currentUser.email, currentPassword)
        await reauthenticateWithCredential(currentUser, credential)

        await updatePassword(currentUser, newPassword)
      } catch (err: unknown) {
        if (err instanceof FirebaseError) {
          if (err.code === 'auth/requires-recent-login') {
            throw new Error('Veuillez vous reconnecter pour changer de mot de passe.')
          }
          if (err.code === 'auth/invalid-credential' || err.code === 'auth/wrong-password') {
             throw new Error('Ancien mot de passe incorrect.')
          }
        }
        throw err
      }
    },
    onSuccess: () => {
      setPasswordSuccess('Mot de passe modifié avec succès.')
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    },
    onError: (err: Error | FirebaseError) => {
      setPasswordError(err.message || 'Erreur lors du changement de mot de passe.')
    }
  })

  // Section Météo
  const { data: clubInfo } = useFirestoreDocument<ClubInfo>(
    'ClubInfoSettings',
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

  const [weather, setWeather] = useState<{ temp: number, desc: string, wind: number } | null>(null)
  const [weatherLoading, setWeatherLoading] = useState(false)
  const [weatherError, setWeatherError] = useState(false)

  useEffect(() => {
    if (!clubInfo?.latitude || !clubInfo?.longitude) return

    let isMounted = true
    const fetchWeather = async () => {
      setWeatherLoading(true)
      setWeatherError(false)
      try {
        const res = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${clubInfo.latitude}&longitude=${clubInfo.longitude}&current=temperature_2m,weathercode,windspeed_10m&timezone=auto`)
        if (!res.ok) throw new Error('API Error')
        const data = await res.json()
        if (isMounted) {
          setWeather({
            temp: data.current.temperature_2m,
            desc: getWeatherDescription(data.current.weathercode),
            wind: data.current.windspeed_10m
          })
        }
      } catch {
        if (isMounted) {
           setWeatherError(true)
        }
      } finally {
        if (isMounted) {
           setWeatherLoading(false)
        }
      }
    }

    fetchWeather()

    return () => { isMounted = false }
  }, [clubInfo?.latitude, clubInfo?.longitude])

  if (!user) return <AppLayout><div>Chargement...</div></AppLayout>

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto space-y-8 p-6">
        <h1 className="text-3xl font-bold">Paramètres</h1>

        {/* PROFIL */}
        <div className="bg-white p-6 rounded-lg shadow space-y-4">
          <h2 className="text-xl font-semibold">Profil</h2>

          <div>
            <span className="font-medium">Email :</span> {user.email}
          </div>
          <div>
            <span className="font-medium">Rôle :</span> <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">{roleLabels[user.role]}</span>
          </div>

          <div className="flex flex-col gap-2 pt-4">
            <label className="font-medium">Nom</label>
            <div className="flex gap-4">
              <input
                type="text"
                value={nameInput}
                onChange={(e) => setNameInput(e.target.value)}
                className="border rounded p-2 flex-grow"
              />
              <button
                onClick={() => updateNameMutation.mutate(nameInput)}
                disabled={updateNameMutation.isPending || nameInput === user.name}
                className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {updateNameMutation.isPending ? 'Sauvegarde...' : 'Modifier le nom'}
              </button>
            </div>
            {updateNameMutation.isSuccess && <p className="text-green-600 text-sm">Nom mis à jour</p>}
            {updateNameMutation.isError && <p className="text-red-600 text-sm">Erreur: {updateNameMutation.error.message}</p>}
          </div>
        </div>

        {/* MOT DE PASSE */}
        <div className="bg-white p-6 rounded-lg shadow space-y-4">
          <h2 className="text-xl font-semibold">Changer de mot de passe</h2>
          <div className="space-y-4 max-w-sm">
            <input
              type="password"
              placeholder="Ancien mot de passe"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              className="border rounded p-2 w-full"
            />
            <input
              type="password"
              placeholder="Nouveau mot de passe"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              className="border rounded p-2 w-full"
            />
            <input
              type="password"
              placeholder="Confirmer le nouveau mot de passe"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="border rounded p-2 w-full"
            />
            <button
              onClick={() => updatePasswordMutation.mutate()}
              disabled={updatePasswordMutation.isPending || !currentPassword || !newPassword || !confirmPassword}
              className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
            >
              {updatePasswordMutation.isPending ? 'Modification...' : 'Modifier le mot de passe'}
            </button>
            {passwordSuccess && <p className="text-green-600 text-sm">{passwordSuccess}</p>}
            {passwordError && <p className="text-red-600 text-sm">{passwordError}</p>}
          </div>
        </div>

        {/* METEO */}
        <div className="bg-white p-6 rounded-lg shadow space-y-4">
          <h2 className="text-xl font-semibold">Météo du Club</h2>
          {(!clubInfo?.latitude || !clubInfo?.longitude) ? (
            <p className="text-gray-500">Configurez la localisation du club dans Administration &gt; Infos Club</p>
          ) : (
            <div>
              {weatherLoading && <p>Chargement météo...</p>}
              {weatherError && <p className="text-red-500">Météo indisponible</p>}
              {weather && (
                <div className="flex gap-8 text-lg">
                  <div><span className="font-medium">Température:</span> {weather.temp} °C</div>
                  <div><span className="font-medium">Conditions:</span> {weather.desc}</div>
                  <div><span className="font-medium">Vent:</span> {weather.wind} km/h</div>
                </div>
              )}
            </div>
          )}
        </div>

      </div>
    </AppLayout>
  )
}
