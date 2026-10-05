# Sharing Forever Wayfinder

## Atlas release · 0.7.0-alpha

This release gives the Atlas a new illustrated frame and 38 zone
paintings. **Zones** opens a selected-zone overview with a landscape banner,
Classic progress, Forever discoveries, and a continent record. **Quests** opens
the Classic or Forever checklist, with an unfinished filter. **Class quests**
has its own chapter and score. Class quests do not inflate zone totals.
Aligned controls, stronger contrast, and a **Text** size button improve reading.
Drag an empty area to move the window; its position is saved.

Clicking **To find** on a Classic quest with a mapped starter opens its map and
sets a waypoint; **Map only** means no reliable starter coordinate is bundled.
The landscape illustrations are atmosphere, not navigation maps.
Fully exit WoW, extract the
`ForeverWayfinder` folder from the upload archive into
`World of Warcraft/_classic_beta_/Interface/AddOns/`, and replace the older
`ForeverWayfinder` folder. The result must be
`AddOns/ForeverWayfinder/ForeverWayfinder.toc`. Restart the game and type
`/fw atlas`, or open the Discovery Journal and click **Atlas** at the bottom.
This Atlas has offline test and layout coverage but still needs in-game beta
client verification.

Upload `dist/ForeverWayfinder-0.7.0-alpha.zip` as an alpha release. It contains one
installable addon folder, game textures, readable Lua data, build tools, tests,
artwork prompts, attribution, and the GPL-3.0 license. Original PNG artwork is
available in the repository and the separate `-source.zip` archive.

The notes below describe the earlier 0.5.6 beta release.

The 0.5.6 package is a **WoW Forever beta** build for client interface
`16001`. Share it as a test build until it has had a clean-install pass on
another player's computer. It is standalone and does not require Questie.

## Discord message

Version 0.5.6 adds All, Class, Special, and Zones categories to Where next?.
Special contains 15 curated reward chains, with named items, item tooltips,
finale levels, and your next available or active quest step. Class essentials
come first in All, then special rewards, other class quests, and zones.
The catalog checks prerequisites, completion, and starter-item possession.
Rewards and routes are Classic references; Forever may change them.

> **Forever Wayfinder 0.5.6 beta** — a quest companion and personal Discovery Journal for WoW Forever.
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
> This update improves readability across the journal, Chain, and Where next?:
> larger text, stronger ink, more spacing, and a saved Text size button.
> Fold personal notes to give a quest's story more room on the right page.
> Field-note Delete now opens a visible confirmation, and footer controls stay
> above long notes. The download is smaller with the same in-game artwork.
> Where next? now puts class priorities first: abilities, forms, pets, totems,
> stances, poisons, and class training before ordinary zone suggestions.
> These are Classic references; check your trainer if Forever changed a route.
> Browse the new Special category for standout reward chains, their payoff items,
> and your next quest step. Hover an item for its tooltip. Verify actual rewards
> in your live Forever quest log.
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
- Check class priorities above zones, including an older unfinished ability
  route. Click an active priority to open its log entry. Expand and fold the
  class list; confirm completed routes disappear and no hostile starter is offered.
- Switch between All, Class, Special, and Zones. In Special, hover a reward,
  use a next-step waypoint, and open an active quest. Check that a completed
  finale disappears and an item-start quest requires the item in your bags.
- Reload the UI and repeat the main interactions without Lua errors.
- Click the minimap compass to open and close the journal. Drag it around the
  minimap, then `/reload` and confirm its position is preserved.
- Write a journal note with tags, favorite it, and switch entries. Confirm the
  draft is saved. Search and combine zone, type, class, character, and status filters.
- Scroll a long quest description and a long personal note; change index pages
  with buttons and the mouse wheel. Check the book fits your UI scale.
- Try Standard, Large, and Extra Large with the Text button in each Wayfinder
  screen. Confirm titles, buttons, and long chapter names remain readable.
- Fold and unfold personal notes, change text size while editing, and confirm
  the draft and saved size survive `/reload` and a full client restart.
- Accept and turn in a quest, discover another zone, and revisit a dungeon.
  Confirm events update the correct character's records without duplicate rows.
- Confirm journal notes and favorites survive `/reload`, logout, and a full
  client restart. Use `/fw journal status` to compare entry and session counts.

The upload zip includes the addon icon and book game textures, generation prompt,
readable Lua data, build tools, journal test sources, attribution, and GPL-3.0 license.
Original PNG artwork is kept in a separate full source archive. Build the upload
with `python tools/package_release.py`; add `--source` for the archive containing
the original PNGs. Use the smaller `-beta.zip` for CurseForge and Discord.
