---
name: lint-ratchet
description: Incrementally ratchet up linter coverage on any codebase. Discovers active linters, fills gaps with boring ecosystem defaults, and progressively enables rules one atomic slice at a time — never breaking CI. Use when asked to improve linting, enable lint rules, reduce lint debt, add a linter, or set up automated lint ratcheting on a repository.
license: MIT
metadata:
  author: jfeldstein
  version: "1.0.0"
  source: https://github.com/jfeldstein/agentic-lint-ratchet
---

# Lint-Ratchet

Lint-Ratchet is an agentic workflow that takes a repository from "linting is a mess" to "every rule is enforced" — one small, always-green PR at a time. It never touches inline suppression comments; it fixes violations or uses config-level excludes, then peels those excludes back incrementally.

## When to Apply

Use this skill when the user asks to:
- Enable or improve linting on a codebase
- Incrementally reduce lint debt without breaking CI
- Set up a lint ratchet / progressive lint enforcement
- Add gap-fill linters for languages that have no coverage yet
- Run the lint-ratchet bot on a repository

## Config

Place `.lint-ratchet.config.yml` at the root of your **target** repository (not this skill repo):

```yaml
repo:
  repository: "owner/repo-name"   # GitHub owner/name
  base_branch: "main"             # omit to use the repo default branch

setup:
  max_fix_files_without_ignore: 10  # files threshold: fix vs. config-level exclude
```

Override the path with `LINT_RATCHET_CONFIG_PATH`. See [references/config-example.yml](references/config-example.yml).

## Invariants (never skip)

### PR body signing

Before every `gh pr create`, derive the signature from the config file SHA-256:

```bash
export LINT_RATCHET_SIGNATURE="#lint-ratchet-$(shasum -a 256 "$LINT_RATCHET_CONFIG_PATH" | awk '{print $1}')"
```

Every PR you open — Setup, Ratchet, or any supporting branch — **must** include `$LINT_RATCHET_SIGNATURE` verbatim in its body. Verify after creation:

```bash
gh pr view <n> --repo <repo> --json body -q .body | grep -F "$LINT_RATCHET_SIGNATURE"
```

### No inline suppression comments

Never add `# noqa`, `# type: ignore`, `// eslint-disable-*`, `//nolint:`, `#[allow(...)]`, `@SuppressWarnings`, or any equivalent per-line/per-block suppression. Fix the underlying violation or use config-level path excludes.

### Duplicate PR guard

Before opening a `lint-ratchet/*` branch PR, check for existing open ratchet PRs:

```bash
gh pr list --repo "$LINT_RATCHET_REPOSITORY" --state open \
  --json number,title,body,headRefName \
  | jq --arg sig "$LINT_RATCHET_SIGNATURE" \
    '.[] | select(.body | contains($sig)) | select(.headRefName | startswith("lint-ratchet/"))'
```

If any exist with failing/pending required checks → babysit them first. If they're green → wait for one to merge before opening another `lint-ratchet/*` PR.

## Workflow

### Phase detection

1. **Setup not done** → run Setup.
2. **Setup done, no ratchet baseline** → run Ratchet (first time).
3. **Ratchet baseline exists** → run Ratchet (ongoing) until nothing remains.

### Setup

Goal: linters installed, CI runs them on PRs, CI is green (possibly with broad excludes).

1. Run duplicate PR guard.
2. Discover linters from manifests and config files. Fill gaps per language:
   - Python → Ruff (`pyproject.toml`)
   - JS/TS → ESLint with `eslint:recommended` (+ `@typescript-eslint/recommended` if TS)
   - Go → `golangci-lint` with default config, or `go vet` + `staticcheck`
   - Rust → `clippy` + `rustfmt`
   - Ruby → RuboCop
   New configs start as **noop** (all paths excluded).
3. If CI doesn't run linters on PRs, add a workflow that does.
4. If violations exist:
   - ≤ `max_fix_files_without_ignore` files → fix them.
   - More files → add config-level path excludes so CI passes.
5. Open PR with `$LINT_RATCHET_SIGNATURE`. Branch prefix: `lint-ratchet/`.
6. Babysit until all required checks are green.

### Ratchet (first time)

Goal: replace vague exclude-alls with an explicit depth-first inventory. No behavior change; just documents the todo queue in config form.

1. Run duplicate PR guard.
2. Map the directory tree: where code lives, packages, sub-components.
3. Rewrite linter configs so every subtree is **explicitly** listed: either active or commented out as a deferred queue entry. Behavior unchanged.
4. Open PR. Babysit.

### Ratchet (ongoing)

Goal: peel excludes / enable queued paths one leaf at a time.

**Terminate** when no excludes remain and no commented queue entries remain.

1. Run duplicate PR guard.
2. If any source area is still implicitly out of scope → broaden the map first; open a scope PR if needed.
3. Pull the next leaf from the commented queue (remove exclude or enable include). Continue pulling leaves — aggregating config-only changes on one branch — until linters report violations that require source-file edits.
4. Fix all violations (no inline suppressions).
5. Run full test suite; fix failures; re-run linters.
6. Commit (Conventional Commits subject). Open PR. Babysit.

### PR babysitting

After opening any PR, loop until all required checks are green:

1. Read state: `gh pr view <n> --repo <repo> --json mergeStateStatus,statusCheckRollup`
2. For each failing required check: read logs (`gh run view --log-failed <run-id>`), fix, commit, push.
3. Rebase/merge base branch if conflicts appear.
4. Stop when all required checks succeed (`BLOCKED` due to pending human review is acceptable).

## Global rules

- **Scope before tighten:** explicit lint map covering every intended source area before tightening any rule, threshold, or suppression — across all linters.
- **Branch names:** `lint-ratchet/<descriptor>`. PR titles follow Conventional Commits.
- **One slice per PR:** never flip the entire codebase to full rules in one PR.
- **Coverage CI:** treat a failing `coverage` required check with the same priority as lint/test failures.
- **Aggregation:** successive queue leaves that produce only config changes land in one PR. Stop aggregating when source edits are needed.
