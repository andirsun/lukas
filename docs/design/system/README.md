# Lukas design system

The source files of the Lukas design system: tokens, brand book, component guidelines and live previews, reference screens and the mascot concept.

- `project/README.md`: the brand book (voice, color, type, shape and depth, motion, Lukas, iconography).
- `project/tokens.json`: every token, in the `night` and `day` themes.
- `project/components/bundle.css`: the component classes (`lk-` prefix), built only from tokens.
- `project/components/<Name>/`: guidelines (`README.md`) and a live preview (`preview.html`) per component and reference screen.

The same files are published as a browsable page: https://claude.ai/artifact/Nwffxfo9QkVWv8jV5oqrUo. Previews load the mascot image from that page's asset store (`/_blob/…`); the original is `docs/brand/lukas-mascot-concept.webp`.

In Stage 2 these tokens and classes move into `apps/web` and Storybook becomes the living catalog.
