# Repository Agent Index

## Core Instructions

* Rules & standards: Refer to [.dev/rules/main.md](.dev/rules/main.md)
* Architecture & design notes: Refer to [.dev/docs/architecture.md](.dev/docs/architecture.md)

## Active task context

* **Current mission:** Maintain and document **agentic-lint-ratchet** and **agentic-mutation-testing-ratchet**: composite actions, `RATCHET.md` prompts, TechDocs adoption guides.
* **References:** [docs/lint-ratchet.md](docs/lint-ratchet.md), [docs/mutation-testing-ratchet.md](docs/mutation-testing-ratchet.md), [docs/ratchets.md](docs/ratchets.md), [.github/actions/lint-ratchet/RATCHET.md](.github/actions/lint-ratchet/RATCHET.md), [.github/actions/mutation-testing-ratchet/RATCHET.md](.github/actions/mutation-testing-ratchet/RATCHET.md)
* Session memory: See [.dev/memory.md](.dev/memory.md) for latest status (create/update during sessions)

## Ratchet layout (all ratchets)

Production prompts belong **beside** `.github/actions/<name>/action.yml`, not under `.dev/skills/`. See [.dev/rules/main.md](.dev/rules/main.md#ratchet-conventions).

## Operational prompts

* **Lint ratchet:** [.github/actions/lint-ratchet/RATCHET.md](.github/actions/lint-ratchet/RATCHET.md) (authoritative automation prompt)
* **Mutation testing ratchet:** [.github/actions/mutation-testing-ratchet/RATCHET.md](.github/actions/mutation-testing-ratchet/RATCHET.md) (authoritative automation prompt)
* Bootstrap env: [docs/lint-ratchet.md](docs/lint-ratchet.md#bootstrap-environment), [docs/mutation-testing-ratchet.md](docs/mutation-testing-ratchet.md#bootstrap-environment)
