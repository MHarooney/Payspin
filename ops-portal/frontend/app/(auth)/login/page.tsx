'use client';

import { useRouter } from 'next/navigation';
import { FormEvent, useEffect, useState } from 'react';
import { OpsBrandMark } from '@/components/ops/brand-mark';
import { OpsEmblemLoader, OpsPageLoader } from '@/components/ops/emblem-loader';
import { OpsThemeToggle } from '@/components/ops/theme-toggle';
import { useAuth } from '@/lib/auth';

export default function LoginPage() {
  const { admin, loading, login } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!loading && admin) router.replace('/');
  }, [loading, admin, router]);

  if (loading) {
    return <OpsPageLoader label="Checking session" />;
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-wrap">
      <div className="login-toolbar">
        <OpsThemeToggle />
      </div>
      <form className="login-card" onSubmit={onSubmit}>
        <div className="brand">
          <OpsBrandMark variant="auth" />
        </div>
        <div className="tagline">Internal operations portal — authorised staff only.</div>
        <div className="field">
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="username"
            required
          />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            required
          />
        </div>
        {error && <div className="error-text">{error}</div>}
        <button className="btn primary ops-btn-loader" type="submit" disabled={submitting}>
          {submitting ? (
            <>
              <OpsEmblemLoader size={22} label="Signing in" />
              Signing in…
            </>
          ) : (
            'Sign in'
          )}
        </button>
      </form>
    </div>
  );
}
