# Roadmap: Milestones e Issues

Reto: **Remittance Service** (CUBO+ The Build Sprint 2026). Todo es simulado: sin custodia ni movimiento de fondos reales.

Etiquetas sugeridas: `dev`, `non-dev`, `docs`, `db`, `engine`, `ui`, `admin`, `blocked`.
Cada issue se asigna con el patrón de rama de [git-workflow.md](./git-workflow.md).

---

## Milestone 1: Discovery & Architecture Baseline

**Objetivo:** equipo alineado, repo listo y modelo de datos definido.

### [Dev] (`@adiel23`, `@MatMTByElias`)

- [ ] Inicializar monorepo (pnpm workspaces + Turborepo, `apps/web`, `apps/admin`, `packages/database`, `packages/config`)
- [ ] Configuración compartida: TypeScript, ESLint, Prettier, Tailwind en `packages/config`
- [ ] Crear proyecto Supabase, variables de entorno y `.env.example`
- [ ] Migración inicial: enums de estado, `profiles`, `currencies`, `exchange_rates`, `fee_rules`, `transfers`, `transfer_history`, `audit_logs`
- [ ] Políticas RLS y seed de monedas (USD, SAT/BTC y locales) con tasas estáticas
- [ ] Generar tipos TypeScript desde el esquema (`db:types`)
- [ ] Workflow de CI en GitHub Actions: lint, typecheck, test, build
- [ ] Activar Branch Protection en `main` y `dev`
- [ ] Documentar arquitectura base en `docs/architecture.md` (diagrama, decisiones, esquema)

### [Non-Dev] (`@100a-dot`, `@Fonsii319`)

- [ ] Investigación de mercado de remesas: cómo operan los servicios tradicionales y sus puntos de fricción
- [ ] Mapeo de competidores (tarifas, transparencia de tasa, tiempos, confianza)
- [ ] Definición de Personas: remitente y destinatario
- [ ] User journey inicial del flujo de remesa
- [ ] Bocetos iniciales de UX (wireframes de baja fidelidad)

Salida en `docs/market-research/` y `docs/strategic-specs/`.

---

## Milestone 2: Core Simulation & Business Rules

**Objetivo:** una transferencia simulada de punta a punta con cálculos correctos.

### [Dev]

- [ ] Motor de conversión: tasa vigente por par, inversa y redondeo según `currencies.decimals`
- [ ] Sistema de cálculo de comisiones, mostrada separada de la tasa (`fee_rules`)
- [ ] Endpoint de cotización (`/api/quote`) con validación server-side
- [ ] Creación de transferencias: ID único (`reference_code`), snapshot de tasa y fee
- [ ] Máquina de estados: `Created → Processing → Completed | Failed`, `Created → Cancelled` (en BD y en servicio)
- [ ] Autenticación con Supabase Auth (remitente y destinatario)
- [ ] UI del remitente: monto, moneda destino, desglose (enviado, tasa, fee, recibido), confirmación
- [ ] UI del destinatario y detalle de una transferencia
- [ ] Historial de transacciones con estado en tiempo real (Supabase Realtime)

### [Non-Dev]

- [ ] Matriz detallada del modelo de tarifas (Fee Model)
- [ ] Modelo de conversión: cómo se comunican tasa y fees al usuario
- [ ] Flujo del ciclo de vida de la transferencia (estados, tiempos estimados, qué ve cada actor)
- [ ] Qué información necesita el usuario antes de confirmar
- [ ] Wireframes de alta fidelidad / prototipo

---

## Milestone 3: Administrative Dashboard & Bitcoin/Lightning Specs

**Objetivo:** monitoreo, calidad y cierre del entregable con la visión Bitcoin.

### [Dev]

- [ ] Panel administrativo (`apps/admin`): listado y filtros de transferencias, métricas básicas
- [ ] Simulación de completar o fallar transferencias (acción admin + job simulado de procesamiento)
- [ ] Vista de `audit_logs` y `transfer_history` para admin
- [ ] Pruebas unitarias del cálculo (conversión, fees, redondeo, casos borde) y de las transiciones de estado
- [ ] Demo end-to-end de una transferencia (script/seed de datos de demo)
- [ ] Documentación de la API (`docs/api.md`)
- [ ] Documento de arquitectura de conexión futura a Bitcoin/Lightning (BOLT11 invoices, nodo LN, mapeo de estados)

### [Non-Dev]

- [ ] KPIs: tasa de completitud, abandono, tamaño promedio de transferencia y retención
- [ ] Reporte de oportunidad de Bitcoin (dónde mejoraría la infraestructura de remesas)
- [ ] Diseño de recibos y pantallas de confirmación
- [ ] Definición de cómo se presenta el historial de transacciones
- [ ] Flujo UX/pagos final y recomendación de producto
- [ ] Guion y material de la presentación final

---

## Mapa de entregables del reto

| Entregable del reto                      | Milestone |
| ---------------------------------------- | --------- |
| Market research, competidores, personas  | 1         |
| Diseño de base de datos                  | 1         |
| Fee model, conversion model, lifecycle   | 2         |
| Conversion engine, fee system, state machine | 2     |
| Transfer creation, historial, UX sender/recipient | 2 |
| Wireframes / prototipo                   | 2         |
| Admin dashboard                          | 3         |
| KPIs, oportunidad Bitcoin, recomendación | 3         |
| Calculation tests, demo E2E, API docs    | 3         |
| Arquitectura hacia Bitcoin/Lightning     | 3         |
