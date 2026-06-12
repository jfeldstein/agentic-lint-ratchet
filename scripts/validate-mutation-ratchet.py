#!/usr/bin/env python3
"""Validate mutation-testing-ratchet artifacts and cross-file consistency."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    ".github/actions/mutation-testing-ratchet/action.yml",
    ".github/actions/mutation-testing-ratchet/version.txt",
    ".github/actions/mutation-testing-ratchet/CHANGELOG.md",
    ".github/actions/mutation-testing-ratchet/RATCHET.md",
    "docs/mutation-testing-ratchet.md",
    "docs/examples/mutation-testing-ratchet.workflow.yml",
]

FILE_NEEDLES: dict[str, list[str]] = {
    ".github/actions/mutation-testing-ratchet/action.yml": [
        "pr_signature_prefix: mutation-ratchet",
        "ratchet_env_prefix: MUTATION_RATCHET",
        "default: .mutation-ratchet.config.yml",
        "default: RATCHET.md",
        "prompt_action_path:",
        'default: "mutation-ratchet/"',
        "./../ratchet-runner",
    ],
    ".github/actions/mutation-testing-ratchet/RATCHET.md": [
        "MUTATION_RATCHET_SIGNATURE",
        "#mutation-ratchet-<64-hex>",
        "mutation-ratchet/",
        "PR babysitting",
        "Setup",
        "Ratchet (first time)",
        "Ratchet (ongoing)",
    ],
    "docs/mutation-testing-ratchet.md": [
        ".mutation-ratchet.config.yml",
        "mutation-ratchet/",
        "#mutation-ratchet-<64-char-hex>",
        ".github/actions/mutation-testing-ratchet",
    ],
    "docs/examples/mutation-testing-ratchet.workflow.yml": [
        "mutation-testing-ratchet",
        ".mutation-ratchet.config.yml",
        "mutation-ratchet/",
    ],
}

LINT_CONSTANTS = [
    ".lint-ratchet.config.yml",
    "lint-ratchet/",
    "#lint-ratchet-",
    "LINT_RATCHET",
]


def main() -> int:
    errors: list[str] = []

    for rel in REQUIRED_FILES:
        path = ROOT / rel
        if not path.is_file():
            errors.append(f"missing required file: {rel}")

    for rel, needles in FILE_NEEDLES.items():
        path = ROOT / rel
        if not path.is_file():
            continue
        text = path.read_text()
        for needle in needles:
            if needle not in text:
                errors.append(f"{rel} missing {needle!r}")

    release = (ROOT / "release-please-config.json").read_text()
    manifest = (ROOT / ".release-please-manifest.json").read_text()
    if ".github/actions/mutation-testing-ratchet" not in release:
        errors.append("release-please-config.json missing mutation action package")
    if "mutation-testing-ratchet-action" not in release:
        errors.append("release-please-config.json missing mutation-testing-ratchet-action component")
    if '"1.0.0"' not in (ROOT / ".github/actions/mutation-testing-ratchet/version.txt").read_text().strip() if (ROOT / ".github/actions/mutation-testing-ratchet/version.txt").is_file() else "":
        if (ROOT / ".github/actions/mutation-testing-ratchet/version.txt").is_file():
            ver = (ROOT / ".github/actions/mutation-testing-ratchet/version.txt").read_text().strip()
            if ver != "1.0.0":
                errors.append(f"version.txt expected 1.0.0, got {ver!r}")
    if ".github/actions/mutation-testing-ratchet" not in manifest:
        errors.append(".release-please-manifest.json missing mutation action path")

    readme = (ROOT / "README.md").read_text()
    if "Planned" in readme and "agentic-mutation-testing-ratchet" in readme:
        if "| Planned |" in readme or "Planned:" in readme:
            errors.append("README.md still marks mutation ratchet as Planned")

    ratchets = (ROOT / "docs/ratchets.md").read_text()
    if "Planned" in ratchets and "agentic-mutation-testing-ratchet" in ratchets:
        if "| [agentic-mutation-testing-ratchet]" in ratchets and "Planned" in ratchets.split("agentic-mutation-testing-ratchet")[1][:80]:
            errors.append("docs/ratchets.md still marks mutation ratchet as Planned")

    mkdocs = (ROOT / "mkdocs.yml").read_text()
    if "mutation-testing-ratchet.md" not in mkdocs:
        errors.append("mkdocs.yml missing mutation-testing-ratchet.md nav entry")

    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 1

    print("validate-mutation-ratchet: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
