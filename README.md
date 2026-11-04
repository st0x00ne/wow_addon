# Forever Wayfinder

**An illustrated atlas, personal journal, and quest guide for World of Warcraft: Forever.**

Find unfinished quests, track your progress, and keep a record of your adventures.

**Launch candidate: 0.8.0-rc.1** for WoW Forever `1.60.1` (interface `16001`).
The installed live client was checked at build `1.60.1.70790` on November 4, 2026.
Offline checks pass; a live-world smoke test is still pending.

## Features

- **Expeditions:** Browse 29 dungeon destinations and the three announced first-tier raids. Original Atlas floor plans cover 25 destinations with 34 map sheets, selectable reference markers, wing/page controls, and an enlarged view. Hall of Thanes also has twelve loot entries, an account wishlist, and five quests. Maps and encounters are beta references awaiting live verification; the optional route sketch shows encounter order.
- **Illustrated Atlas:** Browse painted zone overviews across Kalimdor and the Eastern Kingdoms. Track Classic quest completion by zone and continent, filter unfinished quests, and click **To find** for a mapped starter waypoint. Class quests have their own chapter; Forever discoveries grow as you encounter them.
- **Your Discovery Journal:** Record quests, explored zones, dungeon visits, and milestones. Add personal notes, favorite discoveries, and mark places to revisit. Search your history and filter by character, zone, class, and more.
- **Where next?:** Find important class abilities and training, standout reward chains, and Classic quest starts suited to your character. Browse **All**, **Class**, **Special**, or **Zones**, with reward item tooltips and your next available quest step.
- **Classic quest chains:** Follow supported chains with objectives, quest givers, requirements, reference rewards, and clickable map locations.

Move the Atlas by dragging an empty area; its position is saved. Choose **Standard**, **Large**, or **Extra Large** text. Works standalone—Questie is not required.

## Commands

| Command | What it does |
| --- | --- |
| `/fw atlas` | Open or close the Atlas. |
| `/fw expeditions` | Open or close the dungeon and raid reference. |
| `/fw journal` | Open or close your Discovery Journal. |
| `/fw` or `/fw where` | Open Where next? for quest suggestions. |
| `/fw chain` | Show the supported Classic chain for the quest selected in your log. |
| `/fw text` | Cycle through the three text sizes. |
| `/fw text standard`, `/fw text large`, `/fw text extra` | Set your preferred text size. |

## Getting started

Extract the upload zip into `World of Warcraft/_forever_/Interface/AddOns/`.
The result must be `AddOns/ForeverWayfinder/ForeverWayfinder.toc`.
Fully exit and reopen the game after installing, then enable Forever Wayfinder
on the character selection AddOns screen. Questie and Atlas are not required.

Click the **minimap compass** or the **Journal** button in your quest log.
Open **Atlas** from the journal, or use `/fw atlas` directly.
Use `/fw expeditions` for dungeon and raid maps.

## Notes

Classic completion can include older quests when the client reports their completed flags. Dated journal history starts at installation and is saved locally across your account.
The live game saves journal data in `_forever_/WTF`; the beta used a separate
`_classic_beta_/WTF` directory. Installing the addon does not move beta journals.

Classic data is a growing reference; Forever may change quest locations, requirements, and rewards. **Map only** means no reliable starter coordinate is bundled. Setting a waypoint replaces your current marker. `∞` marks a possible Forever quest; `D` marks a dungeon quest.

Developers can review Expeditions without WoW: run `python tools/preview_expeditions.py --open`
to render and open `dist/expeditions-preview/index.html`. The gallery contains nine captured
states at Standard, Large, and Extra Large text sizes. See DEVELOPMENT.md for
dependencies and the limits of the mocked renderer.
