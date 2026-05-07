# agentic-lint-ratchet

This repository ships **three ways** to run lint ratcheting against a GitHub repo: a **composable GitHub Action** (scheduled PR bot), a **Helm chart** that wraps [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) for in-cluster deployment, and a **local skill** you can install. The chart’s HTTP `CronJob` today only **wakes** the agent process; a fully autonomous in-cluster ratchet (checkout, `gh`, CI babysitting on the cluster) is **documented as a product gap** in [docs/in-cluster-bot.md](docs/in-cluster-bot.md).

---

## If you operate the repo (humans)

**Fastest path — GitHub Actions**

1. Copy [workflows/lint-ratchet.yml](workflows/lint-ratchet.yml) to `.github/workflows/lint-ratchet.yml` in the **target** repository (this repo keeps an equivalent under [.github/workflows/lint-ratchet.yml](.github/workflows/lint-ratchet.yml) for itself).
2. In **Repository → Settings → Actions → General → Workflow permissions**: enable **Read and write permissions** and **Allow GitHub Actions to create and approve pull requests**.
3. Add repository secret **`CURSOR_API_KEY`** under **Settings → Secrets → Actions**.
4. Choose runtime in workflow `with.agent`:
   - `agent: cursor` (default) requires `CURSOR_API_KEY` and optionally `cursor_model`.
   - `agent: pi` requires job/step `env:` entries for `LITELLM_BASE_URL`, `LITELLM_API_KEY`, and `PI_MODEL`.

To vendor the composite action instead of referencing this repo by ref, copy [`actions/lint-ratchet.yml`](actions/lint-ratchet.yml) to `.github/actions/lint-ratchet/action.yml` in the target repo and point the workflow `uses:` at `./.github/actions/lint-ratchet`.

**Config in the target repo:** mirror [config/.lint-ratchet.config.example.yml](config/.lint-ratchet.config.example.yml) to `.lint-ratchet.config.yml` at the repo root, or set **`LINT_RATCHET_CONFIG_PATH`** / the action’s `config_path` input to another path.

---

## If you integrate or extend this repo (agents and tools)

| Concern | Location |
| -------- | -------- |
| Ratchet instructions read by the deployed agent | [skills/lint-ratchet/resources/RATCHET.md](skills/lint-ratchet/resources/RATCHET.md) — wired via Helm **`agent.systemPromptFile`**; edit in git, not inline in `values.yaml` (library chart allows exactly one of `systemPrompt` or `systemPromptFile`). |
| Helm values for the agent | `values.yaml` — tunables under **`agent:`**; `templates/agent.yaml` includes `declarative-agent.system` (same pattern as upstream [hello-world](https://github.com/jfeldstein/declarative-agent-library-chart/tree/main/examples/hello-world)). |
| Composite action runtime | Uses env **`RATCHET_PROMPT_FILE`** from the checked-out repo at **`action_ref`**; does **not** depend on `npx skills add`. |
| Supported agent runtimes | `cursor` and `pi` are implemented. `claude` and `opencode` are currently unsupported and fail fast with an explicit error. |
| Skill version ↔ Helm | After bumping **`skills/lint-ratchet/package.json`**, run **`python3 scripts/sync_skill_version_to_values.py`** so **`lintRatchet.skillVersion`** stays aligned. |
| Optional local install | `npx skills add jfeldstein/agentic-lint-ratchet#<git-ref> -a cursor -y` or a tree URL like `https://github.com/jfeldstein/agentic-lint-ratchet/tree/<tag>/skills/lint-ratchet`. |

---

## Helm (cluster)

**Dependency:** [Chart.yaml](Chart.yaml) resolves the library chart from `file://../declarative-agent-library-chart/helm/chart`. Clone [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) beside this repo or change the URL, then:

```bash
helm dependency build --skip-refresh
```

Build or supply the image referenced by **`agent.image`** (see the library chart README), then install:

```bash
helm upgrade --install lint-ratchet . -n <namespace> --wait -f values.yaml
```

When **`triggerCron.enabled`** is true (default), a **CronJob** sends **`POST /api/v1/trigger`** to the agent Service. That wake **does not** clone a repo or open PRs by itself; behavior limits and the path to a real worker are in [docs/in-cluster-bot.md](docs/in-cluster-bot.md). Tune or disable via **`triggerCron`** in `values.yaml`.
