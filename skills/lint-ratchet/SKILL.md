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

Read and follow the full workflow specification:

[resources/RATCHET.md](resources/RATCHET.md)

That file is the authoritative system prompt for the lint-ratchet agent. It covers:

- Invariants (PR body signing, no inline suppressions, duplicate PR guard)
- Linter discovery and gap-fill defaults per language
- Setup, Ratchet (first time), and Ratchet (ongoing) phases
- PR babysitting loop
- Config contract (`.lint-ratchet.config.yml`)
