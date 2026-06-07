'use client';

import { ComplianceAlertDto, SupportThreadDto } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { OpsBrandMark } from '@/components/ops/brand-mark';
import { NAV } from '@/lib/nav';

function initials(name: string | null, email: string): string {
  if (name) return name.slice(0, 1).toUpperCase();
  return email.slice(0, 1).toUpperCase();
}

export function OpsSidebar() {
  const pathname = usePathname();
  const { admin, logout } = useAuth();

  const { data: compliance } = useQuery({
    queryKey: ['compliance'],
    queryFn: () => apiRequest<ComplianceAlertDto[]>('/compliance'),
  });
  const { data: messages } = useQuery({
    queryKey: ['messages'],
    queryFn: () => apiRequest<SupportThreadDto[]>('/messages'),
  });

  const badges = {
    compliance: compliance?.filter((c) => c.status !== 'CLEARED').length ?? 0,
    messages: messages?.filter((m) => m.unread).length ?? 0,
  };

  return (
    <aside className="sidebar">
      <div className="logo">
        <OpsBrandMark variant="inline" />
      </div>
      <nav className="nav">
        {NAV.map((s) => (
          <div key={s.section}>
            <div className="nav-section">{s.section}</div>
            {s.items.map((item) => {
              const active = item.href === '/' ? pathname === '/' : pathname.startsWith(item.href);
              const badge = item.badgeKey ? badges[item.badgeKey] : 0;
              return (
                <Link key={item.href} href={item.href} className={`nav-item${active ? ' active' : ''}`}>
                  <span className="ico">{item.icon}</span>
                  <span>{item.label}</span>
                  {badge > 0 && (
                    <span className={`badge${item.badgeKey === 'messages' ? ' b' : ''}`}>{badge}</span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>
      <div className="admin-foot">
        <div className="avatar">{admin ? initials(admin.displayName, admin.email) : 'P'}</div>
        <div className="meta">
          <b>{admin?.displayName ?? admin?.email ?? 'Admin'}</b>
          <br />
          <span>{admin?.role.replace('_', ' ') ?? ''}</span>
        </div>
        <button className="logout" onClick={logout}>
          Sign out
        </button>
      </div>
    </aside>
  );
}
