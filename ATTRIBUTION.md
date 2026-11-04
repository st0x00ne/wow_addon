# Source attribution

Forever Wayfinder is distributed under GPL-3.0. Its bundled Classic quest and
location reference files were generated from [QuestieDB](https://github.com/Questie/QuestieDB)
Classic quest, NPC, object, and item tables, plus QuestieDB's Forever support
XP and map data. Those subsets were transformed for Forever Wayfinder on
2026-09-27. QuestieDB is GPL-3.0 and remains credited to its contributors.

The generated files are `Data/ClassicQuests.lua`, `Data/ClassicChainDetails.lua`,
`Data/QuestOpportunities.lua`, `Data/ClassQuestPriorities.lua`,
`Data/SpecialQuests.lua`, and `Data/AtlasQuestCatalog.lua`. The included `Source/tools` scripts show how
they were made. See DEVELOPMENT.md for the specific upstream files and refresh
commands. The game loads only the Lua files named in `ForeverWayfinder.toc`.

The class priority subset was generated on 2026-09-28. Its curated ability
labels and player spell guards were checked against the
[CMaNGOS Classic quest database](https://github.com/cmangos/classic-db)
and [TellMeWhen's ability references](https://github.com/ascott18/TellMeWhen).
No code from those projects is embedded in the addon. Classic references are
not a claim about verified Forever unlock requirements.

The Special quests catalog was generated on 2026-09-28 from the QuestieDB
Classic quest, item reward, and starter tables. Its selection is curated;
the named reward references are not guaranteed live Forever offers.

World of Warcraft and its art are trademarks and property of Blizzard
Entertainment. Forever Wayfinder is a community addon.

The Expeditions development catalog was checked on 2026-10-26 against Blizzard's
[dungeon announcement](https://news.blizzard.com/en-us/article/24303862/world-of-warcraft-forever-whats-next-panel-recap),
[raid overview](https://news.blizzard.com/en-gb/article/24303009/world-of-warcraft-forever-raid-overviewlocations-raid-sizes-and-attunement),
and Wowhead's [Forever dungeon overview](https://www.wowhead.com/forever/guide/dungeons-overview-locations-details).
Hall of Thanes encounter, item-source, and quest facts reference
[Jurdi's beta guide](https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards)
(updated 2026-09-29); the item's or quest's linked database record supplies its ID.
Descriptions are brief original summaries. The original encounter diagram uses
native frames and the existing Wayfinder frame artwork. Guide screenshots and
Santiago Reyes's fan maps are not embedded.

The 34 original dungeon/raid map sheets and derived label positions were imported
on 2026-10-27 from [Atlas Kalimdor & Eastern Kingdoms](https://github.com/arithmandar/Atlas-Kalimdor-and-Eastern-Kingdoms),
revision `d4b16efa424e9116fc895543a6a5faa3f746cf1a`. Atlas credits Dan Gilbert,
Lothaer, Arith Hsu, and the Atlas Team. The selected textures are unmodified BLP
files in `Media/Maps`; their embedded artist credits remain intact. The original
Forever data source, readme, GPL-2.0 text, and per-file hash manifest accompany
them. Atlas's data source grants GPL-2.0-or-later; the generated subset in
`Data/ExpeditionMaps.lua` is distributed under this project's GPL-3.0. The map
inputs and original notices retain their stated upstream terms. The upstream
readme also requests credit and notification when including its files in a
product; that request is preserved with the imported files. No notification has
been sent by this tooling. `tools/import_expedition_maps.py` verifies all selected
inputs against pinned Git blob hashes and generates the standalone reference.

The compass icon and Discovery Journal book background are original generated
artwork for Forever Wayfinder. Full-size PNG sources are retained in the repository's
`art` folder and included in the separate full source archive's `art` folder.
The install zip includes the game textures; `JournalBook-prompt.md` records the book's built-in imagegen prompt.

The Atlas frame is original generated artwork for Forever Wayfinder. Its PNG source
is `art/AtlasFrame-source.png`, its game texture is `Media/AtlasFrame.tga`, and
`art/AtlasFrame-prompt.md` records the prompt. The Atlas quest catalog was generated
on 2026-10-04 from QuestieDB's Classic quest table and Forever area-to-map table
using `tools/build_atlas_catalog.py`.
The visual study used Classic WoW's spellbook and quest-log layouts; no third-party
addon code or screenshot artwork is embedded in the journal.

The 0.7.0 Atlas frame and zone paintings are original artwork generated on
2026-10-04 with the built-in image_gen tool. Sources are
`art/AtlasFrameV2-source.png`, `art/AtlasKalimdor-source.png`, and
`art/AtlasEastern-source.png`; `art/AtlasArt-prompts.json` records the full prompts.
`tools/build_atlas_art.py` exports `Media/AtlasFrameV2.tga` and 38 textures in
`Media/Zones`. The landscape scenes are decorative illustrations, not surveyed
maps or coordinate references.

The 0.5.3 readability pass also studied the public
[Forever Journal gallery](https://www.curseforge.com/wow/addons/forever-journal)
by Uggezen for its dark parchment ink, type hierarchy, and spacing. Wayfinder's
implementation and illustrated book remain its own work.
