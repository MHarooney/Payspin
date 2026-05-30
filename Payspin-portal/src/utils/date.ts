import { Timestamp } from 'firebase/firestore';
import { FirebaseDateUtils } from './firebase-date';

/**
 * @deprecated Use FirebaseDateUtils.formatForDisplay instead
 */
export const formatDate = (date: Date | Timestamp | undefined | null): string => {
  if (!date) return 'N/A';
  return FirebaseDateUtils.formatForDisplay(
    date instanceof Timestamp ? date : FirebaseDateUtils.toTimestamp(date)
  );
};

/**
 * @deprecated Use FirebaseDateUtils.toDate instead
 */
export const timestampToDate = (timestamp: Timestamp | undefined | null): Date | undefined => {
  if (!timestamp) return undefined;
  const date = FirebaseDateUtils.toDate(timestamp);
  return date || undefined;
};

/**
 * @deprecated Use FirebaseDateUtils.toTimestamp instead
 */
export const dateToTimestamp = (date: Date | undefined | null): Timestamp | undefined => {
  if (!date) return undefined;
  return FirebaseDateUtils.toTimestamp(date) || undefined;
};

/**
 * @deprecated Use FirebaseDateUtils.now instead
 */
export const now = (): Timestamp => {
  return FirebaseDateUtils.now();
}; 