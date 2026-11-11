const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: string): boolean {
  return UUID_RE.test(value);
}

export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const RECORD_STATUSES = ["active", "paused", "offboarded"] as const;
export type RecordStatus = (typeof RECORD_STATUSES)[number];

export function isRecordStatus(value: string): value is RecordStatus {
  return (RECORD_STATUSES as readonly string[]).includes(value);
}

// Suggestions for the timezone field. "UTC" and "Asia/Kolkata" are added
// by hand because supportedValuesOf() omits UTC and lists India as the
// older canonical name "Asia/Calcutta".
export function getTimeZones(): string[] {
  const zones = Intl.supportedValuesOf("timeZone");
  return Array.from(new Set(["UTC", "Asia/Kolkata", ...zones])).sort();
}

export function isValidTimeZone(value: string): boolean {
  // Regex first: stops offset-style values like "+05:00" that Intl accepts
  // but aren't IANA names.
  if (!/^(UTC|[A-Za-z]+(\/[A-Za-z0-9_+-]+)+)$/.test(value)) return false;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: value });
    return true;
  } catch {
    return false;
  }
}