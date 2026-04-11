export interface JwtPayload {
  sub: string;
  email?: string;
  email_verified?: boolean;
  iss: string;
  exp: number;
  aud: string;
  iat: number;
  [key: string]: any;
}
