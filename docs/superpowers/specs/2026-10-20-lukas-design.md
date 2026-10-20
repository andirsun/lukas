# Lukas — Diseño general y Etapa 1 (Núcleo y cuentas)

- **Fecha:** 2026-10-20
- **Estado:** borrador para revisión
- **Licencia del proyecto:** AGPL-3.0

## 1. Contexto y objetivo

Lukas es una app de finanzas personales gamificada ("lukas" = dinero en Colombia). Nace para reemplazar a Budge, que el autor usa desde 2023, con un UX mucho más simple y divertido.

**Objetivo de la primera versión:** reproducir lo que hoy se hace en Budge (registrar movimientos, ver el saldo del mes, seguir un presupuesto mensual por categoría y analizar los gastos por categoría) con una interfaz más clara y que se sienta como un juego.

**Modelo de producto:** servicio alojado por el autor con cuentas de usuario abiertas al público. El código es open source (AGPL-3.0) para recibir contribuciones. Por ahora no se ofrece self-hosting; el README lo menciona como posible trabajo futuro según el interés.

### Criterios de éxito

1. El autor importa su historial de Budge (CSV) y ve sus datos desde 2023 sin pérdida.
2. Al abrir la app o mirar el widget se ve en un segundo **cuánto le queda para gastar este mes**.
3. Registrar un gasto desde el widget o la app toma menos de 5 segundos y da feedback satisfactorio (animación, vibración, sonido).
4. Un agente de IA (Claude, ChatGPT) conectado vía MCP puede leer, crear y editar movimientos, pedir reportes y ajustar presupuestos.

### Fuera de alcance (v1)

- Varias cuentas y varias monedas. El modelo ya tiene `account` y `currency`, pero la UI muestra una sola cuenta en EUR.
- Pagos en cuotas.
- Presupuesto con arrastre de saldo entre meses.
- Inicio de sesión con Google o Apple.
- App de iOS. Se hará después con el mismo código Flutter, más un widget nativo en WidgetKit.
- Self-hosting documentado.

## 2. Producto

### 2.1 Lo que se reproduce de Budge

Según las capturas y el export del autor:

| Vista en Budge | En Lukas |
|---|---|
| Saldo del mes + pestañas de meses + ingresos/gastos | Pantalla principal: **lo que queda del presupuesto** en grande y el saldo del mes como dato secundario |
| Lista de movimientos por día, con estado pagado/pendiente | Lista diaria con estado y total del día |
| Presupuesto total y por categoría (%, restante) | Presupuesto con visualización inequívoca de **gastado vs. disponible** (ver 2.3) |
| Análisis: dona por categoría (gastos/ingresos), filtro pagado/pendiente | Dona + lista de categorías + evolución mes a mes (web) |
| Botón "+" | Botón grande de agregar, en la app y en el widget |

### 2.2 Definiciones de cifras

- **Lo que queda este mes** (número principal) = Σ presupuestos vigentes de las categorías de gasto del mes − Σ gastos del mes (pagados **y** pendientes). Las categorías de gasto sin presupuesto también restan.
  - Caso de referencia (octubre 2026): 2.800,00 € − 2.237,08 € = **562,92 €**.
- **Saldo del mes** (número secundario) = Σ ingresos del mes − Σ gastos del mes.
- **Gastado en una categoría** = −Σ montos de la categoría en el mes. Un monto positivo en una categoría de gasto (devolución) reduce lo gastado.

### 2.3 Lenguaje de diseño

Lo que se señala de Budge: la barra de presupuesto muestra lo *restante*, y "100 %" en azul significa "no gastado". Se lee al revés.

Principios para Lukas:

- **Una cifra protagonista por pantalla.** Lo demás es secundario.
- **Las barras siempre se llenan con lo gastado** y cambian de color al acercarse al límite (verde → ámbar → rojo). Si te pasas, se muestra explícitamente "te pasaste X €" y no un porcentaje negativo.
- **Botones grandes con relieve** (sombra inferior sólida, al estilo Duolingo/Buddy) que se hunden al tocarlos.
- **Feedback multisensorial por eventos semánticos:** cada acción importante combina animación, vibración háptica y sonido corto. Por ejemplo, `expenseSaved`, `nearLimit`, `overBudget` y `streak`.
- **Deshacer siempre disponible** en lugar de confirmaciones bloqueantes. Los borrados son suaves.
- La gamificación avanzada (rachas, logros) es la Etapa 5, pero el tono de juego está presente desde la Etapa 2.

### 2.4 Onboarding

Web y móvil comparten el flujo:

1. Pantallas cortas y animadas sobre qué hace Lukas.
2. Crear cuenta / entrar con email (enlace mágico + código).
3. Ofrecer crear una passkey ("¿Entrar con tu huella la próxima vez?").
4. Configuración inicial: elegir categorías sugeridas, fijar el presupuesto por categoría y, si se quiere, importar un CSV de Budge. Con un import, los presupuestos se sugieren según el gasto promedio.

### 2.5 "Conecta tu asistente"

Sección en la web y en el móvil:

- URL del servidor MCP con botón de copiar. Es única para todos; OAuth identifica al usuario.
- Pasos por cliente (Claude, ChatGPT, Claude Code y otros). Los pasos exactos se verifican al construir la Etapa 4, porque esos menús cambian.
- Pantalla de consentimiento OAuth: "Claude quiere acceder a tus finanzas: leer, crear y editar movimientos".
- Lista de asistentes conectados con botón para revocar cada uno.
- Ejemplos de peticiones.

## 3. Arquitectura

### 3.1 Monorepo

```
/
├── apps/
│   ├── api/          # Backend TypeScript (Hono) + Better Auth
│   ├── web/          # React + Vite
│   ├── mcp/          # Servidor MCP remoto (TypeScript)
│   └── mobile/       # Flutter (Android; iOS después)
│       └── android/…/widget/   # Widget nativo Kotlin + Jetpack Glance
├── packages/
│   ├── core/         # Reglas de negocio puras + esquemas zod
│   ├── db/           # Esquema Drizzle + migraciones (Postgres)
│   └── importers/    # Importadores (primero: Budge CSV)
├── docker-compose.yml   # Postgres + Mailpit + api + mcp
└── docs/
```

- **Herramientas:** pnpm workspaces y Turborepo para TypeScript. Flutter usa su propio toolchain dentro de `apps/mobile`.
- **Fuente de verdad:** la API. El MCP, la web, el móvil y el widget hablan con la API; **ninguno accede a la base de datos directamente**.
- **Contrato:** OpenAPI generado desde los esquemas zod de `core`. A partir de él se generan el cliente Dart (Flutter) y los tipos de la web.
- **Cálculos en el servidor:** la API devuelve las cifras ya calculadas, así que Flutter y el widget no duplican reglas de negocio.

### 3.2 Decisiones y motivos

| Decisión | Motivo |
|---|---|
| TypeScript para api/web/mcp/core | El SDK de MCP más maduro, código compartido y facilidad para contribuidores |
| Flutter para móvil | Una sola base para Android e iOS (iOS futuro); su motor propio de renderizado facilita la UI de juego (Rive, Lottie, `flutter_animate`) |
| Widget nativo (Kotlin + Glance) | Ningún framework multiplataforma dibuja widgets de pantalla de inicio. El widget comparte datos con la app vía `home_widget` y llama a la API para registrar gastos |
| Hápticos nativos vía platform channel | Patrones tipo Duolingo: `VibrationEffect.Composition` en Android y Core Haptics en iOS. La calidad depende del motor de vibración de cada teléfono |
| Better Auth | Open source, guarda los datos en el Postgres propio, sin dependencia de proveedores ni costo por usuario; soporta enlace mágico, OTP por email, passkeys y servidor OAuth (requerido por MCP remoto) |
| React (no Flutter Web) para la web | Mejor para dashboards y gráficas, para el rendimiento en navegador y para recibir contribuciones |

### 3.3 Etapas

Cada etapa tiene su propio spec → plan → implementación.

1. **Núcleo y cuentas** (detallado en este documento, §4–§8).
2. **Web v1:** onboarding, pantalla principal, movimientos, presupuesto, análisis, importación y "Conecta tu asistente".
3. **Móvil + widget:** onboarding, registro rápido, lo que queda, módulo de feedback (hápticos, sonido, animación) y widget Android.
4. **MCP:** servidor remoto con OAuth; herramientas para leer, crear y editar movimientos, generar reportes y ajustar presupuestos.
5. **Gamificación avanzada:** rachas, logros y recompensas.

## 4. Modelo de datos (Etapa 1)

### 4.1 Principios

- Dinero como **entero en unidades menores** (céntimos) más código ISO de moneda. Nunca decimales en punto flotante.
- **Monto con signo:** gastos negativos e ingresos positivos.
- **Toda tabla de dominio tiene `user_id`**. El aislamiento se aplica en la capa de consultas y además con **Row-Level Security** de Postgres.
- Fechas de movimientos como `date`, sin hora ni zona horaria. El usuario tiene una `timezone` que define qué es "hoy" y "este mes".
- Borrado suave (`deleted_at`) en movimientos, para poder deshacer. Borrar la cuenta elimina todo de forma definitiva.
- Todos los ids son UUID v7. `created_at` y `updated_at` están en todas las tablas de dominio.

### 4.2 Tablas

**Better Auth** (gestionadas por la librería): `user`, `session`, `verification`, `passkey` y las tablas del plugin OAuth. Al usuario se le añaden `timezone` (IANA, por ejemplo `Europe/Lisbon`) y `locale` (por ejemplo `es`).

**`accounts`**
| Campo | Tipo | Notas |
|---|---|---|
| id, user_id | uuid | |
| name | text | "Principal" |
| currency | char(3) | `EUR` |
| is_default | bool | Exactamente una por usuario. Se crea al registrarse |

**`categories`**
| Campo | Tipo | Notas |
|---|---|---|
| id, user_id | uuid | |
| name | text | Único por usuario entre las no archivadas |
| kind | enum `expense` \| `income` | |
| icon | text | Clave del set de iconos de la app |
| color | text | Token de color de la paleta de la app |
| sort_order | int | |
| archived_at | timestamptz? | Las archivadas no aparecen en la UI, pero conservan su historial |

**`category_budgets`**: historial del presupuesto base.
| Campo | Tipo | Notas |
|---|---|---|
| id, user_id, category_id | uuid | Solo categorías `expense` |
| amount | bigint | Céntimos, ≥ 0 |
| effective_from | date | Siempre el día 1 de un mes. Único por (category_id, effective_from) |

El presupuesto vigente de una categoría en el mes M es la fila con el mayor `effective_from` ≤ M. Si no hay ninguna, la categoría no tiene presupuesto ese mes.

**`transactions`**
| Campo | Tipo | Notas |
|---|---|---|
| id, user_id, account_id, category_id | uuid | |
| name | text | Por ejemplo "continente" |
| amount | bigint | Céntimos con signo, ≠ 0 |
| currency | char(3) | Igual a la de la cuenta |
| date | date | |
| status | enum `paid` \| `pending` | |
| note | text? | |
| recurrence_id | uuid? | |
| import_id | uuid? | |
| source | enum `app` \| `web` \| `widget` \| `mcp` \| `import` \| `recurrence` | |
| external_hash | text? | Solo en importaciones; único por (user_id, external_hash) |
| deleted_at | timestamptz? | |

Índices: (user_id, date), (user_id, category_id, date). Restricción única parcial (recurrence_id, date) donde recurrence_id no es nulo.

**`recurrences`**
| Campo | Tipo | Notas |
|---|---|---|
| id, user_id, account_id, category_id | uuid | |
| name, amount | text, bigint | Plantilla del movimiento |
| frequency | enum `monthly` \| `yearly` | |
| day_of_month | int 1–31 | Si el mes es más corto, se usa el último día |
| month_of_year | int 1–12? | Solo para `yearly` |
| start_date | date | |
| end_date | date? | |

**`imports`**
| Campo | Tipo | Notas |
|---|---|---|
| id, user_id | uuid | |
| source | enum `budge` | |
| file_hash | text | SHA-256 del archivo; único por usuario entre las importaciones confirmadas |
| status | enum `preview` \| `confirmed` \| `reverted` | |
| stats | jsonb | Movimientos, categorías nuevas, duplicados omitidos y rango de fechas |
| payload | jsonb? | Filas parseadas, guardadas solo mientras la importación está en `preview`. Se borra al confirmar |

**`idempotency_keys`**: (user_id, key, response, created_at). Se purgan a las 24 h.

## 5. Reglas de negocio (`packages/core`)

Son funciones puras, sin I/O, probadas de forma exhaustiva:

- `monthSummary(month, budgets, transactions)` devuelve `{ budgetTotal, spent, remaining, income, balance, categories[] }`. Cada categoría incluye `{ budget, spent, remaining, ratio, state }`, donde `state` es `ok` \| `near` (≥ 80 %) \| `over` (> 100 %).
- `effectiveBudget(categoryBudgets, month)`.
- `occurrences(recurrence, month)` devuelve las fechas en que ocurre una recurrencia dentro de un mes, incluyendo el ajuste al último día del mes.
- Esquemas zod de cada entidad y de cada entrada de la API, con reglas como: el signo del monto debe ser coherente con el tipo de categoría, salvo en devoluciones (positivo en `expense`) y correcciones (negativo en `income`), que se permiten.

**Materialización de recurrentes:** cuando la API calcula el resumen o lista los movimientos de un mes M ≤ mes actual + 1, primero inserta las ocurrencias de M que falten como `pending`, con `source = recurrence`. Usa `ON CONFLICT DO NOTHING` sobre (recurrence_id, date). Una ocurrencia que el usuario borró (borrado suave) no se regenera, porque la fila sigue existiendo. No hace falta un cron.

## 6. Autenticación y seguridad

- **Inicio de sesión sin contraseña:**
  - **Email:** un solo correo con un **enlace mágico y un código de 6 dígitos**. El enlace abre la app en Android vía App Links; el código sirve cuando se abre el correo en otro dispositivo. Ambos caducan a los 10 minutos y son de un solo uso.
  - **Passkeys (WebAuthn):** se ofrecen tras el primer inicio de sesión. Se puede tener varias por usuario.
  - El registro y el inicio de sesión son el mismo flujo: si el email no existe, se crea la cuenta.
- **Sesiones:** cookie `httpOnly` + `SameSite=Lax` en la web; token *bearer* guardado en el almacenamiento seguro en Flutter y en el widget.
- **OAuth (servidor):** Better Auth actúa como servidor de autorización para clientes MCP, con registro dinámico de clientes y PKCE, como exige la especificación de MCP. Los scopes de la v1 son `finance:read` y `finance:write`.
- **Rate limiting** en `/auth/*`, por IP y por email.
- **Envío de correos:** Resend en producción (detrás de una interfaz `Mailer` intercambiable) y Mailpit en local.
- **RGPD:** exportación completa (JSON + CSV), borrado de cuenta definitivo y política de privacidad mínima.

## 7. API (Etapa 1)

REST en `/v1`, JSON y OpenAPI generado. Todas las rutas requieren sesión, salvo `/auth/*` y `/health`.

| Método y ruta | Descripción |
|---|---|
| `GET /health` | Estado del servicio |
| `GET /v1/me` · `PATCH /v1/me` | Perfil (timezone, locale) |
| `GET /v1/summary?month=YYYY-MM` | Resumen del mes (§5); por defecto, el mes actual según la timezone |
| `GET /v1/transactions?month=&category=&status=&cursor=` | Lista paginada, ordenada por fecha descendente |
| `POST /v1/transactions` | Crear. Acepta `Idempotency-Key` |
| `PATCH /v1/transactions/:id` · `DELETE /v1/transactions/:id` · `POST /v1/transactions/:id/restore` | Editar, borrar (suave) y restaurar |
| `GET/POST /v1/categories` · `PATCH /v1/categories/:id` | Gestión de categorías (archivar = `PATCH archived: true`) |
| `PUT /v1/categories/:id/budget` | Body `{ amount, effectiveFrom: "YYYY-MM" }` |
| `GET/POST /v1/recurrences` · `PATCH/DELETE /v1/recurrences/:id` | Recurrentes. Borrar una recurrencia no borra los movimientos ya generados |
| `GET /v1/reports/by-category?from=&to=&kind=&status=` | Totales y porcentajes por categoría (alimenta la dona) |
| `GET /v1/reports/trend?from=&to=` | Ingresos, gastos y presupuesto por mes |
| `POST /v1/imports` (multipart, `source=budge`) | Parsea el archivo y devuelve la vista previa con sus estadísticas |
| `POST /v1/imports/:id/confirm` · `DELETE /v1/imports/:id` | Confirmar, o revertir (borra los movimientos de esa importación) |
| `GET /v1/me/export` · `DELETE /v1/me` | Exportar datos y borrar la cuenta |

**Errores:** `application/problem+json` (RFC 9457) con un `code` estable, por ejemplo `validation_failed`, `not_found`, `import_duplicate_file` o `budget_category_not_expense`. Para `validation_failed` se incluyen los errores por campo.

## 8. Importador de Budge (`packages/importers/budge`)

**Formato observado** (export "Format version 1"): bloques separados por `###`.

1. Metadatos: `Format version,Period,User ID`.
2. Movimientos: `Date` (DD-MM-YYYY), `Payment`, `Is paid`, `Amount` (decimal con punto, con signo), `Currency`, `Account`, `Category`, `Subcategory`, `Goal`, `Description`.
3. Cuentas: `Account, Account Balance, Available Balance, Credit Limit, Currency, Is savings, Description`.

**Mapeo:**

| Budge | Lukas |
|---|---|
| Date | `date` |
| Payment (con trim) | `name` |
| Is paid | `status` (`true` → `paid`) |
| Amount | `amount` en céntimos, con un parseo decimal exacto (sin `float`) |
| Currency | `currency`. Si no es la moneda de la cuenta por defecto, la fila se rechaza en la v1 y se informa en la vista previa |
| Account | Se ignora en la v1; todo va a la cuenta por defecto |
| Category | Se busca o se crea una categoría con ese nombre (sin distinguir mayúsculas). `kind` = signo mayoritario de sus movimientos; el ícono y el color se asignan con un diccionario de nombres comunes (supermercado → carrito, restaurante → cubiertos, casa, transporte, salario…) y, si no hay coincidencia, con un valor por defecto |
| Subcategory, Goal | Se ignoran (vacíos en los datos observados) |
| Description | `note` |
| — | `source = import`, `import_id`, `external_hash = sha256(date‖name‖amount‖category)` |

- **Duplicados:** las filas cuyo `external_hash` ya existe para el usuario se omiten y se cuentan en la vista previa. Filas idénticas dentro del mismo archivo (por ejemplo, dos cafés iguales el mismo día) se distinguen añadiendo su ordinal al hash.
- **El bloque de cuentas y el `User ID`** se ignoran y no se guardan.
- **Presupuestos:** Budge no los exporta. La vista previa incluye el gasto mensual promedio por categoría para sugerirlos en el onboarding.
- **Robustez:** pueden faltar bloques; se aceptan finales de línea `\r\n`; el BOM se ignora. Si el formato no se reconoce, se responde `import_unrecognized_format`.

## 9. Desarrollo local y CI

- `docker compose up` levanta Postgres, Mailpit, `api` y `mcp`. La web corre con `pnpm dev`.
- Las migraciones de Drizzle se aplican al arrancar `api` en desarrollo.
- Un seed de desarrollo crea un usuario de prueba con los datos del CSV de ejemplo anonimizado.
- **CI (GitHub Actions):** lint, typecheck, pruebas unitarias e integración (con un Postgres de servicio) en cada PR.
- Repositorio: README (qué es, cómo correrlo, cómo contribuir), CONTRIBUTING, licencia AGPL-3.0 y Conventional Commits.

## 10. Pruebas (Etapa 1)

- **`core` (Vitest):** `monthSummary`, con el caso real de octubre 2026 (562,92 €), devoluciones, categorías sin presupuesto, cambios de presupuesto entre meses, `occurrences` con días 29–31 y años bisiestos, y validaciones de signo.
- **`importers/budge`:** fixture anonimizado con la misma estructura que el export real (bloques, comillas, comas en nombres, `Is paid=false`, filas positivas en categorías de gasto). Se prueba el parseo exacto de montos, la deduplicación y los formatos inválidos. **El CSV real del autor nunca entra al repo.**
- **`api` (integración, Postgres real):** flujos CRUD, resumen, materialización de recurrentes (idempotente), idempotencia de `POST /transactions`, importación preview → confirm → revert y **aislamiento entre usuarios** (A no puede leer ni modificar los datos de B, incluso con ids válidos de B).
- **Auth:** enlace o código inválido o caducado, de un solo uso, y rate limiting.

## 11. Fuera de esta etapa

Las Etapas 2–5 se especificarán por separado. Este documento solo fija lo que necesitan de la Etapa 1: `GET /v1/summary` como única llamada para la pantalla principal y el widget, OAuth listo para MCP y la importación usable desde el onboarding.
