# In-cluster lint-ratchet bot (product goal)

## Intent

**agentic-lint-ratchet** is meant to be an **autonomous bot** that advances linter coverage on a **configured GitHub repository** on a schedule, **inside Kubernetes**, without depending on a developer laptop. The human operator configures **which repo** and **which base branch**; the cluster carries execution and credentials.

This is **not** “run the same shell cron on my Mac,” but “the cluster owns recurrence, checkout, `gh`, and CI babysitting.”

## What the Declarative Agent HTTP Deployment does today

This chart vendors [declarative-agent-library-chart](https://github.com/jfeldstein/declarative-agent-library-chart). Its `**POST /api/v1/trigger`** entry runs the LangGraph pipeline in `**helm/src/agent/trigger_graph.py**`:

- With **no** `chatModel` **and** **no** non-empty `**subagents`** list, the handler resolves to `**trigger_reply_text**` (`helm/src/agent/reply.py`): it returns either the `**Respond, "…"**` fragment from the system prompt or the **raw system prompt string**. There is **no** LLM call and **no** repository side effects.
- With a **supervisor** configuration (`subagents` + `chatModel`), the runtime can call an LLM, but the **built-in tool registry** (see `helm/src/pyproject.toml` entry points `declarative_agent.tools`) exposes **sample**, **Slack**, and **Jira** tools—**not** generic `git` / `gh` / shell / repo mutation. So the **PROMPT.md** workflow (clone, discover linters, `gh pr create`, babysit checks) is **not** implementable on the stock image by HTTP trigger alone.

The **hourly CronJob** in this chart only **POSTs** to that HTTP endpoint. It is a **wake-up ping**, not a ratchet engine.

## What an actual in-cluster bot needs

The **PROMPT** and **INSTALL_BY_AGENT** model assume a process that can:

1. Read `**config.yaml`** (repo, `base_branch`, `local_path`, setup limits).
2. `cd` to a real checkout and run **language-native linters** and **tests** the same way CI does.
3. Use `**gh`** (with `**GITHUB_TOKEN**`) to open and update PRs, and to poll check status.

That requires **at least**:


| Concern         | In-cluster approach                                                                                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Config**      | `ConfigMap` (or `Secret`) for `config.yaml`; for `local_path`, use a path inside the pod (e.g. `/workspace/target`) that matches a **volume** where the repo is cloned.                       |
| **Credentials** | `Secret` for `GITHUB_TOKEN` (and any LLM keys if you add an LLM step). Mount or env-inject; never commit.                                                                                     |
| **Workspace**   | `emptyDir` or PVC; **shallow clone** of `repo.repository` at `base_branch` (or default).                                                                                                      |
| **Recurrence**  | `CronJob` (or `Deployment` + work queue) that runs the **ratchet worker**, not only `curl` to the DALC pod.                                                                                   |
| **Execution**   | A **ratchet worker** image: `git`, `gh`, and the target repo’s toolchains (Node, Python, Go, …) or a **thin** image that runs only `gh` + a **hosted** job runner if you delegate heavy work. |


## Architecture options (pick one or layer them)

1. **Ratchet worker (recommended first real step)**
  A dedicated container image and `CronJob` that implements the **operational** steps of the PROMPT (clone, run linters, open PRs, poll checks) in **code** (Python/Go) or a **constrained** script. An LLM is optional for *fix* generation; the *orchestration* and *GitHub* I/O should not depend on the DALC HTTP app unless you intentionally merge them.
2. **DALC as control plane only**
  Keep the DALC Deployment for **observability / API** and have the worker call `**POST /api/v1/trigger`** only if you add **new tools** and a **custom image** that can execute the PROMPT—still requires **new** in-process or sidecar execution surfaces.
3. **External agent runtime (e.g. hosted sandbox API)**
  The in-cluster `CronJob` **submits** a job to a remote executor that runs a full agent with shell access. The cluster still holds **schedule + config + secret references**; execution is elsewhere.

## Relation to this repository

- `**PROMPT.md` / `config.yaml`**: These define **behavior and identity** (`#lint-ratchet-…` signature) for an **agent-style** ratchet. An in-cluster **worker** should read the same `config.yaml` bytes so signatures stay stable.
- `**templates/trigger-cronjob.yaml`**: Placeholder **wake** for the HTTP agent; replace or augment with a **worker CronJob** once the worker image exists.

Until a **ratchet worker** is added, this chart deploys **configuration + scheduling hooks**, not a finished autonomous ratchet.