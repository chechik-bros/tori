/**
 * Israeli phone numbers are stored as 972XXXXXXXXX (no plus, no leading zero).
 * Mobile numbers have 9 digits after 972, landlines have 8.
 */

/** Converts user input like "050-123 4567" or "+972501234567" to "972501234567". Returns null if invalid. */
export function normalizeIsraeliPhone(input: string): string | null {
  const digits = input.replace(/\D/g, "");

  let local: string;
  if (digits.startsWith("972")) local = digits.slice(3);
  else if (digits.startsWith("0")) local = digits.slice(1);
  else return null;

  // People sometimes type "+972 050..." with the zero kept.
  if (local.startsWith("0")) local = local.slice(1);

  if (!/^[2-9]\d{7,8}$/.test(local)) return null;
  return `972${local}`;
}

/** Converts "972501234567" to "050-1234567" for display. */
export function formatIsraeliPhone(phone: string): string {
  const local = phone.startsWith("972") ? phone.slice(3) : phone;
  if (local.length === 9) return `0${local.slice(0, 2)}-${local.slice(2)}`;
  if (local.length === 8) return `0${local[0]}-${local.slice(1)}`;
  return phone;
}
