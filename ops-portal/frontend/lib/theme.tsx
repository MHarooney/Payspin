'use client';

import { createContext, useCallback, useContext, useState, type ReactNode } from 'react';

export type OpsTheme = 'light' | 'dark';

type ThemeContextValue = {
  theme: OpsTheme;
  toggle: () => void;
  setTheme: (theme: OpsTheme) => void;
};

const STORAGE_KEY = 'ops-theme';

const ThemeContext = createContext<ThemeContextValue | null>(null);

function resolveInitialTheme(): OpsTheme {
  if (typeof document !== 'undefined') {
    const attr = document.documentElement.dataset.theme;
    if (attr === 'light' || attr === 'dark') return attr;
  }
  return 'dark';
}

/** Applies `data-theme` on `<html>`, persists choice, default dark. */
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<OpsTheme>(() => resolveInitialTheme());

  const apply = useCallback((next: OpsTheme) => {
    setThemeState(next);
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem(STORAGE_KEY, next);
    } catch {
      // Private mode — theme still applies for this session.
    }
  }, []);

  const toggle = useCallback(() => {
    apply(theme === 'dark' ? 'light' : 'dark');
  }, [apply, theme]);

  return (
    <ThemeContext.Provider value={{ theme, toggle, setTheme: apply }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) {
    return { theme: 'dark', toggle: () => {}, setTheme: () => {} };
  }
  return ctx;
}

/** Inline script for `layout.tsx` — dark default, no flash. */
export const themeNoFlashScript = `(() => {
  try {
    var stored = localStorage.getItem('${STORAGE_KEY}');
    document.documentElement.dataset.theme =
      stored === 'light' || stored === 'dark' ? stored : 'dark';
  } catch (e) {
    document.documentElement.dataset.theme = 'dark';
  }
})();`;
