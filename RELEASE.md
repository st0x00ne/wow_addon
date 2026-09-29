# Sharing Forever Wayfinder

The current package is a **WoW Forever beta** build for client interface
`16001`. Share it as a test build until it has had a clean-install pass on
another player's computer. It is standalone and does not require Questie.

## Discord message

> **Forever Wayfinder 0.5.2 beta** — a quest companion and personal Discovery Journal for WoW Forever.
> It marks possible new Forever quests without revealing their future steps,
> labels dungeon quests, shows expandable details for known Classic chains,
> and suggests a few places to explore next. Classic locations and future
> rewards are references; Forever can change them.
> Open your own illustrated field journal: zone chapters, searchable discoveries,
> class and character filters, favorites, revisit markers, and personal notes.
> It grows from quests, places, dungeon visits, and milestones you encounter.
> Search and categories now sit above the book, leaving a clear chapter index
> on the left and discovery details and notes on the right.
> Click the compass on your minimap to open the journal. Drag it around the
> minimap's edge to choose a saved position.
>
> Download the attached zip and extract it into
> `World of Warcraft/_classic_beta_/Interface/AddOns/`. You should end up with
> `AddOns/ForeverWayfinder/ForeverWayfinder.toc`. Enable the addon at character
> select, then open the normal quest log. `/fw` opens Where next? and `/fw chain`
> opens the selected Classic chain. Click **Journal** or use `/fw journal` for
> your discoveries. Fully exit and reopen WoW after installing this update.
>
> If something looks wrong, please share the quest name or ID, your client
> version, a screenshot, and the full Lua error text if one appears.

## Before calling it stable

- Install the zip on a second client with no previous ForeverWayfinder folder.
- Open the quest list and a quest detail, then return to the list. Confirm the
  Where next? button appears only on the list.
- Expand and collapse several Classic chain steps, scroll to the bottom, and
  confirm there are no leftover lines or click targets.
- Check a known Classic quest, a candidate Forever quest, and a dungeon quest
  in both the log and objective tracker.
- Use a Where next? starter waypoint and a Classic chain start/turn-in link.
- Reload the UI and repeat the main interactions without Lua errors.
- Click the minimap compass to open and close the journal. Drag it around the
  minimap, then `/reload` and confirm its position is preserved.
- Write a journal note with tags, favorite it, and switch entries. Confirm the
  draft is saved. Search and combine zone, type, class, character, and status filters.
- Scroll a long quest description and a long personal note; change index pages
  with buttons and the mouse wheel. Check the book fits your UI scale.
- Accept and turn in a quest, discover another zone, and revisit a dungeon.
  Confirm events update the correct character's records without duplicate rows.
- Confirm journal notes and favorites survive `/reload`, logout, and a full
  client restart. Use `/fw journal status` to compare entry and session counts.

The release zip includes the addon icon, original book artwork and generation prompt,
readable Lua data, build tools, journal test sources, attribution, and GPL-3.0 license. A release can be rebuilt with
`python tools/package_release.py` from the repository root.
