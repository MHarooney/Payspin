import {
  SupportCategory,
  SupportMessageView,
  SupportThreadView,
  SupportThreadWithMessages,
} from '@payspin/shared-types';

interface MessageRow {
  id: string;
  direction: string;
  body: string;
  authorName: string;
  createdAt: Date;
}

interface ThreadRow {
  id: string;
  subjectName: string;
  category: string | null;
  contextRef: string | null;
  status: string;
  userUnread: boolean;
  lastMessageAt: Date;
  createdAt: Date;
}

interface UserRow {
  email: string;
  displayName: string | null;
  phoneE164?: string | null;
}

const CATEGORY_LABELS: Record<SupportCategory, string> = {
  PAYMENT: 'Payment issue',
  ACCOUNT: 'Account',
  CIRCLE: 'Circle',
  OTHER: 'Other',
};

/** Shared shaping for consumer support threads/messages. */
export class SupportMapper {
  static categoryLabel(category?: SupportCategory | null): string | null {
    return category ? CATEGORY_LABELS[category] : null;
  }

  /** Friendly author name for the user's own (IN) messages. */
  static authorName(user: UserRow): string {
    const name = user.displayName?.trim();
    if (name) return name;
    if (user.email && !user.email.includes('@')) return user.email;
    return user.email?.split('@')[0] ?? 'You';
  }

  /** Stable identity line shown to admins (email / phone / short id). */
  static userRef(user: UserRow, userId: string): string {
    return user.email || user.phoneE164 || `User ${userId.slice(0, 8)}`;
  }

  /** Admin-facing context line, e.g. "Karim Demir · Payment issue · ref abc123". */
  static buildMeta(
    user: UserRow,
    category?: SupportCategory | null,
    contextRef?: string | null,
  ): string | null {
    const parts = [
      user.displayName?.trim() || undefined,
      this.categoryLabel(category) || undefined,
      contextRef ? `ref ${contextRef}` : undefined,
    ].filter((p): p is string => Boolean(p));
    return parts.length > 0 ? parts.join(' · ') : null;
  }

  static toMessage(m: MessageRow): SupportMessageView {
    return {
      id: m.id,
      direction: m.direction === 'OUT' ? 'OUT' : 'IN',
      body: m.body,
      authorName: m.authorName,
      createdAt: m.createdAt.toISOString(),
    };
  }

  static toView(t: ThreadRow, preview: string): SupportThreadView {
    return {
      id: t.id,
      subject: t.subjectName,
      category: (t.category ?? null) as SupportCategory | null,
      contextRef: t.contextRef ?? null,
      status: t.status,
      userUnread: t.userUnread,
      preview,
      lastMessageAt: t.lastMessageAt.toISOString(),
      createdAt: t.createdAt.toISOString(),
    };
  }

  static toDetail(t: ThreadRow & { messages: MessageRow[] }): SupportThreadWithMessages {
    const messages = t.messages.map((m) => this.toMessage(m));
    const preview = messages[messages.length - 1]?.body ?? '';
    return { ...this.toView(t, preview), messages };
  }
}
