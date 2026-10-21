import type { Mail } from "../mailer.ts";

const COPY = {
  es: {
    subject: (code: string) => `Tu código de Lukitas: ${code}`,
    intro: "Usa este código para entrar a Lukitas:",
    link: "O toca este enlace en este dispositivo:",
    outro: "El código vence en 10 minutos. Si no fuiste tú, ignora este correo.",
  },
  en: {
    subject: (code: string) => `Your Lukitas code: ${code}`,
    intro: "Use this code to sign in to Lukitas:",
    link: "Or tap this link on this device:",
    outro: "The code expires in 10 minutes. If this wasn't you, ignore this email.",
  },
};

const escapeHtml = (s: string) =>
  s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c] ?? c);

export function signInEmail(input: {
  code: string;
  link: string;
  locale: "es" | "en";
}): Omit<Mail, "to"> {
  const copy = COPY[input.locale];
  return {
    subject: copy.subject(input.code),
    text: `${copy.intro}\n\n${input.code}\n\n${copy.link}\n${input.link}\n\n${copy.outro}\n`,
    html: `<p>${copy.intro}</p><p style="font-size:32px;font-weight:bold;letter-spacing:6px">${input.code}</p><p>${copy.link}<br><a href="${escapeHtml(input.link)}">${escapeHtml(input.link)}</a></p><p>${copy.outro}</p>`,
  };
}
