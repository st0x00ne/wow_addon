# Source attribution

Forever Wayfinder is distributed under GPL-3.0. Its bundled Classic quest and
location reference files were generated from [QuestieDB](https://github.com/Questie/QuestieDB)
Classic quest, NPC, object, and item tables, plus QuestieDB's Forever support
XP and map data. Those subsets were transformed for Forever Wayfinder on
2026-09-27. QuestieDB is GPL-3.0 and remains credited to its contributors.

The generated files are `Data/ClassicQuests.lua`, `Data/ClassicChainDetails.lua`,
`Data/QuestOpportunities.lua`, `Data/ClassQuestPriorities.lua`, and
`Data/SpecialQuests.lua`. The included `Source/tools` scripts show how
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

The compass icon and Discovery Journal book background are original generated
artwork for Forever Wayfinder. Full-size PNG sources are retained in the repository's
`art` folder and included in the separate full source archive's `art` folder.
The install zip includes the game textures; `JournalBook-prompt.md` records the book's built-in imagegen prompt.
The visual study used Classic WoW's spellbook and quest-log layouts; no third-party
addon code or screenshot artwork is embedded in the journal.

The 0.5.3 readability pass also studied the public
[Forever Journal gallery](https://www.curseforge.com/wow/addons/forever-journal)
by Uggezen for its dark parchment ink, type hierarchy, and spacing. Wayfinder's
implementation and illustrated book remain its own work.
