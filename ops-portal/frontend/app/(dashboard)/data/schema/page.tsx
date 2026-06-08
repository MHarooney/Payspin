'use client';

import { SchemaMetadata, SchemaModelDto, SchemaFieldDto } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

function fieldTypePill(f: SchemaFieldDto) {
  if (f.isRelation) return <OpsPill tone="blue">{f.isList ? `${f.relationTarget}[]` : f.relationTarget}</OpsPill>;
  const tone =
    f.type === 'String'
      ? 'pend'
      : f.type === 'Int' || f.type === 'Float' || f.type === 'Decimal'
        ? 'ok'
        : f.type === 'Boolean'
          ? 'blue'
          : f.type === 'DateTime'
            ? 'amber'
            : 'blue';
  return <OpsPill tone={tone}>{f.isList ? `${f.type}[]` : f.type}</OpsPill>;
}

function ModelDetail({ model, onRelationClick }: { model: SchemaModelDto; onRelationClick: (name: string) => void }) {
  const scalarFields = model.fields.filter((f) => !f.isRelation);
  const relationFields = model.fields.filter((f) => f.isRelation);
  return (
    <div className="schema-detail">
      <div className="schema-detail-header">
        <h2 className="schema-model-title">{model.name}</h2>
        <span className="schema-dbtable">@map(&quot;{model.dbTable}&quot;)</span>
      </div>

      <div className="schema-section-label">Fields</div>
      <div className="schema-fields-table">
        <div className="schema-fields-head">
          <span>Name</span>
          <span>Type</span>
          <span>Required</span>
        </div>
        {scalarFields.map((f) => (
          <div className="schema-field-row" key={f.name}>
            <span className="mono schema-field-name">{f.name}</span>
            <span>{fieldTypePill(f)}</span>
            <span>{f.isRequired ? <OpsPill tone="ok">required</OpsPill> : <span className="hint">optional</span>}</span>
          </div>
        ))}
      </div>

      {relationFields.length > 0 && (
        <>
          <div className="schema-section-label" style={{ marginTop: 16 }}>
            Relations
          </div>
          <div className="schema-fields-table">
            {relationFields.map((f) => (
              <div className="schema-field-row" key={f.name}>
                <span className="mono schema-field-name">{f.name}</span>
                <button
                  className="schema-relation-link"
                  onClick={() => f.relationTarget && onRelationClick(f.relationTarget)}
                >
                  → {f.relationTarget}
                  {f.isList ? '[]' : ''}
                </button>
                <span>
                  <OpsPill tone="purple">{f.isList ? '1:n' : '1:1'}</OpsPill>
                </span>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

export default function SchemaPage() {
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['schema'],
    queryFn: () => apiRequest<SchemaMetadata>('/data/schema'),
  });

  if (isLoading || !data) {
    return (
      <div className="content">
        <OpsLoadingPanel label="Loading schema…" size={36} />
      </div>
    );
  }

  const models = data.models.filter((m) =>
    search ? m.name.toLowerCase().includes(search.toLowerCase()) : true,
  );

  const selectedModel = data.models.find((m) => m.name === (selected ?? data.models[0]?.name));

  return (
    <div className="content">
      <OpsSectionHead
        title="Schema & Relations"
        sub={`${data.models.length} models · ${data.relations.length} relations`}
      />

      <div className="schema-layout">
        {/* Left: model list */}
        <OpsCard className="schema-sidebar" title={undefined} count={undefined}>
          <input
            className="search"
            style={{ width: '100%', marginBottom: 10 }}
            placeholder="Search models…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          {models.map((m) => {
            const isSelected = m.name === (selected ?? data.models[0]?.name);
            return (
              <button
                key={m.name}
                className={`schema-model-btn${isSelected ? ' active' : ''}`}
                onClick={() => setSelected(m.name)}
              >
                <span className="schema-model-name">{m.name}</span>
                <span className="schema-model-count">{m.fields.filter((f) => !f.isRelation).length} fields</span>
              </button>
            );
          })}
          {models.length === 0 && <div className="hint" style={{ padding: 8 }}>No models match.</div>}
        </OpsCard>

        {/* Right: detail */}
        <OpsCard className="schema-main" title={undefined} count={undefined}>
          {selectedModel ? (
            <ModelDetail model={selectedModel} onRelationClick={(name) => setSelected(name)} />
          ) : (
            <div className="hint" style={{ padding: 24 }}>Select a model to inspect.</div>
          )}
        </OpsCard>
      </div>

      {/* Relations overview */}
      <OpsCard title="Relations Overview" count={undefined} style={{ marginTop: 20 }}>
        <div className="schema-relations-grid">
          {data.relations.map((r) => (
            <div key={r.name} className="schema-relation-card">
              <button className="schema-rel-model" onClick={() => setSelected(r.from)}>
                {r.from}
              </button>
              <span className="schema-rel-arrow">
                <OpsPill tone="purple">{r.kind}</OpsPill>
              </span>
              <button className="schema-rel-model" onClick={() => setSelected(r.to)}>
                {r.to}
              </button>
            </div>
          ))}
        </div>
      </OpsCard>
    </div>
  );
}
