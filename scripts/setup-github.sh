#!/usr/bin/env bash
# Creates labels, milestones and issues from docs/roadmap.md.
# Safe to re-run: existing labels, milestones and issue titles are skipped.
#
# Usage:
#   scripts/setup-github.sh            # dry run, prints what would be created
#   scripts/setup-github.sh --apply    # creates everything in the current repo
set -euo pipefail

APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true

REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
echo "Repo: $REPO ($([[ $APPLY == true ]] && echo APPLY || echo DRY RUN))"

M1="Milestone 1: Discovery & Architecture Baseline"
M2="Milestone 2: Core Simulation & Business Rules"
M3="Milestone 3: Administrative Dashboard & Bitcoin/Lightning Specs"

EXISTING_MILESTONES="$(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title')"
EXISTING_ISSUES="$(gh issue list --state all --limit 1000 --json title --jq '.[].title')"
EXISTING_LABELS="$(gh label list --limit 200 --json name --jq '.[].name')"

has_line() { grep -Fxq -- "$2" <<<"$1"; }

label() { # name color description
  has_line "$EXISTING_LABELS" "$1" && return 0
  echo "label: $1"
  [[ $APPLY == true ]] && gh label create "$1" --color "$2" --description "$3" >/dev/null
  return 0
}

milestone() { # title description
  has_line "$EXISTING_MILESTONES" "$1" && return 0
  echo "milestone: $1"
  [[ $APPLY == true ]] && gh api "repos/$REPO/milestones" -f title="$1" -f description="$2" >/dev/null
  return 0
}

issue() { # milestone labels title
  local ms="$1" labels="$2" title="$3"
  has_line "$EXISTING_ISSUES" "$title" && return 0
  echo "issue [$labels] $title"
  [[ $APPLY == true ]] && gh issue create --title "$title" --milestone "$ms" --label "$labels" \
    --body "Parte del roadmap: ver [docs/roadmap.md](https://github.com/$REPO/blob/dev/docs/roadmap.md).

Rama sugerida: \`feat/dev-...\` (Devs) o \`docs/non-dev-...\` (Non-Devs), creada desde \`dev\`. PR hacia \`dev\` con \`Closes #<este issue>\`." >/dev/null
  return 0
}

# --- Labels ---------------------------------------------------------------
label dev       1d76db "Trabajo del track técnico"
label non-dev   d93f0b "Trabajo del track estratégico"
label docs      0075ca "Documentación y especificaciones"
label db        5319e7 "Esquema, migraciones y Supabase"
label engine    fbca04 "Conversión, comisiones y máquina de estados"
label ui        0e8a16 "Interfaz de remitente/destinatario"
label admin     b60205 "Panel administrativo"
label blocked   000000 "Bloqueado por otra tarea"

# --- Milestones -----------------------------------------------------------
milestone "$M1" "Equipo alineado, repo listo y modelo de datos definido."
milestone "$M2" "Una transferencia simulada de punta a punta con cálculos correctos."
milestone "$M3" "Monitoreo, calidad y cierre del entregable con la visión Bitcoin."

# --- Milestone 1: Dev -----------------------------------------------------
issue "$M1" "dev"      "Inicializar monorepo (pnpm workspaces + Turborepo)"
issue "$M1" "dev"      "Configuración compartida en packages/config (TypeScript, ESLint, Prettier, Tailwind)"
issue "$M1" "dev,db"   "Crear proyecto Supabase, variables de entorno y .env.example"
issue "$M1" "dev,db"   "Migración inicial: enums, profiles, currencies, exchange_rates, fee_rules, transfers, history y audit_logs"
issue "$M1" "dev,db"   "Políticas RLS y seed de monedas con tasas estáticas"
issue "$M1" "dev,db"   "Generar tipos TypeScript desde el esquema (db:types)"
issue "$M1" "dev"      "Workflow de CI en GitHub Actions: lint, typecheck, test, build"
issue "$M1" "dev"      "Activar Branch Protection en main y dev"
issue "$M1" "dev,docs" "Documentar arquitectura base en docs/architecture.md"

# --- Milestone 1: Non-Dev -------------------------------------------------
issue "$M1" "non-dev,docs" "Investigación de mercado de remesas y puntos de fricción"
issue "$M1" "non-dev,docs" "Mapeo de competidores (tarifas, transparencia de tasa, tiempos, confianza)"
issue "$M1" "non-dev,docs" "Definir Personas: remitente y destinatario"
issue "$M1" "non-dev,docs" "User journey inicial del flujo de remesa"
issue "$M1" "non-dev,ui"   "Bocetos iniciales de UX (wireframes de baja fidelidad)"

# --- Milestone 2: Dev -----------------------------------------------------
issue "$M2" "dev,engine" "Motor de conversión: tasa por par, inversa y redondeo por decimales de moneda"
issue "$M2" "dev,engine" "Sistema de cálculo de comisiones mostrado separado de la tasa"
issue "$M2" "dev,engine" "Endpoint de cotización /api/quote con validación server-side"
issue "$M2" "dev,engine" "Creación de transferencias con ID único y snapshot de tasa y fee"
issue "$M2" "dev,engine" "Máquina de estados de transferencias (BD y servicio)"
issue "$M2" "dev"        "Autenticación con Supabase Auth para remitente y destinatario"
issue "$M2" "dev,ui"     "UI del remitente: monto, destino, desglose y confirmación"
issue "$M2" "dev,ui"     "UI del destinatario y detalle de una transferencia"
issue "$M2" "dev,ui"     "Historial de transacciones con estado en tiempo real (Realtime)"

# --- Milestone 2: Non-Dev -------------------------------------------------
issue "$M2" "non-dev,docs" "Matriz detallada del modelo de tarifas (Fee Model)"
issue "$M2" "non-dev,docs" "Modelo de conversión: cómo se comunican tasa y fees al usuario"
issue "$M2" "non-dev,docs" "Flujo del ciclo de vida de la transferencia"
issue "$M2" "non-dev,docs" "Definir qué información necesita el usuario antes de confirmar"
issue "$M2" "non-dev,ui"   "Wireframes de alta fidelidad / prototipo"

# --- Milestone 3: Dev -----------------------------------------------------
issue "$M3" "dev,admin"  "Panel administrativo: listado, filtros y métricas de transferencias"
issue "$M3" "dev,admin"  "Simulación de completar o fallar transferencias (acción admin + job)"
issue "$M3" "dev,admin"  "Vista de audit_logs y transfer_history para admin"
issue "$M3" "dev,engine" "Pruebas unitarias del cálculo y de las transiciones de estado"
issue "$M3" "dev"        "Demo end-to-end de una transferencia con datos de demo"
issue "$M3" "dev,docs"   "Documentación de la API (docs/api.md)"
issue "$M3" "dev,docs"   "Arquitectura de conexión futura a Bitcoin/Lightning"

# --- Milestone 3: Non-Dev -------------------------------------------------
issue "$M3" "non-dev,docs" "Especificar KPIs: completitud, abandono, tamaño promedio y retención"
issue "$M3" "non-dev,docs" "Reporte de oportunidad de Bitcoin en remesas"
issue "$M3" "non-dev,ui"   "Diseño de recibos y pantallas de confirmación"
issue "$M3" "non-dev,ui"   "Definir presentación del historial de transacciones"
issue "$M3" "non-dev,docs" "Flujo UX/pagos final y recomendación de producto"
issue "$M3" "non-dev,docs" "Guion y material de la presentación final"

echo "Done."
