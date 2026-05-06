#!/usr/bin/env bats

@test "sync_skill_version_to_values aligns lintRatchet.skillVersion with skills/lint-ratchet/package.json" {
  run python3 scripts/sync_skill_version_to_values.py
  [ "$status" -eq 0 ]

  ver="$(jq -r .version skills/lint-ratchet/package.json)"
  run grep -F "skillVersion: \"$ver\"" values.yaml
  [ "$status" -eq 0 ]
}

@test "values reference RATCHET.md on disk for DALC systemPromptFile" {
  run grep -q 'systemPromptFile: skills/lint-ratchet/resources/RATCHET.md' values.yaml
  [ "$status" -eq 0 ]
  [[ -f skills/lint-ratchet/resources/RATCHET.md ]]
}
