"""Build compact Classic quest-starter suggestions for Forever Wayfinder.

Inputs are QuestieDB's Classic quest/NPC/object tables and Forever area map table.
They are build inputs only; the addon never loads QuestieDB.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

from build_classic_data import ROW, numbers, optional_int, split_lua_fields


MAP_ROW = re.compile(r"^\s*\[(\d+)\] = (\d+),")
ZONE_ROW = re.compile(r"^\s*\{(\d+),")
SPAWN = re.compile(r"\[(\d+)\]\s*=\s*\{\s*\{\s*([\d.]+)\s*,\s*([\d.]+)")


def read_rows(path: Path) -> dict[int, list[str]]:
    rows = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if match := ROW.match(line):
            rows[int(match.group(1))] = split_lua_fields(match.group(2))
    return rows


def read_maps(path: Path) -> dict[int, int]:
    return {int(match.group(1)): int(match.group(2))
            for line in path.read_text(encoding="utf-8").splitlines()
            if (match := MAP_ROW.match(line))}


def curated_maps(path: Path) -> set[int]:
    return {int(match.group(1))
            for line in path.read_text(encoding="utf-8").splitlines()
            if (match := ZONE_ROW.match(line))}


def starter_ids(field: str) -> tuple[list[int], list[int]]:
    if field == "nil":
        return [], []
    parts = split_lua_fields(field[1:-1])
    parts.extend(["nil"] * (3 - len(parts)))
    return numbers(parts[0]), numbers(parts[1])


def spawns(field: str) -> dict[int, tuple[float, float]]:
    if field == "nil":
        return {}
    return {int(area): (float(x), float(y))
            for area, x, y in SPAWN.findall(field)}


def lua_array(ids: list[int]) -> str:
    return "{" + ",".join(map(str, ids)) + "}" if ids else "nil"


def read_transforms(path: Path) -> dict[int, dict[str, float]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return {row["ui_map_id"]: row["coefficients"]
            for row in data["geometry"]["transforms"] if row["changed"]}


def build(quest_path: Path, npc_path: Path, object_path: Path,
          map_path: Path, conversion_path: Path, zone_path: Path, output: Path) -> None:
    quests = read_rows(quest_path)
    npcs = read_rows(npc_path)
    objects = read_rows(object_path)
    area_to_map = read_maps(map_path)
    transforms = read_transforms(conversion_path)
    allowed_maps = curated_maps(zone_path)
    by_map: dict[int, dict[int, tuple]] = {map_id: {} for map_id in allowed_maps}

    for quest_id, fields in quests.items():
        fields.extend(["nil"] * (36 - len(fields)))
        # Skill, reputation, spell, specialization, and rank gates need checks
        # that the small guide does not currently make.
        if any(fields[i] != "nil" for i in (17, 18, 19, 29, 30, 34)):
            continue
        creature_ids, object_ids = starter_ids(fields[1])
        for source_rows, source_ids, spawn_index, faction_index in (
            (npcs, creature_ids, 6, 12),
            (objects, object_ids, 3, None),
        ):
            for source_id in source_ids:
                source = source_rows.get(source_id)
                if not source:
                    continue
                faction = source[faction_index] if faction_index is not None and len(source) > faction_index else '"AH"'
                if faction == "nil":
                    continue
                for area_id, (x, y) in spawns(source[spawn_index]).items():
                    map_id = area_to_map.get(area_id)
                    if map_id not in by_map:
                        continue
                    if transform := transforms.get(map_id):
                        x = x * transform["scale_x"] + transform["offset_x"]
                        y = y * transform["scale_y"] + transform["offset_y"]
                    if not (0 < x < 100 and 0 < y < 100):
                        continue
                    if quest_id in by_map[map_id]:
                        continue
                    by_map[map_id][quest_id] = (
                        quest_id, fields[0], optional_int(fields[3]) or 1,
                        optional_int(fields[4]) or 1,
                        optional_int(fields[5]) or 0,
                        optional_int(fields[6]) or 0,
                        round(x, 2), round(y, 2),
                        numbers(fields[12]), numbers(fields[11]),
                        source[0], faction,
                    )

    lines = [
        "-- Generated from QuestieDB Classic starter data and Forever map geometry.",
        "-- See README.md for provenance and availability limits.",
        "local _, addon = ...",
        "-- {questID, title, requiredLevel, questLevel, raceMask, classMask, x, y,",
        "--  preQuestSingle, preQuestGroup, starterName, friendlyFaction}",
        "addon.QuestOpportunities = {",
    ]
    total = 0
    for map_id, rows in sorted(by_map.items()):
        if not rows:
            continue
        lines.append(f"  [{map_id}] = {{")
        for row in sorted(rows.values(), key=lambda item: (item[3], item[0])):
            quest_id, title, required, level, races, classes, x, y, single, group, starter, faction = row
            lines.append(
                f"    {{{quest_id},{title},{required},{level},{races},{classes},{x},{y},"
                f"{lua_array(single)},{lua_array(group)},{starter},{faction}}},"
            )
            total += 1
        lines.append("  },")
    lines.extend(["}", ""])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"{total} quest starter placements in {sum(bool(rows) for rows in by_map.values())} curated maps")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("quests", type=Path)
    parser.add_argument("npcs", type=Path)
    parser.add_argument("objects", type=Path)
    parser.add_argument("maps", type=Path)
    parser.add_argument("conversion", type=Path)
    parser.add_argument("--zones", type=Path, default=Path("ForeverWayfinder/Data/Zones.lua"))
    parser.add_argument("--output", type=Path, default=Path("ForeverWayfinder/Data/QuestOpportunities.lua"))
    args = parser.parse_args()
    build(args.quests, args.npcs, args.objects, args.maps, args.conversion, args.zones, args.output)


if __name__ == "__main__":
    main()
