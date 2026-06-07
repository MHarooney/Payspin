'use client';

import { DisputeDto } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { eurExact } from '@/lib/format';

export default function DisputesPage() {
  const { data } = useQuery({
    queryKey: ['disputes'],
    queryFn: () => apiRequest<DisputeDto[]>('/disputes'),
  });

  const disputes = data ?? [];
  const held = disputes.reduce((s, d) => s + d.amountCents, 0);

  const columns: Column<DisputeDto>[] = [
    { header: 'Case', cell: (d) => <span className="mono">{d.caseRef}</span> },
    { header: 'Type', cell: (d) => d.type },
    { header: 'Amount', cell: (d) => <b>{eurExact(d.amountCents)}</b> },
    { header: 'Parties', cell: (d) => d.parties },
    { header: 'Status', cell: (d) => <OpsPill tone="pend">{d.status.replace(/_/g, ' ').toLowerCase()}</OpsPill> },
  ];

  return (
    <>
      <OpsSectionHead title="Disputes & escrow" sub={`${disputes.length} open · ${eurExact(held)} held`} preview />
      <OpsCard>
        <OpsDataTable columns={columns} rows={disputes} rowKey={(d) => d.id} empty="No disputes. Run the seed for demo data." />
      </OpsCard>
    </>
  );
}
