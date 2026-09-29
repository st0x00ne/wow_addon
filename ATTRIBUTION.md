# Source attribution

Forever Wayfinder is distributed under GPL-3.0. Its bundled Classic quest and
location reference files were generated from [QuestieDB](https://github.com/Questie/QuestieDB)
Classic quest, NPC, object, and item tables, plus QuestieDB's Forever support
XP and map data. Those subsets were transformed for Forever Wayfinder on
2026-09-27. QuestieDB is GPL-3.0 and remains credited to its contributors.

The generated files are `Data/ClassicQuests.lua`, `Data/ClassicChainDetails.lua`,
and `Data/QuestOpportunities.lua`. The included `Source/tools` scripts show how
they were made. See the README for the specific upstream files and refresh
commands. The game loads only the Lua files named in `ForeverWayfinder.toc`.

World of Warcraft and its art are trademarks and property of Blizzard
Entertainment. Forever Wayfinder is a community addon.

The compass icon and Discovery Journal book background are original generated
artwork for Forever Wayfinder. Full-size PNG sources are in `Source/art` in the
release archive; `JournalBook-prompt.md` records the book's built-in imagegen prompt.
The visual study used Classic WoW's spellbook and quest-log layouts; no third-party
addon code or screenshot artwork is embedded in the journal.

The 0.5.3 readability pass also studied the public
[Forever Journal gallery](https://www.curseforge.com/wow/addons/forever-journal)
by Uggezen for its dark parchment ink, type hierarchy, and spacing. Wayfinder's
implementation and illustrated book remain its own work.
