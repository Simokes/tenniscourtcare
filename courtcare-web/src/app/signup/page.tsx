'use client'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { toast, Toaster } from 'sonner'
import { Role, roleLabels } from '@/domain/enums/role'

const schema = z.object({
  name: z.string().min(2, 'Nom requis (minimum 2 caracteres)'),
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Minimum 6 caracteres'),
  confirmPassword: z.string(),
  role: z.nativeEnum(Role),
}).refine(d => d.password === d.confirmPassword, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirmPassword'],
})

type FormData = z.infer<typeof schema>

export default function SignupPage() {
  const router = useRouter()
  const [error, setError] = useState<string | null>(null)
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      role: Role.AGENT,
    }
  })

  const onSubmit = async (data: FormData) => {
    setError(null)
    const res = await fetch('/api/auth/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: data.name, email: data.email, password: data.password, role: data.role }),
    })
    if (!res.ok) {
      const d = await res.json()
      setError(d.error ?? 'Erreur lors de l\'inscription.')
    } else {
      toast.success('Inscription envoyee -- en attente de validation par un administrateur.')
      router.push('/login')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-50 dark:bg-zinc-950 p-4">
      <div className="w-full max-w-md rounded-xl bg-white dark:bg-zinc-900 p-8 shadow-md">
        <div className="flex flex-col items-center mb-6">
          <div className="h-12 w-12 rounded-full bg-emerald-100 dark:bg-emerald-900 flex items-center justify-center text-2xl mb-4">📝</div>
          <h1 className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">Creer un compte</h1>
          <p className="text-sm text-zinc-500 mt-1">Rejoignez CourtCare.</p>
        </div>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Nom</label>
            <input {...register('name')} type="text" placeholder="Votre nom"
              className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            {errors.name && <p className="text-red-500 text-xs mt-1">{errors.name.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input {...register('email')} type="email" placeholder="Votre adresse email"
              className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Mot de passe</label>
            <div className="relative">
              <input {...register('password')} type={showPassword ? 'text' : 'password'} placeholder="Votre mot de passe"
                className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-2 pr-10 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
              <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-2 top-2 text-zinc-500 hover:text-zinc-700">
                {showPassword ? '👁️' : '🙈'}
              </button>
            </div>
            {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Confirmer le mot de passe</label>
            <div className="relative">
              <input {...register('confirmPassword')} type={showConfirmPassword ? 'text' : 'password'} placeholder="Confirmez votre mot de passe"
                className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-2 pr-10 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
              <button type="button" onClick={() => setShowConfirmPassword(!showConfirmPassword)} className="absolute right-2 top-2 text-zinc-500 hover:text-zinc-700">
                {showConfirmPassword ? '👁️' : '🙈'}
              </button>
            </div>
            {errors.confirmPassword && <p className="text-red-500 text-xs mt-1">{errors.confirmPassword.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Role</label>
            <select {...register('role')} className="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500">
              <option value={Role.AGENT}>{roleLabels[Role.AGENT]}</option>
              <option value={Role.SECRETARY}>{roleLabels[Role.SECRETARY]}</option>
            </select>
            {errors.role && <p className="text-red-500 text-xs mt-1">{errors.role.message}</p>}
          </div>
          {error && (
            <div className="rounded-lg border border-red-300 bg-red-50 p-3 text-sm text-center text-red-700 dark:bg-red-950 dark:border-red-800 dark:text-red-300">
              {error}
            </div>
          )}
          <button type="submit" disabled={isSubmitting}
            className="w-full rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 text-sm flex items-center justify-center disabled:opacity-60 transition-colors mt-2">
            {isSubmitting ? (
              <>
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Inscription...
              </>
            ) : 'S\'inscrire'}
          </button>
        </form>
        <p className="text-center text-sm text-zinc-500 mt-6">
          Deja un compte ?{' '}
          <Link href="/login" className="font-semibold text-emerald-600 hover:underline">Se connecter</Link>
        </p>
      </div>
      <Toaster richColors />
    </div>
  )
}
