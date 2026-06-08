'use client';

import { ReconciliationException } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsCard, OpsKpiStrip, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { eur } from '@/lib/format';

export default function FinancePage() {
  const { data } = useQuery({
    queryKey: ['finance-exceptions'],
    queryFn: () => apiRequest<ReconciliationException[]>('/finance/exceptions'),
  });

  const exceptions = data ?? [];
  const awaiting = exceptions.reduce((s, e) => s + e.deltaCents, 0);

  const columns: Column<ReconciliationException>[] = [
    { header: 'Tx ID', cell: (e) => <span className="mono">{e.txId.slice(0, 10)}</span> },
    { header: 'Ledger', cell: (e) => e.ledger },
    { header: 'Yapily / Bank', cell: (e) => e.bank },
    { header: 'Δ', cell: (e) => <OpsPill tone="fail">{eur(e.deltaCents)}</OpsPill> },
    { header: 'Status', cell: (e) => <OpsPill tone="pend">{e.status}</OpsPill> },
  ];

  return (
    <>
      <OpsSectionHead
        title="Settlement & reconciliation"
        sub="Ledger vs Yapily / bank confirmation"
        preview
      />
      <OpsKpiStrip
        columns={4}
        kpis={[
          { label: 'Awaiting Bank', value: eur(awaiting), trend: `${exceptions.length} tx`, direction: 'flat' },
          { label: 'Mismatches', value: String(exceptions.length), trend: exceptions.length ? 'needs action' : 'clean', direction: exceptions.length ? 'down' : 'up' },
          { label: 'Settled Today', value: '—', trend: 'wire settlement feed', direction: 'flat' },
          { label: 'Fee Revenue', value: '—', trend: 'Phase 2', direction: 'flat' },
        ]}
      />
      <OpsCard title="Reconciliation exceptions">
        <OpsDataTable columns={columns} rows={exceptions} rowKey={(e) => e.id} empty="No exceptions — all in-progress payments reconcile." />
      </OpsCard>
    </>
  );
}
