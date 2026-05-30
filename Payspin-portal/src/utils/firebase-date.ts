import { Timestamp } from 'firebase/firestore';
import { format, startOfMonth, endOfMonth, isValid, parseISO, isAfter, isBefore, isEqual } from 'date-fns';
import { utcToZonedTime } from 'date-fns-tz';

/**
 * Custom error class for Firebase date operations
 */
export class FirebaseDateError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FirebaseDateError';
  }
}

/**
 * Type guard for Timestamp
 */
export function isTimestamp(value: any): value is Timestamp {
  return value instanceof Timestamp;
}

/**
 * Interface for date range operations
 */
export interface DateRange {
  start: Timestamp;
  end: Timestamp;
}

/**
 * Utility class for handling Firebase Timestamp operations
 */
export class FirebaseDateUtils {
  private static readonly DEFAULT_TIMEZONE = 'UTC';

  /**
   * Converts a JavaScript Date to Firebase Timestamp
   * @throws {FirebaseDateError} If date is invalid
   */
  static toTimestamp(date: Date | null | undefined): Timestamp | null {
    if (!date) return null;
    if (!isValid(date)) {
      throw new FirebaseDateError('Invalid date provided');
    }
    return Timestamp.fromDate(date);
  }

  /**
   * Converts a Firebase Timestamp to JavaScript Date
   */
  static toDate(timestamp: Timestamp | null | undefined): Date | null {
    if (!timestamp) return null;
    if (!(timestamp instanceof Timestamp)) {
      throw new FirebaseDateError('Invalid Timestamp object provided');
    }
    return timestamp.toDate();
  }

  /**
   * Gets the first day of the month as a Timestamp
   * @param date Optional reference date, defaults to current date
   */
  static getFirstDayOfMonth(date: Date | Timestamp = Timestamp.now()): Timestamp {
    const inputDate = date instanceof Timestamp ? date.toDate() : date;
    return Timestamp.fromDate(startOfMonth(inputDate));
  }

  /**
   * Gets the last day of the month as a Timestamp
   * @param date Optional reference date, defaults to current date
   */
  static getLastDayOfMonth(date: Date | Timestamp = Timestamp.now()): Timestamp {
    const inputDate = date instanceof Timestamp ? date.toDate() : date;
    return Timestamp.fromDate(endOfMonth(inputDate));
  }

  /**
   * Creates a date range with start and end Timestamps
   */
  static createDateRange(start: Date, end: Date): DateRange {
    if (!isValid(start) || !isValid(end)) {
      throw new FirebaseDateError('Invalid date range');
    }
    if (start > end) {
      throw new FirebaseDateError('Start date must be before end date');
    }
    return {
      start: Timestamp.fromDate(start),
      end: Timestamp.fromDate(end)
    };
  }

  /**
   * Gets the current time as a Timestamp
   */
  static now(): Timestamp {
    return Timestamp.now();
  }

  /**
   * Formats a Timestamp for display
   * @param timestamp The timestamp to format
   * @param formatStr Optional format string (date-fns format)
   */
  static formatForDisplay(
    timestamp: Timestamp | null | undefined,
    formatStr: string = 'MMM dd, yyyy'
  ): string {
    if (!timestamp) return 'N/A';
    return format(timestamp.toDate(), formatStr);
  }

  /**
   * Converts a Timestamp to local timezone
   */
  static toLocalTime(timestamp: Timestamp | null | undefined): Date | null {
    if (!timestamp) return null;
    const utcDate = timestamp.toDate();
    return utcToZonedTime(utcDate, Intl.DateTimeFormat().resolvedOptions().timeZone);
  }

  /**
   * Converts a local date to UTC Timestamp
   */
  static toUTCTimestamp(localDate: Date): Timestamp {
    if (!isValid(localDate)) {
      throw new FirebaseDateError('Invalid local date');
    }
    const utcDate = utcToZonedTime(
      localDate,
      Intl.DateTimeFormat().resolvedOptions().timeZone
    );
    return Timestamp.fromDate(utcDate);
  }

  /**
   * Safely parses an ISO date string to Timestamp
   */
  static parseISOString(isoString: string): Timestamp {
    const date = parseISO(isoString);
    if (!isValid(date)) {
      throw new FirebaseDateError('Invalid ISO date string');
    }
    return Timestamp.fromDate(date);
  }

  /**
   * Compares two timestamps
   * @returns negative if t1 < t2, 0 if equal, positive if t1 > t2
   */
  static compare(a: Timestamp | null, b: Timestamp | null): number {
    if (a === null && b === null) return 0;
    if (a === null) return -1;
    if (b === null) return 1;

    const dateA = a.toDate();
    const dateB = b.toDate();

    if (isEqual(dateA, dateB)) return 0;
    if (isBefore(dateA, dateB)) return -1;
    return 1;
  }

  /**
   * Checks if a timestamp is between two other timestamps
   */
  static isBetween(
    timestamp: Timestamp,
    start: Timestamp,
    end: Timestamp,
    inclusive: boolean = true
  ): boolean {
    if (inclusive) {
      return this.compare(timestamp, start) >= 0 && this.compare(timestamp, end) <= 0;
    }
    return this.compare(timestamp, start) > 0 && this.compare(timestamp, end) < 0;
  }

  static fromDate(date: Date): Timestamp {
    if (!(date instanceof Date)) {
      throw new FirebaseDateError('Invalid date object provided');
    }
    return Timestamp.fromDate(date);
  }

  static fromISO(isoString: string, timezone: string = FirebaseDateUtils.DEFAULT_TIMEZONE): Timestamp {
    try {
      const date = parseISO(isoString);
      const zonedDate = utcToZonedTime(date, timezone);
      return Timestamp.fromDate(zonedDate);
    } catch (error) {
      throw new FirebaseDateError(`Invalid ISO string provided: ${isoString}`);
    }
  }

  static toISO(timestamp: Timestamp | null, timezone: string = FirebaseDateUtils.DEFAULT_TIMEZONE): string | null {
    if (!timestamp) return null;
    const date = timestamp.toDate();
    const zonedDate = utcToZonedTime(date, timezone);
    return zonedDate.toISOString();
  }

  static isAfter(date: Timestamp | null, compareDate: Timestamp | null): boolean {
    if (!date || !compareDate) return false;
    return isAfter(date.toDate(), compareDate.toDate());
  }

  static isBefore(date: Timestamp | null, compareDate: Timestamp | null): boolean {
    if (!date || !compareDate) return false;
    return isBefore(date.toDate(), compareDate.toDate());
  }

  static isEqual(date: Timestamp | null, compareDate: Timestamp | null): boolean {
    if (date === null && compareDate === null) return true;
    if (!date || !compareDate) return false;
    return isEqual(date.toDate(), compareDate.toDate());
  }

  static validateTimestamp(timestamp: unknown): timestamp is Timestamp {
    return timestamp instanceof Timestamp &&
           typeof timestamp.seconds === 'number' &&
           typeof timestamp.nanoseconds === 'number';
  }
} 