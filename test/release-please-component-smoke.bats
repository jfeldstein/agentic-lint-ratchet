#!/usr/bin/env bats
#
# End-to-end release-please check (pushes ephemeral branches). Skip unless:
#   ALLOW_RP_SMOKE_PUSH=1

@test "release-please component smoke (opt-in GitHub push)" {
  if [[ "${ALLOW_RP_SMOKE_PUSH:-}" != "1" ]]; then
    skip "set ALLOW_RP_SMOKE_PUSH=1 to run pushes + dry-run assertions"
  fi
  run bash "${BATS_TEST_DIRNAME}/../scripts/release-please-component-smoke.sh"
  echo "$output"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"OK: linked-versions keeps"* ]]
}
