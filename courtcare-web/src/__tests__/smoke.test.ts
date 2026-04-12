import { describe, it, expect } from 'vitest'

// --- Terrain selectors ---
import {
  getPlayableTerrains,
  getClosedTerrains,
  getPlayableTerrainCount,
  getTerrainById,
} from '@/core/selectors/terrain.selectors'
import { TerrainStatus } from '@/domain/enums/terrain-status'
import type { Terrain } from '@/domain/entities/terrain'

// --- Maintenance selectors ---
import {
  getOverdueMaintenances,
  getUpcomingMaintenances,
} from '@/core/selectors/maintenance.selectors'
import type { Maintenance } from '@/domain/entities/maintenance'

// --- Stock selectors ---
import { getLowStockItems, getCriticalItems } from '@/core/selectors/stock.selectors'
import { isStockLow } from '@/domain/entities/stock-item'
import type { StockItem } from '@/domain/entities/stock-item'

// --- Domain logic ---
import { hasPermission, getPermissionsForRole } from '@/domain/logic/permission-resolver'
import { Role } from '@/domain/enums/role'
import { Permission } from '@/domain/enums/permission'

// --- Helpers ---
function makeTerrain(overrides: Partial<Terrain> = {}): Terrain {
  return {
    id: 1,
    nom: 'Court 1',
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    type: 'clay' as any,
    status: TerrainStatus.PLAYABLE,
    latitude: null,
    longitude: null,
    photoUrl: null,
    closureReason: null,
    closureUntil: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    firebaseId: null,
    createdBy: null,
    modifiedBy: null,
    ...overrides,
  }
}

function makeMaintenance(overrides: Partial<Maintenance> = {}): Maintenance {
  return {
    id: 1,
    terrainId: 1,
    type: 'preventive',
    description: 'Test',
    isPlanned: true,
    date: Date.now() - 86400000,
    createdAt: new Date(),
    updatedAt: new Date(),
    firebaseId: null,
    createdBy: null,
    modifiedBy: null,
    ...overrides,
  } as unknown as Maintenance
}

function makeStockItem(overrides: Partial<StockItem> = {}): StockItem {
  return {
    id: 1,
    name: 'Balles',
    quantity: 3,
    unit: 'boite',
    comment: null,
    isCustom: false,
    minThreshold: 5,
    category: 'sport',
    sortOrder: 0,
    createdAt: new Date(),
    updatedAt: new Date(),
    firebaseId: null,
    createdBy: null,
    modifiedBy: null,
    ...overrides,
  }
}

// --- Tests ---
describe('Smoke tests -- selectors et domain logic', () => {

  describe('terrain.selectors', () => {
    it('getPlayableTerrains retourne uniquement les terrains jouables', () => {
      const terrains = [
        makeTerrain({ id: 1, status: TerrainStatus.PLAYABLE }),
        makeTerrain({ id: 2, status: TerrainStatus.UNAVAILABLE }),
      ]
      const result = getPlayableTerrains(terrains)
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(1)
    })

    it('getPlayableTerrains retourne tableau vide si aucun terrain jouable', () => {
      const result = getPlayableTerrains([makeTerrain({ status: TerrainStatus.UNAVAILABLE })])
      expect(result).toHaveLength(0)
    })

    it('getPlayableTerrainCount retourne le bon compte', () => {
      const terrains = [
        makeTerrain({ status: TerrainStatus.PLAYABLE }),
        makeTerrain({ status: TerrainStatus.PLAYABLE }),
        makeTerrain({ status: TerrainStatus.UNAVAILABLE }),
      ]
      expect(getPlayableTerrainCount(terrains)).toBe(2)
    })

    it('getTerrainById retrouve le bon terrain', () => {
      const terrains = [makeTerrain({ id: 1 }), makeTerrain({ id: 2 })]
      expect(getTerrainById(terrains, 2)?.id).toBe(2)
      expect(getTerrainById(terrains, 99)).toBeUndefined()
    })

    it('getClosedTerrains retourne terrains avec closureUntil dans le futur', () => {
      const future = new Date(Date.now() + 86400000)
      const past = new Date(Date.now() - 86400000)
      const terrains = [
        makeTerrain({ id: 1, closureUntil: future }),
        makeTerrain({ id: 2, closureUntil: past }),
        makeTerrain({ id: 3, closureUntil: null }),
      ]
      const closed = getClosedTerrains(terrains)
      expect(closed).toHaveLength(1)
      expect(closed[0].id).toBe(1)
    })
  })

  describe('maintenance.selectors', () => {
    it('getOverdueMaintenances retourne les maintenances passees planifiees', () => {
      const now = Date.now()
      const maintenances = [
        makeMaintenance({ id: 1, isPlanned: true, date: now - 86400000 }),
        makeMaintenance({ id: 2, isPlanned: true, date: now + 86400000 }),
        makeMaintenance({ id: 3, isPlanned: false, date: now - 86400000 }),
      ]
      const result = getOverdueMaintenances(maintenances, now)
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(1)
    })

    it('getUpcomingMaintenances retourne futures maintenances planifiees triees', () => {
      const now = Date.now()
      const maintenances = [
        makeMaintenance({ id: 1, isPlanned: true, date: now + 200000 }),
        makeMaintenance({ id: 2, isPlanned: true, date: now + 100000 }),
        makeMaintenance({ id: 3, isPlanned: false, date: now + 300000 }),
      ]
      const result = getUpcomingMaintenances(maintenances, now)
      expect(result).toHaveLength(2)
      expect(result[0].id).toBe(2) // le plus proche en premier
    })
  })

  describe('stock.selectors + isStockLow', () => {
    it('isStockLow retourne true si quantity <= minThreshold', () => {
      expect(isStockLow(makeStockItem({ quantity: 3, minThreshold: 5 }))).toBe(true)
      expect(isStockLow(makeStockItem({ quantity: 5, minThreshold: 5 }))).toBe(true)
      expect(isStockLow(makeStockItem({ quantity: 6, minThreshold: 5 }))).toBe(false)
    })

    it('isStockLow retourne false si minThreshold est null', () => {
      expect(isStockLow(makeStockItem({ quantity: 0, minThreshold: null }))).toBe(false)
    })

    it('getLowStockItems filtre correctement', () => {
      const items = [
        makeStockItem({ id: 1, quantity: 2, minThreshold: 5 }),
        makeStockItem({ id: 2, quantity: 10, minThreshold: 5 }),
      ]
      const result = getLowStockItems(items)
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(1)
    })

    it('getCriticalItems retourne items avec quantity === 0 et minThreshold non null', () => {
      const items = [
        makeStockItem({ id: 1, quantity: 0, minThreshold: 5 }),
        makeStockItem({ id: 2, quantity: 0, minThreshold: null }),
        makeStockItem({ id: 3, quantity: 1, minThreshold: 5 }),
      ]
      expect(getCriticalItems(items)).toHaveLength(1)
    })
  })

  describe('permission-resolver', () => {
    it('hasPermission: admin a toutes les permissions', () => {
      expect(hasPermission(Role.ADMIN, Permission.CAN_MANAGE_USERS)).toBe(true)
    })

    it('hasPermission: agent peut editer maintenance', () => {
      expect(hasPermission(Role.AGENT, Permission.CAN_EDIT_MAINTENANCE)).toBe(true)
    })

    it('hasPermission: agent ne peut pas gerer les utilisateurs', () => {
      expect(hasPermission(Role.AGENT, Permission.CAN_MANAGE_USERS)).toBe(false)
    })

    it('getPermissionsForRole retourne un tableau non vide pour admin', () => {
      const perms = getPermissionsForRole(Role.ADMIN)
      expect(perms.length).toBeGreaterThan(0)
    })

    it('getPermissionsForRole retourne tableau vide pour role inconnu', () => {
      expect(getPermissionsForRole('unknown_role' as Role)).toHaveLength(0)
    })
  })
})