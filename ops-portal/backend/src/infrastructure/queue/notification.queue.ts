// Shared with the main backend's NotificationProcessor (backend/src/infrastructure/
// queue/notification.processor.ts). Ops is producer-only: it enqueues "push" jobs
// onto this queue and the main backend worker delivers them via FCM.
export const NOTIFICATIONS_QUEUE = 'notifications';

export interface PushJob {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}
