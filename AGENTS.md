# AGENTS.md

Instructions for AI agents working in this repo. Humans: see `docs/`.

## Project

SatPay is a **simulated, transparent remittance service** built for CUBO+ The Build Sprint 2026 (challenge: Remittance Service). It must show amount sent, conversion rate, fees, amount received, transfer status, estimated processing info and history. It is designed so it could later connect to Bitcoin/Lightning.

**No real funds are ever held or moved.** Never add real payment, custody or wallet integrations. Exchange rates are static or mock.

Team: devs `@adiel23`, `@MatMTByElias`; non-devs `@100a-dot`, `@Fonsii319` (research, specs, UX, they only touch `docs/`).

Talk to the team in Spanish. Code, comments, commits, branch names and PR titles are in English.

## Stack and layout

Next.js (App Router) + TypeScript, Supabase (Postgres, Auth, Realtime), pnpm workspaces + Turborepo.

```
apps/web        Sender/recipient app
apps/admin      Admin monitoring dashboard
packages/database   Supabase migrations, seed, generated types
packages/config     Shared ESLint / Tailwind / TypeScript config
docs/           Markdown specs (strategic-specs/, market-research/), git-workflow.md, roadmap.md
```

Commands (root): `pnpm dev | build | lint | typecheck | test`, `pnpm db:start | db:reset | db:types`. Only claim something works after running the relevant command.

## Git rules

- Never push to `main` or `dev`. Branch from `dev`: `feat/dev-<topic>`, `fix/dev-<topic>`, `docs/non-dev-<topic>`. PRs target `dev`, need 1 dev approval. See `docs/git-workflow.md`.
- **Commits: English Conventional Commits**, `type(scope): imperative description`.
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`.
  - Scopes: `repo`, `web`, `admin`, `database`, `docs`, `ci`, plus feature areas like `engine` or `transfers`.
  - One logical change per commit. Example: `feat(engine): add fee calculation with minimum fee`.
- Do not commit `.env*`, keys or generated secrets.
- Link the issue in the PR (`Closes #n`). Work only on what the issue asks.

## Domain rules (do not break)

1. **Money is never a JS `number` float.** Use `numeric` in Postgres and a decimal library (or integer minor units) in TypeScript. Round per `currencies.decimals` (USD 2, BTC 8, SAT 0).
2. **Calculations are validated on the server.** The client may preview, but `/api` routes recompute conversion, fee and received amount before creating a transfer.
3. **Fee is shown separately from the exchange rate.** Each transfer stores a snapshot (rate, fee, ids of the rate and fee rule used).
4. **State machine** (enforced by a DB trigger, mirror it in services): `Created → Processing | Cancelled`, `Processing → Completed | Failed`. Terminal states are final; financial fields are immutable.
5. Transfers, rates and fees are written only through server code using the service role. The service role key never reaches the browser.

## Database rules

- Migrations live in `packages/database/supabase/migrations/`. Never edit a migration that is merged to `dev`; add a new one.
- Every new table needs RLS enabled with explicit policies.
- After schema changes, regenerate types with `pnpm db:types`.

## Definition of done

`pnpm lint`, `pnpm typecheck` and `pnpm test` pass; calculation or state-machine changes include unit tests; user-facing changes are checked in the running app; docs updated if behavior or API changed.

## Skills

Recommended skills and plugins are tracked in `docs/agent-skills.md` (to be defined).
