#!/usr/bin/env bats

@test "ratchet prompt makes scope steps bite-seeking" {
  run grep -q "Scope steps are bite-seeking too" skills/lint-ratchet/resources/RATCHET.md
  [ "$status" -eq 0 ]

  run grep -q "Before opening a config-only PR" skills/lint-ratchet/resources/RATCHET.md
  [ "$status" -eq 0 ]
}

@test "scope and tighten behavior use generalized bite controls" {
  run grep -q "Scope and tighten steps share bite bounds" skills/lint-ratchet/resources/RATCHET.md
  [ "$status" -eq 0 ]

  run grep -q "max_bite_steps_without_source_changes" skills/lint-ratchet/resources/RATCHET.md
  [ "$status" -eq 0 ]

  run grep -q "Scope and tighten behavior use the same bite controls" config/.lint-ratchet.config.example.yml
  [ "$status" -eq 0 ]

  run grep -q "max_bite_fix_files" .lint-ratchet.config.yml
  [ "$status" -eq 0 ]

  run bash -lc "! grep -R \"max_scope_\\|max_tighten_\" .lint-ratchet.config.yml config/.lint-ratchet.config.example.yml skills/lint-ratchet/resources/RATCHET.md"
  [ "$status" -eq 0 ]
}

@test "readme warns pinned action refs carry stale prompts" {
  run grep -q "Pinned action refs" README.md
  [ "$status" -eq 0 ]

  run grep -q "update the workflow .*action_ref.* together" README.md
  [ "$status" -eq 0 ]
}
