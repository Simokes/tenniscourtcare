'use client';

import React, { useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../firebase/client';
import { useRouter } from 'next/navigation';

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      // In a real implementation, you would populate your Zustand store here
      // For example: useAuthStore.getState().setUser(user);

      if (user) {
        // Optionally update token in cookie for middleware
        const token = await user.getIdToken();
        document.cookie = `session=${token}; path=/; max-age=3600; SameSite=Strict`;
      } else {
        // Clear session cookie
        document.cookie = `session=; path=/; max-age=0; SameSite=Strict`;
      }

      setIsLoading(false);
    });

    return () => unsubscribe();
  }, [router]);

  if (isLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <div>Loading...</div>
      </div>
    );
  }

  return <>{children}</>;
};
