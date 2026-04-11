'use client';

import React from 'react';
import { QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/core/providers/auth-provider';
import { queryClient } from '@/core/providers/query-client';
// import './globals.css'; // Add if you have a globals.css

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <title>CourtCare Web</title>
        <meta name="description" content="CourtCare admin interface" />
      </head>
      <body>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            {children}
          </AuthProvider>
        </QueryClientProvider>
      </body>
    </html>
  );
}
