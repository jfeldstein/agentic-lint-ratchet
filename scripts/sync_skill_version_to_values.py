#!/usr/bin/env python3
"""Align values.yaml lintRatchet.skillVersion with skills/lint-ratchet/package.json."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKG = ROOT / "skills" / "lint-ratchet" / "package.json"
VALUES = ROOT / "values.yaml"


def main() -> None:
    version = json.loads(PKG.read_text(encoding="utf-8"))["version"]
    text = VALUES.read_text(encoding="utf-8")
    updated, n = re.subn(
        r"^(lintRatchet:\n  skillVersion: )\"[^\"]*\"",
        rf'\1"{version}"',
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if n != 1:
        raise SystemExit(
            "expected exactly one lintRatchet.skillVersion block in "
            f"{VALUES}, replaced {n}"
        )
    VALUES.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    main()
