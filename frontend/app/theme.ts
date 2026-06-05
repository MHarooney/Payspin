/**
 * Payspin payer web design tokens — mirrors the mobile dark prototype
 * (`mobile/lib/core/design_system/tokens/payspin_tokens.dart`).
 * Use these for inline styles; shared CSS variables live in `globals.css`.
 */
export const tokens = {
  bg: '#0B0B12',
  bgElevated: '#15141F',
  surfaceRaised: 'rgba(255,255,255,0.04)',
  glass: 'rgba(255,255,255,0.06)',
  border: 'rgba(255,255,255,0.10)',

  textPrimary: '#FFFFFF',
  textBody: 'rgba(255,255,255,0.85)',
  textMuted: 'rgba(255,255,255,0.55)',
  textHint: 'rgba(255,255,255,0.35)',

  pink: '#FC00FF',
  mint: '#07D8DD',
  success: '#22C55E',
  warning: '#FFC408',
  error: '#EF4444',

  gradient: 'linear-gradient(90deg, #FC00FF, #07D8DD)',
  radiusCard: 20,
  radiusPill: 100,
} as const;
