import Link from 'next/link';

export default function HomePage() {
  return (
    <main style={{ maxWidth: 480, margin: '80px auto', padding: 24, textAlign: 'center' }}>
      <h1 style={{ background: 'linear-gradient(90deg,#FC00FF,#07D8DD)', WebkitBackgroundClip: 'text', color: 'transparent' }}>
        Payspin Pay
      </h1>
      <p style={{ color: '#6b7280' }}>Open a payment link shared with you, e.g. /abc12345</p>
      <Link href="/demo1234" style={{ color: '#07D8DD' }}>
        Demo link placeholder
      </Link>
    </main>
  );
}
