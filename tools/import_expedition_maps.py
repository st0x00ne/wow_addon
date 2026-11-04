"""Import unmodified, hash-checked Atlas maps and generate standalone pin data.

Pinned inputs are declared in art/ExpeditionMaps-import.json. Atlas's data file
is parsed as text, never executed. No Atlas installation is needed at runtime.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "ForeverWayfinder/Media/Maps"
CONFIG = ROOT / "art/ExpeditionMaps-import.json"
OUTPUT = ROOT / "ForeverWayfinder/Data/ExpeditionMaps.lua"


def blob_hash(raw: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def fetch(path: Path, url: str, expected: str, offline: bool) -> bytes:
    if path.is_file() and blob_hash(raw := path.read_bytes()) == expected:
        return raw
    if offline:
        raise ValueError(f"Missing or changed pinned Atlas input: {path.name}")
    request = urllib.request.Request(url, headers={"User-Agent": "ForeverWayfinder-map-import"})
    with urllib.request.urlopen(request, timeout=40) as response:
        raw = response.read()
    if blob_hash(raw) != expected:
        raise ValueError(f"Atlas source hash mismatch: {path.name}")
    path.write_bytes(raw)
    return raw


def block(source: str, name: str) -> str:
    """Find a named table and respect quoted braces when scanning its body."""
    match = re.search(r"(?:^|\n)\s*" + re.escape(name) + r"\s*=\s*\{", source)
    if not match:
        return ""
    start = match.end()
    depth, quote, escape, comment = 1, None, False, False
    for index in range(start, len(source)):
        char = source[index]
        if comment:
            if char == "\n":
                comment = False
        elif quote:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == quote:
                quote = None
        elif source[index:index+2] == "--":
            comment = True
        elif char in ('"', "'"):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start:index]
    raise ValueError(f"Unclosed Atlas table: {name}")


def pin_names(body: str) -> tuple[dict, dict]:
    by_label, by_ref = {}, {}
    for row in re.findall(r"^\s*\{(.+)\},?\s*(?:--[^\n]*)?$", body, re.MULTILINE):
        marker = re.search(r'"\s*([A-Za-z0-9]+\x27?)\)\s*"', row)
        if not marker:
            continue
        label = marker[1]
        helper = re.search(r'(getCreatureName|getBossName|getItemTitlebyID)\("([^"\n]+)"(?:,\s*(\d+))?', row)
        words = re.findall(r'(?:L|ALC|BZ)\["([^"\n]+)"\]', row)
        name = helper[2] if helper else "Entrance" if "ENTRANCE" in row else words[0] if words else "Map marker " + label
        kind = "boss" if helper and helper[1] in ("getCreatureName", "getBossName") and "WHIT" in row else "entrance" if "ENTRANCE" in row else "point"
        record = {"label": label, "name": name, "kind": kind}
        if helper and helper[1] == "getCreatureName" and helper[3]:
            record["npcID"] = int(helper[3])
        by_label[label] = record
        if ref := re.search(r",\s*(\d+)\s*$", row):
            by_ref[int(ref[1])] = record
    return by_label, by_ref


def lua(value) -> str:
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, dict):
        return "{" + ",".join("[" + lua(key) + "]=" + lua(item) for key, item in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ",".join(lua(item) for item in value) + "}"
    return str(value)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--offline", action="store_true", help="Verify and regenerate from the bundled inputs only.")
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    MEDIA.mkdir(parents=True, exist_ok=True)
    base = f'https://raw.githubusercontent.com/{config["repository"]}/{config["commit"]}/'
    raw = fetch(MEDIA / "Atlas-Data-ClassicForever.txt", base + config["source"], config["sourceBlob"], args.offline)
    source = re.sub(r"--\[\[.*?\]\]", "", raw.decode("utf-8-sig"), flags=re.DOTALL)
    maps = block(source, "db.AtlasMaps")
    coordinates = block(source, "db.AtlasMaps_NPC_DB")
    def image(record):
        raw_image = fetch(MEDIA / record["name"], base + "Images/" + record["name"], record["sha"], args.offline)
        if len(raw_image) != record["size"] or raw_image[:4] not in (b"BLP1", b"BLP2"):
            raise ValueError(f'Unexpected map texture: {record["name"]}')
        return {**record, "sha256": hashlib.sha256(raw_image).hexdigest()}
    with ThreadPoolExecutor(max_workers=4) as pool:
        images = list(pool.map(image, config["images"]))
    generated = {}
    names = {"CL_SMGraveyard":"Graveyard", "CL_SMLibrary":"Library", "CL_SMArmory":"Armory",
             "CL_SMCathedral":"Cathedral", "CL_DireMaulEast":"East", "CL_DireMaulWest":"West", "CL_DireMaulNorth":"North"}
    for key, sheets in config["groups"].items():
        generated[key] = []
        for index, sheet in enumerate(sheets, 1):
            by_label, by_ref = pin_names(block(maps, sheet))
            pins = []
            for point in re.finditer(r'\{\s*(?:"([^"\n]+)"|(\d+))\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}', block(coordinates, sheet)):
                label, ref, x, y = point[1] or point[2], int(point[3]), int(point[4]), int(point[5])
                if not (0 <= x <= 512 and 0 <= y <= 512):
                    raise ValueError(f"Out-of-bounds Atlas marker: {sheet}")
                record = by_ref.get(ref) or by_label.get(label) or {"label":label,"name":"Map marker " + label,"kind":"point"}
                pins.append({**record,"label":label,"x":x,"y":y})
            generated[key].append({"texture":sheet,"title":names.get(sheet, f"Map {index}" if len(sheets)>1 else "Interior"),
                                   "width":512,"height":512,"source":"atlas","status":"beta-reference","pins":pins})
    header = f'''-- Atlas map references, imported {config["checked"]} from {config["repository"]}.
-- Pinned revision: {config["commit"]}. Original textures are unmodified.
-- Derived data: Copyright 2011-2026 Arith Hsu and the Atlas Team.
-- GPL-2.0-or-later; distributed here under GPL-3.0. See Media/Maps notices.
-- x/y locate Atlas's printed labels on a 512px sheet, not world waypoints.
local _, addon = ...
addon.ExpeditionMaps = {{
'''
    rows = [f"  [{lua(key)}] = {lua(value)}," for key, value in generated.items()]
    OUTPUT.write_text(header + "\n".join(rows) + "\n}\n", encoding="utf-8")
    manifest = {**config, "images": images, "destinations":len(generated), "sheets":len(images),
                "note":"Atlas reference maps and label positions; not independently checked in the live Forever client."}
    (MEDIA / "Atlas-MapManifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Imported {len(images)} original map sheets for {len(generated)} destinations; {sum(len(m['pins']) for maps in generated.values() for m in maps)} selectable markers.")


if __name__ == "__main__":
    main()
