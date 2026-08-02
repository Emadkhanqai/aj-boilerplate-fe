#!/usr/bin/env bash
# auto-format.sh — PostToolUse(Edit|Write)
#
# Formats ONLY the file that was just edited.
#   .ts .tsx .mts .cts .html .scss .css .json .md -> prettier --write
#   .ts .tsx .mts .cts                            -> plus eslint --fix
#
# Never fails the session: a missing tool is a skip with a message, not an error.
# Informational output goes to stderr; stdout stays empty so the harness does not
# try to parse it as a hook response.
#
# Opt out for one session with: AJ_SKIP_FORMAT_HOOK=1

set -u

PAYLOAD="$(cat 2>/dev/null || true)"

log() { printf '[auto-format] %s\n' "$*" >&2; }

[ "${AJ_SKIP_FORMAT_HOOK:-0}" = "1" ] && exit 0

# ---------------------------------------------------------------------------
# Extract a string field from the hook JSON payload. Tries jq, then python3,
# then a sed fallback, so the hook works on a bare machine.
# ---------------------------------------------------------------------------
json_str() {
  _key="$1"
  [ -z "${PAYLOAD:-}" ] && return 0
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$PAYLOAD" | jq -r --arg k "$_key" \
      'getpath($k | split(".")) // empty' 2>/dev/null && return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$PAYLOAD" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    if isinstance(d, dict) and k in d:
        d = d[k]
    else:
        sys.exit(0)
print(d if isinstance(d, str) else json.dumps(d))
' "$_key" 2>/dev/null && return 0
  fi
  # Last resort: match the leaf key name only.
  _leaf="${_key##*.}"
  printf '%s' "$PAYLOAD" \
    | sed -n "s/.*\"${_leaf}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
    | head -n 1
}

FILE="$(json_str 'tool_input.file_path')"
[ -z "${FILE:-}" ] && FILE="$(json_str 'tool_input.notebook_path')"
[ -z "${FILE:-}" ] && exit 0
[ -f "$FILE" ] || exit 0

case "$FILE" in
  */node_modules/*|*/dist/*|*/.angular/*|*/.nx/*|*/coverage/*|*/.git/*) exit 0 ;;
esac

# api-types is generated from the OpenAPI document by `npm run generate:api`.
# Reformatting it would put a diff in a file nobody is allowed to hand-edit.
case "$FILE" in
  */libs/data-access/api-types/src/lib/types.ts) exit 0 ;;
esac

# Resolve to a physical path. If the workspace path and the tool's path disagree
# about symlinks (a real case: /tmp -> /private/tmp on macOS), the formatter can
# silently match nothing and report success.
FILE_DIR="$(cd "$(dirname "$FILE")" 2>/dev/null && pwd -P)" || exit 0
FILE="$FILE_DIR/$(basename "$FILE")"

# ---------------------------------------------------------------------------
# Prettier, plus eslint --fix for TypeScript
# ---------------------------------------------------------------------------
format_web() {
  if ! command -v npx >/dev/null 2>&1; then
    log "npx not installed — skipping ${FILE##*/}"
    return 0
  fi

  # Run from the nearest directory that has a package.json so the local
  # prettier/eslint config and binaries are the ones that get used.
  dir="$(cd "$(dirname "$FILE")" && pwd -P)"
  root=""
  while [ "$dir" != "/" ] && [ -n "$dir" ]; do
    if [ -f "$dir/package.json" ]; then root="$dir"; break; fi
    dir="$(dirname "$dir")"
  done
  [ -z "$root" ] && { log "no package.json above ${FILE##*/} — skipping"; return 0; }

  if ! (cd "$root" && npx --no-install prettier --write "$FILE" >/dev/null 2>&1); then
    log "prettier unavailable or failed on ${FILE##*/} — skipped"
    return 0
  fi

  case "$FILE" in
    *.ts|*.tsx|*.mts|*.cts)
      (cd "$root" && npx --no-install eslint --fix "$FILE" >/dev/null 2>&1) \
        || log "eslint --fix reported unfixable issues in ${FILE##*/}"
      ;;
  esac
  log "formatted ${FILE##*/}"
}

case "$FILE" in
  *.ts|*.tsx|*.mts|*.cts|*.html|*.scss|*.css|*.json|*.md) format_web ;;
  *)                                                      : ;;
esac

exit 0
