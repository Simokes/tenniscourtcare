export interface WeatherSnapshot {
  /** °C */
  temperature: number;
  /** mm instantanée (au pas horaire) */
  precipitation: number;
  /** % */
  humidity: number;
  /** km/h */
  windSpeed: number;
  /** code Open‑Meteo */
  weatherCode: number;
}
