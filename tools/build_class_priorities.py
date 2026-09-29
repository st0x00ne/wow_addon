"""Build class quest priorities from QuestieDB Classic data and Forever maps.

Routes are curated Classic references, not verified Forever unlock requirements.
Spell guards use actual player abilities, never the server's teaching spells.
See DEVELOPMENT.md for sources and the distinction.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_classic_data import numbers, optional_int
from build_opportunities import lua_array, read_maps, read_rows, read_transforms, spawns, starter_ids


# key: (class mask, label, terminal/reference quests, known player spells)
# A multi-spell guard requires ALL listed abilities (e.g. complete pet training).
ROUTES = {
    "defensive": (1, "Defensive Stance", [1498, 1665, 1678, 1683, 1819], [71]),
    "berserker": (1, "Berserker Stance", [1719], [2458]),
    "redemption": (2, "Redemption", [1785, 1788], [7328]),
    "sense": (2, "Sense Undead", [1652], [5502]),
    "warhorse": (2, "Warhorse", [1661], [13819]),
    "charger": (2, "Charger", [7647], [23214]),
    "pets": (4, "Pet taming and training", [6081, 6086, 6089, 6103], [1515, 883, 982, 6991]),
    "locks": (8, "Lockpicking training", [1999, 2260, 2282, 2298, 2381], []),
    "poisons": (8, "Poisons", [2359, 2480], [2842]),
    "earth": (64, "Earth Totem", [1518, 1521], []),
    "fire": (64, "Fire Totem", [1527], []),
    "water": (64, "Water Totem", [96, 1103], []),
    "air": (64, "Air Totem", [1531, 1532], []),
    "water_rank": (128, "Conjure Water upgrade", [7463], [10140]),
    "pig": (128, "Polymorph: Pig", [9364], [28272]),
    "imp": (256, "Summon Imp", [1470, 1485, 1598, 1599], [688]),
    "voidwalker": (256, "Summon Voidwalker", [1471, 1504, 1689], [697]),
    "succubus": (256, "Summon Succubus", [1474, 1513, 1739], [712]),
    "felhunter": (256, "Summon Felhunter", [1795], [691]),
    "felsteed": (256, "Felsteed", [4490], [5784]),
    "infernal": (256, "Summon Infernal", [7603], [1122]),
    "doomguard": (256, "Summon Doomguard", [7583], [18540]),
    "dreadsteed": (256, "Dreadsteed", [7631], [23161]),
    "bear": (1024, "Bear Form", [6001, 6002], [[5487, 9634]]),
    "aquatic": (1024, "Aquatic Form", [31, 5061], [1066]),
    "cure": (1024, "Cure Poison", [6125, 6130], [8946]),
}
PRIEST_ABILITIES = {
    "Stars of Elune", "Desperate Prayer", "A Lack of Fear", "Shadowguard",
    "Devouring Plague", "Hex of Weakness", "Touch of Weakness", "Elune's Grace", "Arcane Feedback",
}
PRIEST_SPELLS = {
    "Stars of Elune": 10797, "Desperate Prayer": 13908, "A Lack of Fear": 6346,
    "Shadowguard": 18137, "Devouring Plague": 2944, "Hex of Weakness": 9035,
    "Touch of Weakness": 2652, "Elune's Grace": 2651, "Arcane Feedback": 13896,
}
# Questie records Lydros at {-1,-1}; retain the ability reminder without inventing
# a dungeon waypoint. The quest text names the Athenaeum as his location.
UNLOCATED_STARTERS = {7463: ("Lorekeeper Lydros", "AH", "Dire Maul · The Athenaeum")}


def build(quests_path: Path, npcs_path: Path, objects_path: Path, maps_path: Path,
          conversion_path: Path, output: Path) -> None:
    quests = read_rows(quests_path)
    for fields in quests.values():
        fields.extend(["nil"] * (36 - len(fields)))
    class_quests = {qid: f for qid, f in quests.items() if optional_int(f[6])}
    routes = dict(ROUTES)
    for title in sorted(PRIEST_ABILITIES):
        ids = [qid for qid, f in class_quests.items() if optional_int(f[6]) == 16 and f[0] == f'"{title}"']
        if not ids:
            raise ValueError(f"Missing priest ability: {title}")
        key = "priest_" + title.lower().replace(" ", "_").replace("'", "")
        routes[key] = (16, "Fear Ward" if title == "A Lack of Fear" else title, ids, [PRIEST_SPELLS[title]])

    parents: dict[int, set[int]] = {qid: set(numbers(f[11]) + numbers(f[12])) for qid, f in class_quests.items()}
    children: dict[int, set[int]] = {qid: set() for qid in class_quests}
    for qid, f in class_quests.items():
        next_ids = numbers(f[13]) + numbers(f[21]) + numbers(f[26])
        for following in next_ids:
            if following in class_quests:
                parents[following].add(qid)
        for parent in parents[qid]:
            if parent in children:
                children[parent].add(qid)
    # Build children after all forward links have contributed their parents.
    for qid, preceding in parents.items():
        for parent in preceding:
            if parent in children:
                children[parent].add(qid)

    def closure(start: int, links: dict[int, set[int]]) -> set[int]:
        seen, pending = {start}, list(links.get(start, []))
        while pending:
            qid = pending.pop()
            if qid not in seen:
                seen.add(qid)
                pending.extend(links.get(qid, []))
        seen.remove(start)
        return seen

    assigned: dict[int, str] = {}
    for key, (mask, _, ends, _) in routes.items():
        for endpoint in ends:
            if endpoint not in class_quests:
                raise ValueError(f"Missing class quest {endpoint}")
            for qid in {endpoint} | closure(endpoint, parents):
                if qid not in class_quests or optional_int(class_quests[qid][6]) != mask:
                    continue
                if qid in assigned and assigned[qid] != key:
                    # Shared preparatory gear quests retain the first route.
                    continue
                assigned[qid] = key

    npcs, objects = read_rows(npcs_path), read_rows(objects_path)
    maps, transforms = read_maps(maps_path), read_transforms(conversion_path)
    lines = [
        "-- Generated from QuestieDB Classic class quests and Forever map geometry.",
        "-- Curated ability routes are Classic references; Forever requirements may differ.",
        "-- See DEVELOPMENT.md and Source/tools/build_class_priorities.py.",
        "local _, addon = ...",
        "-- {label, terminalQuestIDs, knownPlayerSpells (all required; nested lists are alternatives)}",
        "addon.ClassQuestRoutes = {",
    ]
    for key, (_, label, ends, spells) in sorted(routes.items()):
        guard = "{" + ",".join(lua_array(spell) if isinstance(spell, list) else str(spell) for spell in spells) + "}" if spells else "nil"
        lines.append(f'  ["{key}"] = {{"{label}",{lua_array(ends)},{guard}}},')
    lines += ["}", "-- {classMask, routeKey, blockedByActiveOrDone, parentActive, maxLevel,",
              "--  unavailableAfterCompleted, availableStartingWith, disabledWhileActive, supportedGates}",
              "addon.ClassQuestInfo = {"]
    placements = []
    for qid, f in sorted(class_quests.items()):
        repeatable = (optional_int(f[23]) or 0) % 2 == 1
        supported = not repeatable and not any(f[i] != "nil" for i in (17, 18, 19, 29, 30, 34))
        # Suppress ancestors and alternate breadcrumbs after progressing past them.
        blockers = sorted(set(numbers(f[15])) | closure(qid, children))
        key = f'"{assigned[qid]}"' if qid in assigned else "nil"
        lines.append(f"  [{qid}] = {{{f[6]},{key},{lua_array(blockers)},{f[24]},"
                     f"{f[31]},{f[32]},{f[33]},{f[35]},{str(supported).lower()}}},")
        if not supported:
            continue
        creatures, object_ids = starter_ids(f[1])
        locations = {}
        for source_rows, ids, spawn_index, faction_index in ((npcs, creatures, 6, 12), (objects, object_ids, 3, None)):
            for source_id in ids:
                source = source_rows.get(source_id)
                if not source:
                    continue
                faction = source[faction_index] if faction_index is not None and len(source) > faction_index else '"AH"'
                if faction == "nil":
                    continue
                for area, (x, y) in spawns(source[spawn_index]).items():
                    map_id = maps.get(area)
                    # Starter points must be on a valid zone / city map, not a continent.
                    if not map_id or map_id in (1414, 1415):
                        continue
                    if transform := transforms.get(map_id):
                        x = x * transform["scale_x"] + transform["offset_x"]
                        y = y * transform["scale_y"] + transform["offset_y"]
                    if 0 < x < 100 and 0 < y < 100:
                        locations.setdefault(map_id, (x, y, source[0], faction))
        for map_id, (x, y, name, faction) in sorted(locations.items()):
            placements.append(f"  {{{qid},{f[0]},{optional_int(f[3]) or 1},{optional_int(f[4]) or 1},"
                              f"{optional_int(f[5]) or 0},{f[6]},{round(x, 2)},{round(y, 2)},"
                              f"{lua_array(numbers(f[12]))},{lua_array(numbers(f[11]))},{name},{faction},{map_id}}},")
        if not locations and qid in UNLOCATED_STARTERS:
            name, faction, location = UNLOCATED_STARTERS[qid]
            placements.append(f"  {{{qid},{f[0]},{f[3]},{f[4]},{f[5]},{f[6]},nil,nil,"
                              f"{lua_array(numbers(f[12]))},{lua_array(numbers(f[11]))},"
                              f"{json.dumps(name)},{json.dumps(faction)},nil,{json.dumps(location, ensure_ascii=False)}}},")
    lines += ["}", "-- QuestOpportunities row format, with mapID at [13]; includes cities and Moonglade.",
              "addon.ClassQuestStarters = {"] + placements + ["}", ""]
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(routes)} ability routes, {len(class_quests)} class quests, {len(placements)} starter placements")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("quests", "npcs", "objects", "maps", "conversion"):
        parser.add_argument(name, type=Path)
    parser.add_argument("--output", type=Path, default=Path("ForeverWayfinder/Data/ClassQuestPriorities.lua"))
    args = parser.parse_args()
    build(args.quests, args.npcs, args.objects, args.maps, args.conversion, args.output)
