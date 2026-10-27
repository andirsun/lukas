import { expect, it } from "vitest";
import { formatDate } from "./RecurringPage.tsx";

it("writes a recurring date in it-IT and pt-PT, as the app does", () => {
  expect(formatDate("2026-10-23", "it")).toBe("23 ott 2026");
  expect(formatDate("2026-10-23", "pt")).toBe("23/10/2026");
});
