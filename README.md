# agentic-lint-ratchet

**Goal:** an **in-cluster bot** that **independently ratchets** linters on a **configured GitHub repo** (schedule, checkout, `gh`, CI babysitting on the cluster—not on a laptop). What that requires versus what this chart ships today is spelled out in **[docs/in-cluster-bot.md](docs/in-cluster-bot.md)**.

This repo is a **Helm application chart** that vendors [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) the same way as the upstream [hello-world](https://github.com/jfeldstein/declarative-agent-library-chart/tree/main/examples/hello-world) example: `templates/agent.yaml` includes `declarative-agent.system`, tunables under `**agent:`** in `values.yaml`.

The hosted agent reads **`skills/lint-ratchet/resources/RATCHET.md`** via Helm **`agent.systemPromptFile`** (see [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) — exactly one of inline `systemPrompt` or `systemPromptFile`). Edit that file in git; do not inline the prompt in `values.yaml`.

To resync **`lintRatchet.skillVersion`** with `skills/lint-ratchet/package.json` after a skill semver bump:

```bash
python3 scripts/sync_skill_version_to_values.py
```

**Cursor skills CLI (optional):** install a **tagged** copy of this repo’s skill into Cursor’s skill dirs with a git ref fragment, e.g. `npx skills add jfeldstein/agentic-lint-ratchet#lint-ratchet-skill-v1.0.0 -a cursor -y` (the `#ref` is passed to `git clone --branch`). Or use a tree URL: `https://github.com/jfeldstein/agentic-lint-ratchet/tree/<tag>/skills/lint-ratchet`. The composite action’s ratchet runner does **not** require `npx skills add` — it reads `RATCHET_PROMPT_FILE` from the checked-out repo at `action_ref`.

The lint-ratchet config contract is illustrated in **[config/.lint-ratchet.config.example.yml](config/.lint-ratchet.config.example.yml)**. Copy it to **`.lint-ratchet.config.yml`** at the root of your target repository. Override the path via the `LINT_RATCHET_CONFIG_PATH` env var or the `config_path` action input.

## GitHub Actions (cron PR bot)

This repo includes **copy-paste templates** for running lint-ratchet on a schedule in GitHub Actions.

- **`workflows/`**: “this repo using its own composable action” — a ready-to-copy scheduled workflow that references the composable action by full `owner/repo/path@ref`.
- **`actions/`**: the **composable action** template (what the workflow runs).

### End-user install (copy into your repo)

End users only need to copy the workflow file (it references this repo’s composite action directly):

- `workflows/lint-ratchet.yml` → `.github/workflows/lint-ratchet.yml`

Then complete the one-time repository setup below.

#### Required: allow GitHub Actions to create pull requests

The workflow uses the built-in `GITHUB_TOKEN` to push branches and open PRs. GitHub disables this by default.

**Repository → Settings → Actions → General → Workflow permissions**

- Select **"Read and write permissions"**
- Check **"Allow GitHub Actions to create and approve pull requests"**

Then add the secret **`CURSOR_API_KEY`** in **Repository → Settings → Secrets → Actions**.

If you prefer vendoring the composite action (pinning by file copy instead of `@main`), copy `actions/lint-ratchet.yml` into `.github/actions/lint-ratchet/action.yml` and update your workflow’s `uses:` to point at `./.github/actions/lint-ratchet`.

## Dependency path

`Chart.yaml` resolves the library chart from `**file://../declarative-agent-library-chart/helm/chart`**. Clone [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) next to this repo, or change that URL.

```bash
helm dependency build --skip-refresh
```

## Hourly CronJob (HTTP wake)

When `**triggerCron.enabled**` is true (default), a `**CronJob**` calls `**POST /api/v1/trigger**` on the agent Service. That **does not** by itself clone a repo or open PRs; see **docs/in-cluster-bot.md**. Disable or retune via `**triggerCron`** in `values.yaml`.

## Install (outline)

Build or load the runtime image expected by `**agent.image**` (see the library chart README), then:

```bash
helm upgrade --install lint-ratchet . -n <namespace> --wait -f values.yaml
```

