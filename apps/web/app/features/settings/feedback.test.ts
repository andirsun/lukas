import { describe, expect, it } from "vitest";
import { APP_VERSION, FEEDBACK_EMAIL, feedbackMailto } from "./feedback.ts";

describe("feedbackMailto", () => {
  it("writes to the founder's address, with the subject and body percent-encoded", () => {
    expect(FEEDBACK_EMAIL).toBe("lukitas@andersonlaverde.com");
    expect(
      feedbackMailto({
        subject: "Lukitas: comentarios",
        body: "\n\nVersión: 1.2.3\nIdioma: es",
      }),
    ).toBe(
      "mailto:lukitas@andersonlaverde.com?subject=Lukitas%3A%20comentarios&body=%0A%0AVersi%C3%B3n%3A%201.2.3%0AIdioma%3A%20es",
    );
  });

  it("encodes what could end the query early or start another header", () => {
    const link = feedbackMailto({ subject: "a&b=c", body: "x?y#z&cc=someone@else.com" });
    expect(link).toBe(
      "mailto:lukitas@andersonlaverde.com?subject=a%26b%3Dc&body=x%3Fy%23z%26cc%3Dsomeone%40else.com",
    );
    expect(new URL(link).searchParams.get("cc")).toBeNull();
  });

  it("has a version, even in a build that was not given one", () => {
    expect(APP_VERSION.length).toBeGreaterThan(0);
  });
});
