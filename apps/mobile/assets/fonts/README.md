# Fonts

The web's two fonts (`apps/web/app/styles/tokens.css`: `--font-display` Fredoka, `--font-text`
Nunito), bundled so the app never fetches one. Both are SIL Open Font License 1.1; each `*-OFL.txt`
is the licence file the font ships with, and About lists them (`lib/settings/licenses.dart`).

The `@fontsource` packages the web uses ship only woff2, which Flutter cannot load, so these are
the upstream releases, unmodified, from Google Fonts' repository (`google/fonts` at commit
`e7db6ca603fd`):

| File | Source |
| --- | --- |
| `Fredoka-Variable.ttf` | `ofl/fredoka/Fredoka[wdth,wght].ttf` (weights 300-700; the app uses 500-700) |
| `Nunito-Variable.ttf` | `ofl/nunito/Nunito[wght].ttf` (weights 200-1000; the app uses 600-900) |
| `Fredoka-OFL.txt`, `Nunito-OFL.txt` | `ofl/fredoka/OFL.txt`, `ofl/nunito/OFL.txt` |

They are variable fonts, so one file draws every weight the web loads
(`apps/web/app/styles/fonts.ts`); Flutter picks the weight from `TextStyle.fontWeight`.
