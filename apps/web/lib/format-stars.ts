/**
 * Star count formatting utilities for consistent display across the site.
 */

/**
 * Formats a number into a human-readable star count.
 *
 * @param count - The raw star count number
 * @returns Formatted string (e.g., "1.4K", "891", "2.3M")
 */
export function formatStarCount(count: number): string {
  // Handle edge cases
  if (!Number.isFinite(count)) {
    return String(count);
  }

  // Millions
  if (count >= 1_000_000) {
    const formatted = (count / 1_000_000).toFixed(1);
    return formatted.replace(/\.0$/, "") + "M";
  }

  // Thousands
  if (count >= 1_000) {
    const formatted = (count / 1_000).toFixed(1);
    return formatted.replace(/\.0$/, "") + "K";
  }

  // Small numbers - return as-is
  return count.toString();
}

/**
 * Returns the full number for accessibility (aria-label use).
 * Uses locale formatting for proper thousand separators.
 */
export function formatStarCountFull(count: number): string {
  if (!Number.isFinite(count)) {
    return String(count);
  }
  return count.toLocaleString("en-US");
}

/**
 * Parses a formatted star count string back to a number.
 * Returns 0 for invalid input to prevent NaN propagation.
 */
export function parseStarCount(formatted: string): number {
  const trimmed = formatted.trim();

  // Handle empty or invalid input
  if (!trimmed) return 0;

  let result: number;

  if (trimmed.endsWith("M")) {
    result = parseFloat(trimmed.slice(0, -1)) * 1_000_000;
  } else if (trimmed.endsWith("K")) {
    result = parseFloat(trimmed.slice(0, -1)) * 1_000;
  } else {
    result = parseFloat(trimmed.replace(/,/g, ""));
  }

  // Return 0 for NaN to prevent issues in consuming code
  return Number.isFinite(result) ? result : 0;
}
