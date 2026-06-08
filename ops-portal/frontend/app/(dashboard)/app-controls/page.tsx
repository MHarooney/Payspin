'use client';

import { AppControlsResponse } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { OpsCard, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';

export default function AppControlsPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canEdit = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';

  const { data } = useQuery({
    queryKey: ['app-controls'],
    queryFn: () => apiRequest<AppControlsResponse>('/app-controls'),
  });

  const toggle = useMutation({
    mutationFn: (vars: { key: string; enabled: boolean }) =>
      apiRequest(`/config/flags/${vars.key}`, { method: 'PATCH', body: { enabled: vars.enabled } }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['app-controls'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  return (
    <>
      <OpsSectionHead
        title="App view controls"
        sub="Remote-configure what the consumer app shows — no redeploy"
        preview={data?.preview}
      />
      <div className="two-col">
        <OpsCard title="Home screen modules">
          {(data?.modules ?? []).length === 0 ? (
            <div className="empty">Run the seed to populate app modules.</div>
          ) : (
            data!.modules.map((m) => (
              <div className="toggle-row" key={m.key}>
                <div>
                  <b>{m.label}</b>
                  <div className="desc">{m.description}</div>
                </div>
                <button
                  className={`switch${m.enabled ? ' on' : ''}`}
                  disabled={!canEdit || toggle.isPending}
                  onClick={() => toggle.mutate({ key: m.key, enabled: !m.enabled })}
                  aria-label={`Toggle ${m.label}`}
                />
              </div>
            ))
          )}
        </OpsCard>

        <OpsCard title="Announcements & banner">
          <div className="hint">Active in-app banner</div>
          <div
            style={{
              background: 'var(--accent-2-dim)',
              border: '1px solid #fc00ff44',
              borderRadius: 8,
              padding: 12,
              margin: '10px 0 16px',
              fontSize: 13,
            }}
          >
            {data?.banner?.text ?? 'No active banner'}
          </div>
        </OpsCard>

        <OpsCard title="Limits & UX defaults (app-side)">
          {(data?.defaults ?? []).map((d) => (
            <div className="config-row" key={d.key}>
              <span>{d.label}</span>
              <span className="mono">{d.value}</span>
            </div>
          ))}
          {(data?.defaults ?? []).length === 0 && <div className="empty">Run the seed to populate app defaults.</div>}
        </OpsCard>
      </div>
    </>
  );
}
