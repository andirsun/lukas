import nodemailer from "nodemailer";
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

export class ResendMailer implements Mailer {
  private readonly resend: Resend;
  constructor(
    apiKey: string,
    private readonly from: string,
  ) {
    this.resend = new Resend(apiKey);
  }
  async send(mail: Mail): Promise<void> {
    const { error } = await this.resend.emails.send({ from: this.from, ...mail });
    if (error) throw new Error(`Resend failed: ${error.message}`);
  }
}

/** SMTP delivery, used locally with Mailpit. */
export class SmtpMailer implements Mailer {
  private readonly transport: nodemailer.Transporter;
  constructor(
    url: string,
    private readonly from: string,
  ) {
    this.transport = nodemailer.createTransport(url);
  }
  async send(mail: Mail): Promise<void> {
    await this.transport.sendMail({ from: this.from, ...mail });
  }
}

/** Keeps mails in memory; for tests. */
export class MemoryMailer implements Mailer {
  readonly sent: Mail[] = [];
  async send(mail: Mail): Promise<void> {
    this.sent.push(mail);
  }
  lastTo(email: string): Mail | undefined {
    return this.sent.findLast((m) => m.to === email);
  }
}
