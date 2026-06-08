'use client';

import { SystemHealth } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { OpsCard, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

export default function SystemPage() {
  const { data } = useQuery({
    queryKey: ['system-health'],
    queryFn: () => apiRequest<SystemHealth>('/system/health'),
    refetchInterval: 15_000,
  });

  return (
    <>
      <OpsSectionHead
        title="System health"
        sub={data ? `Checked ${new Date(data.checkedAt).toLocaleTimeString()}` : 'Live dependency checks'}
      />
      <OpsCard title="Services">
        <div className="svc-grid">
          {(data?.services ?? []).map((s) => (
            <div className="svc" key={s.name}>
              <div className="top">
                <span className="name">{s.name}</span>
                <span className={s.status === 'ok' ? 'dot-g' : s.status === 'degraded' ? 'dot-a' : 'dot-r'} />
              </div>
              <div className="stat">{s.stat}</div>
              <div className="sub">{s.sub}</div>
            </div>
          ))}
        </div>
      </OpsCard>
      <OpsCard title="Note">
        <p style={{ color: 'var(--muted)', fontSize: 13, lineHeight: 1.6 }}>
          Infrastructure metrics (CPU, RAM, disk, network) live in Grafana/Prometheus on the Hetzner
          host — link out rather than rebuilding here. This panel surfaces business-critical service
          health: Postgres, Redis, the BullMQ queue, and Yapily connectivity.
        </p>
      </OpsCard>
    </>
  );
}
