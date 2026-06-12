#!/usr/bin/env bash
# Dedupe preflight: parse config, export <RATchet_ENV_PREFIX>_*, decide should_run.
# Required env: RATCHET_ENV_PREFIX, PR_SIGNATURE_PREFIX
# Optional env: CONFIG_PATH, RATCHET_BRANCH_PREFIX, PULL_REQUEST_WORKFLOWS
# Caller may preset <PREFIX>_CONFIG_PATH to override CONFIG_PATH.
set -euo pipefail

ENV_PREFIX="${RATCHET_ENV_PREFIX:?RATCHET_ENV_PREFIX is required}"
SIG_PREFIX="${PR_SIGNATURE_PREFIX:?PR_SIGNATURE_PREFIX is required}"
CONFIG_PATH_INPUT="${CONFIG_PATH:-}"
RATCHET_BRANCH_PREFIX="${RATCHET_BRANCH_PREFIX:-}"
PULL_REQUEST_WORKFLOWS="${PULL_REQUEST_WORKFLOWS:-}"

override_var="${ENV_PREFIX}_CONFIG_PATH"
if [[ -n "${!override_var:-}" ]]; then
  CONFIG_PATH="${!override_var}"
else
  CONFIG_PATH="$CONFIG_PATH_INPUT"
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "No config file found at '$CONFIG_PATH'; skipping dedupe preflight (fresh repo)."
  echo "should_run=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

CONFIG_ABS="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$CONFIG_PATH")"
SIGNATURE="#${SIG_PREFIX}-$(shasum -a 256 "$CONFIG_ABS" | awk '{print $1}')"
_repo_fields="$(python3 -c "
import sys
try:
    import yaml
except ImportError:
    sys.exit(2)
cfg = yaml.safe_load(open(sys.argv[1])) or {}
repo = cfg.get('repo') or {}
print(repo.get('repository', ''), end='')
print(' ', end='')
print(repo.get('base_branch') or '', end='')
" "$CONFIG_ABS" 2>/dev/null)" || _repo_fields="$(
  awk '/^repo:/{f=1} f && /^[^ \t#]/ && !/^repo:/{f=0} f && /repository:/{r=$2} f && /base_branch:/{b=$2} END{print r, b}' "$CONFIG_ABS"
)"
read -r RATCHET_REPOSITORY RATCHET_BASE_BRANCH <<< "$_repo_fields"

if [[ -z "$RATCHET_REPOSITORY" ]]; then
  echo "::error::Missing repo.repository in $CONFIG_PATH"
  exit 1
fi
if [[ "$RATCHET_REPOSITORY" != "$GITHUB_REPOSITORY" ]]; then
  echo "::error::Config repo.repository ($RATCHET_REPOSITORY) must match the workflow repository ($GITHUB_REPOSITORY). Add this workflow to the target repo."
  exit 1
fi

echo "Config: $CONFIG_ABS"
echo "Repository: $RATCHET_REPOSITORY"
echo "Signature: $SIGNATURE"
echo "${ENV_PREFIX}_CONFIG_PATH=$CONFIG_ABS" >> "$GITHUB_ENV"
echo "${ENV_PREFIX}_SIGNATURE=$SIGNATURE" >> "$GITHUB_ENV"
echo "${ENV_PREFIX}_REPOSITORY=$RATCHET_REPOSITORY" >> "$GITHUB_ENV"
if [[ -n "$RATCHET_BASE_BRANCH" ]]; then
  echo "${ENV_PREFIX}_BASE_BRANCH=$RATCHET_BASE_BRANCH" >> "$GITHUB_ENV"
fi

if [[ -n "${PULL_REQUEST_WORKFLOWS:-}" ]] && [[ -z "$RATCHET_BASE_BRANCH" ]]; then
  echo "::error::pull_request_workflows is set but repo.base_branch is missing in $CONFIG_PATH"
  exit 1
fi

MATCHING_JSON="$(gh pr list --repo "$RATCHET_REPOSITORY" --state open \
  --json number,body,headRefName \
  | jq --arg sig "$SIGNATURE" --arg p "$RATCHET_BRANCH_PREFIX" \
      '[.[] | select((.body | contains($sig)) and (.headRefName | startswith($p)))]')"

if [[ "$(echo "$MATCHING_JSON" | jq 'length')" -eq 0 ]]; then
  echo "should_run=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

all_green=true
while read -r pr_num; do
  [[ -n "$pr_num" ]] || continue
  if ! gh pr checks "$pr_num" --repo "$RATCHET_REPOSITORY" --required >/dev/null 2>&1; then
    all_green=false
    echo "Open signed ratchet PR #$pr_num needs babysitting (required checks not all green)."
    break
  fi
done < <(echo "$MATCHING_JSON" | jq -r '.[].number')

if $all_green; then
  echo "Open signed ratchet PR(s) have green required checks; skipping new agent run."
  echo "should_run=false" >> "$GITHUB_OUTPUT"
else
  echo "should_run=true" >> "$GITHUB_OUTPUT"
fi
