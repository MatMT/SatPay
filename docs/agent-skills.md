# Skills y herramientas para agentes

## Skills

| Skill / plugin | Origen | Para qué | Estado |
| -------------- | ------ | -------- | ------ |
| `supabase` | Plugin oficial de Supabase | RLS, Auth, Postgres best practices, MCP de base de datos | Pendiente de activar en claude.ai |
| `frontend-design` | Plugin de Anthropic | Implementación de UI/UX | Pendiente de activar en claude.ai |
| `emilkowalski/skill` (10 de 14) | `npx skills add` | Diseño de UI, animación, edge cases visuales (`break-ui`), prototipos | Instalado en `.claude/skills/` |
| `code-review`, `security-review`, `simplify` | Incluidas en Claude Code | Revisar PRs, seguridad y limpieza antes de abrir PR | Disponibles |
| `pptx`, `docs`, `xlsx` | Incluidas | Non-devs: presentación final, documentos, matriz de tarifas y KPIs | Disponibles |

De `emilkowalski/skill` no se instalaron `animate-expo`, `mobile-native` ni `write-swift` (React Native / Swift, fuera del stack).

## Herramientas de validación (propuesta)

Todo corre con `pnpm lint | typecheck | test | build` y en CI.

| Necesidad | Herramienta | Notas |
| --------- | ----------- | ----- |
| Errores al compilar | `tsc --noEmit` (strict) y `next build` | Detecta tipos rotos y errores de rutas/SSR |
| Linter | ESLint (`next/core-web-vitals`, `typescript-eslint`) + Prettier | Config compartida en `packages/config` |
| Lógica de cálculo | Vitest | Conversión, comisiones, redondeo por decimales, máquina de estados |
| Casos borde de dinero | `fast-check` (property tests) | Ej.: nunca recibido negativo, redondeo consistente, ida y vuelta de tasas |
| Dinero sin errores de float | `decimal.js` o `big.js` | Regla en `AGENTS.md` |
| Validación de entrada en API | Zod | Mismo esquema en cliente y servidor |
| Base de datos y RLS | pgTAP con `supabase test db` | Transiciones válidas/inválidas, inmutabilidad, políticas RLS |
| Demo end-to-end | Playwright | Cubre el entregable "End-to-end transfer demonstration" |
| Commits y hooks | commitlint + Husky + lint-staged | Obliga `type(scope): description` y corre lint antes de commit |
| CI | GitHub Actions | `lint`, `typecheck`, `test`, `build`; son los checks requeridos de la protección de ramas |

Verificación visual por agentes: el navegador integrado de Claude Code (o el MCP de Playwright) para probar la app corriendo.
