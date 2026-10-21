# Lukas

The mascot, a chubby gold coin whose mood mirrors the budget. Consumer provides `mood`: `happy` (all categories ok, or right after logging), `worried` (any category near or over), `celebrating` (save, paid, month closed in green).

- Landing: `TravelingLukas`, the sprite sheets in 2.5D (shadow, bob, tilt toward the pointer, hop) that rolls in once per visit and stands beside each section in its mood; replaced by the still sprites under `prefers-reduced-motion` or without JavaScript. The 3D model is an experiment only.
- App: a lightweight 2D rendering beside a `lk-bubble` with the rule-based message.
- Each mood plays its own sprite sheet (`wave`, `worried`, `celebrate`); new art replaces a sheet without code changes.
