# Sharing Forever Wayfinder

The current package is a **WoW Forever beta** build for client interface
`16001`. Share it as a test build until it has had a clean-install pass on
another player's computer. It is standalone and does not require Questie.

## Discord message

> **Forever Wayfinder 0.4.3 beta** — a small quest companion for WoW Forever.
> It marks possible new Forever quests without revealing their future steps,
> labels dungeon quests, shows expandable details for known Classic chains,
> and suggests a few places to explore next. Classic locations and future
> rewards are references; Forever can change them.
>
> Download the attached zip and extract it into
> `World of Warcraft/_classic_beta_/Interface/AddOns/`. You should end up with
> `AddOns/ForeverWayfinder/ForeverWayfinder.toc`. Enable the addon at character
> select, then open the normal quest log. `/fw` opens Where next? and `/fw chain`
> opens the selected Classic chain.
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

The release zip includes the addon icon, its full-size source artwork, readable
Lua data, build scripts, attribution, and GPL-3.0 license. A release can be rebuilt with
`python tools/package_release.py` from the repository root.
