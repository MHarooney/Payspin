'use client';

import { ComplianceAlertDto } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsCard, OpsKpiStrip, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';

const SEV_TONE: Record<string, string> = { HIGH: 'fail', MEDIUM: 'pend', LOW: 'blue' };

export default function CompliancePage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS' || admin?.role === 'SUPPORT';

  const { data } = useQuery({
    queryKey: ['compliance'],
    queryFn: () => apiRequest<ComplianceAlertDto[]>('/compliance'),
  });

  const patch = useMutation({
    mutationFn: (vars: { id: string; status: string }) =>
      apiRequest(`/compliance/${vars.id}`, { method: 'PATCH', body: { status: vars.status } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['compliance'] }),
  });

  const alerts = data ?? [];
  const open = alerts.filter((a) => a.status !== 'CLEARED').length;
  const high = alerts.filter((a) => a.severity === 'HIGH').length;
  const travelRule = alerts.filter((a) => a.type === 'Travel Rule').length;

  const columns: Column<ComplianceAlertDto>[] = [
    { header: 'Type', cell: (a) => a.type },
    { header: 'Subject', cell: (a) => <span className="mono">{a.subject}</span> },
    { header: 'Rule', cell: (a) => a.rule },
    { header: 'Severity', cell: (a) => <OpsPill tone={SEV_TONE[a.severity] ?? 'blue'}>{a.severity}</OpsPill> },
    { header: 'Status', cell: (a) => <OpsPill tone={a.status === 'CLEARED' ? 'ok' : 'pend'}>{a.status.replace(/_/g, ' ').toLowerCase()}</OpsPill> },
    {
      header: 'Actions',
      cell: (a) => canAct ? (
        <div className="row-actions">
          {a.status === 'OPEN' && <button className="mini-btn" onClick={() => patch.mutate({ id: a.id, status: 'INVESTIGATING' })}>Investigate</button>}
          {a.status !== 'CLEARED' && <button className="mini-btn" onClick={() => patch.mutate({ id: a.id, status: 'CLEARED' })}>Clear</button>}
        </div>
      ) : <span className="hint">—</span>,
    },
  ];

  return (
    <>
      <OpsSectionHead title="Compliance & AML" sub={`${open} open alerts`} />
      <OpsKpiStrip
        columns={4}
        kpis={[
          { label: 'Open Alerts', value: String(open), trend: `${high} high`, direction: 'down' },
          { label: 'Travel Rule', value: String(travelRule), trend: '≥ €1,000', direction: 'flat' },
          { label: 'Sanctions Hits', value: '0', trend: 'clean', direction: 'up' },
          { label: 'SARs Filed (YTD)', value: '2', trend: '1 draft', direction: 'flat' },
        ]}
      />
      <OpsCard title="Alert queue">
        <OpsDataTable columns={columns} rows={alerts} rowKey={(a) => a.id} empty="No compliance alerts. Run the seed for demo data." />
      </OpsCard>
    </>
  );
}


