'use client';

import { SupportThreadDetail, SupportThreadDto } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';
import { OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { clock, relativeTime } from '@/lib/format';

type Filter = 'all' | 'open' | 'resolved';

const FILTERS: { key: Filter; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'open', label: 'Open' },
  { key: 'resolved', label: 'Resolved' },
];

// Local canned responses — fast triage, no AI. Edit freely.
const QUICK_REPLIES = [
  "We're looking into your payment now and will update you shortly.",
  'Please try again in 30 minutes — the bank confirmation can take a little while.',
  'Your KYC verification is pending review. We typically clear these within one business day.',
  'Thanks for reaching out! Could you share the payment link or reference involved?',
];

export default function MessagesPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canReply = admin?.role !== 'READ_ONLY';
  const params = useSearchParams();
  const [activeId, setActiveId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const [filter, setFilter] = useState<Filter>('all');
  const bodyRef = useRef<HTMLDivElement>(null);
  const markedRef = useRef<string | null>(null);

  const threads = useQuery({
    queryKey: ['messages'],
    queryFn: () => apiRequest<SupportThreadDto[]>('/messages'),
    refetchInterval: 5000,
  });

  // Allow deep-linking from the User 360° page (?thread=<id>).
  useEffect(() => {
    const wanted = params.get('thread');
    if (wanted) setActiveId(wanted);
  }, [params]);

  const visible = (threads.data ?? []).filter((t) => {
    if (filter === 'open') return t.status !== 'RESOLVED';
    if (filter === 'resolved') return t.status === 'RESOLVED';
    return true;
  });

  useEffect(() => {
    if (!activeId && visible.length > 0) setActiveId(visible[0].id);
  }, [visible, activeId]);

  const thread = useQuery({
    queryKey: ['message', activeId],
    queryFn: () => apiRequest<SupportThreadDetail>(`/messages/${activeId}`),
    enabled: !!activeId,
    refetchInterval: 5000,
  });

  const markRead = useMutation({
    mutationFn: (id: string) => apiRequest(`/messages/threads/${id}/read`, { method: 'PATCH' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['messages'] }),
  });

  // Clear the admin-unread flag once a thread is opened (and only once per id).
  useEffect(() => {
    if (!activeId || !canReply) return;
    const t = threads.data?.find((x) => x.id === activeId);
    if (t?.unread && markedRef.current !== activeId) {
      markedRef.current = activeId;
      markRead.mutate(activeId);
    }
  }, [activeId, threads.data, canReply]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (bodyRef.current) bodyRef.current.scrollTop = bodyRef.current.scrollHeight;
  }, [thread.data]);

  const reply = useMutation({
    mutationFn: () => apiRequest(`/messages/threads/${activeId}/reply`, { method: 'POST', body: { body: replyText } }),
    onSuccess: () => { setReplyText(''); qc.invalidateQueries({ queryKey: ['message', activeId] }); qc.invalidateQueries({ queryKey: ['messages'] }); },
  });

  const resolve = useMutation({
    mutationFn: () => apiRequest(`/messages/threads/${activeId}`, { method: 'PATCH', body: { status: 'RESOLVED' } }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['message', activeId] }); qc.invalidateQueries({ queryKey: ['messages'] }); },
  });

  const unread = threads.data?.filter((t) => t.unread).length ?? 0;
  const active = thread.data;

  return (
    <>
      <OpsSectionHead title="Messages" sub={`Support inbox · ${unread} unread`} />
      <div className="seg" style={{ marginBottom: 14 }}>
        {FILTERS.map((f) => (
          <button key={f.key} className={filter === f.key ? 'active' : ''} onClick={() => setFilter(f.key)}>
            {f.label}
          </button>
        ))}
      </div>
      {threads.data && visible.length === 0 ? (
        <div className="empty">
          {filter === 'all'
            ? 'No support threads. Run the seed for demo data: cd backend && pnpm ops:seed-admin'
            : `No ${filter} threads.`}
        </div>
      ) : (
        <div className="msg-layout">
          <div className="msg-list">
            {visible.map((t) => (
              <div key={t.id} className={`msg-item${t.id === activeId ? ' active' : ''}`} onClick={() => setActiveId(t.id)}>
                <div className="mhead">
                  <span className="mname">{t.subjectName}{t.unread && <span className="unread" />}</span>
                  <span className="mtime">{relativeTime(t.lastMessageAt)}</span>
                </div>
                <div className="mprev">{t.preview}</div>
                {(t.category || t.status === 'RESOLVED') && (
                  <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
                    {t.category && <span className="badge">{t.category}</span>}
                    {t.status === 'RESOLVED' && <span className="badge">resolved</span>}
                  </div>
                )}
              </div>
            ))}
          </div>
          <div className="msg-thread">
            {active ? (
              <>
                <div className="msg-thead">
                  <div>
                    <b>{active.subjectName}</b>
                    <div className="hint">
                      {active.userId ? (
                        <Link href={`/users/${active.userId}`}>{active.userRef}</Link>
                      ) : (
                        active.userRef
                      )}
                      {active.meta ? ` · ${active.meta}` : ''}
                      {active.contextRef ? ` · ref ${active.contextRef}` : ''}
                    </div>
                  </div>
                  <div className="row-actions">
                    {active.status === 'RESOLVED' ? (
                      <span className="badge">resolved</span>
                    ) : (
                      canReply && (
                        <button className="mini-btn" disabled={resolve.isPending} onClick={() => resolve.mutate()}>Mark resolved</button>
                      )
                    )}
                  </div>
                </div>
                <div className="msg-body" ref={bodyRef}>
                  {active.messages.map((m) => (
                    <div key={m.id} className={`bubble ${m.direction === 'IN' ? 'in' : 'out'}`}>
                      {m.body}
                      <div className="bmeta">{m.authorName} · {clock(m.createdAt)}</div>
                    </div>
                  ))}
                </div>
                {canReply && (
                  <div className="msg-compose" style={{ padding: 14, borderTop: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: 10 }}>
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      {QUICK_REPLIES.map((q, i) => (
                        <button
                          key={i}
                          className="mini-btn"
                          title={q}
                          onClick={() => setReplyText((prev) => (prev.trim() ? `${prev} ${q}` : q))}
                        >
                          {q.length > 32 ? `${q.slice(0, 32)}…` : q}
                        </button>
                      ))}
                    </div>
                    <div style={{ display: 'flex', gap: 10 }}>
                      <textarea
                        value={replyText}
                        onChange={(e) => setReplyText(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' && !e.shiftKey) {
                            e.preventDefault();
                            if (replyText.trim() && !reply.isPending) reply.mutate();
                          }
                        }}
                        placeholder="Reply… (Enter to send, Shift+Enter for newline)"
                        style={{ flex: 1, background: 'var(--panel-2)', border: '1px solid var(--border)', borderRadius: 8, color: 'var(--text)', padding: 10, height: 56, resize: 'none' }}
                      />
                      <button className="btn primary" disabled={!replyText.trim() || reply.isPending} onClick={() => reply.mutate()}>
                        {reply.isPending ? '…' : 'Send'}
                      </button>
                    </div>
                  </div>
                )}
              </>
            ) : (
              <div className="empty">Select a conversation.</div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
