#!/usr/bin/env bash
# Opt-in end-to-end check: push ephemeral branches to origin, run release-please --dry-run,
# assert component-scoped conventional commits land in the matching package section only.
#
# Requires: gh auth, git push permission, Node/npx, Python 3, jq.
# Usage:
#   ALLOW_RP_SMOKE_PUSH=1 ./scripts/release-please-component-smoke.sh
#
# Env:
#   WORKSPACE_ROOT   — defaults to repo root (auto-detected from script path)
#   REPO_SLUG        — defaults to origin remote (owner/name)

set -euo pipefail

if [[ "${ALLOW_RP_SMOKE_PUSH:-}" != "1" ]]; then
  echo "Refusing to push branches without ALLOW_RP_SMOKE_PUSH=1" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TMP="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

cd "$ROOT"
REPO_SLUG="${REPO_SLUG:-$(git remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')}"
TOKEN="$(gh auth token)"
export GITHUB_TOKEN="$TOKEN"

CLONE="$TMP/r"
git clone --depth 1 "https://github.com/${REPO_SLUG}.git" "$CLONE"
cd "$CLONE"

TS="$(date +%s)"
BOOT="rp-smoke-base-${TS}"

git checkout -b "$BOOT"

sync_from_workspace() {
  cp "$ROOT/release-please-config.json" "$CLONE/"
  cp "$ROOT/.release-please-manifest.json" "$CLONE/"
  cp "$ROOT/CHANGELOG-chart.md" "$CLONE/"
  cp "$ROOT/values.yaml" "$CLONE/"
  cp "$ROOT/Chart.yaml" "$CLONE/"
  mkdir -p "$CLONE/skills/lint-ratchet" "$CLONE/.github/actions/lint-ratchet"
  rsync -a "$ROOT/skills/lint-ratchet/" "$CLONE/skills/lint-ratchet/"
  rsync -a "$ROOT/.github/actions/lint-ratchet/" "$CLONE/.github/actions/lint-ratchet/"
  if [[ -f "$ROOT/.github/workflows/release-please.yml" ]]; then
    mkdir -p "$CLONE/.github/workflows"
    cp "$ROOT/.github/workflows/release-please.yml" "$CLONE/.github/workflows/"
  fi
}

inject_bootstrap_sha() {
  local sha="$1"
  jq --arg s "$sha" '.["bootstrap-sha"] = $s' "$CLONE/release-please-config.json" >"$TMP/rp.cfg"
  mv "$TMP/rp.cfg" "$CLONE/release-please-config.json"
}

sync_from_workspace
git add -A
git commit -m "chore(ci): bootstrap release-please components for smoke test"
BOOT_COMMIT="$(git rev-parse HEAD)"
inject_bootstrap_sha "$BOOT_COMMIT"
git add release-please-config.json
git commit -m "chore(ci): set bootstrap-sha for smoke isolation"

git push -u origin "$BOOT"

run_dry_run() {
  local branch="$1"
  npx --yes release-please@latest release-pr \
    --dry-run \
    --repo-url "$REPO_SLUG" \
    --target-branch "$branch" \
    --token "$GITHUB_TOKEN" \
    2>&1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "ASSERT FAIL ($label): expected substring not found: $needle" >&2
    echo "--- output ---" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

# linked-versions: merged PR body must list skill/chart/action with the same semver.
assert_linked_versions_aligned() {
  local out="$1"
  printf '%s' "$out" | python3 -c "
import re, sys
text = sys.stdin.read()
pat = r'<details><summary>lint-ratchet-(?:skill|chart|action):\s*([\d.]+)'
vers = re.findall(pat, text)
if len(vers) < 3:
    print(f'ASSERT: expected 3 linked component summaries, got {vers!r}', file=sys.stderr)
    sys.exit(1)
if len(set(vers)) != 1:
    print(f'ASSERT: linked-versions semver mismatch {vers!r}', file=sys.stderr)
    sys.exit(1)
"
}

delete_remote_branch() {
  git push origin --delete "$1" >/dev/null 2>&1 || true
}

### Skill-only branch
SKILL_BR="rp-smoke-skill-${TS}"
git checkout -b "$SKILL_BR" "$BOOT"
echo "smoke" >"skills/lint-ratchet/.release-please-smoke"
git add skills/lint-ratchet/.release-please-smoke
git commit -m "feat(skill): smoke change under skills path only"
git push -u origin "$SKILL_BR"

OUT_SKILL="$(run_dry_run "$SKILL_BR")"
echo "$OUT_SKILL"
assert_contains "$OUT_SKILL" "lint-ratchet-skill" "skill component present"
assert_linked_versions_aligned "$OUT_SKILL"
assert_contains "$OUT_SKILL" "**skill:** smoke" "feat(skill) note"
delete_remote_branch "$SKILL_BR"

### Chart-only branch
CHART_BR="rp-smoke-chart-${TS}"
git checkout -b "$CHART_BR" "$BOOT"
printf '\n# release-please smoke %s\n' "$TS" >>templates/trigger-cronjob.yaml
git add templates/trigger-cronjob.yaml
git commit -m "feat(chart): smoke change under templates path only"
git push -u origin "$CHART_BR"

OUT_CHART="$(run_dry_run "$CHART_BR")"
echo "$OUT_CHART"
assert_contains "$OUT_CHART" "lint-ratchet-chart" "chart component present"
assert_linked_versions_aligned "$OUT_CHART"
assert_contains "$OUT_CHART" "**chart:** smoke" "feat(chart) note"
delete_remote_branch "$CHART_BR"

### Action-only branch
ACT_BR="rp-smoke-action-${TS}"
git checkout -b "$ACT_BR" "$BOOT"
printf '\n# release-please smoke %s\n' "$TS" >>".github/actions/lint-ratchet/action.yml"
git add .github/actions/lint-ratchet/action.yml
git commit -m "feat(action): smoke change under composite action path only"
git push -u origin "$ACT_BR"

OUT_ACT="$(run_dry_run "$ACT_BR")"
echo "$OUT_ACT"
assert_contains "$OUT_ACT" "lint-ratchet-action" "action component present"
assert_linked_versions_aligned "$OUT_ACT"
assert_contains "$OUT_ACT" "**action:** smoke" "feat(action) note"
delete_remote_branch "$ACT_BR"

delete_remote_branch "$BOOT"

echo "OK: linked-versions keeps skill/chart/action on one semver; dry-run shows merged release notes."
