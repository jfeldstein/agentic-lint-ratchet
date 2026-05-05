#!/usr/bin/env bats

@test "preflight uses realpath for config (no naive PWD prefix)" {
  # This is a static check: ensure we use python realpath (covers abs paths too).
  run bash -lc "grep -n \"os.path.realpath\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]
}

@test "preflight exports should_run output and gates agent step" {
  run bash -lc "grep -n \"should_run=\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]

  run bash -lc "grep -n \"steps.preflight.outputs.should_run\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]
}

