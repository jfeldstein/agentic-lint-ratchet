# agentic-ratchets

Progressive improvements, unobtrusive DX — autonomous **agentic ratchets** that open throttled PRs toward a quality goal, one slice at a time.

## What are agentic ratchets?

Each ratchet shares the same operating model:

- **Throttled PRs** — at most one in-flight ratchet-owned branch per config signature until CI is green and the PR can merge
- **Incremental progress** — small PRs toward a defined end state, not big-bang refactors
- **Signed PR bodies** — a config-derived token for dedupe and scheduling
- **Agent execution** — scheduled CI installs the Cursor Agent CLI and runs the ratchet prompt against your repo

See [docs/ratchets.md](docs/ratchets.md) for the full model.

## Available ratchets

| Name | Location | Status |
|------|----------|--------|
| **agentic-lint-ratchet** | [`.github/actions/lint-ratchet`](.github/actions/lint-ratchet) ([`RATCHET.md`](.github/actions/lint-ratchet/RATCHET.md)) · [docs/lint-ratchet.md](docs/lint-ratchet.md) | Available |
| **agentic-mutation-testing-ratchet** | [`.github/actions/mutation-testing-ratchet`](.github/actions/mutation-testing-ratchet) ([`RATCHET.md`](.github/actions/mutation-testing-ratchet/RATCHET.md)) · [docs/mutation-testing-ratchet.md](docs/mutation-testing-ratchet.md) | Available |

**agentic-lint-ratchet** adds and progressively tightens opinionated linting (Setup → Ratchet phases). Target config: `.lint-ratchet.config.yml`; branches: `lint-ratchet/*`.

**agentic-mutation-testing-ratchet** adds and expands mutation testing (Setup → Ratchet phases). Target config: `.mutation-ratchet.config.yml`; branches: `mutation-ratchet/*`.

## Adopt lint-ratchet in your repo

1. Add `.lint-ratchet.config.yml` with `repo.base_branch` (see [docs/lint-ratchet.md](docs/lint-ratchet.md)).
2. Enable [required GitHub Actions permissions](#required-allow-github-actions-to-create-pull-requests).
3. Copy the consumer workflow ([`docs/examples/lint-ratchet.workflow.yml`](docs/examples/lint-ratchet.workflow.yml)) into `.github/workflows/` and set **`pull_request_workflows`** to your CI workflow filenames.
4. Add `workflow_dispatch` + `ref` checkout to each listed workflow (bot PRs do not trigger normal `pull_request` CI).

## Required: allow GitHub Actions to create pull requests

In the **target** repository:

**Settings → Actions → General → Workflow permissions** → enable **Allow GitHub Actions to create and approve pull requests**.

Without this, the agent cannot open ratchet PRs.

## Adopt mutation-testing-ratchet in your repo

1. Add `.mutation-ratchet.config.yml` with `repo.base_branch` (see [docs/mutation-testing-ratchet.md](docs/mutation-testing-ratchet.md)).
2. Enable [required GitHub Actions permissions](#required-allow-github-actions-to-create-pull-requests).
3. Copy the consumer workflow ([`docs/examples/mutation-testing-ratchet.workflow.yml`](docs/examples/mutation-testing-ratchet.workflow.yml)) into `.github/workflows/` and set **`pull_request_workflows`** to your CI workflow filenames (tests, mutation, coverage).
4. Add `workflow_dispatch` + `ref` checkout to each listed workflow (bot PRs do not trigger normal `pull_request` CI).

## Documentation

* **Human / Backstage TechDocs:** `docs/` (see `mkdocs.yml`). Published via the `backstage.io/techdocs-ref` annotation in `catalog-info.yaml`.
* **Agents & conventions:** See [agents.md](agents.md) and [.dev/rules/main.md](.dev/rules/main.md).
