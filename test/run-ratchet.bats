#!/usr/bin/env bats

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export REPO_DIR="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO_DIR"

  # Minimal prompt file.
  printf '%s\n' 'hello' >"$REPO_DIR/PROMPT.md"
}

@test "uses absolute RATCHET_PROMPT_FILE without joining cwd" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="$REPO_DIR/PROMPT.md" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" == *"CURSOR_API_KEY is required"* ]]
}

@test "errors when prompt file missing" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="DOES_NOT_EXIST.md" \
    CURSOR_API_KEY="cursor_fake" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing prompt file:"* ]]
}

@test "errors on unsupported runtime with supported list" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="$REPO_DIR/PROMPT.md" \
    RATCHET_AGENT="bogus" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported agent runtime: bogus"* ]]
  [[ "$output" == *"Supported agents: cursor, pi"* ]]
}

@test "claude runtime currently unsupported" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="$REPO_DIR/PROMPT.md" \
    RATCHET_AGENT="claude" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Supported agents: cursor, pi"* ]]
}

@test "opencode runtime currently unsupported" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="$REPO_DIR/PROMPT.md" \
    RATCHET_AGENT="opencode" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Supported agents: cursor, pi"* ]]
}

@test "pi runtime reports missing required env vars with workflow guidance" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="$REPO_DIR/PROMPT.md" \
    RATCHET_AGENT="pi" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" == *"LITELLM_BASE_URL"* ]]
  [[ "$output" == *"LITELLM_API_KEY"* ]]
  [[ "$output" == *"PI_MODEL"* ]]
  [[ "$output" == *"workflow env:"* ]]
}

@test "pi runtime reports only still-missing vars" {
  run env -i \
    PATH="$PATH" \
    GITHUB_WORKSPACE="$REPO_DIR" \
    RATCHET_PROMPT_FILE="$REPO_DIR/PROMPT.md" \
    RATCHET_AGENT="pi" \
    LITELLM_BASE_URL="https://litellm.example.test/v1" \
    node "$PWD/scripts/run-ratchet.mjs"

  [ "$status" -eq 1 ]
  [[ "$output" != *"LITELLM_BASE_URL"* ]]
  [[ "$output" == *"LITELLM_API_KEY"* ]]
  [[ "$output" == *"PI_MODEL"* ]]
}

