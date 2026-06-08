export interface NavItem {
  href: string;
  label: string;
  icon: string;
  title: string;
  badgeKey?: 'compliance' | 'messages';
}

export interface NavSection {
  section: string;
  items: NavItem[];
}

export const NAV: NavSection[] = [
  {
    section: 'Overview',
    items: [
      { href: '/', label: 'Dashboard', icon: '▦', title: 'Dashboard' },
      { href: '/reports', label: 'Reports', icon: '📊', title: 'Reports' },
    ],
  },
  {
    section: 'Operations',
    items: [
      { href: '/transactions', label: 'Transactions', icon: '⇄', title: 'Transactions' },
      { href: '/payment-links', label: 'Payment Links', icon: '🔗', title: 'Payment Links' },
      { href: '/webhooks', label: 'Webhooks', icon: '⚡', title: 'Webhooks' },
      { href: '/circles', label: 'Circles / ROSCA', icon: '◎', title: 'Circles / ROSCA' },
      { href: '/users', label: 'Users / KYC', icon: '◍', title: 'Users / KYC' },
      { href: '/compliance', label: 'Compliance', icon: '⚠', title: 'Compliance & AML', badgeKey: 'compliance' },
      { href: '/disputes', label: 'Disputes', icon: '⚖', title: 'Disputes & Escrow' },
      { href: '/finance', label: 'Reconciliation', icon: '€', title: 'Reconciliation' },
      { href: '/messages', label: 'Messages', icon: '✉', title: 'Messages', badgeKey: 'messages' },
    ],
  },
  {
    section: 'Platform',
    items: [
      { href: '/system', label: 'System Health', icon: '◈', title: 'System Health' },
      { href: '/testing', label: 'Test Center', icon: '🧪', title: 'Test Center' },
      { href: '/app-controls', label: 'App Controls', icon: '📱', title: 'App Controls' },
      { href: '/config', label: 'Config & Flags', icon: '⚙', title: 'Config & Flags' },
      { href: '/audit', label: 'Audit Log', icon: '▤', title: 'Audit Log' },
    ],
  },
  {
    section: 'Data',
    items: [
      { href: '/data/schema', label: 'Schema', icon: '◫', title: 'Schema & Relations' },
      { href: '/data/tables', label: 'Table Browser', icon: '⊞', title: 'Table Explorer' },
    ],
  },
  {
    section: 'Settings',
    items: [
      { href: '/admin-users', label: 'Admin users', icon: '👥', title: 'Admin users' },
    ],
  },
];

export function titleForPath(path: string): string {
  for (const s of NAV) {
    for (const i of s.items) {
      if (i.href === path) return i.title;
    }
  }
  // Detail routes fall back to the section prefix.
  if (path.startsWith('/transactions')) return 'Transactions';
  if (path.startsWith('/payment-links')) return 'Payment Links';
  if (path.startsWith('/webhooks')) return 'Webhooks';
  if (path.startsWith('/circles')) return 'Circles / ROSCA';
  if (path.startsWith('/users')) return 'Users / KYC';
  if (path.startsWith('/data/schema')) return 'Schema & Relations';
  if (path.startsWith('/data/tables')) return 'Table Explorer';
  if (path.startsWith('/data')) return 'Data Explorer';
  if (path.startsWith('/admin-users')) return 'Admin users';
  if (path.startsWith('/testing')) return 'Test Center';
  return 'Ops';
}
