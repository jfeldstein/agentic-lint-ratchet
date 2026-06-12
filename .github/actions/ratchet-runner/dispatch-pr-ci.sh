#!/usr/bin/env bash
# Dispatch workflow_dispatch CI for the ratchet PR updated during this Actions run.
# Expects: GH_TOKEN, GITHUB_REPOSITORY, RUN_STARTED_AT, PULL_REQUEST_WORKFLOWS,
#          RATCHET_BRANCH_PREFIX, CONFIG_PATH, RATCHET_ENV_PREFIX, PR_SIGNATURE_PREFIX
set -euo pipefail

if [[ -z "${PULL_REQUEST_WORKFLOWS:-}" ]] || [[ -z "${RUN_STARTED_AT:-}" ]]; then
  echo "::error::PULL_REQUEST_WORKFLOWS and RUN_STARTED_AT are required." >&2
  exit 1
fi

ENV_PREFIX="${RATCHET_ENV_PREFIX:?RATCHET_ENV_PREFIX is required}"
SIG_PREFIX="${PR_SIGNATURE_PREFIX:?PR_SIGNATURE_PREFIX is required}"

CONFIG_PATH="${CONFIG_PATH:-}"
if [[ -z "$CONFIG_PATH" ]]; then
  cfg_var="${ENV_PREFIX}_CONFIG_PATH"
  CONFIG_PATH="${!cfg_var:-}"
fi
if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "::error::Config not found at $CONFIG_PATH (required for pull_request_workflows dispatch)." >&2
  exit 1
fi

base_var="${ENV_PREFIX}_BASE_BRANCH"
WORKFLOW_REF="${!base_var:-}"
if [[ -z "$WORKFLOW_REF" ]]; then
  WORKFLOW_REF="$(sed -n 's/^  base_branch: //p' "$CONFIG_PATH" | tr -d '[:space:]')"
fi
if [[ -z "$WORKFLOW_REF" ]]; then
  echo "::error::Missing repo.base_branch in $CONFIG_PATH (required for pull_request_workflows dispatch)." >&2
  exit 1
fi

sig_var="${ENV_PREFIX}_SIGNATURE"
RATCHET_SIGNATURE="${!sig_var:-}"
if [[ -z "$RATCHET_SIGNATURE" ]]; then
  CONFIG_ABS="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$CONFIG_PATH")"
  RATCHET_SIGNATURE="#${SIG_PREFIX}-$(shasum -a 256 "$CONFIG_ABS" | awk '{print $1}')"
fi

RATCHET_BRANCH_PREFIX="${RATCHET_BRANCH_PREFIX:-}"

echo "Using workflow ref (repo.base_branch): $WORKFLOW_REF"
echo "Run started at: $RUN_STARTED_AT"

branch="$(
  gh pr list --repo "$GITHUB_REPOSITORY" --state open --base "$WORKFLOW_REF" \
    --json headRefName,updatedAt,body \
    | jq -r --arg sig "$RATCHET_SIGNATURE" --arg since "$RUN_STARTED_AT" --arg p "$RATCHET_BRANCH_PREFIX" '
      [.[]
        | select(.headRefName | startswith($p))
        | select(.body | contains($sig))
        | select(.updatedAt >= $since)
      ] | sort_by(.updatedAt) | last | .headRefName // empty'
)"

if [[ -z "$branch" ]]; then
  echo "No signed ratchet PR updated since run start; skipping CI dispatch."
  exit 0
fi

mapfile -t workflows < <(printf '%s\n' "$PULL_REQUEST_WORKFLOWS" | sed '/^[[:space:]]*$/d')
if [[ ${#workflows[@]} -eq 0 ]]; then
  echo "pull_request_workflows is empty; skipping CI dispatch."
  exit 0
fi

workflow_dispatch_ref() {
  local wf="$1"
  if gh workflow view "$wf" --repo "$GITHUB_REPOSITORY" --ref "$branch" --yaml >/dev/null 2>&1; then
    echo "$branch"
    return 0
  fi
  if gh workflow view "$wf" --repo "$GITHUB_REPOSITORY" --ref "$WORKFLOW_REF" --yaml >/dev/null 2>&1; then
    echo "$WORKFLOW_REF"
    return 0
  fi
  return 1
}

for wf in "${workflows[@]}"; do
  if ! workflow_dispatch_ref "$wf" >/dev/null; then
    echo "::error::Workflow $wf not found on branch $branch or ref $WORKFLOW_REF (needs workflow_dispatch with required ref input)." >&2
    exit 1
  fi
done

echo "Dispatching CI for branch updated this run: $branch"
for wf in "${workflows[@]}"; do
  dispatch_ref="$(workflow_dispatch_ref "$wf")"
  echo "Dispatching $wf on ref $dispatch_ref (checkout ref=$branch)"
  gh workflow run "$wf" --repo "$GITHUB_REPOSITORY" --ref "$dispatch_ref" -f "ref=${branch}"
done
