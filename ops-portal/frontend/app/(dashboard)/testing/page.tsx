'use client';

import { TestRunResult, TestScenarioInfo, TestStepResult } from '@payspin/shared-types';
import { useMutation, useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useMemo, useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsSectionHead } from '@/components/ops/primitives';
import { useOpsToast } from '@/components/ops/ops-toast';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { payerBaseUrl } from '@/lib/payer-url';

const LAST_RUN_KEY = 'ops-test-center-last-run';

function stepIcon(status: string) {
  if (status === 'pass') return '✓';
  if (status === 'fail') return '✗';
  return '~';
}

export default function TestingPage() {
  const { admin } = useAuth();
  const { toast } = useOpsToast();
  const canRun = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [lastRun, setLastRun] = useState<TestRunResult | null>(() => {
    if (typeof window === 'undefined') return null;
    try {
      const raw = localStorage.getItem(LAST_RUN_KEY);
      return raw ? (JSON.parse(raw) as TestRunResult) : null;
    } catch {
      return null;
    }
  });

  const { data: scenarios, isLoading } = useQuery({
    queryKey: ['testing-scenarios'],
    queryFn: () => apiRequest<TestScenarioInfo[]>('/testing/scenarios'),
  });

  const run = useMutation({
    mutationFn: (ids: string[]) =>
      apiRequest<TestRunResult>('/testing/run', { method: 'POST', body: { scenarios: ids } }),
    onSuccess: (data) => {
      setLastRun(data);
      localStorage.setItem(LAST_RUN_KEY, JSON.stringify(data));
      const failed = data.steps.filter((s: TestStepResult) => s.status === 'fail').length;
      if (failed === 0) toast('All test steps passed');
      else toast(`${failed} step(s) failed`, 'fail');
    },
    onError: (e) => toast(String((e as Error).message), 'fail'),
  });

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const selectAll = () => {
    if (!scenarios) return;
    setSelected(new Set(scenarios.map((s) => s.id)));
  };

  const mutatingSelected = useMemo(
    () => (scenarios ?? []).some((s) => selected.has(s.id) && s.mutating),
    [scenarios, selected],
  );

  if (isLoading || !scenarios) return <OpsLoadingPanel label="Loading test scenarios" />;

  return (
    <>
      <OpsSectionHead title="Test Center" sub="Ops health checks and sandbox workflows" />

      <OpsCard title={undefined} count={undefined} style={{ marginBottom: 16 }}>
        <p className="hint" style={{ marginBottom: 12 }}>
          Uses Yapily sandbox for payer flows — complete the bank step manually in an opened payer tab. Payer web:{' '}
          <span className="mono">{payerBaseUrl()}</span>
        </p>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <Link href="/users" className="mini-btn">
            Users
          </Link>
          <Link href="/system" className="mini-btn">
            System health
          </Link>
          <Link href="/webhooks" className="mini-btn">
            Webhooks
          </Link>
        </div>
      </OpsCard>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 12, marginBottom: 20 }}>
        {scenarios.map((s) => (
          <div
            key={s.id}
            className={`scenario-card${selected.has(s.id) ? ' selected' : ''}`}
            onClick={() => toggle(s.id)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => e.key === 'Enter' && toggle(s.id)}
          >
            <div style={{ fontWeight: 600, marginBottom: 6 }}>{s.label}</div>
            <p className="hint" style={{ fontSize: 12, marginBottom: 8 }}>
              {s.description}
            </p>
            {s.mutating && <span className="preview-badge">Mutating</span>}
          </div>
        ))}
      </div>

      {canRun && (
        <div className="row-actions" style={{ marginBottom: 24 }}>
          <button className="mini-btn" onClick={selectAll}>
            Select all
          </button>
          <button className="mini-btn" disabled={selected.size === 0 || run.isPending} onClick={() => run.mutate([...selected])}>
            {run.isPending ? 'Running…' : `Run selected (${selected.size})`}
          </button>
          <button
            className="mini-btn"
            disabled={run.isPending}
            onClick={() => {
              setSelected(new Set(scenarios.map((s) => s.id)));
              run.mutate(scenarios.map((s) => s.id));
            }}
          >
            Run all
          </button>
        </div>
      )}

      {mutatingSelected && (
        <p className="hint" style={{ marginBottom: 16 }}>
          Selected scenarios include mutating tests (creates/deletes ephemeral users or links).
        </p>
      )}

      {lastRun && (
        <OpsCard title={`Last run · ${new Date(lastRun.startedAt).toLocaleString()}`} count={undefined}>
          {lastRun.steps.map((step: TestStepResult) => (
            <div key={`${lastRun.runId}-${step.id}-${step.label}`} className="test-step">
              <span className={`test-step-icon test-step-${step.status}`}>{stepIcon(step.status)}</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600 }}>{step.label}</div>
                {step.detail && <div className="hint mono" style={{ marginTop: 4, fontSize: 11 }}>{step.detail}</div>}
                <div className="hint" style={{ marginTop: 2 }}>{step.durationMs}ms</div>
              </div>
            </div>
          ))}
        </OpsCard>
      )}
    </>
  );
}
