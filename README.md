# agentic-lint-ratchet

**Goal:** an **in-cluster bot** that **independently ratchets** linters on a **configured GitHub repo** (schedule, checkout, `gh`, CI babysitting on the cluster—not on a laptop). What that requires versus what this chart ships today is spelled out in **[docs/in-cluster-bot.md](docs/in-cluster-bot.md)**.

This repo is a **Helm application chart** that vendors [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) the same way as the upstream [hello-world](https://github.com/jfeldstein/declarative-agent-library-chart/tree/main/examples/hello-world) example: `templates/agent.yaml` includes `declarative-agent.system`, tunables under `**agent:`** in `values.yaml`.

The `**systemPrompt**` is **[PROMPT.md](PROMPT.md)** (from `agentic-pocs/projects/lint-ratchet`). After editing `PROMPT.md`, run:

```bash
python3 scripts/sync_prompt_to_values.py
```

Target repo and base branch for the **lint-ratchet config contract** are illustrated in **[config/config.example.yaml](config/config.example.yaml)**.

## GitHub Actions (cron PR bot)

This repo includes **copy-paste templates** for running lint-ratchet on a schedule in GitHub Actions.

- **`workflows/`**: “this repo using its own composable action” — a ready-to-copy scheduled workflow that references the composable action by full `owner/repo/path@ref`.
- **`actions/`**: the **composable action** template (what the workflow runs).

### End-user install (copy into your repo)

End users only need to copy the workflow file (it references this repo’s composite action directly):

- `workflows/lint-ratchet.yml` → `.github/workflows/lint-ratchet.yml`

Then add the secret **`CURSOR_API_KEY`** in GitHub (Repository → Settings → Secrets → Actions).

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

