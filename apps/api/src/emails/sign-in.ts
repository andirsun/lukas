import type { Mail } from "../mailer.ts";

type Locale = "es" | "en";

const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

const COPY = {
  es: {
    subject: (code: string) => `Tu código de Lukitas: ${code}`,
    preheader: (code: string) => `Tu código para entrar a Lukitas: ${code}`,
    heading: "¡Hola! Este es tu código para entrar",
    lead: "Escríbelo en Lukitas, o toca el botón para entrar directo.",
    button: "ENTRAR A LUKITAS",
    buttonFallback: "¿El botón no funciona? Copia este enlace en tu navegador:",
    expiry: (m: number) => `El código y el enlace vencen en ${plural(m, "minuto", "minutos")}.`,
    ignore: "Si no pediste este correo, ignóralo: nadie puede entrar sin este código.",
    footer: "Lukitas · gratis y de código abierto",
    alt: "Lukitas saludando",
  },
  en: {
    subject: (code: string) => `Your Lukitas code: ${code}`,
    preheader: (code: string) => `Your Lukitas sign-in code: ${code}`,
    heading: "Hi! Here is your sign-in code",
    lead: "Type it into Lukitas, or tap the button to go straight in.",
    button: "SIGN IN TO LUKITAS",
    buttonFallback: "Button not working? Copy this link into your browser:",
    expiry: (m: number) => `The code and the link expire in ${plural(m, "minute", "minutes")}.`,
    ignore: "If you didn't ask for this email, ignore it: nobody can sign in without this code.",
    footer: "Lukitas · free and open source",
    alt: "Lukitas waving hello",
  },
} satisfies Record<Locale, unknown>;

/** The day palette of docs/design/system/project/tokens.json. Dark backgrounds break in many clients. */
const C = {
  bg: "#f7f4ff",
  surface: "#ffffff",
  sunken: "#ece6ff",
  edge: "#d6ccf5",
  stroke: "#e6defc",
  ink: "#221a47",
  muted: "#5b5285",
  brand: "#7b3df0",
  brandEdge: "#4a2bbf",
  gold: "#ffd23f",
  candy: "#e0408f",
} as const;

// Clients do not load web fonts: ask for the brand fonts, fall back to what every system has.
const DISPLAY = `'Fredoka','Baloo 2',Arial,Helvetica,sans-serif`;
const TEXT = `'Nunito',Arial,Helvetica,sans-serif`;
const MONO = `'SFMono-Regular',Menlo,Consolas,'Courier New',monospace`;

const escapeHtml = (s: string) =>
  s.replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] ?? c,
  );

const WAVE_SIZE = 160;
const BUTTON_WIDTH = 300;
const BUTTON_HEIGHT = 56;

/** Pads the preheader so clients do not pull body text in after it. */
const PREHEADER_FILLER = "&#847;&zwnj;&nbsp;".repeat(60);

export function signInEmail(input: {
  code: string;
  /** The magic link Better Auth built, with `lang` and `next` already on it. */
  link: string;
  locale: Locale;
  /** The web origin (`WEB_URL`): where the mascot image and the footer link point. */
  webUrl: string;
  expiresInMinutes: number;
}): Omit<Mail, "to"> {
  const copy = COPY[input.locale];
  const web = input.webUrl.replace(/\/+$/, "");
  const code = escapeHtml(input.code);
  const link = escapeHtml(input.link);
  const webHref = escapeHtml(web);
  const image = escapeHtml(`${web}/email/lukitas-wave.png`);
  const expiry = escapeHtml(copy.expiry(input.expiresInMinutes));

  const text = [
    copy.heading,
    "",
    input.code,
    "",
    copy.lead,
    input.link,
    "",
    copy.expiry(input.expiresInMinutes),
    copy.ignore,
    "",
    copy.footer,
    web,
    "",
  ].join("\n");

  const html = `<!doctype html>
<html lang="${input.locale}" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light only">
<meta name="supported-color-schemes" content="light only">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<title>${escapeHtml(copy.subject(input.code))}</title>
<!--[if mso]><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml><![endif]-->
</head>
<body style="margin:0;padding:0;background-color:${C.bg};-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">
<div style="display:none;font-size:1px;line-height:1px;mso-hide:all;color:${C.bg};">${escapeHtml(copy.preheader(input.code))}${PREHEADER_FILLER}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="${C.bg}" style="background-color:${C.bg};">
<tr>
<td align="center" style="padding:24px 16px 32px 16px;">
<!--[if mso]><table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" align="center"><tr><td><![endif]-->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:600px;">
<tr>
<td align="center" style="padding:8px 0 0 0;">
<img src="${image}" width="${WAVE_SIZE}" height="${WAVE_SIZE}" alt="${escapeHtml(copy.alt)}" style="display:block;width:${WAVE_SIZE}px;height:${WAVE_SIZE}px;border:0;text-decoration:none;font-family:${TEXT};font-size:14px;color:${C.muted};">
</td>
</tr>
<tr>
<td align="center" style="padding:4px 0 0 0;font-family:${DISPLAY};font-size:36px;line-height:42px;font-weight:700;color:${C.candy};letter-spacing:0.5px;">Lukitas</td>
</tr>
<tr>
<td align="center" style="padding:6px 0 20px 0;">
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center"><tr>
<td width="28" height="5" bgcolor="${C.gold}" style="width:28px;height:5px;line-height:5px;font-size:1px;background-color:${C.gold};border-radius:3px 0 0 3px;">&nbsp;</td>
<td width="28" height="5" bgcolor="#f0907f" style="width:28px;height:5px;line-height:5px;font-size:1px;background-color:#f0907f;">&nbsp;</td>
<td width="28" height="5" bgcolor="${C.candy}" style="width:28px;height:5px;line-height:5px;font-size:1px;background-color:${C.candy};border-radius:0 3px 3px 0;">&nbsp;</td>
</tr></table>
</td>
</tr>
<tr>
<td bgcolor="${C.surface}" style="background-color:${C.surface};border:2px solid ${C.stroke};border-bottom:5px solid ${C.edge};border-radius:24px;padding:32px 24px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
<tr>
<td align="center" style="font-family:${DISPLAY};font-size:26px;line-height:32px;font-weight:700;color:${C.ink};padding:0 0 8px 0;">${escapeHtml(copy.heading)}</td>
</tr>
<tr>
<td align="center" style="font-family:${TEXT};font-size:16px;line-height:24px;font-weight:600;color:${C.muted};padding:0 0 24px 0;">${escapeHtml(copy.lead)}</td>
</tr>
<tr>
<td align="center" style="padding:0 0 28px 0;">
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="max-width:100%;"><tr>
<td align="center" bgcolor="${C.sunken}" style="background-color:${C.sunken};border:2px solid ${C.edge};border-radius:16px;padding:16px 20px 16px 30px;font-family:${MONO};font-size:40px;line-height:48px;font-weight:700;letter-spacing:10px;color:${C.ink};-webkit-user-select:all;user-select:all;">${code}</td>
</tr></table>
</td>
</tr>
<tr>
<td align="center" style="padding:0 0 12px 0;">
<!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${link}" style="height:${BUTTON_HEIGHT}px;v-text-anchor:middle;width:${BUTTON_WIDTH}px;" arcsize="28%" strokecolor="${C.brandEdge}" strokeweight="2px" fillcolor="${C.brand}"><w:anchorlock/><center style="color:#ffffff;font-family:Arial,Helvetica,sans-serif;font-size:16px;font-weight:bold;letter-spacing:1px;">${escapeHtml(copy.button)}</center></v:roundrect><![endif]-->
<!--[if !mso]><!-->
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="max-width:100%;"><tr>
<td align="center" bgcolor="${C.brand}" style="background-color:${C.brand};border-radius:16px;border-bottom:4px solid ${C.brandEdge};">
<a href="${link}" target="_blank" style="display:inline-block;padding:16px 32px;font-family:${DISPLAY};font-size:17px;line-height:24px;font-weight:700;letter-spacing:1px;color:#ffffff;text-decoration:none;border-radius:16px;">${escapeHtml(copy.button)}</a>
</td>
</tr></table>
<!--<![endif]-->
</td>
</tr>
<tr>
<td align="center" style="padding:0 0 24px 0;font-family:${TEXT};font-size:13px;line-height:20px;font-weight:600;color:${C.muted};">${escapeHtml(copy.buttonFallback)}<br><a href="${link}" target="_blank" style="color:${C.brand};text-decoration:underline;word-break:break-all;">${link}</a></td>
</tr>
<tr>
<td align="center" style="border-top:2px solid ${C.stroke};padding:20px 0 0 0;font-family:${TEXT};font-size:15px;line-height:22px;font-weight:700;color:${C.ink};">${expiry}</td>
</tr>
<tr>
<td align="center" style="padding:6px 0 0 0;font-family:${TEXT};font-size:14px;line-height:21px;font-weight:600;color:${C.muted};">${escapeHtml(copy.ignore)}</td>
</tr>
</table>
</td>
</tr>
<tr>
<td align="center" style="padding:24px 16px 0 16px;font-family:${TEXT};font-size:13px;line-height:20px;font-weight:700;color:${C.muted};">${escapeHtml(copy.footer)}<br><a href="${webHref}" target="_blank" style="color:${C.brand};text-decoration:underline;">${escapeHtml(web.replace(/^https?:\/\//, ""))}</a></td>
</tr>
</table>
<!--[if mso]></td></tr></table><![endif]-->
</td>
</tr>
</table>
</body>
</html>
`;

  return { subject: copy.subject(input.code), text, html };
}
