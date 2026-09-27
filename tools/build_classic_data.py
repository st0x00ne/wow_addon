"""Build the small Classic reference bundled by Forever Wayfinder.

Input: QuestieDB's data/Classic/classicQuestDB.lua, supplied as a local file.
The input is used at build time only; the addon never loads QuestieDB.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re


ROW = re.compile(r"^\[(\d+)\] = \{(.*)\},?$")
XP_ROW = re.compile(r"^\s*\[(\d+)\] = \{(-?\d+), (\d+)\},")


def split_lua_fields(body: str) -> list[str]:
    fields: list[str] = []
    depth = 0
    quote: str | None = None
    escaped = False
    start = 0
    for index, char in enumerate(body):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'"):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        elif char == "," and depth == 0:
            fields.append(body[start:index].strip())
            start = index + 1
    fields.append(body[start:].strip())
    if quote or depth != 0:
        raise ValueError("Unbalanced Lua row")
    return fields


def numbers(value: str) -> list[int]:
    if value == "nil":
        return []
    return [int(part) for part in re.findall(r"\d+", value)]


def optional_int(value: str) -> int | None:
    return None if value == "nil" else int(value)


def read_quests(path: Path) -> dict[int, dict]:
    quests: dict[int, dict] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = ROW.match(line)
        if not match:
            continue
        quest_id = int(match.group(1))
        fields = split_lua_fields(match.group(2))
        if len(fields) < 17:
            raise ValueError(f"Quest {quest_id} has only {len(fields)} fields")
        fields.extend(["nil"] * (25 - len(fields)))
        quests[quest_id] = {
            "title": fields[0],
            "required_level": optional_int(fields[3]),
            "level": optional_int(fields[4]),
            "race_mask": optional_int(fields[5]),
            "class_mask": optional_int(fields[6]),
            "prerequisites": numbers(fields[12]),
            "children": numbers(fields[13]),
            "next": optional_int(fields[21]),
            "area": optional_int(fields[16]),
        }
    if len(quests) < 4000:
        raise ValueError(f"Expected the full Classic quest set, found {len(quests)}")
    return quests


def read_xp(path: Path) -> dict[int, int]:
    xp: dict[int, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = XP_ROW.match(line)
        if match:
            xp[int(match.group(1))] = int(match.group(3))
    if len(xp) < 3000:
        raise ValueError(f"Expected the full Forever support XP set, found {len(xp)}")
    return xp


def id_ranges(ids: list[int]) -> list[tuple[int, int]]:
    ranges: list[tuple[int, int]] = []
    for quest_id in ids:
        if ranges and quest_id == ranges[-1][1] + 1:
            ranges[-1] = (ranges[-1][0], quest_id)
        else:
            ranges.append((quest_id, quest_id))
    return ranges


def linear_chains(quests: dict[int, dict]) -> list[list[int]]:
    successor: dict[int, int] = {}
    predecessor: dict[int, int] = {}
    candidates: dict[int, list[int]] = {}
    for child_id, child in quests.items():
        if len(child["prerequisites"]) == 1:
            parent_id = child["prerequisites"][0]
            if parent_id in quests:
                candidates.setdefault(parent_id, []).append(child_id)
    for quest_id, quest in quests.items():
        children = candidates.get(quest_id, [])
        if quest["next"] in children:
            child_id = quest["next"]
        elif quest["next"] is None and len(children) == 1:
            child_id = children[0]
        else:
            continue
        successor[quest_id] = child_id
        predecessor[child_id] = quest_id
    chains: list[list[int]] = []
    used: set[int] = set()
    for quest_id in sorted(successor):
        if quest_id in predecessor:
            continue
        chain = [quest_id]
        while chain[-1] in successor:
            next_id = successor[chain[-1]]
            if next_id in chain:
                break
            chain.append(next_id)
        if len(chain) >= 2 and all(part not in used for part in chain):
            chains.append(chain)
            used.update(chain)
    return chains


def continuations(quests: dict[int, dict], chains: list[list[int]]) -> dict[int, list[int]]:
    tails = {chain[-1] for chain in chains}
    result: dict[int, list[int]] = {}
    for tail in sorted(tails):
        linked = []
        next_id = quests[tail]["next"]
        if next_id in quests:
            linked.append(next_id)
        for quest_id, quest in sorted(quests.items()):
            if tail in quest["prerequisites"] and quest_id not in linked:
                linked.append(quest_id)
        if linked:
            result[tail] = linked
    return result


def emit(quests: dict[int, dict], xp: dict[int, int], chains: list[list[int]], output: Path) -> None:
    ranges = id_ranges(sorted(quests))
    lines = [
        "-- Generated from QuestieDB Classic quest data. See README.md for provenance.",
        "local _, addon = ...",
        "addon.ClassicQuestRanges = {",
    ]
    for index in range(0, len(ranges), 8):
        lines.append("  " + ", ".join(f"{{{lo},{hi}}}" for lo, hi in ranges[index:index+8]) + ",")
    lines.extend(["}", "", "addon.ClassicChains = {"])
    for chain in chains:
        entries = ", ".join(
            f"{{{quest_id},{quests[quest_id]['title']},{quests[quest_id]['level'] or 0},"
            f"{quests[quest_id]['required_level'] or 0},{xp.get(quest_id, 0)}}}"
            for quest_id in chain
        )
        lines.append(f"  {{{entries}}},")
    lines.extend(["}", "", "addon.ClassicContinuations = {"])
    for tail, linked in continuations(quests, chains).items():
        entries = ", ".join(
            f"{{{quest_id},{quests[quest_id]['title']},{quests[quest_id]['level'] or 0}}}"
            for quest_id in linked
        )
        lines.append(f"  [{tail}] = {{{entries}}},")
    lines.extend(["}", "", "addon.ChainByQuest = {}"])
    lines.extend([
        "for chainIndex, chain in ipairs(addon.ClassicChains) do",
        "  for step, quest in ipairs(chain) do",
        "    addon.ChainByQuest[quest[1]] = {chainIndex, step}",
        "  end",
        "end",
        "",
    ])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(quests)} quests, {len(ranges)} ranges, {len(chains)} linear chains, {sum(map(len, chains))} chain steps")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--xp-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("ForeverWayfinder/Data/ClassicQuests.lua"))
    args = parser.parse_args()
    quests = read_quests(args.source)
    emit(quests, read_xp(args.xp_source), linear_chains(quests), args.output)


if __name__ == "__main__":
    main()
