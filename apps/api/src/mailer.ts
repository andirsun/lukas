import nodemailer from "nodemailer";
import type SMTPTransport from "nodemailer/lib/smtp-transport/index.js";
import { Resend } from "resend";

export interface Mail {
  to: string;
  subject: string;
  text: string;
  html: string;
}

export interface Mailer {
  send(mail: Mail): Promise<void>;
}

/**
 * Refuses an address under the `.invalid` TLD (RFC 2606: it never resolves). Guests have placeholder
 * emails under guest.lukitas.invalid, and nothing may ever be mailed there; every mailer checks
 * this before it touches the network.
 */
export function assertDeliverable(to: string): void {
  const address = to.trim().toLowerCase().replace(/\.+$/, "");
  if (address.endsWith(".invalid")) {
    throw new Error("Refusing to mail an address under .invalid (a guest's placeholder email)");
  }
}

export class ResendMailer implements Mailer {
  private readonly resend: Resend;
  constructor(
    apiKey: string,
    private readonly from: string,
  ) {
    this.resend = new Resend(apiKey);
  }
  async send(mail: Mail): Promise<void> {
    assertDeliverable(mail.to);
    const { error } = await this.resend.emails.send({ from: this.from, ...mail });
    if (error) throw new Error(`Resend failed: ${error.message}`);
  }
}

export interface SmtpOptions {
  /**
   * Accept a self-signed certificate (Proton Bridge's), but still require STARTTLS so nothing,
   * credentials included, travels in clear text. Applies to this transport only.
   */
  tlsInsecure?: boolean | undefined;
}

/**
 * What to hand to nodemailer for an SMTP URL. By default the URL itself, so nodemailer's own checks
 * apply. With `tlsInsecure` the URL is read into options (nodemailer takes extra settings only
 * next to options, not next to a URL) and the TLS settings are added.
 */
export function smtpTransport(
  url: string,
  { tlsInsecure }: SmtpOptions,
): string | SMTPTransport.Options {
  if (!tlsInsecure) return url;
  const parsed = new URL(url);
  const secure = parsed.protocol === "smtps:";
  return {
    host: parsed.hostname.replace(/^\[|\]$/g, ""),
    port: parsed.port ? Number(parsed.port) : secure ? 465 : 587,
    secure,
    ...(parsed.username
      ? {
          auth: {
            user: decodeURIComponent(parsed.username),
            pass: decodeURIComponent(parsed.password),
          },
        }
      : {}),
    requireTLS: true,
    tls: { rejectUnauthorized: false },
  };
}

/** SMTP delivery: Mailpit in development, Proton Bridge for a personal install. */
export class SmtpMailer implements Mailer {
  private readonly transport: nodemailer.Transporter;
  constructor(
    url: string,
    private readonly from: string,
    options: SmtpOptions = {},
  ) {
    this.transport = nodemailer.createTransport(smtpTransport(url, options));
  }
  async send(mail: Mail): Promise<void> {
    assertDeliverable(mail.to);
    await this.transport.sendMail({ from: this.from, ...mail });
  }
}

/** Keeps mails in memory; for tests. */
export class MemoryMailer implements Mailer {
  readonly sent: Mail[] = [];
  async send(mail: Mail): Promise<void> {
    assertDeliverable(mail.to);
    this.sent.push(mail);
  }
  lastTo(email: string): Mail | undefined {
    return this.sent.findLast((m) => m.to === email);
  }
}
