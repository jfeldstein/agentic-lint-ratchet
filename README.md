# agentic-lint-ratchet

Helm application chart for the **Lint-Ratchet** hosted agent, using [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart) the same way as the upstream [hello-world](https://github.com/jfeldstein/declarative-agent-library-chart/tree/main/examples/hello-world) example: `templates/agent.yaml` includes `declarative-agent.system`, and tunables live under **`agent:`** in `values.yaml`.

The supervisor **`systemPrompt`** is the automation spec in **`PROMPT.md`** (copied from `agentic-pocs/projects/lint-ratchet`). After editing `PROMPT.md`, run:

```bash
python3 scripts/sync_prompt_to_values.py
```

## Dependency path

`Chart.yaml` resolves the library chart from **`file://../declarative-agent-library-chart/helm/chart`**. Keep this repo next to a clone of [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart), or change that URL to match your layout.

```bash
helm dependency build --skip-refresh
```

## Hourly trigger CronJob

When **`triggerCron.enabled`** is true (default), the chart installs a **`CronJob`** on **`0 * * * *`** that **`POST`s** the cluster-internal trigger URL **`http://<agent-service>:<port>/api/v1/trigger`**, matching the HTTP contract described in the upstream architecture docs.

Disable or change schedule via **`values.yaml`** (`triggerCron`).

## Install (outline)

Build or load the runtime image expected by **`agent.image`** (see the library chart README), then:

```bash
helm upgrade --install lint-ratchet . -n <namespace> --wait -f values.yaml
```
