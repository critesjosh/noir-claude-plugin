#!/usr/bin/env bash
set -euo pipefail

# Sync whitelisted skills from the upstream Noir repo into this plugin.
# Fetched files are committed to git — end users never run this script.
#
# Usage:
#   bash scripts/sync-upstream-skills.sh              # fetch from master
#   bash scripts/sync-upstream-skills.sh --ref v1.0.0 # fetch from a tag/branch/SHA

REPO="noir-lang/noir"
SKILLS_DIR="skills"
METADATA_FILE="$SKILLS_DIR/.upstream-sync.json"

# Whitelisted upstream skills (directory names under .claude/skills/)
WHITELIST=(
  noir-idioms
  noir-optimize-acir
)

REF="master"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      REF="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--ref <branch|tag|sha>]" >&2
      exit 1
      ;;
  esac
done

# Resolve the commit SHA for the ref (best-effort; falls back to the ref string)
resolve_sha() {
  local sha
  sha=$(curl -sf -H "Accept: application/vnd.github.v3+json" \
    ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$REPO/commits/$REF" 2>/dev/null \
    | jq -r '.sha // empty' 2>/dev/null) || true
  echo "${sha:-$REF}"
}

echo "Syncing upstream skills from $REPO (ref: $REF)..."

SHA=$(resolve_sha)
echo "Resolved SHA: $SHA"

FETCHED=()
FAILED=()

for skill in "${WHITELIST[@]}"; do
  url="https://raw.githubusercontent.com/$REPO/$REF/.claude/skills/$skill/SKILL.md"
  dest="$SKILLS_DIR/$skill/SKILL.md"

  mkdir -p "$SKILLS_DIR/$skill"

  echo -n "  Fetching $skill... "
  if curl -sf "$url" -o "$dest"; then
    echo "ok ($(wc -c < "$dest") bytes)"
    FETCHED+=("$skill")
  else
    echo "FAILED"
    FAILED+=("$skill")
    rm -f "$dest"
    rmdir "$SKILLS_DIR/$skill" 2>/dev/null || true
  fi
done

# Write metadata
if command -v jq &>/dev/null; then
  jq -n \
    --arg source "https://github.com/$REPO" \
    --arg ref "$REF" \
    --arg sha "$SHA" \
    --arg synced_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson skills "$(printf '%s\n' "${FETCHED[@]}" | jq -R . | jq -s .)" \
    '{source: $source, ref: $ref, sha: $sha, synced_at: $synced_at, skills: $skills}' \
    > "$METADATA_FILE"
else
  # Fallback without jq
  cat > "$METADATA_FILE" <<EOF
{
  "source": "https://github.com/$REPO",
  "ref": "$REF",
  "sha": "$SHA",
  "synced_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "skills": [$(printf '"%s",' "${FETCHED[@]}" | sed 's/,$//')]
}
EOF
fi

echo ""
echo "=== Sync Summary ==="
echo "  Source: https://github.com/$REPO"
echo "  Ref:    $REF"
echo "  SHA:    $SHA"
echo "  Synced: ${FETCHED[*]:-none}"
[[ ${#FAILED[@]} -gt 0 ]] && echo "  Failed: ${FAILED[*]}"
echo "  Metadata: $METADATA_FILE"
