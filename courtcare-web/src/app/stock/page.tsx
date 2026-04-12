'use client'
import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { AppLayout } from '@/components/AppLayout'
import { useInventory } from '@/features/inventory/hooks/useInventory'
import { firestoreStockItemRepository } from '@/data/repositories/stock-item.repository'
import { StockItem, isStockLow } from '@/domain/entities/stock-item'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const stockItemSchema = z.object({
  name: z.string().min(1, "Le nom est requis"),
  quantity: z.number({ message: "Doit être un nombre" }).int().min(0, "Ne peut pas être négatif"),
  unit: z.string().min(1, "L'unité est requise"),
  category: z.string().optional(),
  minThreshold: z.number({ message: "Doit être un nombre" }).int().min(0, "Ne peut pas être négatif").optional().nullable(),
  comment: z.string().optional().nullable(),
  isCustom: z.boolean()
})

type StockItemFormValues = z.infer<typeof stockItemSchema>

export default function InventoryPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const { filtered, byCategory, lowStock, critical, isLoading, error, items } = useInventory(searchQuery)

  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<StockItem | null>(null)

  // State for quantity adjustment inline
  const [adjustItemId, setAdjustItemId] = useState<string | null>(null)
  const [adjustAmount, setAdjustAmount] = useState<number | string>('')
  const [adjustType, setAdjustType] = useState<'add' | 'remove'>('add')

  const form = useForm<StockItemFormValues>({
    resolver: zodResolver(stockItemSchema),
    defaultValues: {
      name: '',
      quantity: 0,
      unit: '',
      category: '',
      minThreshold: null,
      comment: '',
      isCustom: false
    }
  })

  // Mutations
  const addItemMutation = useMutation({
    mutationFn: (data: Omit<StockItem, 'firebaseId' | 'createdAt' | 'updatedAt' | 'id'>) =>
      firestoreStockItemRepository.add({ ...data, id: null }),
    onSuccess: () => setIsModalOpen(false)
  })

  const updateItemMutation = useMutation({
    mutationFn: ({ firebaseId, partial }: { firebaseId: string, partial: Partial<Omit<StockItem, 'firebaseId'>> }) =>
      firestoreStockItemRepository.update(firebaseId, partial),
    onSuccess: () => setIsModalOpen(false)
  })

  const deleteItemMutation = useMutation({
    mutationFn: (firebaseId: string) => firestoreStockItemRepository.remove(firebaseId)
  })

  const openAddModal = () => {
    setEditingItem(null)
    form.reset({
      name: '',
      quantity: 0,
      unit: '',
      category: '',
      minThreshold: null,
      comment: '',
      isCustom: false
    })
    setIsModalOpen(true)
  }

  const openEditModal = (item: StockItem) => {
    setEditingItem(item)
    form.reset({
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      category: item.category || '',
      minThreshold: item.minThreshold,
      comment: item.comment || '',
      isCustom: item.isCustom
    })
    setIsModalOpen(true)
  }

  const handleDelete = (item: StockItem) => {
    if (!item.firebaseId) return
    if (confirm(`Êtes-vous sûr de vouloir supprimer l'article "${item.name}" ?`)) {
      deleteItemMutation.mutate(item.firebaseId)
    }
  }

  const openAdjustmentPrompt = (item: StockItem, type: 'add' | 'remove') => {
    if (!item.firebaseId) return
    setAdjustItemId(item.firebaseId)
    setAdjustType(type)
    setAdjustAmount('')
  }

  const submitAdjustment = (item: StockItem) => {
    if (!item.firebaseId) return
    const amount = Number(adjustAmount)
    if (isNaN(amount) || amount <= 0) return

    let newQuantity = item.quantity
    if (adjustType === 'add') {
      newQuantity += amount
    } else {
      newQuantity -= amount
    }

    if (newQuantity < 0) newQuantity = 0

    updateItemMutation.mutate({
      firebaseId: item.firebaseId,
      partial: { quantity: newQuantity }
    })
    setAdjustItemId(null)
    setAdjustAmount('')
  }

  const onSubmit = (data: StockItemFormValues) => {
    if (editingItem && editingItem.firebaseId) {
      updateItemMutation.mutate({
        firebaseId: editingItem.firebaseId,
        partial: {
          name: data.name,
          quantity: data.quantity,
          unit: data.unit,
          category: data.category || null,
          minThreshold: data.minThreshold ?? null,
          comment: data.comment || null,
          isCustom: data.isCustom
        }
      })
    } else {
      addItemMutation.mutate({
        name: data.name,
        quantity: data.quantity,
        unit: data.unit,
        category: data.category || null,
        minThreshold: data.minThreshold ?? null,
        comment: data.comment || null,
        isCustom: data.isCustom,
        sortOrder: items.length,
        createdBy: null,
        modifiedBy: null
      })
    }
  }

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
            Inventaire
          </h1>
          <button
            className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
            onClick={openAddModal}
          >
            Ajouter un article
          </button>
        </div>

        {/* Alert Section */}
        {(critical.length > 0 || lowStock.length > 0) && (
          <div className="flex flex-col gap-2">
            {critical.length > 0 && (
              <div className="flex flex-col gap-1 rounded-lg bg-red-50 dark:bg-red-950 border border-red-200 dark:border-red-800 px-4 py-3 text-sm text-red-700 dark:text-red-300">
                <div className="flex items-center gap-2 font-bold">
                  <span>⚠️</span>
                  <span>{critical.length} article{critical.length > 1 ? 's' : ''} en rupture de stock</span>
                </div>
                <div className="ml-6 opacity-90">
                  {critical.slice(0, 3).map(item => item.name).join(', ')}
                  {critical.length > 3 && ` et ${critical.length - 3} autres...`}
                </div>
              </div>
            )}

            {lowStock.length > 0 && critical.length === 0 && (
              <div className="flex flex-col gap-1 rounded-lg bg-orange-50 dark:bg-orange-950 border border-orange-200 dark:border-orange-800 px-4 py-3 text-sm text-orange-700 dark:text-orange-300">
                <div className="flex items-center gap-2 font-bold">
                  <span>⚠️</span>
                  <span>{lowStock.length} article{lowStock.length > 1 ? 's' : ''} en stock faible</span>
                </div>
                <div className="ml-6 opacity-90">
                  {lowStock.slice(0, 3).map(item => item.name).join(', ')}
                  {lowStock.length > 3 && ` et ${lowStock.length - 3} autres...`}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Search Bar */}
        <div className="relative">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-zinc-400">
            🔍
          </span>
          <input
            type="text"
            className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 py-2 pl-10 pr-4 text-sm text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
            placeholder="Rechercher un article..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* List Content */}
        {error ? (
          <div className="rounded-xl border border-red-200 dark:border-red-900 bg-red-50 dark:bg-red-950 p-4 text-red-700 dark:text-red-300">
            Une erreur est survenue lors du chargement de l&apos;inventaire: {error.message}
          </div>
        ) : isLoading ? (
          <div className="text-zinc-500">Chargement de l&apos;inventaire...</div>
        ) : items.length === 0 ? (
          <div className="rounded-xl border border-dashed border-zinc-300 dark:border-zinc-700 p-8 text-center text-zinc-500">
            Aucun article en inventaire
          </div>
        ) : filtered.length === 0 ? (
          <div className="rounded-xl border border-dashed border-zinc-300 dark:border-zinc-700 p-8 text-center text-zinc-500">
            Aucun article ne correspond à votre recherche
          </div>
        ) : (
          <div className="space-y-8">
            {Object.entries(byCategory).map(([category, categoryItems]) => (
              <div key={category} className="space-y-4">
                <h2 className="text-lg font-bold text-zinc-900 dark:text-zinc-100 capitalize">
                  {category === 'sans-categorie' ? 'Sans catégorie' : category}
                </h2>
                <div className="grid gap-3">
                  {categoryItems.map(item => {
                    const isRupture = item.quantity === 0 && item.minThreshold !== null
                    const isLow = isStockLow(item) && !isRupture

                    return (
                      <div
                        key={item.firebaseId ?? String(item.id)}
                        className="flex items-center justify-between rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-4 shadow-sm"
                      >
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-zinc-900 dark:text-zinc-100">
                              {item.name}
                            </span>
                            {isRupture && (
                              <span className="rounded-full bg-red-100 dark:bg-red-900 px-2 py-0.5 text-xs font-semibold text-red-700 dark:text-red-300">
                                Rupture
                              </span>
                            )}
                            {isLow && (
                              <span className="rounded-full bg-orange-100 dark:bg-orange-900 px-2 py-0.5 text-xs font-semibold text-orange-700 dark:text-orange-300">
                                Stock faible
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-4 text-sm text-zinc-500">
                            <span>
                              <strong>{item.quantity}</strong> {item.unit}
                            </span>
                            {item.minThreshold !== null && (
                              <span className="text-zinc-400">
                                Min: {item.minThreshold}
                              </span>
                            )}
                          </div>
                          {item.comment && (
                            <div className="text-xs text-zinc-400 mt-1 italic">
                              {item.comment}
                            </div>
                          )}
                        </div>

                        <div className="flex items-center gap-2">
                          {adjustItemId === item.firebaseId ? (
                            <div className="flex items-center gap-1 rounded-lg border border-zinc-200 dark:border-zinc-700 p-1 bg-white dark:bg-zinc-800">
                              <span className="text-sm font-medium px-1 text-zinc-600 dark:text-zinc-400">
                                {adjustType === 'add' ? '+' : '-'}
                              </span>
                              <input
                                type="number"
                                className="w-16 rounded border border-zinc-300 dark:border-zinc-600 px-1 py-0.5 text-sm dark:bg-zinc-900 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:border-emerald-500"
                                value={adjustAmount}
                                onChange={e => setAdjustAmount(e.target.value)}
                                autoFocus
                                onKeyDown={e => {
                                  if (e.key === 'Enter') submitAdjustment(item)
                                  if (e.key === 'Escape') setAdjustItemId(null)
                                }}
                              />
                              <button
                                className="p-1 rounded text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-900/30"
                                onClick={() => submitAdjustment(item)}
                              >
                                ✓
                              </button>
                              <button
                                className="p-1 rounded text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-700"
                                onClick={() => setAdjustItemId(null)}
                              >
                                ✕
                              </button>
                            </div>
                          ) : (
                            <div className="flex items-center rounded-lg border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800">
                              <button
                                className="px-3 py-1 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700 rounded-l-lg disabled:opacity-50"
                                onClick={() => openAdjustmentPrompt(item, 'remove')}
                                disabled={item.quantity <= 0 || !item.firebaseId || updateItemMutation.isPending}
                                title="Retirer"
                              >
                                -
                              </button>
                              <span className="px-2 text-sm font-medium w-8 text-center border-x border-zinc-200 dark:border-zinc-700">
                                {item.quantity}
                              </span>
                              <button
                                className="px-3 py-1 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700 rounded-r-lg disabled:opacity-50"
                                onClick={() => openAdjustmentPrompt(item, 'add')}
                                disabled={!item.firebaseId || updateItemMutation.isPending}
                                title="Ajouter"
                              >
                                +
                              </button>
                            </div>
                          )}

                          <button
                            className="p-2 text-zinc-400 hover:text-blue-600 dark:hover:text-blue-400"
                            title="Modifier"
                            onClick={() => openEditModal(item)}
                          >
                            ✏️
                          </button>
                          <button
                            className="p-2 text-zinc-400 hover:text-red-600 dark:hover:text-red-400"
                            title="Supprimer"
                            onClick={() => handleDelete(item)}
                          >
                            🗑️
                          </button>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-md rounded-xl bg-white dark:bg-zinc-900 p-6 shadow-xl">
              <h2 className="text-xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">
                {editingItem ? 'Modifier l\'article' : 'Ajouter un article'}
              </h2>

              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Nom *</label>
                  <input
                    type="text"
                    {...form.register('name')}
                    className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 p-2 text-sm focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-zinc-900 dark:text-zinc-100"
                  />
                  {form.formState.errors.name && <p className="text-red-500 text-xs mt-1">{form.formState.errors.name.message}</p>}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Quantité *</label>
                    <input
                      type="number"
                      {...form.register('quantity', { valueAsNumber: true })}
                      className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 p-2 text-sm focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-zinc-900 dark:text-zinc-100"
                    />
                    {form.formState.errors.quantity && <p className="text-red-500 text-xs mt-1">{form.formState.errors.quantity.message}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Unité *</label>
                    <input
                      type="text"
                      placeholder="ex: sacs, L"
                      {...form.register('unit')}
                      className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 p-2 text-sm focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-zinc-900 dark:text-zinc-100"
                    />
                    {form.formState.errors.unit && <p className="text-red-500 text-xs mt-1">{form.formState.errors.unit.message}</p>}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Catégorie</label>
                    <input
                      type="text"
                      {...form.register('category')}
                      className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 p-2 text-sm focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-zinc-900 dark:text-zinc-100"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Seuil minimum d&apos;alerte</label>
                    <input
                      type="number"
                      {...form.register('minThreshold', {
                        setValueAs: v => v === '' || v === null || isNaN(v) ? null : parseInt(v, 10)
                      })}
                      className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 p-2 text-sm focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-zinc-900 dark:text-zinc-100"
                    />
                     {form.formState.errors.minThreshold && <p className="text-red-500 text-xs mt-1">{form.formState.errors.minThreshold.message}</p>}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Commentaire</label>
                  <textarea
                    {...form.register('comment')}
                    className="w-full rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 p-2 text-sm focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-zinc-900 dark:text-zinc-100"
                    rows={2}
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="isCustom"
                    {...form.register('isCustom')}
                    className="rounded border-zinc-300 text-emerald-600 focus:ring-emerald-500"
                  />
                  <label htmlFor="isCustom" className="text-sm text-zinc-700 dark:text-zinc-300">
                    Article personnalisé
                  </label>
                </div>

                <div className="mt-6 flex justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setIsModalOpen(false)}
                    className="rounded-lg px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800"
                  >
                    Annuler
                  </button>
                  <button
                    type="submit"
                    disabled={addItemMutation.isPending || updateItemMutation.isPending}
                    className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50"
                  >
                    Sauvegarder
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  )
}
