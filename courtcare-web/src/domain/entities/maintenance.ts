import { WeatherSnapshot } from './weather-snapshot';

export interface Maintenance {
  id: number | null;
  terrainId: number;
  type: string;
  commentaire: string | null;
  /** Epoch ms */
  date: number;
  sacsMantoUtilises: number;
  sacsSottomantoUtilises: number;
  sacsSiliceUtilises: number;
  isPlanned: boolean;
  /** 0-23 */
  startHour: number;
  durationMinutes: number;
  imagePath: string | null;
  weather: WeatherSnapshot | null;
  terrainGele: boolean | null;
  terrainImpraticable: boolean | null;

  // Sync fields
  createdAt: Date;
  updatedAt: Date;
  firebaseId: string | null;
  createdBy: string | null;
  modifiedBy: string | null;
}
