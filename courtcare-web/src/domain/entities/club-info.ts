export interface ClubInfo {
  id: string;
  name: string;
  street: string | null;
  postalCode: string | null;
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  phone: string | null;
  email: string | null;
  openingHour: number | null;
  closingHour: number | null;
  updatedAt: Date;
  updatedBy: string | null;
}
