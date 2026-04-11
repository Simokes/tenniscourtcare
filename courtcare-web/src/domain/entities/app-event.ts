export interface AppEvent {
  id: number | null;
  title: string;
  description: string | null;
  startTime: Date;
  endTime: Date;
  /** int ARGB */
  color: number;
  terrainIds: number[];

  // Sync fields
  createdAt: Date;
  updatedAt: Date;
  firebaseId: string | null;
  createdBy: string | null;
  modifiedBy: string | null;
}
