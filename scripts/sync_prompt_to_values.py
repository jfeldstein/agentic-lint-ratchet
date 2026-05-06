#!/usr/bin/env python3
"""Embed skills/lint-ratchet/resources/RATCHET.md into values.yaml under agent.systemPrompt (literal block)."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROMPT = ROOT / "skills" / "lint-ratchet" / "resources" / "RATCHET.md"
VALUES = ROOT / "values.yaml"

HEADER = """# agent.systemPrompt is synced from skills/lint-ratchet/resources/RATCHET.md.
# Regenerate: python3 scripts/sync_prompt_to_values.py

"""


def indent_block(text: str, prefix: str = "    ") -> str:
    lines = text.splitlines(keepends=True)
    return "".join(prefix + line if line else prefix.rstrip() + "\n" for line in lines)


def main() -> None:
    prompt = PROMPT.read_text(encoding="utf-8")
    block = indent_block(prompt)
    body = f"""agent:
  systemPrompt: |
{block}
  image:
    repository: declarative-agent-library-chart
    tag: local
    pullPolicy: Never

triggerCron:
  enabled: true
  schedule: "0 * * * *"
  image: curlimages/curl:8.5.0
"""
    VALUES.write_text(HEADER + body, encoding="utf-8")


if __name__ == "__main__":
    main()
