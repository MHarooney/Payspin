'use client';

import { useRouter } from 'next/navigation';
import { useEffect, type ReactNode } from 'react';
import { OpsSidebar } from '@/components/ops/sidebar';
import { OpsTopbar } from '@/components/ops/topbar';
import { OpsPageLoader } from '@/components/ops/emblem-loader';
import { useAuth } from '@/lib/auth';

export default function DashboardLayout({ children }: { children: ReactNode }) {
  const { admin, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !admin) {
      router.replace('/login');
    }
  }, [loading, admin, router]);

  if (loading || !admin) {
    return <OpsPageLoader label="Loading portal" />;
  }

  return (
    <div className="ops-shell">
      <OpsSidebar />
      <div className="main">
        <OpsTopbar />
        <div className="content">{children}</div>
      </div>
    </div>
  );
}
