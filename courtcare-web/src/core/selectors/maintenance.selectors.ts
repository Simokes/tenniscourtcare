import { Maintenance } from '@/domain/entities/maintenance';

export function getOverdueMaintenances(maintenances: Maintenance[], nowMs: number): Maintenance[] {
  return maintenances.filter((m) => m.isPlanned && m.date < nowMs);
}

export function getMaintenancesForToday(maintenances: Maintenance[], nowMs: number): Maintenance[] {
  const date = new Date(nowMs);

  const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999).getTime();

  return maintenances.filter((m) => m.isPlanned && m.date >= startOfDay && m.date <= endOfDay);
}

export function getUpcomingMaintenances(maintenances: Maintenance[], nowMs: number): Maintenance[] {
  return maintenances
    .filter((m) => m.isPlanned && m.date > nowMs)
    .sort((a, b) => a.date - b.date);
}

export function groupMaintenancesByDate(maintenances: Maintenance[]): Record<string, Maintenance[]> {
  return maintenances.reduce((acc, m) => {
    const dateKey = new Date(m.date).toISOString().split('T')[0];
    if (!acc[dateKey]) {
      acc[dateKey] = [];
    }
    acc[dateKey].push(m);
    return acc;
  }, {} as Record<string, Maintenance[]>);
}

export function groupMaintenancesByTerrain(maintenances: Maintenance[]): Record<number, Maintenance[]> {
  return maintenances.reduce((acc, m) => {
    const terrainId = m.terrainId;
    if (!acc[terrainId]) {
      acc[terrainId] = [];
    }
    acc[terrainId].push(m);
    return acc;
  }, {} as Record<number, Maintenance[]>);
}

export function getMaintenancesByTerrainId(maintenances: Maintenance[], terrainId: number): Maintenance[] {
  return maintenances
    .filter((m) => m.terrainId === terrainId)
    .sort((a, b) => b.date - a.date);
}
