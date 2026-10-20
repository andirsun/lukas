# Lukas

**Finanzas personales que se sienten como un juego.** Presupuesto mensual, una app Android con widgets para registrar gastos en segundos, una web con gráficas y un servidor MCP para que tu asistente de IA (Claude, ChatGPT…) te ayude con tus cuentas.

## ¿Por qué "Lukas"?

En Colombia, al dinero le decimos **lucas**. Una *luca* son mil pesos, y de ahí se pasa a cualquier plata: "¿cuántas lukas te costó?", "estoy sin lukas", "me faltan unas lukas para fin de mes". Es una palabra cercana y de todos los días, justo como queremos que se sienta manejar tus finanzas.

**Lukas también es la mascota del proyecto.** Te acompaña en la app: celebra cuando registras un gasto, te avisa cuando una categoría se acerca al límite y festeja cuando cierras el mes dentro del presupuesto. La idea es que ser ordenado con tu dinero sea divertido, casi adictivo.

## Qué hace

- **Lo que te queda este mes**, en grande y siempre visible, en la app y en el widget.
- **Presupuesto mensual por categoría**, con barras que se llenan con lo gastado y cambian de color al acercarse al límite.
- **Movimientos por día**, pagados o pendientes, con recurrentes automáticos (arriendo, suscripciones, salario…).
- **Análisis** por categoría y evolución mes a mes.
- **Importación desde Budge** (CSV).
- **Conecta tu asistente:** un servidor MCP para pedirle a tu IA que registre gastos, prepare reportes o ajuste tu presupuesto.
- **Sin contraseñas:** entras con un enlace mágico o un código enviado a tu correo, o con una passkey.

## Estado

🚧 En diseño. La especificación está en [`docs/superpowers/specs/2026-10-20-lukas-design.md`](docs/superpowers/specs/2026-10-20-lukas-design.md).

## Arquitectura

Monorepo con:

- `apps/api`: backend en TypeScript (Hono), Postgres y Better Auth
- `apps/web`: React + Vite
- `apps/mcp`: servidor MCP remoto
- `apps/mobile`: Flutter (Android; iOS más adelante), con widget nativo en Kotlin + Glance
- `packages/core`, `packages/db`, `packages/importers`: reglas de negocio, esquema y migraciones, importadores

## Self-hosting

Por ahora Lukas se ofrece como servicio alojado y no hay documentación para instalarlo por tu cuenta. Si te interesa, abre un issue y lo tendremos en cuenta.

## Licencia

[AGPL-3.0](LICENSE). Si ofreces Lukas modificado como servicio, debes publicar tus cambios.
