import { describe, expect, test } from "vitest";
import { SmtpMailer, smtpTransport } from "../src/mailer.ts";

/** What nodemailer ended up using for the connection. */
const optionsOf = (mailer: SmtpMailer) =>
  (mailer as unknown as { transport: { transporter: { options: Record<string, unknown> } } })
    .transport.transporter.options;

describe("SMTP transport TLS", () => {
  test("by default the URL goes to nodemailer as is, with its own certificate checks", () => {
    expect(smtpTransport("smtp://mail.example.com:587", {})).toBe("smtp://mail.example.com:587");
    expect(smtpTransport("smtp://mail.example.com:587", { tlsInsecure: false })).toBe(
      "smtp://mail.example.com:587",
    );
    const options = optionsOf(new SmtpMailer("smtp://mail.example.com:587", "a@b.test"));
    expect(options.tls).toBeUndefined();
    expect(options.requireTLS).toBeUndefined();
  });

  test("tlsInsecure accepts a self-signed certificate, and still insists on STARTTLS", () => {
    expect(
      smtpTransport("smtp://hola%40andersonlaverde.com:p%40ss%2Fword@host.docker.internal:1025", {
        tlsInsecure: true,
      }),
    ).toEqual({
      host: "host.docker.internal",
      port: 1025,
      secure: false,
      auth: { user: "hola@andersonlaverde.com", pass: "p@ss/word" },
      requireTLS: true,
      tls: { rejectUnauthorized: false },
    });
    const options = optionsOf(
      new SmtpMailer("smtp://u:p@host.docker.internal:1025", "a@b.test", { tlsInsecure: true }),
    );
    expect(options).toMatchObject({
      host: "host.docker.internal",
      port: 1025,
      requireTLS: true,
      tls: { rejectUnauthorized: false },
      auth: { user: "u", pass: "p" },
    });
  });

  test("no credentials in the URL means no auth; an IPv6 host loses its brackets", () => {
    expect(smtpTransport("smtp://[::1]:1025", { tlsInsecure: true })).toEqual({
      host: "::1",
      port: 1025,
      secure: false,
      requireTLS: true,
      tls: { rejectUnauthorized: false },
    });
  });

  test("the option belongs to one mailer: another one keeps the default checks", () => {
    new SmtpMailer("smtp://localhost:1025", "a@b.test", { tlsInsecure: true });
    const other = optionsOf(new SmtpMailer("smtp://localhost:1025", "a@b.test"));
    expect(other.tls).toBeUndefined();
  });
});
