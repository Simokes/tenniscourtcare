'use client'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { auth } from '@/core/firebase/client'
import { firestoreUserRepository } from '@/data/repositories/user.repository'
import { UserStatus } from '@/domain/enums/user-status'

const schema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(1, 'Mot de passe requis'),
})
type FormData = z.infer<typeof schema>

export default function LoginPage() {
  const router = useRouter()
  const [error, setError] = useState<string | null>(null)
  const [isPending, setIsPending] = useState(false)
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setError(null)
    setIsPending(true)
    try {
      const cred = await signInWithEmailAndPassword(auth, data.email, data.password)
      const user = await firestoreUserRepository.getByFirebaseUid(cred.user.uid)
      if (user?.status === UserStatus.INACTIVE) {
        await auth.signOut()
        setError('pending_approval')
        return
      }
      const idToken = await cred.user.getIdToken()
      await fetch('/api/auth/session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      })
      router.replace('/')
    } catch (e: unknown) {
      const code = (e as { code?: string }).code ?? ''
      if (code.includes('user-not-found') || code.includes('wrong-password') || code.includes('invalid-credential')) {
        setError('invalid_credentials')
      } else {
        setError('generic')
      }
    } finally {
      setIsPending(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-50 dark:bg-zinc-950 p-4">
      <div className="w-full max-w-md rounded-xl bg-white dark:bg-zinc-900 p-8 shadow-md">
        <div className="flex flex-col items-center mb-8">
          <div className="h-16 w-16 rounded-full bg-emerald-100 dark:bg-emerald-900 flex items-center justify-center text-3xl mb-4">🎾</div>
          <h1 className="text-3xl font-bold text-emerald-600 dark:text-emerald-400">CourtCare</h1>
          <p className="text-sm text-zinc-500 mt-1">La gestion de club, simplifiée.</p>
        </div>
        <h2 className="text-xl font-bold text-center mb-1">Bon retour</h2>
        <p className="text-sm text-zinc-500 text-center mb-6">Veuillez entrer vos identifiants.</p>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input {...register('email')} type="email" placeholder="Votre adresse email"
              className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Mot de passe</label>
            <input {...register('password')} type="password" placeholder="Votre mot de passe"
              className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
          </div>
          {error && (
            <div className={`rounded-lg border p-3 text-sm text-center ${error === 'pending_approval' ? 'border-orange-300 bg-orange-50 text-orange-700 dark:bg-orange-950 dark:border-orange-800 dark:text-orange-300' : 'border-red-300 bg-red-50 text-red-700 dark:bg-red-950 dark:border-red-800 dark:text-red-300'}`}>
              {error === 'pending_approval'
                ? "Votre compte est en attente d'approbation par un administrateur."
                : error === 'invalid_credentials'
                ? 'Email ou mot de passe incorrect.'
                : 'Une erreur est survenue. Veuillez reessayer.'}
            </div>
          )}
          <button type="submit" disabled={isPending}
            className="w-full rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 text-sm disabled:opacity-60 transition-colors mt-2">
            {isPending ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
        <p className="text-center text-sm text-zinc-500 mt-6">
          Pas encore de compte ?{' '}
          <Link href="/signup" className="font-semibold text-emerald-600 hover:underline">S&apos;inscrire</Link>
        </p>
      </div>
    </div>
  )
}
