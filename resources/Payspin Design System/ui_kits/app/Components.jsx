/* Payspin App UI Kit — Shared Components */
/* Load via: <script type="text/babel" src="Components.jsx"></script> */

// ── Design Tokens ─────────────────────────────────────────────────
const T = {
  primary:       '#FC00FF',
  primaryLight:  '#D94DF8',
  secondary:     '#07D8DD',
  secondaryDark: '#008D8F',
  purpleMid:     '#65558F',
  bgPage:        '#F9F9F9',
  surface:       '#FFFFFF',
  border:        '#F5F5F5',
  borderMid:     '#EDF1F3',
  textHeading:   '#212B36',
  textBody:      '#263238',
  textSecondary: '#6C7278',
  textMuted:     '#606060',
  textPrimary:   '#0A0D13',
  gradientBrand: 'linear-gradient(180deg, #FC00FF 0%, #07D8DD 100%)',
  gradientH:     'linear-gradient(90deg,  #FC00FF 0%, #07D8DD 100%)',
  shadowCard:    '0px 8px 16px 0px rgba(0,0,0,0.08)',
  shadowStrong:  '0px 8px 16px 0px rgba(0,0,0,0.24)',
};

// ── Status Bar ─────────────────────────────────────────────────────
function StatusBar({ dark = false }) {
  const c = dark ? '#fff' : '#0A0D13';
  return (
    <div style={{ height: 44, background: dark ? 'transparent' : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 20px', flexShrink: 0 }}>
      <span style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter,sans-serif', color: c }}>9:41</span>
      <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
        <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
          <rect x="0" y="3" width="3" height="9" rx="1" fill={c} opacity="0.4"/>
          <rect x="4.5" y="2" width="3" height="10" rx="1" fill={c} opacity="0.6"/>
          <rect x="9" y="0" width="3" height="12" rx="1" fill={c}/>
          <rect x="14" y="2" width="2" height="8" rx="1" fill={c} stroke={c} strokeWidth="0.5" fillOpacity="0.2"/>
        </svg>
        <svg width="16" height="12" viewBox="0 0 24 18" fill={c}><path d="M12 3.75C8.5 3.75 5.35 5.1 3 7.35L1.5 5.85C4.25 3.15 8 1.5 12 1.5s7.75 1.65 10.5 4.35L21 7.35C18.65 5.1 15.5 3.75 12 3.75zM12 8.25c-2.25 0-4.3.9-5.8 2.35L4.7 9.1A10.45 10.45 0 0112 6c2.9 0 5.55 1.15 7.5 3.05l-1.5 1.5C16.5 9.1 14.35 8.25 12 8.25zM12 12.75c-1.25 0-2.4.5-3.25 1.3L12 17.25l3.25-3.2A4.6 4.6 0 0012 12.75z"/></svg>
        <svg width="25" height="12" viewBox="0 0 25 12" fill="none">
          <rect x="0.5" y="0.5" width="21" height="11" rx="3.5" stroke={c} strokeOpacity="0.35"/>
          <rect x="2" y="2" width="16" height="8" rx="2" fill={c}/>
          <path d="M23 4v4a2 2 0 0 0 0-4z" fill={c} fillOpacity="0.4"/>
        </svg>
      </div>
    </div>
  );
}

// ── Home Indicator ─────────────────────────────────────────────────
function HomeIndicator() {
  return (
    <div style={{ height: 34, background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ width: 134, height: 5, background: '#0A0D13', borderRadius: 100 }}></div>
    </div>
  );
}

// ── Top Bar ────────────────────────────────────────────────────────
function TopBar({ title, onBack, rightIcon, centerTitle = false }) {
  return (
    <div style={{ height: 56, background: '#fff', display: 'flex', alignItems: 'center', padding: '0 16px', borderBottom: '1px solid #F5F5F5', flexShrink: 0, gap: 12 }}>
      {onBack && (
        <button onClick={onBack} style={{ background: 'none', border: 'none', padding: 0, cursor: 'pointer', width: 24, height: 24, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={T.textPrimary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M19 12H5M12 5l-7 7 7 7"/>
          </svg>
        </button>
      )}
      <span style={{ fontFamily: 'Raleway,sans-serif', fontWeight: 700, fontSize: centerTitle ? 18 : 22, color: T.textHeading, flex: 1, textAlign: centerTitle ? 'center' : 'left', lineHeight: 1 }}>
        {title}
      </span>
      {rightIcon}
    </div>
  );
}

// ── Bottom Nav ─────────────────────────────────────────────────────
function BottomNav({ active = 'home', onNav }) {
  const items = [
    { id: 'home',    label: 'Home',    icon: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg> },
    { id: 'circles', label: 'Circles', icon: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg> },
    { id: 'profile', label: 'Profile', icon: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round"><circle cx="12" cy="8" r="4"/><path d="M6 20v-2a6 6 0 0 1 12 0v2"/></svg> },
    { id: 'settings',label: 'Settings',icon: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg> },
  ];
  return (
    <div style={{ height: 72, background: '#fff', display: 'flex', borderTop: '1px solid #F5F5F5', flexShrink: 0 }}>
      {items.map(item => {
        const isActive = item.id === active;
        const color = isActive ? T.primaryLight : '#9199A0';
        return (
          <button key={item.id} onClick={() => onNav && onNav(item.id)} style={{ flex: 1, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3, padding: 0 }}>
            {item.icon(color)}
            <span style={{ fontFamily: 'Inter,sans-serif', fontSize: 10, fontWeight: isActive ? 600 : 500, color }}>{item.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── Primary Button ─────────────────────────────────────────────────
function PrimaryButton({ label, onClick, color = T.primary, textColor = '#fff', size = 'lg' }) {
  const h = size === 'lg' ? 56 : size === 'md' ? 48 : 40;
  const fs = size === 'lg' ? 16 : 14;
  return (
    <button onClick={onClick} style={{ width: '100%', height: h, borderRadius: 100, background: color, color: textColor, fontFamily: 'Inter,sans-serif', fontWeight: 700, fontSize: fs, border: 'none', cursor: 'pointer', boxShadow: T.shadowCard, letterSpacing: '-0.01em' }}>
      {label}
    </button>
  );
}

// ── Input Field ────────────────────────────────────────────────────
function InputField({ label, value, placeholder, type = 'text', active = false }) {
  return (
    <div style={{ background: '#fff', border: `1px solid ${active ? T.primaryLight : T.borderMid}`, borderRadius: 10, boxShadow: '0px 1px 2px rgba(228,229,231,0.24)', height: 56, padding: '0 14px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
      {label && <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 11, color: '#9199A0', marginBottom: 2 }}>{label}</div>}
      <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 14, fontWeight: 500, color: value ? T.textPrimary : '#9199A0', letterSpacing: '-0.01em' }}>
        {value || placeholder}
      </div>
    </div>
  );
}

// ── Avatar ─────────────────────────────────────────────────────────
function Avatar({ size = 48, initials = '?', color = T.primaryLight }) {
  return (
    <div style={{ width: size, height: size, borderRadius: '50%', background: `linear-gradient(135deg, ${color}, ${T.secondary})`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
      <span style={{ fontFamily: 'Inter,sans-serif', fontSize: size * 0.35, fontWeight: 700, color: '#fff' }}>{initials}</span>
    </div>
  );
}

// ── Circle Card ────────────────────────────────────────────────────
function CircleCard({ adminName, circleName, total, monthly, duration, progress = 0.35, startDate, endDate }) {
  return (
    <div style={{ background: '#fff', borderRadius: 16, border: `1px solid ${T.border}`, boxShadow: T.shadowCard, padding: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
        <Avatar initials={adminName?.[0] || '?'} />
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Raleway,sans-serif', fontWeight: 700, fontSize: 15, color: T.textHeading }}>{adminName} — <span style={{ fontWeight: 600, color: T.textSecondary }}>"{circleName}"</span></div>
          <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 11, color: T.textSecondary, marginTop: 2 }}>Admin</div>
        </div>
        <div style={{ background: '#F7F2FA', borderRadius: 100, padding: '4px 10px' }}>
          <span style={{ fontFamily: 'Inter,sans-serif', fontSize: 10, fontWeight: 500, color: T.textMuted }}>{endDate}</span>
        </div>
      </div>
      <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 22, fontWeight: 700, color: T.textPrimary, letterSpacing: '0.2px', marginBottom: 8 }}>{total}</div>
      <div style={{ height: 8, borderRadius: 8, background: T.borderMid, overflow: 'hidden', marginBottom: 8 }}>
        <div style={{ height: '100%', borderRadius: 8, width: `${progress * 100}%`, background: 'linear-gradient(90deg, #D94DF8 0%, #6B96EA 56%, #48ADE5 75%, #07D8DD 100%)' }}></div>
      </div>
      <div style={{ display: 'flex', gap: 20 }}>
        {[['Monthly', monthly], ['Duration', duration], ['Started', startDate]].map(([k, v]) => (
          <div key={k}>
            <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 10, color: '#9199A0' }}>{k}</div>
            <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 12, fontWeight: 600, color: T.textBody }}>{v}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Banner Card ────────────────────────────────────────────────────
function BannerCard({ title, subtitle, ctaLabel, bg = '#008D8F' }) {
  return (
    <div style={{ background: bg, borderRadius: 16, padding: '16px 16px 16px 16px', color: '#fff', position: 'relative', overflow: 'hidden' }}>
      <div style={{ fontFamily: 'Raleway,sans-serif', fontWeight: 700, fontSize: 18, marginBottom: 6 }}>{title}</div>
      <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 12, opacity: 0.85, lineHeight: 1.5, maxWidth: '70%', marginBottom: 10 }}>{subtitle}</div>
      {ctaLabel && (
        <button style={{ background: 'rgba(234,255,255,0.2)', color: '#fff', border: '1px solid rgba(255,255,255,0.3)', borderRadius: 100, height: 30, padding: '0 16px', fontSize: 12, fontWeight: 700, fontFamily: 'Inter,sans-serif', cursor: 'pointer' }}>
          {ctaLabel}
        </button>
      )}
    </div>
  );
}

// ── Stepper ────────────────────────────────────────────────────────
function Stepper({ step = 1, total = 3 }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 20px' }}>
      {Array.from({ length: total }, (_, i) => (
        <React.Fragment key={i}>
          <div style={{ width: 44, height: 44, borderRadius: '50%', background: i + 1 <= step ? T.primaryLight : '#fff', border: `1.5px solid ${T.primaryLight}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <span style={{ fontFamily: 'Inter,sans-serif', fontWeight: 700, fontSize: 16, color: i + 1 <= step ? '#fff' : T.primaryLight }}>{i + 1}</span>
          </div>
          {i < total - 1 && <div style={{ flex: 1, height: 2, background: T.secondary, margin: '0 4px' }}></div>}
        </React.Fragment>
      ))}
    </div>
  );
}

// ── Contributor Row ────────────────────────────────────────────────
function ContributorRow({ rank, name, amount, paid = false }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: `1px solid ${T.border}` }}>
      <Avatar size={40} initials={name?.[0] || '?'} color={paid ? T.secondary : T.primaryLight} />
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 13, fontWeight: 600, color: T.textHeading }}>{rank} — {name}</div>
      </div>
      <div style={{ fontFamily: 'Inter,sans-serif', fontSize: 13, fontWeight: 700, color: paid ? T.secondaryDark : T.primaryLight }}>{amount}</div>
      <div style={{ width: 8, height: 8, borderRadius: '50%', background: paid ? T.secondary : T.border }}></div>
    </div>
  );
}

// ── Dots Indicator ─────────────────────────────────────────────────
function DotsIndicator({ count = 3, active = 0 }) {
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center', justifyContent: 'center' }}>
      {Array.from({ length: count }, (_, i) => (
        <div key={i} style={{ width: i === active ? 24 : 6, height: 6, borderRadius: 20, background: i === active ? '#F465F6' : '#D9D9D9', transition: 'width 0.2s' }}></div>
      ))}
    </div>
  );
}

// ── Export to window ───────────────────────────────────────────────
Object.assign(window, {
  T,
  StatusBar, HomeIndicator, TopBar, BottomNav,
  PrimaryButton, InputField, Avatar,
  CircleCard, BannerCard, Stepper,
  ContributorRow, DotsIndicator,
});
