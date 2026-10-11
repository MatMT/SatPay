# Flujo de trabajo Git

## Ramas principales

| Rama   | Propósito                                             |
| ------ | ----------------------------------------------------- |
| `main` | Versión estable del entregable final.                 |
| `dev`  | Integración continua. Todo aporte se une primero aquí. |

`main` solo recibe PRs desde `dev` (releases / entregables). Nadie hace push directo a ninguna de las dos.

## Ramas de trabajo

Se crean siempre desde `dev` y se borran al hacer merge.

| Quién    | Patrón                  | Ejemplo                           |
| -------- | ----------------------- | --------------------------------- |
| Devs     | `feat/dev-<tema>`       | `feat/dev-conversion-engine`      |
| Devs     | `fix/dev-<tema>`        | `fix/dev-fee-rounding`            |
| Non-Devs | `docs/non-dev-<tema>`   | `docs/non-dev-personas-definition` |

## Pull Requests

1. Abrir PR hacia `dev` enlazando el issue (`Closes #n`).
2. Mínimo **1 aprobación** de `@MatMTByElias` o `@adiel23`.
3. Los checks de CI (lint, typecheck, test, build) deben pasar.
4. Merge con **squash** para mantener `dev` lineal y legible.

Los Non-Devs que solo tocan `/docs` no necesitan pasar por la CLI: pueden editar y abrir el PR desde la interfaz web de GitHub.

## Branch Protection Rules

Importar [`.github/rulesets/protect-main-and-dev.json`](../.github/rulesets/protect-main-and-dev.json) en *Settings → Rules → Rulesets → New ruleset → Import a ruleset*. Protege `main` y `dev` con PR obligatorio, 1 aprobación, hilos resueltos, squash, sin force push y sin borrado. El rol Admin del repo puede saltarse la aprobación **solo a través de un PR** (modo `pull_request`), para no bloquear al dueño del repo cuando el otro Dev no está disponible. Nunca puede hacer push directo.

Se deja fuera a propósito la regla de status checks: agregarla desde la UI cuando exista el workflow de CI (ver Notas). La restricción "`main` solo recibe PRs desde `dev`" no se puede imponer con rulesets; es una convención del equipo.

Detalle de lo que cubre:

### `dev`

- [x] Require a pull request before merging
  - [x] Required approvals: **1**
  - [x] Dismiss stale approvals when new commits are pushed
  - [x] Require approval of the most recent push
- [x] Require status checks to pass (`lint`, `typecheck`, `test`, `build`) y la rama al día con `dev`
- [x] Require conversation resolution before merging
- [x] Block force pushes
- [x] Restrict deletions
- [x] Allowed merge method: squash

### `main`

Lo mismo que `dev`, más:

- [x] Solo se acepta PR cuyo origen es `dev`
- [x] Required approvals: **1** de un Dev (`@MatMTByElias` o `@adiel23`)
- [x] Bypass solo para el rol Admin y únicamente vía PR (ver arriba)

### Notas

- `.github/CODEOWNERS` solicita review automáticamente al Dev correcto. No activar *Require review from Code Owners* para no bloquear PRs de `/docs` que aprueba un Dev de todos modos.
- Los checks de CI no existen hasta el primer workflow: activar esa regla cuando el issue de CI del Milestone 1 esté cerrado.
