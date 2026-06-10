#!/usr/bin/env bash
#
# clawhub publish – publish skills to ClawHub (clawhub.ai)
#
# Usage:
#   ./scripts/publish.sh                    # publish all new/changed skills
#   ./scripts/publish.sh --skill <name>     # publish a single skill
#   ./scripts/publish.sh --dry-run          # preview only (no upload)
#   ./scripts/publish.sh --owner @other     # override default owner
#
# Configuration: .env (see .env.example)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Load .env if present
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ------ arg parsing ------
DRY_RUN=false
OWNER="${CLAWHUB_OWNER:-}"
SKILL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --owner)   OWNER="$2"; shift 2 ;;
    --skill)   SKILL="$2"; shift 2 ;;
    --help|-h)
      cat <<'HELP'
Usage: publish.sh [--dry-run] [--skill <name>] [--owner <handle>]

  --dry-run        Preview publish plan without uploading
  --skill <name>   Publish a single skill folder (default: all skills)
  --owner <handle> Override the default owner from .env

How it decides what to publish:
  With --skill <name>:   publishes that one folder unconditionally
  Without --skill:       runs clawhub sync, which scans all folders and
                         only uploads skills that are new or have changed
                         (version bump in SKILL.md frontmatter).
HELP
      exit 0
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

# ------ prerequisites ------
check_prereqs() {
  log_info "Checking prerequisites..."

  if ! command -v node &>/dev/null; then
    log_error "Node.js is not installed. Please install Node.js >= 18."
    exit 1
  fi

  local node_ver
  node_ver=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$node_ver" -lt 18 ]; then
    log_error "Node.js >= 18 required (found v$(node -v))."
    exit 1
  fi

  if ! command -v npm &>/dev/null; then
    log_error "npm is not installed."
    exit 1
  fi

  if ! command -v clawhub &>/dev/null; then
    log_info "Installing clawhub CLI..."
    npm install -g clawhub
  fi

  log_info "clawhub version: $(clawhub --version 2>/dev/null || echo 'unknown')"
}

# ------ login check ------
check_login() {
  log_info "Checking clawhub login status..."

  if ! clawhub token &>/dev/null; then
    log_warn "Not logged in to ClawHub. Starting login flow..."
    clawhub login
    if ! clawhub token &>/dev/null; then
      log_error "Login failed. Please run 'clawhub login' manually and retry."
      exit 1
    fi
  fi

  log_info "Authenticated to ClawHub."
}

# ------ single skill publish ------
publish_single() {
  local skill_dir="$ROOT_DIR/$SKILL"
  local skill_md="$skill_dir/SKILL.md"

  if [ ! -f "$skill_md" ]; then
    log_error "SKILL.md not found in $skill_dir"
    exit 1
  fi

  log_info "Publishing single skill: $SKILL"

  local args=("$skill_dir")

  # Extract metadata from SKILL.md frontmatter
  local slug name version
  slug=$(awk '/^name:/ {print $2; exit}' "$skill_md")
  name=$(awk '/^description:/ {in_desc=1; next} in_desc && /^  / {gsub(/^  /,""); printf "%s ", $0} in_desc && !/^  / {exit}' "$skill_md" | sed 's/ $//')
  version=$(awk '/^version:/ {print $2; exit}' "$skill_md")

  [ -n "$slug" ]    && args+=(--slug "$slug")
  [ -n "$version" ] && args+=(--version "$version")
  [ -n "$OWNER" ]   && args+=(--owner "$OWNER")

  if [ "$DRY_RUN" = true ]; then
    log_info "=== DRY RUN (would publish $slug@$version to ${OWNER:-personal}) ==="
    log_info "Files in $skill_dir:"
    find "$skill_dir" -type f -not -path '*/.git/*' | sort
    return
  fi

  log_info "Slug: $slug, Version: $version, Owner: ${OWNER:-personal}"
  clawhub publish "${args[@]}"
}

# ------ sync all skills ------
publish_all() {
  local sync_args=(--all)

  if [ "$DRY_RUN" = true ]; then
    sync_args+=(--dry-run)
    log_info "=== DRY RUN MODE (no changes will be made) ==="
  fi

  [ -n "$OWNER" ] && sync_args+=(--owner "$OWNER")

  log_info "Running: clawhub sync ${sync_args[*]}"
  echo ""

  clawhub sync "${sync_args[@]}"
}

# ------ confirm ------
do_confirm() {
  if [ "$DRY_RUN" = true ]; then
    log_info "Dry run complete. Review the plan above, then run without --dry-run to publish."
    return
  fi

  echo ""
  read -r -p "Publish the skills listed above? [y/N] " yn
  case "$yn" in
    [Yy]|[Yy][Ee][Ss]) ;;
    *)
      log_info "Aborted by user."
      exit 0
      ;;
  esac
}

# ------ main ------
main() {
  echo ""
  log_info "========== ClawHub Skill Publisher =========="
  echo ""

  check_prereqs
  check_login

  if [ -n "$SKILL" ]; then
    publish_single
  else
    # Always dry-run first for safety
    if [ "$DRY_RUN" = false ]; then
      log_info "Step 1/2 – Preview (dry-run)..."
      echo ""
      clawhub sync --dry-run --all ${OWNER:+--owner "$OWNER"} || {
        log_error "Dry-run failed. Fix the issues above and retry."
        exit 1
      }

      echo ""
      echo "----------------------------------------------"
      do_confirm

      echo ""
      log_info "Step 2/2 – Publishing..."
      echo ""
    fi

    publish_all
  fi

  echo ""
  log_info "Done."
}

main
