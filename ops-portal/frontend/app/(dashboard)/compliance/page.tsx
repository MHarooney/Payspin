'use client';

import { ComplianceAlertDto } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsCard, OpsKpiStrip, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

const SEV_TONE: Record<string, string> = { HIGH: 'fail', MEDIUM: 'pend', LOW: 'blue' };

export default function CompliancePage() {
  const { data } = useQuery({
    queryKey: ['compliance'],
    queryFn: () => apiRequest<ComplianceAlertDto[]>('/compliance'),
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
    { header: 'Status', cell: (a) => <OpsPill tone="pend">{a.status.replace(/_/g, ' ').toLowerCase()}</OpsPill> },
  ];

  return (
    <>
      <OpsSectionHead title="Compliance & AML" sub={`${open} open alerts`} preview />
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
