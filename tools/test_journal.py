"""Run the journal's Lua tests with Lua 5.1 or a supplied Fengari executable."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def lua_executable(requested: str | None) -> str:
    if requested:
        return requested
    for name in ("lua5.1", "lua", "fengari"):
        if found := shutil.which(name):
            return found
    temporary = Path(os.environ.get("TEMP", "/tmp")) / "fw-lua-check/node_modules/.bin/fengari.cmd"
    if temporary.is_file():
        return str(temporary)
    raise SystemExit("Install Lua 5.1 or Fengari, or pass --lua PATH.")


def run_lua(executable: str, script: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [executable, str(script), ROOT.as_posix(), *arguments], cwd=ROOT,
        capture_output=True, text=True, encoding="utf-8",
        shell=os.name == "nt" and Path(executable).suffix.lower() in (".cmd", ".bat"),
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua")
    args = parser.parse_args()
    executable = lua_executable(args.lua)
    for name in ("journal_test.lua", "journal_ui_test.lua", "minimap_test.lua", "reading_test.lua", "class_priority_test.lua", "special_quests_test.lua"):
        result = run_lua(executable, ROOT / "tests" / name)
        # Fengari's CLI can report Lua errors with exit code zero.
        if result.returncode or "PASS:" not in result.stdout or result.stderr:
            raise SystemExit(result.stdout + result.stderr)
        print(result.stdout.strip())


if __name__ == "__main__":
    main()
