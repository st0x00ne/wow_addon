"""Build compact Classic chain step details without bundling QuestieDB itself.

Sources: QuestieDB Classic quest, NPC, object, and item tables, plus its
Forever area-to-map and coordinate conversion tables. These are build inputs.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path
import re

from build_classic_data import linear_chains, numbers, optional_int, read_quests, split_lua_fields
from build_opportunities import read_maps, read_rows, read_transforms, spawns


REP = re.compile(r"\{\s*(\d+)\s*,\s*(-?\d+)\s*\}")


def source_ids(value: str) -> tuple[list[int], list[int], list[int]]:
    if value == "nil":
        return [], [], []
    parts = split_lua_fields(value[1:-1])
    parts.extend(["nil"] * (3 - len(parts)))
    return numbers(parts[0]), numbers(parts[1]), numbers(parts[2])


def lua_array(values: list[str]) -> str:
    return "{" + ",".join(values) + "}" if values else "nil"


def names_for_sources(value: str, npcs: dict, objects: dict, items: dict) -> list[str]:
    names = []
    for kind, ids, rows in zip((1, 2, 3), source_ids(value), (npcs, objects, items)):
        for source_id in ids[:4]:
            row = rows.get(source_id)
            if row and row[0] != "nil":
                names.append("{" + str(kind) + "," + row[0] + "}")
    return names


def text_paragraphs(value: str) -> list[str]:
    if value == "nil":
        return []
    return [part for part in split_lua_fields(value[1:-1])
            if part not in ('nil', '""', "''")]


def prerequisites(value: str, quests: dict[int, dict]) -> list[str]:
    result = []
    for quest_id in numbers(value):
        if quest_id in quests:
            result.append("{" + str(quest_id) + "," + quests[quest_id]["title"] + "}")
    return result


def location(value: str, preferred_area: int | None, npcs: dict, objects: dict,
             area_to_map: dict[int, int], transforms: dict) -> str:
    candidates = []
    creatures, game_objects, _ = source_ids(value)
    for ids, rows, spawn_index in ((creatures, npcs, 6), (game_objects, objects, 3)):
        for source_id in ids:
            row = rows.get(source_id)
            if not row or len(row) <= spawn_index:
                continue
            for area_id, (x, y) in spawns(row[spawn_index]).items():
                map_id = area_to_map.get(area_id)
                if not map_id:
                    continue
                if transform := transforms.get(map_id):
                    x = x * transform["scale_x"] + transform["offset_x"]
                    y = y * transform["scale_y"] + transform["offset_y"]
                if 0 < x < 100 and 0 < y < 100:
                    candidates.append((area_id != preferred_area, map_id, x, y))
    if not candidates:
        return "nil"
    _, map_id, x, y = min(candidates)
    return "{" + f"{map_id},{x:.2f},{y:.2f}" + "}"


def build(quest_path: Path, npc_path: Path, object_path: Path, item_path: Path,
          map_path: Path, conversion_path: Path, output: Path) -> None:
    quests = read_quests(quest_path)
    quest_rows = read_rows(quest_path)
    npcs = read_rows(npc_path)
    objects = read_rows(object_path)
    items = read_rows(item_path)
    area_to_map = read_maps(map_path)
    transforms = read_transforms(conversion_path)
    chain_ids = {quest_id for chain in linear_chains(quests) for quest_id in chain}

    rewards: dict[int, list[str]] = defaultdict(list)
    for item_id, row in items.items():
        if len(row) > 5 and row[5] != "nil":
            for quest_id in numbers(row[5]):
                if quest_id in chain_ids and len(rewards[quest_id]) < 12:
                    rewards[quest_id].append("{" + str(item_id) + "," + row[0] + "}")

    lines = [
        "-- Generated from QuestieDB Classic references and Forever map geometry.",
        "-- All future-step information is a Classic reference; Forever may differ.",
        "local _, addon = ...",
        "-- {objective paragraphs, start sources, turn-in sources, Classic item rewards,",
        "--  reputation, start location, turn-in location, one-of prerequisites,",
        "--  all-of prerequisites, supplied quest item}",
        "addon.ClassicChainDetails = {",
    ]
    objective_count = source_count = reward_count = 0
    for quest_id in sorted(chain_ids):
        fields = quest_rows[quest_id]
        fields.extend(["nil"] * (36 - len(fields)))
        objective = text_paragraphs(fields[7])
        starts = names_for_sources(fields[1], npcs, objects, items)
        ends = names_for_sources(fields[2], npcs, objects, items)
        item_rewards = rewards.get(quest_id, [])
        reputation = ["{" + faction + "," + amount + "}"
                      for faction, amount in REP.findall(fields[25])]
        preferred_area = optional_int(fields[16])
        start_location = location(fields[1], preferred_area, npcs, objects, area_to_map, transforms)
        end_location = location(fields[2], preferred_area, npcs, objects, area_to_map, transforms)
        one_of = prerequisites(fields[12], quests)
        all_of = prerequisites(fields[11], quests)
        source_item_id = optional_int(fields[10])
        item = items.get(source_item_id) if source_item_id else None
        supplied = "{" + str(source_item_id) + "," + item[0] + "}" if item else "nil"
        values = (
            lua_array(objective), lua_array(starts), lua_array(ends), lua_array(item_rewards),
            lua_array(reputation), start_location, end_location, lua_array(one_of),
            lua_array(all_of), supplied,
        )
        lines.append(f"  [{quest_id}] = {{{','.join(values)}}},")
        objective_count += bool(objective)
        source_count += bool(starts or ends)
        reward_count += bool(item_rewards)
    lines.extend(["}", ""])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(chain_ids)} steps; {objective_count} objectives, "
          f"{source_count} sources, {reward_count} item reward references")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("quests", type=Path)
    parser.add_argument("npcs", type=Path)
    parser.add_argument("objects", type=Path)
    parser.add_argument("items", type=Path)
    parser.add_argument("maps", type=Path)
    parser.add_argument("conversion", type=Path)
    parser.add_argument("--output", type=Path, default=Path("ForeverWayfinder/Data/ClassicChainDetails.lua"))
    args = parser.parse_args()
    build(args.quests, args.npcs, args.objects, args.items, args.maps, args.conversion, args.output)


if __name__ == "__main__":
    main()
