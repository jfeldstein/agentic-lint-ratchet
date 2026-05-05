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

