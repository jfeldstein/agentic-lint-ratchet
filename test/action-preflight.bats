#!/usr/bin/env bats

@test "preflight uses realpath for config (no naive PWD prefix)" {
  run bash -lc "grep -n \"os.path.realpath\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]
}

@test "preflight default config path is .lint-ratchet.config.yml" {
  run bash -lc "grep -n \".lint-ratchet.config.yml\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]
}

@test "preflight honours LINT_RATCHET_CONFIG_PATH env override" {
  run bash -lc "grep -n \"LINT_RATCHET_CONFIG_PATH:-\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]
}

@test "preflight exports should_run output and gates agent step" {
  run bash -lc "grep -n \"should_run=\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]

  run bash -lc "grep -n \"steps.preflight.outputs.should_run\" .github/actions/lint-ratchet/action.yml"
  [ "$status" -eq 0 ]
}

