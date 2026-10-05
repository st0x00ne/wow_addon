"""Build a conservative Classic zone checklist for Forever Wayfinder.

Uses QuestieDB's Classic quest table and Forever area-to-map mapping. Class
quests, repeatables, event quests, profession/reputation/spell gated quests,
and quests without a positive mapped zone remain outside zone totals.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path
import re

from build_classic_data import numbers, optional_int, split_lua_fields, ROW


MAP_ROW = re.compile(r"^\s*\[(\d+)\] = (\d+),")
ZONE_ROW = re.compile(r"^\s*\{(\d+),")


def build(quests_path: Path, maps_path: Path, zones_path: Path, output: Path) -> None:
    maps = {int(m.group(1)): int(m.group(2)) for line in maps_path.read_text(encoding="utf-8").splitlines()
            if (m := MAP_ROW.match(line))}
    allowed = {int(m.group(1)) for line in zones_path.read_text(encoding="utf-8").splitlines()
               if (m := ZONE_ROW.match(line))}
    quests = {}
    class_quests = {}
    for line in quests_path.read_text(encoding="utf-8").splitlines():
        match = ROW.match(line)
        if not match:
            continue
        quest_id = int(match.group(1))
        fields = split_lua_fields(match.group(2))
        fields.extend(["nil"] * (36 - len(fields)))
        flags = optional_int(fields[23]) or 0
        class_mask = optional_int(fields[6]) or 0
        # The Atlas does not yet evaluate these availability gates. Class
        # quests with such gates remain visible but outside scored totals.
        gated = any(fields[i] != "nil" for i in (17, 18, 19, 29, 30, 34))
        countable = flags % 4 == 0 and not gated
        area = optional_int(fields[16])
        record = {
            "map": maps.get(area) if area and area > 0 else None,
            "name": fields[0],
            "required": optional_int(fields[3]) or 1,
            "level": optional_int(fields[4]) or 1,
            "races": optional_int(fields[5]) or 0,
            "classes": class_mask,
            "exclusive": numbers(fields[15]),
            "countable": countable,
        }
        if class_mask:
            class_quests[quest_id] = record
        elif countable and record["map"] in allowed:
            quests[quest_id] = record
    if len(quests) < 1000:
        raise ValueError(f"Unexpectedly small zone checklist: {len(quests)} quests")

    def alternatives(catalog: dict[int, dict]):
        # Mutually exclusive Classic alternatives are one checklist path.
        parent = {id: id for id in catalog}

        def find(id: int) -> int:
            while parent[id] != id:
                parent[id] = parent[parent[id]]
                id = parent[id]
            return id

        for id, quest in catalog.items():
            for other in quest["exclusive"]:
                if other in catalog:
                    a, b = find(id), find(other)
                    parent[max(a, b)] = min(a, b)
        groups = defaultdict(list)
        for id in catalog:
            groups[find(id)].append(id)
        return find, groups

    find, groups = alternatives(quests)
    class_find, class_groups = alternatives(class_quests)
    by_map = defaultdict(list)
    for id, quest in quests.items():
        by_map[quest["map"]].append((id, quest))

    lines = [
        "-- Generated from QuestieDB Classic quests and Forever area-to-map data.",
        "-- One-time mapped quests only; class, event, repeatable and gated quests are separate.",
        "local _, addon = ...",
        "-- {questID, title, requiredLevel, questLevel, raceMask, alternativeGroupID}",
        "addon.AtlasQuestCatalog = {",
    ]
    for map_id, rows in sorted(by_map.items()):
        lines.append(f"  [{map_id}] = {{")
        for id, quest in sorted(rows, key=lambda pair: (pair[1]["required"], pair[1]["level"], pair[0])):
            group = find(id)
            lines.append(f"    {{{id},{quest['name']},{quest['required']},{quest['level']},"
                         f"{quest['races']},{group if len(groups[group]) > 1 else 'nil'}}},")
        lines.append("  },")
    lines += ["}", "addon.AtlasQuestAlternatives = {"]
    for group, members in sorted(groups.items()):
        if len(members) > 1:
            lines.append(f"  [{group}] = {{{','.join(map(str, sorted(members)))} }},")
    lines += ["}", "-- {questID, title, requiredLevel, questLevel, raceMask, classMask, alternativeGroupID, scored}",
              "addon.AtlasClassQuestCatalog = {"]
    for id, quest in sorted(class_quests.items(), key=lambda pair: (pair[1]["required"], pair[1]["level"], pair[0])):
        group = class_find(id)
        lines.append(f"  {{{id},{quest['name']},{quest['required']},{quest['level']},{quest['races']},"
                     f"{quest['classes']},{group if len(class_groups[group]) > 1 else 'nil'},"
                     f"{str(quest['countable']).lower()}}},")
    lines += ["}", "addon.AtlasClassQuestAlternatives = {"]
    for group, members in sorted(class_groups.items()):
        if len(members) > 1:
            lines.append(f"  [{group}] = {{{','.join(map(str, sorted(members)))} }},")
    lines += ["}", ""]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(quests)} mapped Classic quests in {len(by_map)} curated zones; "
          f"{len(class_quests)} class quests ({sum(q['countable'] for q in class_quests.values())} scored); "
          f"{sum(len(ids) > 1 for ids in groups.values())} zone alternative groups")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("quests", type=Path)
    parser.add_argument("maps", type=Path)
    parser.add_argument("--zones", type=Path, default=Path("ForeverWayfinder/Data/Zones.lua"))
    parser.add_argument("--output", type=Path, default=Path("ForeverWayfinder/Data/AtlasQuestCatalog.lua"))
    args = parser.parse_args()
    build(args.quests, args.maps, args.zones, args.output)


if __name__ == "__main__":
    main()
