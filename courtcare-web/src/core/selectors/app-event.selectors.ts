import { AppEvent } from '@/domain/entities/app-event';

export function getCurrentEvents(events: AppEvent[], nowMs: number): AppEvent[] {
  const dNow = new Date(nowMs);
  return events.filter(e => new Date(e.startTime) <= dNow && new Date(e.endTime) >= dNow);
}

export function getTodayEvents(events: AppEvent[], nowMs: number): AppEvent[] {
  const today = new Date(nowMs);
  return events
    .filter(e => {
      const d = new Date(e.startTime);
      return d.getFullYear() === today.getFullYear() &&
             d.getMonth() === today.getMonth() &&
             d.getDate() === today.getDate();
    })
    .sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime());
}
