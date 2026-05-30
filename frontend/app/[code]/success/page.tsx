export default function SuccessPage() {
  return (
    <main style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ textAlign: 'center', padding: 32 }}>
        <p style={{ fontSize: 48, color: '#10b981' }}>✓</p>
        <h1>Payment sent!</h1>
        <p style={{ color: '#6b7280' }}>Thank you for using Payspin.</p>
      </div>
    </main>
  );
}
