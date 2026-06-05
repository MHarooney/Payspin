'use client';

import { useId, useState } from 'react';

export interface FaqItem {
  q: string;
  a: string;
}

/** Original Payspin payer FAQ — no Tikkie copy. */
export const PAYER_FAQ: FaqItem[] = [
  {
    q: 'What is open banking?',
    a: 'Open banking lets you pay directly from your own bank account, securely authorised in your banking app. There are no card numbers and no middleman holding your money.',
  },
  {
    q: 'How does this work?',
    a: 'Tap “Pay with my bank”, choose your bank, and approve the payment with Face ID, fingerprint or your usual login. The money goes straight from your account to the requester via SEPA.',
  },
  {
    q: 'Is Payspin secure?',
    a: 'Yes. Payments are processed by Yapily, a regulated open-banking provider. Payspin never sees your bank login and never holds your money — it moves directly between bank accounts.',
  },
  {
    q: 'Do I need to install an app?',
    a: 'No. You can pay straight from this page in your browser. You only authenticate inside your own bank’s app or website.',
  },
  {
    q: 'Is it free?',
    a: 'Paying a Payspin request is free for you. Your bank may apply its standard transfer terms, just like any other payment.',
  },
  {
    q: 'Why am I seeing this request?',
    a: 'Someone created a Payspin payment link and shared it with you. Only pay if you recognise the requester and the amount.',
  },
];

export default function FaqAccordion({ items }: { items: FaqItem[] }) {
  return (
    <section>
      <h2 className="ps-section-title" style={{ marginBottom: 12 }}>
        Any questions?
      </h2>
      <div className="ps-faq">
        {items.map((item) => (
          <FaqRow key={item.q} item={item} />
        ))}
      </div>
    </section>
  );
}

function FaqRow({ item }: { item: FaqItem }) {
  const [open, setOpen] = useState(false);
  const panelId = useId();
  return (
    <div className="ps-faq__item">
      <button
        type="button"
        className="ps-faq__button"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen((v) => !v)}
      >
        <span>{item.q}</span>
        <span
          aria-hidden
          className={`ps-faq__chevron${open ? ' ps-faq__chevron--open' : ''}`}
        >
          ▾
        </span>
      </button>
      <div
        id={panelId}
        role="region"
        className={`ps-faq__answer-wrap${open ? ' ps-faq__answer-wrap--open' : ''}`}
        aria-hidden={!open}
      >
        <div className="ps-faq__answer-inner">
          <div className="ps-faq__answer">{item.a}</div>
        </div>
      </div>
    </div>
  );
}
