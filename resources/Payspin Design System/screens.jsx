// Payspin Dark Mode Prototype — Screens
// All screens are mobile-first, designed for the iOS frame inner area (~390x780)

const { useState, useEffect, useRef } = React;

// ── Brand Tokens ─────────────────────────────────────────────────
const PS = {
  bg: '#0B0B12', // deep page bg
  bgElevated: '#15141F', // cards
  bgGlass: 'rgba(255,255,255,0.06)',
  border: 'rgba(255,255,255,0.08)',
  borderActive: 'rgba(252,0,255,0.45)',
  textPrimary: '#FFFFFF',
  textBody: 'rgba(255,255,255,0.85)',
  textMuted: 'rgba(255,255,255,0.55)',
  textHint: 'rgba(255,255,255,0.35)',
  mint: '#07D8DD',
  pink: '#FC00FF',
  purple: '#8E0FF2',
  blue: '#5C7AEA',
  mustard: '#FFC408',
  gradient: 'linear-gradient(135deg, #07D8DD 0%, #5C7AEA 45%, #FC00FF 100%)',
  gradientPink: 'linear-gradient(135deg, #FC00FF 0%, #07D8DD 100%)',
  fontDisplay: "'Raleway', system-ui, sans-serif",
  fontBody: "'Inter', system-ui, sans-serif"
};

// ── Lucide-style inline icons ───────────────────────────────────
const Ico = {
  arrowLeft: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M19 12H5M12 19l-7-7 7-7" /></svg>,
  arrowRight: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M12 5l7 7-7 7" /></svg>,
  check: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>,
  plus: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>,
  home: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" /></svg>,
  qr: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><path d="M14 14h3M20 14v3M14 17v4M17 17v0M14 21h3M20 20v1" /></svg>,
  user: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4" /><path d="M5 21v-1a7 7 0 0 1 14 0v1" /></svg>,
  bell: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" /></svg>,
  card: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="6" width="20" height="13" rx="2" /><path d="M2 11h20" /></svg>,
  shield: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2l8 4v6c0 5-3.5 9-8 10-4.5-1-8-5-8-10V6l8-4z" /></svg>,
  globe: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20" /></svg>,
  help: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3M12 17h.01" /></svg>,
  logout: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9" /></svg>,
  chevronDown: (s = 16, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9" /></svg>,
  chevronRight: (s = 16, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6" /></svg>,
  flash: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M18.5 12L9 22l1.5-7.5H4.5L13.5 4 12 11.5h6.5z" /></svg>,
  backspace: (s = 22, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 5H8l-7 7 7 7h13a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2zM18 9l-6 6M12 9l6 6" /></svg>,
  euro: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M18 7a8 8 0 1 0 0 10M3 11h12M3 15h12" /></svg>,
  users: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></svg>,
  star: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill={c} stroke="none"><polygon points="12 2 15.1 8.6 22 9.3 17 14.1 18.2 21 12 17.6 5.8 21 7 14.1 2 9.3 8.9 8.6 12 2" /></svg>,
  send: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" /></svg>,
  request: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 5v14M5 12l7 7 7-7" /></svg>,
  close: (s = 24, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>,
  search: (s = 22, c = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>
};

// ── Reusable: Gradient text ─────────────────────────────────────
function GradientText({ children, style = {} }) {
  return (
    <span style={{
      backgroundImage: PS.gradientPink,
      WebkitBackgroundClip: 'text',
      backgroundClip: 'text',

      WebkitTextFillColor: 'transparent',
      ...style, textAlign: "center", lineHeight: "1.4", color: "rgb(255, 255, 255)"
    }}>{children}</span>);

}

// ── Reusable: Gradient circle FAB / Next button ─────────────────
function GradientCircleButton({ icon, size = 56, onClick, disabled = false, style = {} }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      width: size, height: size, borderRadius: '50%',
      background: disabled ? 'rgba(255,255,255,0.08)' : PS.gradientPink,
      border: 'none', cursor: disabled ? 'default' : 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: disabled ? 'none' : '0 8px 24px rgba(252,0,255,0.32), 0 4px 12px rgba(7,216,221,0.18)',
      position: 'relative', overflow: 'hidden', flexShrink: 0,
      ...style
    }}>
      <div style={{ position: 'relative', zIndex: 1 }}>{icon}</div>
    </button>);

}

// ── Reusable: Gradient pill button ───────────────────────────────
function GradientPillButton({ label, icon, onClick, style = {} }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', height: 56, borderRadius: 100,
      background: PS.gradientPink, border: 'none', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      fontFamily: PS.fontBody, fontWeight: 700, fontSize: 16, color: '#fff',
      letterSpacing: '-0.01em',
      boxShadow: '0 8px 24px rgba(252,0,255,0.28), 0 4px 12px rgba(7,216,221,0.16)',
      ...style
    }}>
      {icon}
      {label}
    </button>);

}

// ── Reusable: Onboarding shell (header + heading + footer) ──────
function OnboardingShell({ step, totalSteps, onBack, onNext, nextDisabled, nextIcon, title, subtitle, children }) {
  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody
    }}>
      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 24px 8px' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, width: 32, height: 32, display: 'flex', alignItems: 'center' }}>
          {Ico.arrowLeft(24, '#fff')}
        </button>
        <span style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 14, color: PS.textMuted, letterSpacing: '0.02em' }}>
          {step}<span style={{ color: PS.textHint }}>/{totalSteps}</span>
        </span>
      </div>

      {/* Progress bar */}
      <div style={{ padding: '4px 24px 20px' }}>
        <div style={{ height: 3, background: 'rgba(255,255,255,0.06)', borderRadius: 100, overflow: 'hidden' }}>
          <div style={{ width: `${step / totalSteps * 100}%`, height: '100%', background: PS.gradientPink, borderRadius: 100, transition: 'width 0.35s ease' }}></div>
        </div>
      </div>

      {/* Content */}
      <div style={{ flex: 1, padding: '12px 24px 0', overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
        <h1 style={{
          fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 30,
          lineHeight: 1.15, color: '#fff', letterSpacing: '-0.02em',
          marginBottom: subtitle ? 28 : 36
        }}>{title}</h1>
        {children}
        {subtitle &&
        <p style={{
          fontFamily: PS.fontBody, fontWeight: 400, fontSize: 13,
          color: PS.textMuted, lineHeight: 1.6, marginTop: 16, maxWidth: 320
        }}>{subtitle}</p>
        }
      </div>

      {/* Bottom action row */}
      <div style={{ padding: '16px 24px 28px', display: 'flex', justifyContent: 'flex-end' }}>
        <GradientCircleButton
          icon={nextIcon || Ico.arrowRight(22, '#fff')}
          onClick={onNext}
          disabled={nextDisabled} />
        
      </div>
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Step 1: Name
// ─────────────────────────────────────────────────────────────────
function Step1Name({ value, setValue, onNext, onBack }) {
  return (
    <OnboardingShell
      step={1} totalSteps={5} onBack={onBack} onNext={onNext}
      nextDisabled={!value.trim()}
      title="What should we call you?"
      subtitle="We use this name in the app. Others will see it too after they've paid you.">
      
      <div style={{ position: 'relative', borderBottom: `1px solid ${value ? PS.borderActive : 'rgba(255,255,255,0.12)'}`, paddingBottom: 8 }}>
        <input
          autoFocus
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="Enter your name"
          style={{
            width: '100%', background: 'transparent', border: 'none', outline: 'none',
            fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 22,
            color: value ? PS.mint : 'rgba(255,255,255,0.35)',
            caretColor: PS.mint, padding: 0
          }} />
        
      </div>
    </OnboardingShell>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Step 2: Phone
// ─────────────────────────────────────────────────────────────────
function Step2Phone({ value, setValue, country, setCountry, onNext, onBack }) {
  const countries = [
  { code: '+31', flag: '🇳🇱', name: 'Netherlands' },
  { code: '+49', flag: '🇩🇪', name: 'Germany' },
  { code: '+33', flag: '🇫🇷', name: 'France' },
  { code: '+44', flag: '🇬🇧', name: 'UK' },
  { code: '+1', flag: '🇺🇸', name: 'USA' }];

  const [open, setOpen] = useState(false);
  return (
    <OnboardingShell
      step={2} totalSteps={5} onBack={onBack} onNext={onNext}
      nextDisabled={value.length < 6}
      title={'What is your\nmobile number?'.split('\n').map((l, i) => <span key={i}>{l}<br /></span>)}
      subtitle="We'll send you a verification code by text message so you can confirm that it's really you.">
      
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, position: 'relative' }}>
        {/* Country pill */}
        <button onClick={() => setOpen(!open)} style={{
          background: 'rgba(255,255,255,0.06)',
          border: '1px solid rgba(255,255,255,0.12)',
          borderRadius: 100, padding: '8px 12px',
          display: 'flex', alignItems: 'center', gap: 8,
          cursor: 'pointer', height: 42, flexShrink: 0
        }}>
          <span style={{ fontSize: 18 }}>{country.flag}</span>
          <span style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 14, color: '#fff' }}>{country.code}</span>
          {Ico.chevronDown(14, 'rgba(255,255,255,0.6)')}
        </button>
        {/* Number input */}
        <input
          autoFocus
          inputMode="tel"
          value={value}
          onChange={(e) => setValue(e.target.value.replace(/[^0-9 ]/g, ''))}
          placeholder="06 12345678"
          style={{
            flex: 1, background: 'transparent', border: 'none', outline: 'none',
            fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 22,
            color: value ? PS.mint : 'rgba(255,255,255,0.35)',
            caretColor: PS.mint, padding: 0
          }} />
        
        {open &&
        <div style={{
          position: 'absolute', top: 50, left: 0, right: 0, zIndex: 10,
          background: PS.bgElevated, border: `1px solid ${PS.border}`,
          borderRadius: 16, padding: 6, boxShadow: '0 12px 32px rgba(0,0,0,0.4)'
        }}>
            {countries.map((c) =>
          <button key={c.code} onClick={() => {setCountry(c);setOpen(false);}} style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', background: 'none', border: 'none',
            cursor: 'pointer', borderRadius: 10, color: '#fff',
            fontFamily: PS.fontBody, fontSize: 14, fontWeight: 500, textAlign: 'left'
          }}>
                <span style={{ fontSize: 18 }}>{c.flag}</span>
                <span style={{ flex: 1 }}>{c.name}</span>
                <span style={{ color: PS.textMuted }}>{c.code}</span>
              </button>
          )}
          </div>
        }
      </div>
    </OnboardingShell>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Step 3: OTP
// ─────────────────────────────────────────────────────────────────
function Step3OTP({ value, setValue, phoneDisplay, onNext, onBack }) {
  const inputRef = useRef(null);
  useEffect(() => {inputRef.current?.focus();}, []);
  return (
    <OnboardingShell
      step={3} totalSteps={5} onBack={onBack} onNext={onNext}
      nextDisabled={value.length < 4}
      title={`Enter the code sent to ${phoneDisplay}`}
      subtitle="It may take a while before you receive the text.">
      
      <div style={{ display: 'flex', gap: 14, marginBottom: 12 }}>
        {[0, 1, 2, 3].map((i) =>
        <div key={i} style={{
          flex: 1, height: 64, borderRadius: 14,
          background: 'rgba(255,255,255,0.04)',
          border: `1px solid ${value[i] ? PS.borderActive : 'rgba(255,255,255,0.1)'}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 28,
          color: PS.mint, transition: 'all 0.15s'
        }}>
            {value[i] || ''}
          </div>
        )}
      </div>
      <input
        ref={inputRef}
        inputMode="numeric"
        maxLength={4}
        value={value}
        onChange={(e) => setValue(e.target.value.replace(/[^0-9]/g, '').slice(0, 4))}
        style={{ position: 'absolute', opacity: 0, pointerEvents: 'none' }} />
      
      <button style={{
        background: 'none', border: 'none', cursor: 'pointer', padding: 0,
        textAlign: 'left', marginTop: 6,
        fontFamily: PS.fontBody, fontWeight: 600, fontSize: 13,
        color: PS.mint, textDecoration: 'underline', textUnderlineOffset: 3
      }}>Resend code</button>
    </OnboardingShell>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Step 4: IBAN
// ─────────────────────────────────────────────────────────────────
function Step4IBAN({ value, setValue, onNext, onBack }) {
  const formatted = value || 'NL00 ABNA 1234 5678 90';
  const isFilled = value.length > 4;
  return (
    <OnboardingShell
      step={4} totalSteps={5} onBack={onBack} onNext={onNext}
      nextDisabled={value.length < 8}
      title={'Which IBAN do you want\nthe money paid into?'.split('\n').map((l, i) => <span key={i}>{l}<br /></span>)}
      subtitle="Your IBAN is only shared with people that have to pay you back.">
      
      <div style={{ position: 'relative', borderBottom: `1px solid ${isFilled ? PS.borderActive : 'rgba(255,255,255,0.12)'}`, paddingBottom: 8, marginBottom: 16 }}>
        <input
          autoFocus
          value={value}
          onChange={(e) => setValue(e.target.value.toUpperCase())}
          placeholder="NL00 ABNA 1234 5678 90"
          style={{
            width: '100%', background: 'transparent', border: 'none', outline: 'none',
            fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 22,
            color: isFilled ? PS.mint : 'rgba(255,255,255,0.35)',
            caretColor: PS.mint, padding: 0, letterSpacing: '0.02em'
          }} />
        
      </div>
      <button style={{
        background: 'none', border: 'none', cursor: 'pointer', padding: 0,
        textAlign: 'left',
        fontFamily: PS.fontBody, fontWeight: 600, fontSize: 13,
        color: '#fff', textDecoration: 'underline', textUnderlineOffset: 3
      }}>Foreign IBAN?</button>
    </OnboardingShell>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Step 5: Full Name
// ─────────────────────────────────────────────────────────────────
function Step5FullName({ value, setValue, ibanDisplay, onNext, onBack }) {
  return (
    <OnboardingShell
      step={5} totalSteps={5} onBack={onBack} onNext={onNext}
      nextDisabled={!value.trim() || !value.includes(' ')}
      nextIcon={Ico.check(24, '#fff')}
      title={'What\'s your first and\nlast name?'.split('\n').map((l, i) => <span key={i}>{l}<br /></span>)}>
      
      <div style={{ position: 'relative', borderBottom: `1px solid ${value ? PS.borderActive : 'rgba(255,255,255,0.12)'}`, paddingBottom: 8, marginBottom: 16 }}>
        <input
          autoFocus
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="First and last name"
          style={{
            width: '100%', background: 'transparent', border: 'none', outline: 'none',
            fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 22,
            color: value ? '#fff' : 'rgba(255,255,255,0.35)',
            caretColor: PS.mint, padding: 0
          }} />
        
      </div>
      <p style={{ fontFamily: PS.fontBody, fontSize: 13, color: PS.textMuted, lineHeight: 1.6 }}>
        We will use this to check whether <strong style={{ color: '#fff', fontWeight: 700 }}>{ibanDisplay}</strong> is in your name, so we can keep Payspin safe.
      </p>
    </OnboardingShell>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Success
// ─────────────────────────────────────────────────────────────────
function SuccessScreen({ name, onContinue }) {
  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody, position: 'relative'
    }}>
      {/* Confetti dots */}
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
        {Array.from({ length: 30 }).map((_, i) => {
          const colors = [PS.mint, PS.pink, PS.mustard, PS.blue, PS.purple];
          const c = colors[i % colors.length];
          const left = i * 37 % 100;
          const top = i * 53 % 100;
          const sz = 6 + i % 5 * 2;
          const rot = i * 47 % 360;
          return (
            <div key={i} style={{
              position: 'absolute', left: `${left}%`, top: `${top}%`,
              width: sz, height: sz / 2.2, background: c,
              borderRadius: 2, transform: `rotate(${rot}deg)`,
              opacity: 0.9
            }}></div>);

        })}
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '40px 32px', position: 'relative', zIndex: 1, textAlign: 'center' }}>
        {/* Glow */}
        <div style={{
          position: 'absolute', top: '32%', left: '50%', transform: 'translate(-50%, -50%)',
          width: 320, height: 320, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(252,0,255,0.18) 0%, rgba(7,216,221,0.08) 50%, transparent 70%)',
          filter: 'blur(20px)'
        }}></div>

        <div style={{ position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <h1 style={{
            fontFamily: PS.fontDisplay, fontWeight: 900, fontSize: 56,
            lineHeight: 1, color: '#fff', letterSpacing: '-0.04em', marginBottom: 14
          }}>Nice!</h1>
          <p style={{
            fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 24,
            lineHeight: 1.25, color: PS.textBody, marginBottom: 32, maxWidth: 280
          }}>You can now use <GradientText>Payspin</GradientText></p>

          <div style={{ marginBottom: 36 }}>
            <img src="assets/Emblem_Gradient.png" alt="" style={{ width: 96, height: 96, objectFit: 'contain', filter: 'drop-shadow(0 12px 32px rgba(252,0,255,0.4))' }} />
          </div>

          <p style={{ fontFamily: PS.fontBody, fontSize: 14, color: PS.textMuted, lineHeight: 1.6, maxWidth: 280, marginBottom: 32 }}>
            Welcome aboard{name ? `, ${name}` : ''}. Send and request payments in seconds.
          </p>
        </div>
      </div>

      <div style={{ padding: '0 24px 36px', position: 'relative', zIndex: 2 }}>
        <GradientPillButton label="Go to Home" onClick={onContinue} icon={Ico.arrowRight(20, '#fff')} />
      </div>
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Home (Tikkies / activity feed)
// ─────────────────────────────────────────────────────────────────
function HomeScreen({ name, onTab, onFAB, onOpenTikkie, mode = 'list' }) {
  // mode: 'list' (with history) or 'empty' (new user)
  const tikkies = [
  { id: 1, emoji: '🍣', title: 'Sushi saturday', date: '11 aug', status: 'Paid 2x', amount: '€ 50,00', tint: 'rgba(252,0,255,0.18)' },
  { id: 2, emoji: '⛽', title: 'Petrol', date: '11 aug', status: 'Paid 1x', amount: '€ 90,00', tint: 'rgba(7,216,221,0.18)' },
  { id: 3, emoji: '🎁', title: 'Gift for Liza', date: '11 aug', status: 'Paid 1x', amount: '€ 25,00', tint: 'rgba(255,196,8,0.18)' },
  { id: 4, emoji: '☕', title: 'Coffee run', date: '08 aug', status: 'Paid 4x', amount: '€ 18,40', tint: 'rgba(92,122,234,0.18)' }];

  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody, position: 'relative'
    }}>
      {/* Top header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px 16px' }}>
        <button onClick={() => onTab('scan')} style={{ background: 'rgba(255,255,255,0.06)', border: `1px solid ${PS.border}`, borderRadius: 12, width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          {Ico.qr(20, '#fff')}
        </button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <img src="assets/Emblem_Gradient.png" alt="" style={{ width: 22, height: 22, objectFit: 'contain' }} />
          <span style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 18, letterSpacing: '-0.02em' }}>
            <GradientText>Payspin</GradientText>
          </span>
        </div>
        <button style={{ background: 'rgba(255,255,255,0.06)', border: `1px solid ${PS.border}`, borderRadius: 12, width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          {Ico.search(18, '#fff')}
        </button>
      </div>

      {/* Tab strip */}
      <div style={{ display: 'flex', gap: 24, padding: '0 24px 8px' }}>
        {[
        { id: 'tikkies', label: 'Tikkies' },
        { id: 'deals', label: 'Deals' },
        { id: 'groepies', label: 'Groepies' }].
        map((t) =>
        <button key={t.id} onClick={() => t.id === 'groepies' ? onTab('groepies') : null} style={{
          background: 'none', border: 'none', cursor: 'pointer', padding: '8px 0',
          fontFamily: PS.fontBody, fontWeight: t.id === 'tikkies' ? 700 : 500,
          fontSize: 14,
          color: t.id === 'tikkies' ? '#fff' : PS.textMuted,
          borderBottom: t.id === 'tikkies' ? `2px solid ${PS.mint}` : '2px solid transparent'
        }}>{t.label}</button>
        )}
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '20px 20px 100px' }}>
        {mode === 'empty' ?
        // EMPTY STATE — new user
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 40 }}>
            {/* Stacked card illustration */}
            <div style={{ position: 'relative', width: 240, height: 180, marginBottom: 32 }}>
              {[
            { rot: -8, top: 0, scale: 0.85, op: 0.35, label: 'Sushi saturday', amt: '€ 50,00' },
            { rot: -3, top: 18, scale: 0.92, op: 0.6, label: 'Petrol', amt: '€ 90,00' },
            { rot: 4, top: 36, scale: 1, op: 1, label: 'Gift for Liza', amt: '€ 25,00' }].
            map((c, i) =>
            <div key={i} style={{
              position: 'absolute', left: '50%', top: c.top,
              transform: `translateX(-50%) rotate(${c.rot}deg) scale(${c.scale})`,
              width: 220, padding: '14px 16px',
              background: 'rgba(255,255,255,0.06)',
              border: `1px solid ${PS.border}`,
              borderRadius: 16,
              opacity: c.op,
              boxShadow: '0 12px 32px rgba(0,0,0,0.4)',
              display: 'flex', alignItems: 'center', gap: 10
            }}>
                  <div style={{ width: 32, height: 32, borderRadius: 10, background: PS.gradientPink, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>
                    {i === 0 ? '🍣' : i === 1 ? '⛽' : '🎁'}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 13, color: '#fff' }}>{c.label}</div>
                  </div>
                  <div style={{ fontFamily: PS.fontBody, fontWeight: 700, fontSize: 13, color: PS.mint }}>{c.amt}</div>
                </div>
            )}
            </div>
            <h2 style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 24, color: '#fff', letterSpacing: '-0.02em', marginBottom: 10 }}>
              Time for your first Tikkie!
            </h2>
            <p style={{ fontFamily: PS.fontBody, fontSize: 14, color: PS.textMuted }}>Cash your money quickly.</p>
          </div> :

        // LIST — recent tikkies
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {tikkies.map((t, i) =>
          <button key={t.id} onClick={onOpenTikkie} style={{
            width: '100%', textAlign: 'left',
            background: 'rgba(255,255,255,0.04)',
            border: `1px solid ${PS.border}`,
            borderRadius: 18, padding: '14px 16px', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 14,
            position: 'relative', overflow: 'hidden'
          }}>
                <div style={{
              width: 44, height: 44, borderRadius: 14,
              background: t.tint, display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22, flexShrink: 0
            }}>{t.emoji}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 15, color: '#fff', marginBottom: 4 }}>{t.title}</div>
                  <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(7,216,221,0.12)', padding: '3px 8px', borderRadius: 100 }}>
                    <div style={{ width: 6, height: 6, borderRadius: '50%', background: PS.mint }}></div>
                    <span style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 11, color: PS.mint }}>{t.status}</span>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontFamily: PS.fontBody, fontWeight: 500, fontSize: 11, color: PS.textHint, marginBottom: 4 }}>{t.date}</div>
                  <div style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 16, color: '#fff' }}>{t.amount}</div>
                </div>
              </button>
          )}

            {/* Promo card */}
            <div style={{
            marginTop: 4, borderRadius: 20, padding: 1,
            background: PS.gradient, position: 'relative', overflow: 'hidden'
          }}>
              <div style={{
              background: PS.bgElevated, borderRadius: 19, padding: '18px 18px 20px'
            }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                  <div style={{ background: PS.mustard, color: '#0B0B12', fontFamily: PS.fontBody, fontWeight: 800, fontSize: 10, padding: '3px 8px', borderRadius: 100, letterSpacing: '0.04em' }}>NEW</div>
                  <span style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 11, color: PS.textMuted, letterSpacing: '0.02em' }}>SPLIT BILLS WITH FRIENDS</span>
                </div>
                <div style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 20, color: '#fff', lineHeight: 1.2, marginBottom: 14, letterSpacing: '-0.01em' }}>
                  Try Groepies for shared expenses
                </div>
                <button onClick={() => onTab('groepies')} style={{
                background: PS.gradientPink, border: 'none', borderRadius: 100,
                padding: '10px 18px', cursor: 'pointer',
                fontFamily: PS.fontBody, fontWeight: 700, fontSize: 13, color: '#fff',
                display: 'inline-flex', alignItems: 'center', gap: 6
              }}>Open Groepies {Ico.chevronRight(14, '#fff')}</button>
              </div>
            </div>
          </div>
        }
      </div>

      {/* FAB */}
      <GradientCircleButton
        icon={Ico.plus(28, '#fff')}
        size={64}
        onClick={onFAB}
        style={{ position: 'absolute', bottom: 96, right: 20, zIndex: 5 }} />
      

      {/* Bottom nav */}
      <BottomNav active="home" onTab={onTab} />
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// COMPONENT — Bottom Nav
// ─────────────────────────────────────────────────────────────────
function BottomNav({ active, onTab }) {
  const items = [
  { id: 'home', label: 'Home', icon: Ico.home },
  { id: 'scan', label: 'Scan QR', icon: Ico.qr },
  { id: 'profile', label: 'Profile', icon: Ico.user }];

  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 4,
      background: 'rgba(11,11,18,0.85)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: `1px solid ${PS.border}`,
      padding: '10px 8px 18px',
      display: 'flex'
    }}>
      {items.map((it) => {
        const isActive = it.id === active;
        return (
          <button key={it.id} onClick={() => onTab(it.id)} style={{
            flex: 1, background: 'none', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            padding: '6px 0'
          }}>
            <div style={{ position: 'relative' }}>
              {it.icon(22, isActive ? '#fff' : PS.textMuted)}
              {isActive &&
              <div style={{
                position: 'absolute', bottom: -8, left: '50%', transform: 'translateX(-50%)',
                width: 4, height: 4, borderRadius: '50%', background: PS.mint
              }}></div>
              }
            </div>
            <span style={{
              fontFamily: PS.fontBody, fontWeight: isActive ? 700 : 500, fontSize: 10,
              color: isActive ? '#fff' : PS.textMuted, letterSpacing: '0.02em'
            }}>{it.label}</span>
          </button>);

      })}
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Groepies (group expenses sub-section)
// ─────────────────────────────────────────────────────────────────
function GroepiesScreen({ onTab, onFAB }) {
  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody, position: 'relative'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px 16px' }}>
        <button onClick={() => onTab('scan')} style={{ background: 'rgba(255,255,255,0.06)', border: `1px solid ${PS.border}`, borderRadius: 12, width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          {Ico.qr(20, '#fff')}
        </button>
        <span style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 17, color: '#fff' }}>Groepies</span>
        <div style={{ width: 40, height: 40 }}></div>
      </div>

      {/* Tab strip */}
      <div style={{ display: 'flex', gap: 24, padding: '0 24px 8px' }}>
        {[
        { id: 'tikkies', label: 'Tikkies' },
        { id: 'deals', label: 'Deals' },
        { id: 'groepies', label: 'Groepies' }].
        map((t) =>
        <button key={t.id} onClick={() => t.id === 'tikkies' ? onTab('home') : null} style={{
          background: 'none', border: 'none', cursor: 'pointer', padding: '8px 0',
          fontFamily: PS.fontBody, fontWeight: t.id === 'groepies' ? 700 : 500,
          fontSize: 14,
          color: t.id === 'groepies' ? '#fff' : PS.textMuted,
          borderBottom: t.id === 'groepies' ? `2px solid ${PS.mint}` : '2px solid transparent'
        }}>{t.label}</button>
        )}
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 20px 120px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        {/* Stacked cards */}
        <div style={{ position: 'relative', width: 260, height: 180, marginBottom: 24, marginTop: 12 }}>
          <div style={{
            position: 'absolute', left: '50%', top: 0,
            transform: 'translateX(-60%) rotate(-6deg)',
            width: 200, height: 110,
            background: PS.bgElevated,
            border: `1px solid ${PS.border}`,
            borderRadius: 16, padding: 14,
            boxShadow: '0 16px 32px rgba(0,0,0,0.4)'
          }}>
            <div style={{ fontSize: 22, marginBottom: 10 }}>🏠</div>
            <div style={{ fontFamily: PS.fontBody, fontSize: 10, color: PS.textMuted, marginBottom: 2 }}>7 participants</div>
            <div style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 14, color: '#fff' }}>House bill</div>
          </div>
          <div style={{
            position: 'absolute', left: '50%', top: 50,
            transform: 'translateX(-30%) rotate(8deg)',
            width: 200, height: 130,
            background: 'linear-gradient(135deg, rgba(252,0,255,0.2), rgba(7,216,221,0.15))',
            border: `1px solid ${PS.borderActive}`,
            borderRadius: 16, padding: 14,
            boxShadow: '0 16px 32px rgba(0,0,0,0.5)'
          }}>
            <div style={{ fontSize: 22, marginBottom: 6 }}>🚗</div>
            <div style={{ fontFamily: PS.fontBody, fontSize: 10, color: 'rgba(255,255,255,0.7)', marginBottom: 2 }}>5 participants</div>
            <div style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 14, color: '#fff', marginBottom: 10 }}>Weekend trip</div>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(255,255,255,0.12)', padding: '4px 10px', borderRadius: 100 }}>
              <span style={{ fontFamily: PS.fontBody, fontWeight: 500, fontSize: 10, color: '#fff' }}>You'll receive</span>
              <span style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 11, color: PS.mint }}>€ 69,00</span>
            </div>
          </div>
        </div>

        <h2 style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 26, color: '#fff', letterSpacing: '-0.02em', marginBottom: 12 }}>
          Track group expenses?
        </h2>
        <p style={{ fontFamily: PS.fontBody, fontSize: 14, color: PS.textMuted, lineHeight: 1.6, maxWidth: 300, marginBottom: 28 }}>
          Keep track of costs together quickly and easily. And we'll do all the math.
        </p>
        <div style={{ width: '100%', maxWidth: 320 }}>
          <GradientPillButton label="Create Groepie" onClick={onFAB} icon={Ico.plus(20, '#fff')} />
        </div>
        <button style={{
          marginTop: 18, background: 'none', border: 'none', cursor: 'pointer',
          fontFamily: PS.fontBody, fontWeight: 700, fontSize: 13, color: '#fff'
        }}>How does it work?</button>
      </div>

      <BottomNav active="home" onTab={onTab} />
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Profile
// ─────────────────────────────────────────────────────────────────
function ProfileScreen({ name, fullName, iban, phone, onTab, onLogout }) {
  const settings = [
  { id: 'account', icon: Ico.user, label: 'Account details', detail: fullName },
  { id: 'iban', icon: Ico.card, label: 'Linked IBAN', detail: iban ? iban.slice(0, 4) + ' •••• ' + iban.slice(-4) : '—' },
  { id: 'notifications', icon: Ico.bell, label: 'Push notifications', detail: 'On' },
  { id: 'security', icon: Ico.shield, label: 'Security & privacy' },
  { id: 'language', icon: Ico.globe, label: 'Language', detail: 'English' },
  { id: 'help', icon: Ico.help, label: 'Help & support' }];

  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody, position: 'relative'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px 8px' }}>
        <button onClick={() => onTab('home')} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, width: 32, height: 32, display: 'flex', alignItems: 'center' }}>
          {Ico.arrowLeft(22, '#fff')}
        </button>
        <span style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 17 }}>Profile</span>
        <div style={{ width: 32 }}></div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 20px 120px' }}>
        {/* Avatar header */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '20px 0 28px' }}>
          <div style={{
            width: 96, height: 96, borderRadius: '50%',
            background: PS.gradientPink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 14,
            boxShadow: '0 12px 32px rgba(252,0,255,0.32)'
          }}>
            <span style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 36, color: '#fff' }}>
              {(name || 'P')[0].toUpperCase()}
            </span>
          </div>
          <h2 style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 22, color: '#fff', marginBottom: 4 }}>
            {fullName || name || 'Payspin user'}
          </h2>
          <p style={{ fontFamily: PS.fontBody, fontSize: 13, color: PS.textMuted }}>{phone || '—'}</p>
        </div>

        {/* IBAN card */}
        <div style={{
          background: 'linear-gradient(135deg, rgba(252,0,255,0.12), rgba(7,216,221,0.08))',
          border: `1px solid ${PS.border}`,
          borderRadius: 18, padding: '16px 18px', marginBottom: 24,
          position: 'relative', overflow: 'hidden'
        }}>
          <div style={{ position: 'absolute', top: -40, right: -40, width: 140, height: 140, borderRadius: '50%', background: 'radial-gradient(circle, rgba(252,0,255,0.3) 0%, transparent 70%)', filter: 'blur(20px)' }}></div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 11, color: PS.textMuted, letterSpacing: '0.06em', marginBottom: 8 }}>LINKED IBAN</div>
            <div style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 18, color: '#fff', letterSpacing: '0.06em' }}>
              {iban || 'NL•• ABNA •••• •••• ••'}
            </div>
          </div>
        </div>

        {/* Settings list */}
        <div style={{ background: 'rgba(255,255,255,0.04)', border: `1px solid ${PS.border}`, borderRadius: 18, overflow: 'hidden' }}>
          {settings.map((s, i) =>
          <button key={s.id} style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 14,
            padding: '14px 16px', background: 'none', border: 'none', cursor: 'pointer',
            borderBottom: i < settings.length - 1 ? `1px solid ${PS.border}` : 'none',
            textAlign: 'left'
          }}>
              <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'rgba(255,255,255,0.06)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
            }}>{s.icon(18, '#fff')}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 14, color: '#fff' }}>{s.label}</div>
                {s.detail && <div style={{ fontFamily: PS.fontBody, fontSize: 12, color: PS.textMuted, marginTop: 2 }}>{s.detail}</div>}
              </div>
              {Ico.chevronRight(16, PS.textHint)}
            </button>
          )}
        </div>

        {/* Logout */}
        <button onClick={onLogout} style={{
          width: '100%', marginTop: 16,
          background: 'rgba(252,0,255,0.08)',
          border: '1px solid rgba(252,0,255,0.2)',
          borderRadius: 14, padding: '14px',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          cursor: 'pointer',
          fontFamily: PS.fontBody, fontWeight: 700, fontSize: 14, color: PS.pink
        }}>
          {Ico.logout(18, PS.pink)} Log out
        </button>
      </div>

      <BottomNav active="profile" onTab={onTab} />
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Scan QR
// ─────────────────────────────────────────────────────────────────
function ScanQRScreen({ onTab, onClose }) {
  return (
    <div style={{
      flex: 1, background: '#000', color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody, position: 'relative'
    }}>
      {/* Faux camera background */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `
          radial-gradient(ellipse at 30% 40%, rgba(60,60,80,0.6) 0%, transparent 50%),
          radial-gradient(ellipse at 70% 70%, rgba(40,40,60,0.5) 0%, transparent 50%),
          linear-gradient(135deg, #1a1a22 0%, #0a0a10 100%)
        `
      }}></div>

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px', position: 'relative', zIndex: 2 }}>
        <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.1)', border: 'none', borderRadius: '50%', width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', backdropFilter: 'blur(20px)' }}>
          {Ico.close(20, '#fff')}
        </button>
        <div style={{ display: 'flex', gap: 10 }}>
          <button style={{ background: 'rgba(255,255,255,0.1)', border: 'none', borderRadius: '50%', width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', backdropFilter: 'blur(20px)' }}>
            {Ico.flash(20, '#fff')}
          </button>
          <button style={{ background: 'rgba(255,255,255,0.1)', border: 'none', borderRadius: '50%', width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', backdropFilter: 'blur(20px)' }}>
            {Ico.help(20, '#fff')}
          </button>
        </div>
      </div>

      {/* Scrim with viewfinder */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', position: 'relative', zIndex: 2 }}>
        {/* Hint pill */}
        <div style={{
          background: 'rgba(255,255,255,0.15)',
          backdropFilter: 'blur(20px)',
          padding: '8px 16px', borderRadius: 100,
          marginBottom: 20,
          fontFamily: PS.fontBody, fontWeight: 500, fontSize: 13, color: '#fff'
        }}>Aim the camera at the QR code</div>

        {/* Viewfinder */}
        <div style={{ position: 'relative', width: 240, height: 240 }}>
          {/* Corner brackets */}
          {[
          { top: 0, left: 0, br: '0', borderTop: true, borderLeft: true },
          { top: 0, right: 0, br: '0', borderTop: true, borderRight: true },
          { bottom: 0, left: 0, br: '0', borderBottom: true, borderLeft: true },
          { bottom: 0, right: 0, br: '0', borderBottom: true, borderRight: true }].
          map((c, i) =>
          <div key={i} style={{
            position: 'absolute',
            top: c.top, left: c.left, right: c.right, bottom: c.bottom,
            width: 36, height: 36,
            borderTop: c.borderTop ? `3px solid ${PS.mint}` : 'none',
            borderLeft: c.borderLeft ? `3px solid ${PS.mint}` : 'none',
            borderRight: c.borderRight ? `3px solid ${PS.mint}` : 'none',
            borderBottom: c.borderBottom ? `3px solid ${PS.mint}` : 'none',
            borderTopLeftRadius: c.borderTop && c.borderLeft ? 12 : 0,
            borderTopRightRadius: c.borderTop && c.borderRight ? 12 : 0,
            borderBottomLeftRadius: c.borderBottom && c.borderLeft ? 12 : 0,
            borderBottomRightRadius: c.borderBottom && c.borderRight ? 12 : 0
          }}></div>
          )}
          {/* Scanning line */}
          <div style={{
            position: 'absolute', left: 12, right: 12, top: '50%',
            height: 2, background: `linear-gradient(90deg, transparent, ${PS.mint}, transparent)`,
            boxShadow: `0 0 16px ${PS.mint}`
          }}></div>
        </div>
      </div>

      {/* Bottom info card */}
      <div style={{ padding: '0 20px 32px', position: 'relative', zIndex: 2 }}>
        <div style={{
          background: PS.bgElevated,
          border: `1px solid ${PS.border}`,
          borderRadius: 20, padding: '20px 22px',
          textAlign: 'center',
          boxShadow: '0 16px 40px rgba(0,0,0,0.5)'
        }}>
          <h3 style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 18, color: '#fff', marginBottom: 8, letterSpacing: '-0.01em' }}>
            Scan a Payspin QR code
          </h3>
          <p style={{ fontFamily: PS.fontBody, fontSize: 13, color: PS.textMuted, lineHeight: 1.55, marginBottom: 16 }}>
            Pay your friends without sending links, donate to your favourite charity, participate in cool promotions, and more!
          </p>
          <GradientPillButton label="OK, nice!" onClick={onClose} />
        </div>
      </div>
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Send (amount + numpad)
// ─────────────────────────────────────────────────────────────────
function SendAmountScreen({ amount, setAmount, onBack, onNext }) {
  const append = (k) => {
    if (k === 'back') {
      setAmount((prev) => prev.length <= 1 ? '0' : prev.slice(0, -1));
    } else if (k === ',') {
      setAmount((prev) => prev.includes(',') ? prev : prev + ',');
    } else {
      setAmount((prev) => {
        if (prev === '0') return k;
        return prev + k;
      });
    }
  };
  const display = amount || '0';
  const isZero = display === '0' || display === '';

  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody
    }}>
      {/* Top */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 24px 8px' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, width: 32, height: 32, display: 'flex', alignItems: 'center' }}>
          {Ico.arrowLeft(24, '#fff')}
        </button>
        <button style={{ background: 'rgba(255,255,255,0.06)', border: `1px solid ${PS.border}`, borderRadius: '50%', width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          {Ico.help(18, '#fff')}
        </button>
      </div>

      <div style={{ padding: '20px 24px 8px' }}>
        <h1 style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 30, lineHeight: 1.15, color: '#fff', letterSpacing: '-0.02em', marginBottom: 16 }}>
          What's the amount?
        </h1>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
          <span style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 38, color: PS.mint }}>€</span>
          <span style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 42, color: isZero ? PS.mint : '#fff', letterSpacing: '-0.02em' }}>
            {isZero ? '0,00' : display}
          </span>
        </div>
        <p style={{ fontFamily: PS.fontBody, fontSize: 12, color: PS.textMuted, marginTop: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 14 }}>💡</span> You can request back a maximum of €950.
        </p>
      </div>

      {/* Toggle row */}
      <div style={{ flex: 1, padding: '24px 24px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
        <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
          <div style={{
            width: 38, height: 22, background: 'rgba(255,255,255,0.1)',
            borderRadius: 100, position: 'relative', transition: 'background 0.2s'
          }}>
            <div style={{
              position: 'absolute', top: 2, left: 2,
              width: 18, height: 18, background: '#fff', borderRadius: '50%',
              boxShadow: '0 2px 4px rgba(0,0,0,0.3)'
            }}></div>
          </div>
          <span style={{ fontFamily: PS.fontBody, fontSize: 13, color: PS.textBody }}>Payer may choose amount</span>
        </label>
        <GradientCircleButton
          icon={Ico.arrowRight(22, '#fff')}
          onClick={onNext}
          disabled={isZero} />
        
      </div>

      {/* Account picker */}
      <div style={{ padding: '0 16px 12px' }}>
        <div style={{
          background: 'rgba(255,255,255,0.06)',
          border: `1px solid ${PS.border}`,
          borderRadius: 14, padding: '12px 16px',
          display: 'flex', alignItems: 'center', gap: 12
        }}>
          <div style={{ flex: 1, fontFamily: PS.fontBody, fontWeight: 600, fontSize: 13, color: '#fff' }}>
            Account: <span style={{ color: PS.mint }}>Payspin</span>
          </div>
          {Ico.chevronDown(16, PS.textMuted)}
        </div>
      </div>

      {/* Numpad */}
      <div style={{ padding: '4px 16px 28px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
        {[
        ['1', null], ['2', 'ABC'], ['3', 'DEF'],
        ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
        ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
        [',', null], ['0', null], ['back', null]].
        map(([k, sub]) =>
        <button key={k} onClick={() => append(k)} style={{
          height: 56, background: 'rgba(255,255,255,0.06)',
          border: `1px solid ${PS.border}`, borderRadius: 14,
          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 4, color: '#fff'
        }}>
            {k === 'back' ? Ico.backspace(22, '#fff') :
          <>
                <span style={{ fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 22, color: '#fff' }}>{k}</span>
                {sub && <span style={{ fontFamily: PS.fontBody, fontWeight: 600, fontSize: 9, color: PS.textMuted, marginTop: 6 }}>{sub}</span>}
              </>
          }
          </button>
        )}
      </div>
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Send Step 2: Name it
// ─────────────────────────────────────────────────────────────────
function SendNameItScreen({ amount, label, setLabel, onBack, onSend }) {
  const charLeft = 35 - label.length;
  const filled = label.trim().length > 0;
  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 24px 8px' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, width: 32, height: 32, display: 'flex', alignItems: 'center' }}>
          {Ico.arrowLeft(24, '#fff')}
        </button>
        <button style={{ background: 'rgba(255,255,255,0.06)', border: `1px solid ${PS.border}`, borderRadius: '50%', width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          {Ico.help(18, '#fff')}
        </button>
      </div>

      <div style={{ flex: 1, padding: '20px 24px 0', display: 'flex', flexDirection: 'column' }}>
        <div style={{ fontFamily: PS.fontBody, fontSize: 13, color: PS.textMuted, marginBottom: 4 }}>
          Requesting <span style={{ color: PS.mint, fontWeight: 700 }}>€ {amount || '0,00'}</span>
        </div>
        <h1 style={{ fontFamily: PS.fontDisplay, fontWeight: 800, fontSize: 30, lineHeight: 1.15, color: '#fff', letterSpacing: '-0.02em', marginBottom: 28 }}>
          What is it for?
        </h1>

        <div style={{ position: 'relative', borderBottom: `1px solid ${filled ? PS.borderActive : 'rgba(255,255,255,0.12)'}`, paddingBottom: 8 }}>
          <input
            autoFocus
            maxLength={35}
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            placeholder="E.g. Dinner"
            style={{
              width: '100%', background: 'transparent', border: 'none', outline: 'none',
              fontFamily: PS.fontDisplay, fontWeight: 700, fontSize: 22,
              color: filled ? PS.mint : 'rgba(255,255,255,0.35)',
              caretColor: PS.mint, padding: 0
            }} />
          
        </div>

        <div style={{ flex: 1 }}></div>

        <div style={{ textAlign: 'right', fontFamily: PS.fontBody, fontWeight: 600, fontSize: 13, color: PS.textMuted, marginBottom: 12 }}>
          {charLeft}
        </div>
      </div>

      {/* Bottom action row */}
      <div style={{ padding: '0 16px 28px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={onSend} disabled={!filled} style={{
          flex: 1, height: 52, borderRadius: 100,
          background: filled ? PS.gradientPink : 'rgba(255,255,255,0.08)',
          border: 'none', cursor: filled ? 'pointer' : 'default',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          fontFamily: PS.fontBody, fontWeight: 700, fontSize: 15, color: '#fff',
          boxShadow: filled ? '0 8px 24px rgba(252,0,255,0.28)' : 'none'
        }}>
          {Ico.send(18, '#fff')} Share via WhatsApp
        </button>
        <button style={{
          width: 52, height: 52, borderRadius: '50%',
          background: filled ? 'rgba(7,216,221,0.15)' : 'rgba(255,255,255,0.06)',
          border: `1px solid ${filled ? 'rgba(7,216,221,0.3)' : PS.border}`,
          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>{Ico.qr(20, filled ? PS.mint : '#fff')}</button>
        <button style={{
          width: 52, height: 52, borderRadius: '50%',
          background: filled ? 'rgba(7,216,221,0.15)' : 'rgba(255,255,255,0.06)',
          border: `1px solid ${filled ? 'rgba(7,216,221,0.3)' : PS.border}`,
          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>{Ico.send(18, filled ? PS.mint : '#fff')}</button>
      </div>
    </div>);

}

// ─────────────────────────────────────────────────────────────────
// SCREEN — Welcome / Splash (entry to onboarding)
// ─────────────────────────────────────────────────────────────────
function WelcomeScreen({ onStart }) {
  return (
    <div style={{
      flex: 1, background: PS.bg, color: '#fff',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: PS.fontBody, position: 'relative'
    }}>
      {/* Glow background */}
      <div style={{
        position: 'absolute', top: '20%', left: '50%', transform: 'translate(-50%, -50%)',
        width: 400, height: 400, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(252,0,255,0.25) 0%, rgba(7,216,221,0.12) 50%, transparent 70%)',
        filter: 'blur(40px)'
      }}></div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px', position: 'relative', zIndex: 2 }}>
        <img src="assets/Emblem_Gradient.png" alt="" style={{ width: 110, height: 110, objectFit: 'contain', marginBottom: 28, filter: 'drop-shadow(0 16px 40px rgba(252,0,255,0.4))' }} />
        <h1 style={{ fontFamily: PS.fontDisplay, fontWeight: 900, fontSize: 48, color: '#fff', letterSpacing: '-0.04em', marginBottom: 14, textAlign: 'center' }}>
          <GradientText>Payspin</GradientText>
        </h1>
        <p style={{ fontFamily: PS.fontBody, fontSize: 15, color: PS.textBody, textAlign: 'center', lineHeight: 1.55, maxWidth: 280, marginBottom: 48 }}>
          Send and request money. <br />Your money, your community, your peace of mind.
        </p>
      </div>

      <div style={{ padding: '0 24px 36px', position: 'relative', zIndex: 2 }}>
        <GradientPillButton label="Get started" onClick={onStart} icon={Ico.arrowRight(20, '#fff')} />
        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <button onClick={onStart} style={{ background: 'none', border: 'none', cursor: 'pointer', fontFamily: PS.fontBody, fontWeight: 600, fontSize: 13, color: PS.textMuted }}>
            Already have an account? <span style={{ color: PS.mint }}>Log in</span>
          </button>
        </div>
      </div>
    </div>);

}

// ── Export to window ──────────────────────────────────────────────
Object.assign(window, {
  PS, Ico, GradientText, GradientCircleButton, GradientPillButton,
  WelcomeScreen,
  Step1Name, Step2Phone, Step3OTP, Step4IBAN, Step5FullName, SuccessScreen,
  HomeScreen, GroepiesScreen, ProfileScreen, ScanQRScreen,
  SendAmountScreen, SendNameItScreen, BottomNav
});