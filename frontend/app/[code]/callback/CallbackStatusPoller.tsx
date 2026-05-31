'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/v1';
const POLL_INTERVAL_MS = 3500;
const MAX_DURATION_MS = 120_000;

type Phase = 'processing' | 'completed' | 'failed' | 'timeout';

/**
 * Auto-refreshes a payer's "processing" callback until the payment reaches a
 * terminal state. On COMPLETED it forwards to the success page; otherwise it
 * shows a final processing message after ~2 minutes so the page never hangs.
 */
export default function CallbackStatusPoller({
  code,
  paymentId,
}: {
  code: string;
  paymentId: string;
}) {
  const router = useRouter();
  const [phase, setPhase] = useState<Phase>('processing');
  const startedAt = useRef<number>(Date.now());

  useEffect(() => {
    let active = true;
    let timer: ReturnType<typeof setTimeout>;

    async function poll() {
      try {
        const res = await fetch(`${API_URL}/pay/${code}/status/${paymentId}`, {
          cache: 'no-store',
        });
        if (res.ok && active) {
          const data = (await res.json()) as { status: string };
          if (data.status === 'COMPLETED') {
            setPhase('completed');
            router.replace(`/${code}/success`);
            return;
          }
          if (data.status === 'FAILED' || data.status === 'CANCELLED') {
            setPhase('failed');
            return;
          }
        }
      } catch {
        /* transient network error — keep polling until the deadline */
      }

      if (!active) return;
      if (Date.now() - startedAt.current >= MAX_DURATION_MS) {
        setPhase('timeout');
        return;
      }
      timer = setTimeout(poll, POLL_INTERVAL_MS);
    }

    timer = setTimeout(poll, POLL_INTERVAL_MS);
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [code, paymentId, router]);

  if (phase === 'failed') {
    return (
      <>
        <p style={styles.error}>Payment failed</p>
        <Link href={`/${code}`} style={styles.link}>
          Back to payment
        </Link>
      </>
    );
  }

  if (phase === 'completed') {
    return <p style={styles.success}>Payment sent</p>;
  }

  if (phase === 'timeout') {
    return (
      <>
        <p style={styles.success}>Still processing</p>
        <p style={styles.muted}>
          Your bank is taking longer than usual. The requester is notified
          automatically once it settles — you can safely close this page.
        </p>
      </>
    );
  }

  return (
    <>
      <style>{'@keyframes payspin-spin{to{transform:rotate(360deg)}}'}</style>
      <p style={styles.success}>Payment is being processed</p>
      <p style={styles.muted}>
        Your bank is confirming the transfer. This page updates automatically —
        you can safely close it.
      </p>
      <span style={styles.spinner} aria-hidden />
    </>
  );
}

const styles: Record<string, React.CSSProperties> = {
  success: { color: '#10b981', fontWeight: 700, fontSize: 20 },
  error: { color: '#ef4444', fontWeight: 700, fontSize: 20 },
  muted: { color: '#6b7280', fontSize: 14, marginTop: 8 },
  link: { color: '#07D8DD', display: 'block', marginTop: 16 },
  spinner: {
    display: 'inline-block',
    width: 20,
    height: 20,
    marginTop: 16,
    border: '3px solid #e5e7eb',
    borderTopColor: '#07D8DD',
    borderRadius: '50%',
    animation: 'payspin-spin 0.8s linear infinite',
  },
};
