#!/usr/bin/env bats

@test "ratchet prompt makes scope steps bite-seeking" {
  run grep -q "Scope steps are bite-seeking too" skills/lint-ratchet/resources/RATCHET.md
  [ "$status" -eq 0 ]

  run grep -q "Before opening a config-only PR" skills/lint-ratchet/resources/RATCHET.md
  [ "$status" -eq 0 ]
}

@test "ratchet config documents scope bite controls" {
  run grep -q "max_scope_steps_without_source_changes" config/.lint-ratchet.config.example.yml
  [ "$status" -eq 0 ]

  run grep -q "max_scope_fix_files" config/.lint-ratchet.config.example.yml
  [ "$status" -eq 0 ]

  run grep -q "max_scope_fix_loc" config/.lint-ratchet.config.example.yml
  [ "$status" -eq 0 ]
}

@test "readme warns pinned action refs carry stale prompts" {
  run grep -q "Pinned action refs" README.md
  [ "$status" -eq 0 ]

  run grep -q "update the workflow .*action_ref.* together" README.md
  [ "$status" -eq 0 ]
}
