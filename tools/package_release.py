"""Build a checked, installable Forever Wayfinder zip with its source notices."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path, PurePosixPath
import re
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "ForeverWayfinder"
TOC = ADDON / "ForeverWayfinder.toc"
STAMP = (2026, 9, 27, 0, 0, 0)


def release_files() -> tuple[str, list[tuple[Path, str]]]:
    toc = TOC.read_text(encoding="utf-8")
    match = re.search(r"^## Version:\s*([^\s]+)\s*$", toc, re.MULTILINE)
    if not match:
        raise ValueError("TOC has no version")
    version = match.group(1)
    members = [(TOC, "ForeverWayfinder/ForeverWayfinder.toc")]
    loaded_lua: set[Path] = set()
    for raw in toc.splitlines():
        name = raw.strip()
        if not name or name.startswith("##"):
            continue
        relative = PurePosixPath(name.replace("\\", "/"))
        if relative.is_absolute() or ".." in relative.parts or relative.suffix.lower() != ".lua":
            raise ValueError(f"Unsafe or unexpected TOC entry: {name}")
        source = ADDON.joinpath(*relative.parts)
        if not source.is_file():
            raise FileNotFoundError(source)
        loaded_lua.add(source.resolve())
        members.append((source, "ForeverWayfinder/" + relative.as_posix()))
    other_lua = {path.resolve() for path in ADDON.rglob("*.lua")} - loaded_lua
    if other_lua:
        raise ValueError(f"Lua files missing from TOC: {sorted(map(str, other_lua))}")
    for source in sorted((ADDON / "Media").rglob("*")):
        if source.is_file():
            members.append((source, "ForeverWayfinder/" + source.relative_to(ADDON).as_posix()))
    for name in ("README.md", "LICENSE", "ATTRIBUTION.md"):
        members.append((ROOT / name, "ForeverWayfinder/" + name))
    for source in sorted((ROOT / "tools").glob("*.py")):
        members.append((source, "ForeverWayfinder/Source/tools/" + source.name))
    for source in sorted((ROOT / "tests").glob("*.lua")):
        members.append((source, "ForeverWayfinder/Source/tests/" + source.name))
    for source in sorted((ROOT / "art").iterdir()):
        if source.is_file():
            members.append((source, "ForeverWayfinder/Source/art/" + source.name))
    if not members or any(not source.is_file() for source, _ in members):
        raise FileNotFoundError("Release source file missing")
    return version, sorted(members, key=lambda item: item[1])


def build(output: Path | None = None) -> Path:
    version, members = release_files()
    output = output or ROOT / "dist" / f"ForeverWayfinder-{version}-beta.zip"
    output.parent.mkdir(parents=True, exist_ok=True)
    expected = {name: source.read_bytes() for source, name in members}
    with ZipFile(output, "w") as archive:
        for name, contents in expected.items():
            info = ZipInfo(name, STAMP)
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, contents, compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(output) as archive:
        if archive.testzip() is not None or set(archive.namelist()) != set(expected):
            raise ValueError("Release archive failed integrity or layout check")
        for name, contents in expected.items():
            if archive.read(name) != contents:
                raise ValueError(f"Release archive changed {name}")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"{output} ({output.stat().st_size} bytes; SHA-256 {digest})")
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    build(args.output)
