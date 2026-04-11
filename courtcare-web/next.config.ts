import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Prevent firebase-admin from being bundled client-side
  serverExternalPackages: ["firebase-admin"],
};

export default nextConfig;
