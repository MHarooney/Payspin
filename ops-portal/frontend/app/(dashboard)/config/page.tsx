'use client';

import { FeatureFlagDto, PlatformConfigDto } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { OpsCard, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';

export default function ConfigPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canEdit = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';

  const flags = useQuery({
    queryKey: ['flags'],
    queryFn: () => apiRequest<FeatureFlagDto[]>('/config/flags'),
  });
  const config = useQuery({
    queryKey: ['platform-config'],
    queryFn: () => apiRequest<PlatformConfigDto[]>('/config/platform'),
  });

  const toggleFlag = useMutation({
    mutationFn: (vars: { key: string; enabled: boolean }) =>
      apiRequest(`/config/flags/${vars.key}`, { method: 'PATCH', body: { enabled: vars.enabled } }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['flags'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  const platformFlags = (flags.data ?? []).filter((f) => f.category === 'platform');
  const limits = (config.data ?? []).filter((c) => c.group === 'limits');

  return (
    <>
      <OpsSectionHead title="Configuration & feature flags" sub="Changes are logged to the audit trail" />
      <div className="two-col">
        <OpsCard title="Limits & thresholds">
          {limits.length === 0 ? (
            <div className="empty">Run the seed to populate platform config.</div>
          ) : (
            limits.map((c) => <ConfigRow key={c.key} config={c} canEdit={canEdit} />)
          )}
        </OpsCard>
        <OpsCard title="Feature flags">
          {platformFlags.length === 0 ? (
            <div className="empty">Run the seed to populate feature flags.</div>
          ) : (
            platformFlags.map((f) => (
              <div className="toggle-row" key={f.key}>
                <div>
                  <b>{f.label}</b>
                  <div className="desc">{f.description}</div>
                </div>
                <button
                  className={`switch${f.enabled ? ' on' : ''}`}
                  disabled={!canEdit || toggleFlag.isPending}
                  onClick={() => toggleFlag.mutate({ key: f.key, enabled: !f.enabled })}
                  aria-label={`Toggle ${f.label}`}
                />
              </div>
            ))
          )}
        </OpsCard>
      </div>
    </>
  );
}

function ConfigRow({ config, canEdit }: { config: PlatformConfigDto; canEdit: boolean }) {
  const qc = useQueryClient();
  const [value, setValue] = useState(config.value);
  useEffect(() => setValue(config.value), [config.value]);

  const save = useMutation({
    mutationFn: () => apiRequest(`/config/platform/${config.key}`, { method: 'PATCH', body: { value } }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['platform-config'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  const dirty = value !== config.value;

  return (
    <div className="config-row">
      <span>{config.label}</span>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <input value={value} disabled={!canEdit} onChange={(e) => setValue(e.target.value)} />
        {canEdit && dirty && (
          <button className="mini-btn" disabled={save.isPending} onClick={() => save.mutate()}>
            Save
          </button>
        )}
      </div>
    </div>
  );
}
