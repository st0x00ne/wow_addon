# Forever Wayfinder

A standalone quest companion and personal Discovery Journal for **World of Warcraft: Forever**. It adds quiet markers and optional context to Forever's quest log and remembers your own travels.

This is a community beta for the Forever beta client (`1.60.1`, interface `16001`). It has been iterated from in-game testing, but still needs a clean install and wider character testing before a stable release.

## What it does

- **Discovery Journal** opens an illustrated leather-bound book. Search and category filters sit in a separate header above it; zone chapters and the entry index occupy the left page, with discovery details and personal notes on the right. It records quests in your log, acceptance and turn-in events, first zone discoveries, dungeon visits, and level-up milestones. Search names, NPCs, quest text, rewards observed in your log, tags, and personal notes. Combine zone, type, class, character, status, race, and faction filters; bookmark favorites and places to revisit. Write and edit field notes, with drafts saved when changing entries or leaving the editor. Recorded locations can open the map and set a waypoint. An encountered Classic quest can link to the existing Chain panel.
- **∞** on the right side of a quest row and its objective tracker entry means the quest ID is absent from a 4,244-quest Classic Era reference. This is a *candidate* Forever quest, not a guarantee that Blizzard created it for Forever. Its future steps and rewards stay hidden. Hover over the badge for a native tooltip explaining it.
- **D** on the right side of the quest log and tracker entry marks a dungeon quest using the client's quest tag. Hover over the badge for its native tooltip. Blizzard's quest details remain unchanged.
- **Chain** appears in the quest details for a known, linear Classic chain segment. Its journal-style side panel has expandable steps and **Show all / Hide all** controls. Opening a chain scrolls to the selected quest; clicking **Next** expands and scrolls to that step. Each step can show objectives, quest giver and turn-in, clickable map locations, prerequisites, a supplied quest item, level guidance, Classic XP, possible Classic item and reputation rewards. Where the source branches, possible Classic follow-ups are shown without claiming they are the end of the full chain. Forever may revise the order, locations, and rewards.
- For the selected active quest, the panel reads **live Forever XP, money, and item rewards** from the client. Future steps show possible Classic item rewards, clearly labeled as a reference; exact Forever rewards remain unknown until the quest is in your log, unless separately checked against Forever. The initial checked item entry is *The Defias Brotherhood* (quest 166).
- **Where next?** opens a journal-style panel with a gold-trimmed dark frame, compass heading, parchment reading area, and inset quest rows. It suggests up to three areas and shows a few possible **Classic** quests in each. It filters by level, faction, race, class, known prerequisites, and quests already active or completed. Click an area to open its map, or click a quest to set a native waypoint to its *starter* and super-track the waypoint. New Forever quest names remain hidden.

## Install

For the Discord zip, extract it into:

`World of Warcraft/_classic_beta_/Interface/AddOns/`

The result must be `AddOns/ForeverWayfinder/ForeverWayfinder.toc`. You can also copy the [ForeverWayfinder](ForeverWayfinder) folder from this repository to `AddOns`. Enable it on the character selection AddOns screen, then open the regular quest log. The [TOC](ForeverWayfinder/ForeverWayfinder.toc) targets Forever's beta interface `16001`; when the client moves out of beta, its add-on directory and interface number may need updating.

Fully exit and reopen WoW after installing this version so the new modules, artwork, and saved-variable declaration are loaded. Click **Journal** or **Where next?** at the bottom of the quest list, or **Chain** on an eligible Classic quest. `/fw journal` and `/fw journey` open the journal; `/fw` and `/fw where` open the suggestions; `/fw chain` opens the selected Classic chain. Clicking a recorded journal location, a Classic step location, or a quest in Where next? can replace your current user waypoint.

The **Wayfinder compass button on the minimap** also opens or closes your journal.
Drag it around the minimap's edge to choose a position; that position is saved
with your journal settings and restored after `/reload` or login.

## Your Discovery Journal

The journal is account-wide on this WoW installation and keeps each character's
records separate. Class, race, and faction describe the character who made a
discovery. Use custom tags such as `class quest` for your own quest labels.
Zone chapters describe where a discovery was recorded; a quest's objectives can
take place elsewhere. Existing quests are marked as first observed in your log;
acceptance dates are recorded only when the addon sees an acceptance event.
Earlier travel and completed quests are not reconstructed as invented history.

WoW stores `ForeverWayfinderJournal` in its SavedVariables directory under
`_classic_beta_/WTF/Account/<account>/SavedVariables/ForeverWayfinder.lua`.
Normal logout and `/reload` let WoW write it to disk. Your personal records are
outside the addon folder, so updating the Discord package preserves them.
Each player builds their own journal. Back up the saved-variable file with WoW
closed if you want a copy of your journey.

For a first in-game persistence check, write a field note, `/reload`, and then
fully exit and reopen WoW. The note should remain each time. `/fw journal status`
prints the entry and saved-session counts for troubleshooting.

## Data and limits

The bundled [ClassicQuests.lua](ForeverWayfinder/Data/ClassicQuests.lua) is generated from [QuestieDB's Classic quest data](https://github.com/Questie/QuestieDB/blob/master/data/Classic/classicQuestDB.lua) and its [Forever support XP table](https://github.com/Questie/QuestieDB/blob/master/support/Forever/QuestXP/xpDB-classic.lua). We keep quest ID ranges, unambiguous linear chain segments, linked follow-ups, levels, and XP estimates. [ClassicChainDetails.lua](ForeverWayfinder/Data/ClassicChainDetails.lua) adds step objectives, contact names, approximate locations, prerequisites, and possible item and reputation rewards from the Classic quest, [NPC](https://github.com/Questie/QuestieDB/blob/master/data/Classic/classicNpcDB.lua), [object](https://github.com/Questie/QuestieDB/blob/master/data/Classic/classicObjectDB.lua), and [item](https://github.com/Questie/QuestieDB/blob/master/data/Classic/classicItemDB.lua) tables. [QuestOpportunities.lua](ForeverWayfinder/Data/QuestOpportunities.lua) keeps a smaller subset of quest starter names and coordinates. This addon loads the generated files directly and does not install Questie. The sources are GPL-3.0; this repository includes the [license](LICENSE).

To refresh, download the Classic quest, NPC, object, and item tables plus the Forever XP table, the [Forever area-to-map table](https://github.com/Questie/QuestieDB/blob/master/support/Forever/Zones/areaIdToUiMapId.lua), and [coordinate conversion](https://github.com/Questie/QuestieDB/blob/master/data/Forever/conversion.json). Run `python tools/build_classic_data.py path/to/classicQuestDB.lua --xp-source path/to/xpDB-classic.lua`, `python tools/build_chain_details.py path/to/classicQuestDB.lua path/to/classicNpcDB.lua path/to/classicObjectDB.lua path/to/classicItemDB.lua path/to/areaIdToUiMapId.lua path/to/conversion.json`, and `python tools/build_opportunities.py path/to/classicQuestDB.lua path/to/classicNpcDB.lua path/to/classicObjectDB.lua path/to/areaIdToUiMapId.lua path/to/conversion.json` from the repository root.

The curated zone bands are approximate. The Forever zone IDs were cross-checked against [QuestieDB's Forever map mapping](https://github.com/Questie/QuestieDB/blob/master/support/Forever/Zones/areaIdToUiMapId.lua), with new-zone level guidance from [Blizzard's Forever overview](https://worldofwarcraft.blizzard.com/en-us/news/24303862/world-of-warcraft-forever-whats-next-panel-recap). The initial Defias reward entry was checked against a [Forever beta quest capture](https://wowforevertalent.com/quests/the-defias-brotherhood-166/). More reward entries should be added only after Forever-specific verification.

Forever quests that reuse a Classic quest ID will not receive an ∞ marker. Conversely, any quest absent from the Classic reference receives one, even if its provenance is uncertain. Branching Classic chains are omitted when the source does not give a single clear next step. No future Forever chain information is bundled.

Where next? shows *possible* Classic starts, not guaranteed live offers: Forever can move quest givers, revise requirements, or change coordinates. The waypoint marks a starter NPC or object, not the quest objective. It provides direction to that point; it does not calculate the fastest flight, boat, or zeppelin itinerary.

The chain panel's Classic locations likewise mark a possible starter or turn-in, not the objective area. Classic item references may include choice or fixed rewards without distinguishing them; the panel labels them as possibilities. All future-step details are Classic references and can differ in Forever.

## Sharing a beta build

Run `python tools/package_release.py` to create a versioned zip in `dist/`.
The zip contains one installable `ForeverWayfinder` folder, including the
GPL-3.0 license, [attribution](ATTRIBUTION.md), original book artwork and prompt,
build tools, and journal test sources. [RELEASE.md](RELEASE.md) has a Discord message and the in-game
checks to complete before calling the addon stable.

## Development checks

Run `python tools/test_journal.py` with Lua 5.1 or Fengari available; `--lua PATH`
selects an executable. The tests cover recording, duplicate events, filters,
notes, character isolation, serialized cold loads, newer-schema protection,
native-frame interactions, paging, draft preservation, and screen fitting.

`python tools/render_journal_preview.py --state quest` renders a layout preview
from the actual mocked frame geometry and needs Pillow. `note` and `empty` are
also available. It uses substitute fonts and controls; in-game rendering and
client SavedVariables persistence still need an in-game check.
