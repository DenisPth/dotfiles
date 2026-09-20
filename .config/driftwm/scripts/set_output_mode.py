#!/usr/bin/env python3
"""Persist an output's mode (and optionally scale) into config.toml's
[[outputs]] table.

Used by DisplaySection.qml's Display settings (mod+s) and by install.sh's
first-run display wizard, so a mode/scale picked there survives a driftwm
restart — driftwm only reads [[outputs]] at startup, so a live wlr-randr
call doesn't by itself stick around. Edits only the matching [[outputs]]
block (found by its `name`), leaving every other line/comment/block in the
file untouched; appends a new block if this connector has no entry yet.
This is the single place that writes [[outputs]] fields, so config.toml
stays the one source of truth across machines sharing this repo (no
separate kanshi file to keep in sync, and no risk of one machine's sed
clobbering another's block).

Usage: set_output_mode.py <connector> <mode> [<scale>]
"""
import re
import sys
from pathlib import Path

CONFIG = Path.home() / ".config/driftwm/config.toml"

BLOCK_RE = re.compile(r"^\[\[outputs\]\]\n(?:(?!^\[).*\n?)*", re.MULTILINE)


def set_field(block: str, field: str, value: str) -> str:
    if re.search(rf"^{field}\s*=", block, re.MULTILINE):
        return re.sub(rf"^{field}\s*=.*$", f"{field} = {value}", block, count=1, flags=re.MULTILINE)
    return block.rstrip("\n") + f"\n{field} = {value}\n"


def main() -> None:
    connector, mode = sys.argv[1], sys.argv[2]
    scale = sys.argv[3] if len(sys.argv) > 3 else None
    text = CONFIG.read_text()

    found = False

    def repl(m: re.Match) -> str:
        nonlocal found
        block = m.group(0)
        if not re.search(rf'^name\s*=\s*"{re.escape(connector)}"(?=\s|$)', block, re.MULTILINE):
            return block
        found = True
        block = set_field(block, "mode", f'"{mode}"')
        if scale is not None:
            block = set_field(block, "scale", scale)
        return block

    text = BLOCK_RE.sub(repl, text)

    if not found:
        scale_line = f"scale = {scale}\n" if scale is not None else "scale = 1.0\n"
        new_block = f'\n[[outputs]]\nname = "{connector}"\nmode = "{mode}"\n{scale_line}'
        text = text.rstrip("\n") + "\n" + new_block

    CONFIG.write_text(text)


if __name__ == "__main__":
    main()
