/** Scans per user per UTC day. Each one is a paid OpenAI request. */
export const dailyScanLimit = 20;

/** A user's count in `scanUsage/{uid}`, for one UTC day. */
export interface ScanUsage {
  /** "2026-10-06" */
  day: string;
  count: number;
}

export function utcDay(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/** When the count starts again. Also the document's TTL, so old counts get cleaned up. */
export function nextUTCMidnight(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1));
}

/** The stored usage, or `undefined` when there's none or it isn't in the expected shape. */
export function readUsage(data: unknown): ScanUsage | undefined {
  if (typeof data !== "object" || data === null) return undefined;
  const { day, count } = data as Record<string, unknown>;
  if (typeof day !== "string" || typeof count !== "number" || !Number.isInteger(count) || count < 0) {
    return undefined;
  }
  return { day, count };
}

/** The usage with one more scan today, or `null` when today's limit is reached. */
export function countedScan(usage: ScanUsage | undefined, now: Date): ScanUsage | null {
  const day = utcDay(now);
  const count = usage?.day === day ? usage.count : 0;
  return count < dailyScanLimit ? { day, count: count + 1 } : null;
}

/**
 * The usage with a scan given back, after a scan that failed on OpenAI's side, or `null`
 * when there's nothing to give back because the day has already moved on.
 */
export function refundedScan(usage: ScanUsage | undefined, day: string): ScanUsage | null {
  return usage?.day === day && usage.count > 0 ? { day, count: usage.count - 1 } : null;
}
