'use client';

import { AdminLoginResponse, AdminProfile } from '@payspin/shared-types';
import { useRouter } from 'next/navigation';
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';
import { apiRequest, clearToken, getToken, setToken } from './admin-api';

interface AuthState {
  admin: AdminProfile | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [admin, setAdmin] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = getToken();
    if (!token) {
      setLoading(false);
      return;
    }
    apiRequest<AdminProfile>('/auth/me')
      .then(setAdmin)
      .catch(() => clearToken())
      .finally(() => setLoading(false));
  }, []);

  const login = useCallback(
    async (email: string, password: string) => {
      const res = await apiRequest<AdminLoginResponse>('/auth/login', {
        method: 'POST',
        body: { email, password },
      });
      setToken(res.accessToken);
      setAdmin(res.admin);
      router.push('/');
    },
    [router],
  );

  const logout = useCallback(() => {
    clearToken();
    setAdmin(null);
    router.push('/login');
  }, [router]);

  return (
    <AuthContext.Provider value={{ admin, loading, login, logout }}>{children}</AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
