#!/usr/bin/env bats

@test "values reference RATCHET.md on disk for DALC systemPromptFile" {
  run grep -q 'systemPromptFile: skills/lint-ratchet/resources/RATCHET.md' values.yaml
  [ "$status" -eq 0 ]
  [[ -f skills/lint-ratchet/resources/RATCHET.md ]]
}
