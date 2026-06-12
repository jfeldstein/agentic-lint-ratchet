# agentic-mutation-testing-ratchet

**agentic-mutation-testing-ratchet** progressively adds and expands mutation testing in a target repository. It discovers existing mutation tooling, fills gaps with boring defaults, then runs **Setup → Ratchet (first time) → Ratchet (ongoing)** until intended code has meaningful mutation coverage on CI.

The authoritative agent instructions are [`.github/actions/mutation-testing-ratchet/RATCHET.md`](../.github/actions/mutation-testing-ratchet/RATCHET.md) (shipped beside the composite action).

## Mechanics

| Item | Value |
|------|--------|
| Config file | `.mutation-ratchet.config.yml` in the **target** repo |
| Branch prefix | `mutation-ratchet/` |
| PR signature | `#mutation-ratchet-<64-char-hex>` = SHA-256 of entire config file |
| Composite actions | [`.github/actions/mutation-testing-ratchet`](../.github/actions/mutation-testing-ratchet) (calls shared [`ratchet-runner`](../.github/actions/ratchet-runner)) |

## Config shape

The agent reads `.mutation-ratchet.config.yml` for **`repo`** (GitHub `owner/name`) and **`setup`** only — not a mutation-tool checklist. Frameworks are inferred from the target repo.

Example skeleton:

```yaml
repo:
  repository: your-org/your-repo
  base_branch: main   # required when using pull_request_workflows (see below)

setup:
  max_fix_files_without_ignore: 10
  max_bite_steps_without_source_changes: 3
```

See [`.github/actions/mutation-testing-ratchet/RATCHET.md`](../.github/actions/mutation-testing-ratchet/RATCHET.md) for Setup success criteria and ratchet phases.

## Bootstrap environment

CI sets these via the [mutation-testing-ratchet composite action](../.github/actions/mutation-testing-ratchet). Reproduce locally when debugging.

| Variable | Description |
|----------|-------------|
| `MUTATION_RATCHET_CONFIG_PATH` | Absolute path to `.mutation-ratchet.config.yml` in the **target** repository |
| `MUTATION_RATCHET_SIGNATURE` | `#mutation-ratchet-<64-char-hex>` — SHA-256 of the entire config file (lowercase hex) |
| `MUTATION_RATCHET_REPOSITORY` | `repo.repository` from config; CI sets in preflight |
| `GH_TOKEN` / `GITHUB_TOKEN` | Token for `gh` (PR list, create, checks) |
| `CURSOR_API_KEY` | Cursor Agent CLI authentication (required in CI) |
| `GITHUB_WORKSPACE` | Target repo root (CI: `target` checkout path) |
| `MUTATION_RATCHET_BASE_BRANCH` | Optional; from `repo.base_branch` when set |

Derive the signature when unset:

```bash
export MUTATION_RATCHET_CONFIG_PATH="$(realpath .mutation-ratchet.config.yml)"
export MUTATION_RATCHET_SIGNATURE="#mutation-ratchet-$(shasum -a 256 "$MUTATION_RATCHET_CONFIG_PATH" | awk '{print $1}')"
```

## Adopt in CI

Setup checklist for the **target** repository (`repo.repository` must match that repo; the composite action checks out the workflow repo as the workspace).

1. Commit `.mutation-ratchet.config.yml` with `repo.repository` and **`repo.base_branch`** (used when dispatching CI).
2. Enable **Allow GitHub Actions to create and approve pull requests** ([README — required permissions](../README.md#required-allow-github-actions-to-create-pull-requests)).
3. Add `.github/workflows/mutation-testing-ratchet.yml` that calls the composite action (template below).
4. Pass **`pull_request_workflows`** with your CI workflow filenames, and wire those workflows for `workflow_dispatch` (see below).

### Why you need `pull_request_workflows`

PRs opened or updated by the ratchet use `GITHUB_TOKEN`. GitHub [does not emit `pull_request` (or `push`) workflow events](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow) for those updates, so your normal PR CI **will not start** on `mutation-ratchet/*` branches.

After a successful agent run, the composite action dispatches the workflows you list via `workflow_dispatch`. It targets only the signed `mutation-ratchet/*` PR **updated during that workflow run** — not every open ratchet branch.

Merge the mutation-testing-ratchet workflow to your default branch before relying on scheduled dispatch; scheduled runs use the workflow file on the default branch.

### Preflight (dedupe)

Before the agent runs, [ratchet-runner](../.github/actions/ratchet-runner) preflight checks for an **open** signed PR on a branch matching `ratchet_branch_prefix` (default `mutation-ratchet/`). If one exists and **required checks are green**, the run is skipped (no second slice PR). If required checks are failing or pending, the run proceeds so the agent can **babysit** that PR. This matches the duplicate-PR guard in `.github/actions/mutation-testing-ratchet/RATCHET.md`.

### Consumer workflow

Copy [docs/examples/mutation-testing-ratchet.workflow.yml](examples/mutation-testing-ratchet.workflow.yml) to `.github/workflows/mutation-testing-ratchet.yml` and edit:

| Input / knob | Purpose |
|--------------|---------|
| `pull_request_workflows` | Newline-separated workflow **filenames** under `.github/workflows/` (e.g. `test.yml`, `mutation.yml`); dispatched by the action after a successful agent run |
| `uses:` `@ref` | Pin `<org>/agentic-ratchets` ref on the composite action (e.g. `@main` or `mutation-testing-ratchet-action-v1.0.0`) |
| `ratchet_branch_prefix` | Default `mutation-ratchet/`; must match ratchet branch names and your `pull_request` CI targets |
| `cursor_api_key` | `CURSOR_API_KEY` secret |
| `schedule` / `workflow_dispatch` | When the ratchet runs |

Example:

```yaml
- uses: <org>/agentic-ratchets/.github/actions/mutation-testing-ratchet@mutation-testing-ratchet-action-v1.0.0
  with:
    cursor_api_key: ${{ secrets.CURSOR_API_KEY }}
    pull_request_workflows: |
      test.yml
      mutation.yml
```

Until a release tag exists, use `@main`. See [docs/examples/mutation-testing-ratchet.workflow.yml](examples/mutation-testing-ratchet.workflow.yml).

The [mutation-testing-ratchet](../.github/actions/mutation-testing-ratchet) action forwards to [ratchet-runner](../.github/actions/ratchet-runner) (`pr_signature_prefix: mutation-ratchet`, `ratchet_env_prefix: MUTATION_RATCHET`), which runs dedupe preflight, installs Cursor CLI, executes `agent -p` with the bundled [RATCHET.md](../.github/actions/mutation-testing-ratchet/RATCHET.md), and dispatches each listed workflow on the ratchet PR branch head.

Omit `pull_request_workflows` (or leave empty) to skip dispatch — useful while bootstrapping before your CI supports `workflow_dispatch`.

### Wire your existing CI workflows

Each workflow listed in `pull_request_workflows` must:

1. Declare **`workflow_dispatch`** with a required string input **`ref`** (branch or SHA to check out).
2. Pass that input to **`actions/checkout`**:

```yaml
on:
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      ref:
        description: Git ref to check out (mutation-ratchet CI dispatch)
        required: true
        type: string

jobs:
  test:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event_name == 'workflow_dispatch' && inputs.ref || github.event.pull_request.head.sha || github.sha }}
```

Repeat for every job that should run on ratchet PRs (test, mutation, coverage, etc.).

### Bootstrap without CI dispatch

If your CI does not yet support `workflow_dispatch` + `ref`, omit `pull_request_workflows`. The agent can still open PRs; required checks will not run until you wire CI and pass the input.

## Local debugging

Same as CI after installing the CLI:

```bash
curl https://cursor.com/install -fsS | bash
export MUTATION_RATCHET_CONFIG_PATH="$(realpath .mutation-ratchet.config.yml)"
export MUTATION_RATCHET_SIGNATURE="#mutation-ratchet-$(shasum -a 256 "$MUTATION_RATCHET_CONFIG_PATH" | awk '{print $1}')"
export CURSOR_API_KEY=...
export GH_TOKEN=...

agent -p "$(cat /path/to/agentic-ratchets/.github/actions/mutation-testing-ratchet/RATCHET.md)" \
  --workspace "$(pwd)" \
  --trust --force \
  --model "${CURSOR_MODEL:-composer-2}"
```

## Conventions

* **PR titles:** Conventional Commits (not `mutation-ratchet:` prefixes); ownership via branch name
* **No score gaming:** do not weaken tests or blanket-ignore mutants to pass CI; fix tests or code
* **Babysitting:** agent must drive required CI to green on each ratchet PR it opens or updates
