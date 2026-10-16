# SatPay

Simulador transaccional y transparente de remesas, construido para **CUBO+ | The Build Sprint 2026** (reto *Remittance Service*).


SatPay modela el flujo completo de una remesa: el remitente ingresa un monto, ve la conversión y las comisiones por separado, crea una transferencia teórica y sigue su progreso hasta que el destinatario la recibe. Está pensado para usuarios que no dominan la terminología financiera ni de Bitcoin, y su arquitectura permite conectarse a futuro con Bitcoin y Lightning Network.

> **Todo es simulado.** No se custodia ni se mueve dinero real. Las tasas de cambio son estáticas o mock.

## Qué muestra la plataforma

- Monto enviado, tasa de conversión, comisiones y monto recibido
- Estado de la transferencia y tiempo estimado de procesamiento
- Historial de transacciones y detalle de cada transferencia
- Panel administrativo para monitorear y simular el éxito o fallo de transferencias

Ciclo de vida de una transferencia:

```
Created ──► Processing ──► Completed
   │            └────────► Failed
   └──► Cancelled
```

## Stack

- [Next.js](https://nextjs.org) (App Router) + TypeScript
- [Supabase](https://supabase.com): PostgreSQL, Auth y Realtime
- pnpm workspaces + Turborepo

## Estructura

```
apps/
  web/          App de remitente y destinatario
  admin/        Dashboard administrativo
packages/
  database/     Migraciones, seed y tipos de Supabase
  config/       Configuración compartida (ESLint, Tailwind, TypeScript)
docs/           Especificaciones, investigación, flujo Git y roadmap
```

## Estado del proyecto

Fase de inicialización. Ya están definidos el esquema de base de datos, el flujo de trabajo y el roadmap. Las apps `web` y `admin` y la configuración compartida aún no se han creado, y falta generar la configuración local de Supabase (`supabase init --workdir packages/database`).

## Primeros pasos

Requisitos: Node.js 22 o superior, pnpm y Docker (para Supabase en local).

```bash
pnpm install
pnpm db:start     # Supabase local (requiere la configuración inicial mencionada arriba)
pnpm db:reset     # aplica migraciones y seed
```

Comandos de la raíz: `pnpm dev`, `build`, `lint`, `typecheck`, `test`.

## Documentación

- [Roadmap y milestones](docs/roadmap.md)
- [Flujo de trabajo Git](docs/git-workflow.md)
- [Skills y herramientas para agentes](docs/agent-skills.md)
- [AGENTS.md](AGENTS.md): reglas para agentes de IA que trabajan en el repo

## Equipo

| Track | Integrantes |
| ----- | ----------- |
| Dev | [@adiel23](https://github.com/adiel23), [@MatMTByElias](https://github.com/MatMTByElias) |
| Non-Dev | [@100a-dot](https://github.com/100a-dot), [@Fonsii319](https://github.com/Fonsii319) |

## Cómo contribuir

Todo cambio entra por Pull Request hacia `dev`, con al menos una aprobación de un Dev. Los commits siguen Conventional Commits en inglés (`feat(scope): description`). Detalles en [docs/git-workflow.md](docs/git-workflow.md).
