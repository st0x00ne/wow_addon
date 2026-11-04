-- Curated reference, checked 2026-10-26. No entry is launch-verified.
-- Keep evidence for geography, encounters and drops separate. A known item ID
-- does not verify its drop source. Diagram positions are never world coordinates.
local _, addon = ...
addon.ExpeditionSources = {
  atlas = {label="Atlas Team · map reference", checked="2026-10-27",
    url="https://github.com/arithmandar/Atlas-Kalimdor-and-Eastern-Kingdoms/tree/d4b16efa424e9116fc895543a6a5faa3f746cf1a"},
  overview = {label="Forever beta overview", checked="2026-10-26",
    url="https://www.wowhead.com/forever/guide/dungeons-overview-locations-details"},
  dungeons = {label="Blizzard dungeon announcement", checked="2026-10-26",
    url="https://news.blizzard.com/en-us/article/24303862/world-of-warcraft-forever-whats-next-panel-recap"},
  hall = {label="Wowhead beta guide, 29 Sep", checked="2026-10-26",
    url="https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards"},
  raids = {label="Blizzard raid announcement", checked="2026-10-26",
    url="https://news.blizzard.com/en-gb/article/24303009/world-of-warcraft-forever-raid-overviewlocations-raid-sizes-and-attunement"},
}
local catalog = {}
addon.ExpeditionCatalog = catalog
local function dungeon(key, name, low, high, zone, continent, mapID, origin, wings)
  local entry = {key=key, name=name, kind="dungeon", minLevel=low, maxLevel=high,
    zone=zone, continent=continent, zoneMapID=mapID, origin=origin or "classic",
    status="reference", source="overview", wings=wings}
  catalog[#catalog+1] = entry
  return entry
end
local hall = dungeon("hall-of-thanes", "Hall of Thanes", 13, 18, "Ironforge", "Eastern Kingdoms", 1455, "forever")
dungeon("ragefire-chasm", "Ragefire Chasm", 13, 18, "Orgrimmar", "Kalimdor", 1454)
dungeon("ruins-of-lordaeron", "Ruins of Lordaeron", 15, 20, "Tirisfal Glades", "Eastern Kingdoms", 1420, "forever")
dungeon("wailing-caverns", "Wailing Caverns", 15, 25, "The Barrens", "Kalimdor", 1413)
dungeon("deadmines", "The Deadmines", 18, 23, "Westfall", "Eastern Kingdoms", 1436)
dungeon("shadowfang-keep", "Shadowfang Keep", 22, 30, "Silverpine Forest", "Eastern Kingdoms", 1421)
dungeon("stockade", "The Stockade", 22, 30, "Stormwind", "Eastern Kingdoms", 1453)
dungeon("blackfathom-deeps", "Blackfathom Deeps", 24, 32, "Ashenvale", "Kalimdor", 1440)
dungeon("excavation-site", "Excavation Site: Wetlands", 24, 29, "Wetlands", "Eastern Kingdoms", 1437, "forever")
dungeon("city-of-dalaran", "City of Dalaran", 28, 33, "Alterac Mountains", "Eastern Kingdoms", 1416, "forever")
dungeon("gnomeregan", "Gnomeregan", 29, 38, "Dun Morogh", "Eastern Kingdoms", 1426)
dungeon("razorfen-kraul", "Razorfen Kraul", 30, 40, "The Barrens", "Kalimdor", 1413)
dungeon("scarlet-monastery", "Scarlet Monastery", 28, 45, "Tirisfal Glades", "Eastern Kingdoms", 1420, nil,
  {"Graveyard", "Library", "Armory", "Cathedral"})
dungeon("drowned-city", "The Drowned City", 35, 40, "Stranglethorn Vale", "Eastern Kingdoms", 1434, "forever")
dungeon("razorfen-downs", "Razorfen Downs", 40, 50, "The Barrens", "Kalimdor", 1413)
dungeon("kroldok-stronghold", "Krol'dok Stronghold", 40, 45, "Riverglades", "Eastern Kingdoms", 2548, "forever")
dungeon("uldaman", "Uldaman", 42, 52, "Badlands", "Eastern Kingdoms", 1418)
dungeon("zul-farrak", "Zul'Farrak", 44, 54, "Tanaris", "Kalimdor", 1446)
dungeon("maraudon", "Maraudon", 45, 57, "Desolace", "Kalimdor", 1443, nil,
  {"Wicked Grotto", "Foulspore Cavern", "Earth Song Falls"})
dungeon("alcaz-prison", "Alcaz Prison", 48, 53, "Dustwallow Marsh", "Kalimdor", 1445, "forever")
dungeon("sunken-temple", "The Sunken Temple", 50, 60, "Swamp of Sorrows", "Eastern Kingdoms", 1435)
dungeon("blackrock-depths", "Blackrock Depths", 52, 60, "Blackrock Mountain", "Eastern Kingdoms", 1428)
dungeon("blackmaw-hold", "Blackmaw Hold", 55, 60, "Azshara", "Kalimdor", 1447, "forever")
dungeon("lower-blackrock-spire", "Lower Blackrock Spire", 55, 60, "Blackrock Mountain", "Eastern Kingdoms", 1428)
dungeon("upper-blackrock-spire", "Upper Blackrock Spire", 58, 60, "Blackrock Mountain", "Eastern Kingdoms", 1428)
dungeon("dire-maul", "Dire Maul", 58, 60, "Feralas", "Kalimdor", 1444, nil, {"East", "West", "North"})
dungeon("scholomance", "Scholomance", 58, 60, "Western Plaguelands", "Eastern Kingdoms", 1422)
dungeon("stratholme", "Stratholme", 58, 60, "Eastern Plaguelands", "Eastern Kingdoms", 1423)
dungeon("shapers-terrace", "Shaper's Terrace", 58, 60, "Un'Goro Crater", "Kalimdor", 1449, "forever")
for _, raid in ipairs({
  {"barrow-deeps", "Barrow Deeps", 10, "Mount Hyjal / Winterspring / Blackmaw Hold", "forever", 8},
  {"hyjal-summit", "Hyjal Summit", 20, "Mount Hyjal", "forever", 13},
  {"onyxias-lair", "Onyxia's Lair", 40, "Dustwallow Marsh", "classic", 1, 1445},
}) do
  catalog[#catalog+1] = {key=raid[1], name=raid[2], kind="raid", minLevel=60, maxLevel=60,
    players=raid[3], zone=raid[4], origin=raid[5], bossCount=raid[6], zoneMapID=raid[7],
    continent="Kalimdor", status="announced", source="raids", opens="9 Dec 2026",
    summary=raid[1]=="onyxias-lair" and "Carry the Drakefire Amulet. The attunement differs by faction."
      or "Announced for the first raid tier. Encounter maps and drop tables await verification."}
end

hall.status, hall.source, hall.players = "beta", "hall", 5
hall.summary = "The royal tombs beneath Ironforge, now disturbed by Dark Iron dwarves."
hall.entrance = "In the High Seat, take the left passage into Old Ironforge and descend to the portal."
hall.map = {kind="schematic", status="unverified",
  caption="Encounter sequence only. Floor plan and boss positions are not surveyed."}
hall.routes = {
  {key="bosses", name="Boss circuit", note="Follow the four encounters in guide order. No shortcut or fastest-path claim.", bosses={1,2,3,4}},
  {key="quests", name="Quest circuit", note="Check the attendant near the first boss; gather heirlooms and inspect the final vaults.", bosses={1,2,3,4}, stops={[1]=true,[4]=true}},
}
hall.bosses = {
  {name="Faldrim Anvilmar", npcID=261306, family="Undead", area="Anvilmar's Rest", source="hall", status="beta",
    note="Wait for the patrol and clear nearby enemies. Prepare to remove a curse.", loot={
      {id=271097,name="Spiritwraith Drape",slot="Back",armor="Cloth"},
      {id=270227,name="Ephemeral Choker",slot="Neck",armor="Miscellaneous"},
      {id=271096,name="Aetherwisp Bracers",slot="Wrist",armor="Cloth"}}},
  {name="Magmatus", npcID=261316, family="Elemental", area="With a Dark Iron Summoner", source="hall", status="beta",
    note="Defeat the summoner first. Keep the elemental apart from the group.", loot={
      {id=270230,name="Kindlegem Girdle",slot="Waist",armor="Mail"},
      {id=270231,name="Flamefist Grips",slot="Hands",armor="Leather"},
      {id=271095,name="Fang of Magmatus",slot="Main hand",armor="Dagger"}}},
  {name="Plunder", npcID=261311, family="Elemental", area="Patrols a hallway", source="hall", status="beta",
    note="Choose a cleared corner so knockbacks cannot carry you into enemies.", loot={
      {id=270228,name="Golemheart Stave",slot="Two-hand",armor="Staff"},
      {id=271098,name="Golemguard Chest",slot="Chest",armor="Mail"},
      {id=270229,name="Treads of the Protector Golem",slot="Feet",armor="Mail"}}},
  {name="Durgen Dirgehammer", npcID=261319, family="Humanoid", area="Reliquary of Kings", source="hall", status="beta",
    note="Clear the room edges before the fear. Focus the accompanying golems one at a time.", loot={
      {id=270256,name="Durgen's Crescent Axe",slot="Main hand",armor="Axe"},
      {id=270260,name="Direhammer Leggings",slot="Legs",armor="Leather"},
      {id=270261,name="Robes of the Disgraced Thane",slot="Chest",armor="Cloth"}}},
}
hall.quests = {
  {id=96403,name="Important Heirlooms",faction="Both",note="Thom Filch in Old Ironforge; collect heirlooms."},
  {id=96394,name="The Restless Dead",faction="Alliance",note="Afadra Dunwall in Old Ironforge; defeat apparitions and souls."},
  {id=96393,name="Old Ironforge Incursion",faction="Alliance",note="Earthseer Farsen in Dun Morogh; requires the Underground Map chain."},
  {id=96395,name="An Ancient Grudge",faction="Both",note="Ghostly Attendant near Faldrim; defeat the first boss."},
  {id=98423,name="The Treaty of Understanding",faction="Alliance",note="Inspect a tablet in the final room's vaults."},
}
for _, boss in ipairs(hall.bosses) do
  for _, item in ipairs(boss.loot) do item.source, item.status = "hall", "beta" end
end
for _, quest in ipairs(hall.quests) do quest.source, quest.status = "hall", "beta" end
