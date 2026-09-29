"""Build a curated Classic reward-chain catalog from QuestieDB references.

Selection is editorial; rewards and all prerequisite/availability data come from
the source tables. No item rarity or promised Forever upgrade is inferred.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_classic_data import numbers, optional_int, split_lua_fields
from build_opportunities import lua_array, read_maps, read_rows, read_transforms, spawns, starter_ids


# key, finale quest, catalog title, reason to pursue, retain when outleveled
CATALOG = [
    ("defias", 166, "The Defias Brotherhood", "Dungeon finale with weapon and armor rewards", False),
    ("wrynn", 396, "Seal of Wrynn", "Named ring after the Defias investigation in Stormwind", False),
    ("sylvanas", 1014, "Seal of Sylvanas", "Named ring from Shadowfang Keep", False),
    ("fang", 914, "Leaders of the Fang", "Weapon rewards from Wailing Caverns", False),
    ("verigan", 1806, "Verigan's Fist", "Paladin weapon chain with dungeon objectives", False),
    ("whirlwind", 1792, "Whirlwind weapons", "Warrior weapon chain with three weapon options", False),
    ("bloodrobe", 4786, "Enchanted Gold Bloodrobe", "Warlock armor chain with a named robe", False),
    ("magewand", 1952, "Mage's Wand", "Class wand chain with three reward options", False),
    ("carrot", 2770, "Carrot on a Stick", "Travel trinket from Zul'Farrak", True),
    ("stopwatch", 778, "Nifty Stopwatch", "Utility trinket from a multi-part quest", True),
    ("doomskull", 737, "Skull of Impending Doom", "Utility off-hand with a distinctive activated effect", True),
    ("eranikus", 3373, "The Essence of Eranikus", "Named trinket from the Sunken Temple", False),
    ("fordring", 5944, "In Dreams", "Reward choices after Tirion Fordring's Plaguelands story", False),
    ("drakkisath_a", 5102, "Blackrock Spire rewards", "Trinket options after General Drakkisath", False),
    ("drakkisath_h", 4974, "Blackrock Spire rewards", "Trinket options after the Horde's Blackrock Spire chain", False),
]


def build(quest_path: Path, npc_path: Path, object_path: Path, item_path: Path,
          map_path: Path, conversion_path: Path, output: Path) -> None:
    quests, npcs, objects, items = map(read_rows, (quest_path, npc_path, object_path, item_path))
    for f in quests.values():
        f.extend(["nil"] * (36 - len(f)))
    maps, transforms = read_maps(map_path), read_transforms(conversion_path)
    parents = {qid: set(numbers(f[11]) + numbers(f[12])) for qid, f in quests.items()}
    for qid, f in quests.items():
        for child in numbers(f[13]) + numbers(f[21]) + numbers(f[26]):
            if child in parents:
                parents[child].add(qid)
        sources = split_lua_fields(f[1][1:-1]) if f[1] != "nil" else []
        for item_id in numbers(sources[2]) if len(sources) > 2 else []:
            item = items.get(item_id)
            if item and len(item) > 5:
                # Some trainer quests award a book which starts the next quest.
                # Keep the trainer step without pretending the book is owned.
                parents[qid].update(parent for parent in numbers(item[5]) if parent in quests)
    membership: dict[int, dict[str, int]] = {}
    lines = [
        "-- Curated Classic reward chains; generated from QuestieDB quest/item/starter data.",
        "-- Rewards are Classic references, not guaranteed Forever offers or upgrades.",
        "-- See DEVELOPMENT.md and Source/tools/build_special_quests.py.",
        "local _, addon = ...", "addon.SpecialQuestRoutes = {",
    ]
    for key, finale, title, reason, utility in CATALOG:
        f = quests[finale]
        rewards = [f"{{{item_id},{row[0]}}}" for item_id, row in sorted(items.items())
                   if len(row) > 5 and finale in numbers(row[5])]
        if not rewards:
            raise ValueError(f"No source reward for {key}")
        lines += [f'  ["{key}"] = {{title={json.dumps(title)}, finale={finale},',
                  f"    minLevel={optional_int(f[3]) or 1}, level={optional_int(f[4]) or 1}, "
                  f"raceMask={optional_int(f[5]) or 0}, classMask={optional_int(f[6]) or 0},",
                  f"    reason={json.dumps(reason)}, utility={str(utility).lower()}, rewards={{{','.join(rewards)}}}}},"]
        distances, pending = {finale: 0}, [finale]
        while pending:
            current = pending.pop(0)
            membership.setdefault(current, {})[key] = distances[current]
            for parent in parents.get(current, []):
                if parent in quests and parent not in distances:
                    distances[parent] = distances[current] + 1
                    pending.append(parent)
    selected = set(membership)
    children = {qid: set() for qid in selected}
    for qid in selected:
        for parent in parents[qid]:
            if parent in children:
                children[parent].add(qid)
    def descendants(start: int) -> set[int]:
        seen, pending = {start}, list(children[start])
        while pending:
            qid = pending.pop()
            if qid not in seen:
                seen.add(qid)
                pending.extend(children[qid])
        return seen - {start}
    lines += ["}", "-- QuestID -> route key -> remaining reference steps (shortest prerequisite path).",
              "addon.SpecialQuestMembership = {"]
    for qid, routes in sorted(membership.items()):
        values = ",".join(f'["{key}"]={distance}' for key, distance in sorted(routes.items()))
        lines.append(f"  [{qid}] = {{{values}}},")
    lines += ["}", "-- Same gate tuple as ClassQuestInfo; routeKey [2] is nil.", "addon.SpecialQuestGates = {"]
    placements = []
    for qid in sorted(selected):
        f = quests[qid]
        supported = (optional_int(f[23]) or 0) % 2 != 1 and not any(f[i] != "nil" for i in (17, 18, 19, 29, 30, 34))
        blockers = sorted(set(numbers(f[15])) | descendants(qid))
        lines.append(f"  [{qid}] = {{{optional_int(f[6]) or 0},nil,{lua_array(blockers)},"
                     f"{f[24]},{f[31]},{f[32]},{f[33]},{f[35]},{str(supported).lower()}}},")
        if not supported:
            continue
        creatures, object_ids = starter_ids(f[1])
        parts = f[1][1:-1] if f[1] != "nil" else ""
        # Item-start quests are shown as requiring the item, without fabricated
        # NPC coordinates; the client must confirm possession to recommend them.
        source_parts = split_lua_fields(parts) if parts else []
        item_ids = numbers(source_parts[2]) if len(source_parts) > 2 else []
        locations = {}
        for table, ids, spawn_idx, faction_idx in ((npcs, creatures, 6, 12), (objects, object_ids, 3, None)):
            for source_id in ids:
                source = table.get(source_id)
                if not source:
                    continue
                faction = source[faction_idx] if faction_idx is not None and len(source) > faction_idx else '"AH"'
                if faction == "nil":
                    continue
                for area, (x, y) in spawns(source[spawn_idx]).items():
                    map_id = maps.get(area)
                    if not map_id or map_id in (1414, 1415):
                        continue
                    if transform := transforms.get(map_id):
                        x = x * transform["scale_x"] + transform["offset_x"]
                        y = y * transform["scale_y"] + transform["offset_y"]
                    if 0 < x < 100 and 0 < y < 100:
                        locations.setdefault(map_id, (x, y, source[0], faction))
        prefix = f"{qid},{f[0]},{optional_int(f[3]) or 1},{optional_int(f[4]) or 1},{optional_int(f[5]) or 0},{optional_int(f[6]) or 0}"
        pre = f"{lua_array(numbers(f[12]))},{lua_array(numbers(f[11]))}"
        for map_id, (x, y, name, faction) in sorted(locations.items()):
            placements.append(f"  {{{prefix},{round(x,2)},{round(y,2)},{pre},{name},{faction},{map_id}}},")
        if not locations and item_ids:
            for item_id in item_ids:
                if item := items.get(item_id):
                    placements.append(f"  {{{prefix},nil,nil,{pre},{item[0]},\"AH\",nil,{item_id}}},")
    lines += ["}", "-- QuestOpportunities row format; [13] mapID, [14] required starter itemID if no coordinates.",
              "addon.SpecialQuestStarters = {"] + placements + ["}", ""]
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(CATALOG)} standout reward chains; {len(selected)} reference steps; {len(placements)} starter placements")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("quests", "npcs", "objects", "items", "maps", "conversion"):
        parser.add_argument(name, type=Path)
    parser.add_argument("--output", type=Path, default=Path("ForeverWayfinder/Data/SpecialQuests.lua"))
    args = parser.parse_args()
    build(args.quests, args.npcs, args.objects, args.items, args.maps, args.conversion, args.output)
