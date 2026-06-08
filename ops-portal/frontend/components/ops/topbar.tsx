'use client';

import { GlobalSearchResult, KillSwitchState, SystemHealth } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/admin-api';
import { titleForPath } from '@/lib/nav';
import { KillSwitchModal } from './kill-switch-modal';
import { OpsThemeToggle } from './theme-toggle';

const SEARCH_HREF: Record<GlobalSearchResult['type'], string> = {
  payment: '/transactions',
  user: '/users',
  payment_link: '/transactions',
};

export function OpsTopbar() {
  const pathname = usePathname();
  const [showKill, setShowKill] = useState(false);
  const [query, setQuery] = useState('');
  const [debounced, setDebounced] = useState('');

  useEffect(() => {
    const t = setTimeout(() => setDebounced(query), 250);
    return () => clearTimeout(t);
  }, [query]);

  const { data: health } = useQuery({
    queryKey: ['system-health'],
    queryFn: () => apiRequest<SystemHealth>('/system/health'),
    refetchInterval: 30_000,
  });
  const { data: kill } = useQuery({
    queryKey: ['kill-switch'],
    queryFn: () => apiRequest<KillSwitchState>('/kill-switch'),
  });
  const { data: results } = useQuery({
    queryKey: ['search', debounced],
    queryFn: () => apiRequest<GlobalSearchResult[]>('/search', { query: { q: debounced } }),
    enabled: debounced.length >= 1,
  });

  const healthy = health?.overall === 'ok';

  return (
    <header className="topbar">
      <h1>{titleForPath(pathname)}</h1>
      <div className="search-wrap">
        <input
          className="search"
          placeholder="Search tx ID, user, short code…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {debounced && results && results.length > 0 && (
          <div className="search-results">
            {results.map((r) => (
              <Link key={`${r.type}-${r.id}`} href={SEARCH_HREF[r.type]} onClick={() => setQuery('')}>
                <div className="stype">{r.type.replace('_', ' ')}</div>
                <div>{r.label}</div>
                <div className="hint">{r.sub}</div>
              </Link>
            ))}
          </div>
        )}
      </div>
      <div className={`health-pill${healthy ? '' : ' bad'}`}>
        <span className="dot" />
        {kill?.active
          ? 'Kill switch active'
          : healthy
            ? 'All systems operational'
            : 'Degraded service'}
      </div>
      <OpsThemeToggle />
      <button className={`kill-btn${kill?.active ? ' on' : ''}`} onClick={() => setShowKill(true)}>
        ⏻ {kill?.active ? 'Resume' : 'Kill Switch'}
      </button>
      {showKill && <KillSwitchModal state={kill} onClose={() => setShowKill(false)} />}
    </header>
  );
}
