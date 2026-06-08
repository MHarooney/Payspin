'use client';

import { SupportThreadDetail, SupportThreadDto } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useRef, useState } from 'react';
import { OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { clock, relativeTime } from '@/lib/format';

export default function MessagesPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canReply = admin?.role !== 'READ_ONLY';
  const [activeId, setActiveId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const bodyRef = useRef<HTMLDivElement>(null);

  const threads = useQuery({
    queryKey: ['messages'],
    queryFn: () => apiRequest<SupportThreadDto[]>('/messages'),
  });

  useEffect(() => {
    if (!activeId && threads.data && threads.data.length > 0) setActiveId(threads.data[0].id);
  }, [threads.data, activeId]);

  const thread = useQuery({
    queryKey: ['message', activeId],
    queryFn: () => apiRequest<SupportThreadDetail>(`/messages/${activeId}`),
    enabled: !!activeId,
  });

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

  return (
    <>
      <OpsSectionHead title="Messages" sub={`Support inbox · ${unread} unread`} />
      {threads.data && threads.data.length === 0 ? (
        <div className="empty">No support threads. Run the seed for demo data.</div>
      ) : (
        <div className="msg-layout">
          <div className="msg-list">
            {(threads.data ?? []).map((t) => (
              <div key={t.id} className={`msg-item${t.id === activeId ? ' active' : ''}`} onClick={() => setActiveId(t.id)}>
                <div className="mhead">
                  <span className="mname">{t.subjectName}{t.unread && <span className="unread" />}</span>
                  <span className="mtime">{relativeTime(t.lastMessageAt)}</span>
                </div>
                <div className="mprev">{t.preview}</div>
              </div>
            ))}
          </div>
          <div className="msg-thread">
            {thread.data ? (
              <>
                <div className="msg-thead">
                  <div>
                    <b>{thread.data.subjectName}</b>
                    <div className="hint">{thread.data.userRef} · {thread.data.meta ?? ''}</div>
                  </div>
                  <div className="row-actions">
                    {thread.data.status !== 'RESOLVED' && canReply && (
                      <button className="mini-btn" disabled={resolve.isPending} onClick={() => resolve.mutate()}>Mark resolved</button>
                    )}
                  </div>
                </div>
                <div className="msg-body" ref={bodyRef}>
                  {thread.data.messages.map((m) => (
                    <div key={m.id} className={`bubble ${m.direction === 'IN' ? 'in' : 'out'}`}>
                      {m.body}
                      <div className="bmeta">{m.authorName} · {clock(m.createdAt)}</div>
                    </div>
                  ))}
                </div>
                {canReply && (
                  <div className="msg-compose" style={{ padding: 14, borderTop: '1px solid var(--border)', display: 'flex', gap: 10 }}>
                    <textarea
                      value={replyText}
                      onChange={(e) => setReplyText(e.target.value)}
                      placeholder="Reply…"
                      style={{ flex: 1, background: 'var(--panel-2)', border: '1px solid var(--border)', borderRadius: 8, color: 'var(--text)', padding: 10, height: 42, resize: 'none' }}
                    />
                    <button className="btn primary" disabled={!replyText.trim() || reply.isPending} onClick={() => reply.mutate()}>
                      {reply.isPending ? '…' : 'Send'}
                    </button>
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


