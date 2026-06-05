'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/v1';
const POLL_INTERVAL_MS = 5000;
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
      let nextDelay = POLL_INTERVAL_MS;

      try {
        const res = await fetch(`${API_URL}/pay/${code}/status/${paymentId}`, {
          cache: 'no-store',
        });

        if (res.status === 429) {
          const retryAfter = Number(res.headers.get('Retry-After') ?? '0');
          nextDelay = retryAfter > 0 ? retryAfter * 1000 : POLL_INTERVAL_MS * 3;
        } else if (res.ok && active) {
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
        nextDelay = POLL_INTERVAL_MS * 2;
      }

      if (!active) return;
      if (Date.now() - startedAt.current >= MAX_DURATION_MS) {
        setPhase('timeout');
        return;
      }
      timer = setTimeout(poll, nextDelay);
    }

    timer = setTimeout(poll, POLL_INTERVAL_MS);
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [code, paymentId, router]);

  if (phase === 'failed') {
    return (
      <div className="ps-status">
        <div className="ps-status__icon ps-status__icon--error" aria-hidden>
          !
        </div>
        <h1 className="ps-status__title">Payment failed</h1>
        <Link href={`/${code}`} className="ps-link-btn">
          Back to payment
        </Link>
      </div>
    );
  }

  if (phase === 'completed') {
    return (
      <div className="ps-status">
        <div className="ps-status__icon ps-status__icon--success" aria-hidden>
          ✓
        </div>
        <h1 className="ps-status__title">Payment sent</h1>
      </div>
    );
  }

  if (phase === 'timeout') {
    return (
      <div className="ps-status">
        <div className="ps-status__icon ps-status__icon--success" aria-hidden>
          ⧖
        </div>
        <h1 className="ps-status__title">Still processing</h1>
        <p className="ps-status__sub">
          Your bank is taking longer than usual. The requester is notified
          automatically once it settles — you can safely close this page.
        </p>
      </div>
    );
  }

  return (
    <div className="ps-status">
      <span className="ps-spinner" aria-hidden />
      <h1 className="ps-status__title" style={{ marginTop: 16 }}>
        Payment is being processed
      </h1>
      <p className="ps-status__sub">
        Your bank is confirming the transfer. This page updates automatically —
        you can safely close it.
      </p>
    </div>
  );
}
