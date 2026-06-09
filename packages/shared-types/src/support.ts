// Consumer-facing support chat DTOs. Used by backend (/v1/support response shapes),
// the mobile app, and shared with the ops admin DTOs in admin.ts. Framework-agnostic.

export type SupportCategory = 'PAYMENT' | 'ACCOUNT' | 'CIRCLE' | 'OTHER';

export type SupportThreadStatus = 'OPEN' | 'RESOLVED';

/** A single message in a thread. `IN` = user→admin, `OUT` = admin→user. */
export interface SupportMessageView {
  id: string;
  direction: 'IN' | 'OUT';
  body: string;
  authorName: string;
  createdAt: string;
}

/** Thread summary for the user's inbox. */
export interface SupportThreadView {
  id: string;
  subject: string;
  category: SupportCategory | null;
  contextRef: string | null;
  status: string;
  /** User has an unread admin (OUT) reply. */
  userUnread: boolean;
  preview: string;
  lastMessageAt: string;
  createdAt: string;
}

export interface SupportThreadWithMessages extends SupportThreadView {
  messages: SupportMessageView[];
}

export interface CreateSupportThreadInput {
  subject?: string;
  category?: SupportCategory;
  body: string;
  contextRef?: string;
}

export interface SendSupportMessageInput {
  body: string;
}

export interface SupportUnreadCount {
  count: number;
}
