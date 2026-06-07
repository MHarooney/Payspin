'use client';

import { AdminCircleDetail, AdminCircleListItem, Paginated } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { C, DoughnutChart, BarChart } from '@/components/ops/charts';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsKpiStrip, OpsPill, OpsSectionHead, OpsSegment } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { eur, statusPill } from '@/lib/format';

type Filter = 'all' | 'active' | 'risk' | 'completed';

export default function CirclesPage() {
  const [filter, setFilter] = useState<Filter>('all');
  const [detailId, setDetailId] = useState<string | null>(null);

  const { data } = useQuery({
    queryKey: ['circles', filter],
    queryFn: () =>
      apiRequest<Paginated<AdminCircleListItem>>('/circles', { query: { filter, pageSize: 50 } }),
  });

  const circles = data?.items ?? [];
  const totalEscrow = circles.reduce((s, c) => s + c.escrowCents, 0);
  const totalMembers = circles.reduce((s, c) => s + c.activeMemberCount, 0);
  const activeCount = circles.filter((c) => c.status === 'ACTIVE').length;
  const atRisk = circles.filter((c) => c.status === 'ACTIVE' && c.activeMemberCount < c.memberCount).length;

  const statusCounts = circles.reduce<Record<string, number>>((acc, c) => {
    acc[c.status] = (acc[c.status] ?? 0) + 1;
    return acc;
  }, {});

  const columns: Column<AdminCircleListItem>[] = [
    { header: 'Circle', cell: (c) => <span className="mono">{c.name}</span> },
    { header: 'Members', cell: (c) => `${c.activeMemberCount} / ${c.memberCount}` },
    {
      header: 'Pot / cycle',
      cell: (c) => (
        <span>
          <b>{eur(c.potCents)}</b> · {eur(c.contributionCents)} ea
        </span>
      ),
    },
    { header: 'Round', cell: (c) => `${c.currentRound} / ${c.memberCount}` },
    { header: 'Escrow', cell: (c) => <OpsPill tone="purple">{eur(c.escrowCents)} locked</OpsPill> },
    { header: 'State', cell: (c) => <OpsPill tone={statusPill(c.status)}>{c.status}</OpsPill> },
    {
      header: 'Actions',
      cell: (c) => (
        <button className="mini-btn" onClick={() => setDetailId(c.id)}>
          View
        </button>
      ),
    },
  ];

  return (
    <>
      <OpsSectionHead
        title="Circles / ROSCA monitoring"
        sub="Group savings · escrow, payout cycles, member health"
      >
        <OpsSegment
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'all', label: 'All' },
            { value: 'active', label: 'Active' },
            { value: 'risk', label: 'At risk' },
            { value: 'completed', label: 'Completed' },
          ]}
        />
      </OpsSectionHead>

      <OpsKpiStrip
        columns={5}
        kpis={[
          { label: 'Active circles', value: String(activeCount), trend: `${circles.length} total`, direction: 'flat' },
          { label: 'Total in escrow', value: eur(totalEscrow), trend: 'locked', direction: 'flat' },
          { label: 'Members enrolled', value: String(totalMembers), trend: null, direction: 'flat' },
          { label: 'At-risk circles', value: String(atRisk), trend: atRisk ? 'missed contributions' : 'healthy', direction: atRisk ? 'down' : 'up' },
          { label: 'Completed', value: String(statusCounts['COMPLETED'] ?? 0), trend: null, direction: 'flat' },
        ]}
      />

      <div className="grid-2">
        <OpsCard title="Circles by state">
          <div className="chart-box">
            <DoughnutChart
              data={{
                labels: Object.keys(statusCounts),
                datasets: [
                  {
                    data: Object.values(statusCounts),
                    backgroundColor: [C.accent, C.amber, C.blue, C.red, C.purple],
                    borderWidth: 0,
                  },
                ],
              }}
            />
          </div>
        </OpsCard>
        <OpsCard title="Escrow locked per circle">
          <div className="chart-box">
            <BarChart
              data={{
                labels: circles.slice(0, 12).map((c) => c.name.slice(0, 8)),
                datasets: [
                  {
                    label: 'Escrow €',
                    data: circles.slice(0, 12).map((c) => c.escrowCents / 100),
                    backgroundColor: C.purple + 'cc',
                    borderRadius: 4,
                  },
                ],
              }}
            />
          </div>
        </OpsCard>
      </div>

      <OpsCard title="Circle register">
        <OpsDataTable
          columns={columns}
          rows={circles}
          rowKey={(c) => c.id}
          empty="No circles match this filter."
        />
      </OpsCard>

      {detailId && <CircleDetail id={detailId} onClose={() => setDetailId(null)} />}
    </>
  );
}

function CircleDetail({ id, onClose }: { id: string; onClose: () => void }) {
  const { data } = useQuery({
    queryKey: ['circle', id],
    queryFn: () => apiRequest<AdminCircleDetail>(`/circles/${id}`),
  });

  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" style={{ width: 560 }} onClick={(e) => e.stopPropagation()}>
        <h2>{data?.name ?? 'Circle'}</h2>
        {!data ? (
          <OpsLoadingPanel label="Loading circle detail" size={36} />
        ) : (
          <div className="grid-2" style={{ gridTemplateColumns: '1fr 1fr' }}>
            <div>
              <div className="hint">Smart contract</div>
              <div className="mono" style={{ margin: '6px 0 14px', color: 'var(--text)', fontSize: 11 }}>
                {data.smartContractAddress ?? 'not deployed'}
              </div>
              <div className="hint">Host</div>
              <div style={{ marginTop: 6, fontSize: 13 }}>{data.hostName ?? data.hostUserId.slice(0, 8)}</div>
              <div className="hint" style={{ marginTop: 14 }}>Pot</div>
              <div style={{ marginTop: 6, fontSize: 13 }}>
                {eur(data.potCents)} · round {data.currentRound}/{data.memberCount}
              </div>
            </div>
            <div>
              <div className="hint">Payout order</div>
              <table style={{ marginTop: 8 }}>
                <tbody>
                  {data.members.map((m) => (
                    <tr key={m.id}>
                      <td style={{ padding: '7px 8px' }}>
                        {m.payoutOrder}. {m.displayName ?? m.userId.slice(0, 6)}
                      </td>
                      <td style={{ padding: '7px 8px' }}>
                        {m.isCurrentRecipient ? (
                          <OpsPill tone="blue">next</OpsPill>
                        ) : (
                          <OpsPill tone={statusPill(m.status)}>{m.status}</OpsPill>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
        <div className="modal-actions" style={{ marginTop: 18 }}>
          <button className="btn ghost" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
