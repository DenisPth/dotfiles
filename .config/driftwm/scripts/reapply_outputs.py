#!/usr/bin/env python3
"""Re-apply config.toml's [[outputs]] modes via wlr-randr.

swayidle's after-resume hook. GPU drivers (amdgpu, i915) often renegotiate a
DP/eDP link on wake using the panel's preferred mode instead of the custom
(often overclocked, e.g. 165Hz/120Hz) mode this rig is actually configured
for in config.toml — this reapplies each configured output's name/mode/scale
so resume-from-sleep doesn't leave the screen stuck at a low refresh rate.
Reads config.toml directly rather than hardcoding a mode, so the same hook
works unmodified across machines with different panels/outputs.
"""
import subprocess
import tomllib
from pathlib import Path

CONFIG = Path.home() / ".config/driftwm/config.toml"


def main() -> None:
    data = tomllib.loads(CONFIG.read_text())
    for out in data.get("outputs", []):
        name = out.get("name")
        mode = out.get("mode")
        if not name or not mode:
            continue
        cmd = ["wlr-randr", "--output", name, "--on", "--mode", mode]
        scale = out.get("scale")
        if scale is not None:
            cmd += ["--scale", str(scale)]
        subprocess.run(cmd, check=False)


if __name__ == "__main__":
    main()
