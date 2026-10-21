# PressButton

The pressable button: a filled shape on a solid bottom edge that sinks when pressed. Use one `primary` per view for the main action (`AGREGAR GASTO`, `GUARDAR`, `EMPIEZA GRATIS`); `secondary` for the alternative; `ghost` for skip or dismiss.

- Classes: `lk-btn` plus `lk-btn-primary` | `lk-btn-secondary` | `lk-btn-ghost`; `lk-btn-sm` for compact cards.
- Labels are verbs in uppercase (`button` type style). Keep them to two or three words.
- The consumer provides the label and the click handler; the press effect is pure CSS (`:active`), and the app adds the `tap` feedback event.
- Don't stack two primaries, don't put a primary on `brand`, and don't remove the edge.
