#!/usr/bin/env bash
# tf.sh — Terraform wrapper for harvester-dc-terraform
#
# Usage: ./tf.sh <action> --region <region> --layer <layer> [options] [-- <terraform args>]
#
# Actions:   apply | destroy | plan | output | init | fmt | validate
# Layers:    bootstrap | rancher-auth | management | tenants  (or their 00-/01-/02-/03- prefix forms)
#
# Examples:
#   ./tf.sh apply   --region lk --layer bootstrap
#   ./tf.sh apply   --region lk --layer rancher-auth
#   ./tf.sh plan    --region lk --layer management
#   ./tf.sh destroy --region lk --layer management
#   ./tf.sh apply   --region lk --layer bootstrap --skip-validate -- -target=module.rancher_bootstrap

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

log()  { printf "\n%s▶  %s%s\n\n" "${CYAN}${BOLD}" "$*" "${RESET}"; }
ok()   { printf "%s✔  %s%s\n"    "${GREEN}"         "$*" "${RESET}"; }
warn() { printf "%s⚠  %s%s\n"    "${YELLOW}"        "$*" "${RESET}"; }
err()  { printf "%s✖  %s%s\n"    "${RED}"           "$*" "${RESET}" >&2; exit 1; }
sep()  { printf "%s────────────────────────────────────────────────%s\n" "${BOLD}" "${RESET}"; }

# ── Layer → directory mapping ─────────────────────────────────────────────────
layer_to_dir() {
  case "$1" in
    bootstrap|00-bootstrap)        echo "00-bootstrap" ;;
    rancher-auth|01-rancher-auth)  echo "01-rancher-auth" ;;
    management|02-management)      echo "02-management" ;;
    tenants|03-tenants)            echo "03-tenants" ;;
    *) err "Unknown layer '$1'. Valid values: bootstrap, rancher-auth, management, tenants" ;;
  esac
}

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<USAGE

  ${BOLD}Usage:${RESET} $(basename "$0") <action> --region <region> --layer <layer> [options]

  ${BOLD}Actions:${RESET}
    apply      Run terraform fmt → init (if needed) → validate → apply
    destroy    Run terraform destroy (with confirmation prompt)
    plan       Run terraform fmt → init (if needed) → validate → plan
    validate   Run terraform validate only
    output     Show terraform outputs
    init       Run terraform init
    fmt        Run terraform fmt across the entire repo

  ${BOLD}Required:${RESET}
    --region <name>    Region directory (e.g. lk)
    --layer  <name>    bootstrap | rancher-auth | management | tenants

  ${BOLD}Options:${RESET}
    --init             Force terraform init even if .terraform/ already exists
    --skip-init        Skip terraform init entirely
    --skip-fmt         Skip terraform fmt
    --skip-validate    Skip terraform validate
    --                 Pass remaining arguments directly to terraform

  ${BOLD}Examples:${RESET}
    $(basename "$0") apply   --region lk --layer bootstrap
    $(basename "$0") apply   --region lk --layer rancher-auth
    $(basename "$0") plan    --region lk --layer management
    $(basename "$0") destroy --region lk --layer management
    $(basename "$0") apply   --region lk --layer bootstrap -- -target=module.rancher_bootstrap

USAGE
  exit 1
}

# ── Parse arguments ───────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && usage

ACTION="$1"; shift

REGION=""
LAYER=""
FORCE_INIT=false
SKIP_INIT=false
SKIP_FMT=false
SKIP_VALIDATE=false
PASSTHROUGH=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)         REGION="$2";          shift 2 ;;
    --layer)          LAYER="$2";           shift 2 ;;
    --init)           FORCE_INIT=true;      shift ;;
    --skip-init)      SKIP_INIT=true;       shift ;;
    --skip-fmt)       SKIP_FMT=true;        shift ;;
    --skip-validate)  SKIP_VALIDATE=true;   shift ;;
    --)               shift; PASSTHROUGH+=("$@"); break ;;
    -*)               err "Unknown option: $1" ;;
    *)                PASSTHROUGH+=("$1");  shift ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────────────
[[ -z "$REGION" ]] && err "--region is required"
[[ -z "$LAYER"  ]] && err "--layer is required"

LAYER_DIR="$(layer_to_dir "$LAYER")"
TARGET_DIR="$SCRIPT_DIR/environments/$REGION/$LAYER_DIR"

[[ ! -d "$TARGET_DIR" ]] && err "Layer directory not found: $TARGET_DIR"

# ── Auto-discover secret var files ────────────────────────────────────────────
VAR_FILE_ARGS=()
shopt -s nullglob
for f in "$TARGET_DIR"/*.secret.tfvars; do
  VAR_FILE_ARGS+=("-var-file=$(realpath "$f")")
done
shopt -u nullglob

# ── Header ────────────────────────────────────────────────────────────────────
sep
printf "  %sRegion%s  : %s\n"  "${BOLD}" "${RESET}" "$REGION"
printf "  %sLayer%s   : %s → %s\n" "${BOLD}" "${RESET}" "$LAYER" "$LAYER_DIR"
printf "  %sAction%s  : %s\n"  "${BOLD}" "${RESET}" "$ACTION"
printf "  %sDir%s     : %s\n"  "${BOLD}" "${RESET}" "$TARGET_DIR"
if [[ ${#VAR_FILE_ARGS[@]} -gt 0 ]]; then
  for vf in "${VAR_FILE_ARGS[@]}"; do
    printf "  %sVar file%s: %s\n" "${BOLD}" "${RESET}" "${vf#*=}"
  done
else
  warn "No *.secret.tfvars found in $TARGET_DIR"
fi
[[ ${#PASSTHROUGH[@]} -gt 0 ]] && printf "  %sExtra%s   : %s\n" "${BOLD}" "${RESET}" "${PASSTHROUGH[*]}"
sep

# ── Destroy: require explicit confirmation ────────────────────────────────────
if [[ "$ACTION" == "destroy" ]]; then
  echo ""
  warn "You are about to DESTROY resources in region=${REGION} layer=${LAYER}."
  warn "This is irreversible. All managed infrastructure in this layer will be removed."
  echo ""
  read -rp "  Type the layer name to confirm destruction [${LAYER}]: " CONFIRM
  echo ""
  [[ "$CONFIRM" != "$LAYER" ]] && { warn "Aborted — confirmation did not match."; exit 1; }
fi

# ── Change to target directory ────────────────────────────────────────────────
cd "$TARGET_DIR"

# ── fmt (skip for destroy/output/init/fmt-only actions) ──────────────────────
if [[ "$SKIP_FMT" == false ]] && [[ "$ACTION" =~ ^(apply|plan|validate)$ ]]; then
  log "terraform fmt (repo-wide)"
  terraform fmt -recursive "$SCRIPT_DIR"
  ok "fmt complete"
fi

# ── init ──────────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "init" ]]; then
  log "terraform init"
  terraform init ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
  ok "init complete"
  exit 0
fi

if [[ "$SKIP_INIT" == false ]]; then
  if [[ "$FORCE_INIT" == true || ! -d ".terraform" ]]; then
    log "terraform init"
    terraform init
    ok "init complete"
  fi
fi

# ── fmt-only action ───────────────────────────────────────────────────────────
if [[ "$ACTION" == "fmt" ]]; then
  log "terraform fmt (repo-wide)"
  terraform fmt -recursive "$SCRIPT_DIR" ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
  ok "fmt complete"
  exit 0
fi

# ── validate ──────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "validate" ]]; then
  log "terraform validate"
  terraform validate ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
  ok "validate complete"
  exit 0
fi

if [[ "$SKIP_VALIDATE" == false ]] && [[ "$ACTION" =~ ^(apply|plan)$ ]]; then
  log "terraform validate"
  terraform validate
  ok "validate complete"
fi

# ── Main action ───────────────────────────────────────────────────────────────
case "$ACTION" in
  apply)
    log "terraform apply"
    terraform apply ${VAR_FILE_ARGS[@]+"${VAR_FILE_ARGS[@]}"} ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
    ;;
  destroy)
    log "terraform destroy"
    terraform destroy ${VAR_FILE_ARGS[@]+"${VAR_FILE_ARGS[@]}"} ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
    ;;
  plan)
    log "terraform plan"
    terraform plan ${VAR_FILE_ARGS[@]+"${VAR_FILE_ARGS[@]}"} ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
    ;;
  output)
    log "terraform output"
    terraform output ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
    ;;
  *)
    err "Unknown action '$ACTION'. Run $(basename "$0") --help for usage."
    ;;
esac

ok "Done."
