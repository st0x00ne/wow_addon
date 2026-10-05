local root = assert(arg[1], "workspace path required")
local mock = assert(loadfile(root .. "/tests/wow_mock.lua"))()
if arg[2] == "preview" and arg[5] then mock.fontMetrics = assert(loadfile(arg[5]))() end
mock.player = {name = "Kora", realm = "Forever", guid = "Player-1-Kora", class = "WARRIOR",
  className = "Warrior", race = "Orc", faction = "Horde", level = 20}
mock.mapID, mock.zone, mock.subzone = 1411, "Durotar", "Razor Hill"
mock.mapNames = {[1411] = "Durotar", [2521] = "Zephras Isle"}
mock.completed[788] = true
local addon = mock.load(root, true)
local atlas = addon.Atlas
local durotar = atlas.Zone(1411)
assert(durotar.total > 0 and durotar.completed > 0, "Classic zone progress missing")
local found788, foundClass
for _, quest in ipairs(durotar.quests) do
  if quest.id == 788 then found788 = quest.status == "completed" end
  if quest.id == 2383 then foundClass = true end
  assert(quest.id ~= 7664 and quest.id ~= 8828, "repeatable or seasonal quest entered the zone score")
end
assert(found788, "completed quest flag was ignored")
assert(not foundClass, "class quest inflated zone total")
local knownStarter, crossZoneStarter, unknownStarter
for _, quest in ipairs(durotar.quests) do
  if quest.id == 789 then knownStarter = atlas.Starter(quest, 1411) end
  if quest.id == 842 then crossZoneStarter = atlas.Starter(quest, 1411) end
  if quest.id == 787 then unknownStarter = atlas.Starter(quest, 1411) end
end
assert(knownStarter and knownStarter.mapID == 1411 and knownStarter.x == 42.06,
  "mapped Classic starter was not found")
assert(crossZoneStarter and crossZoneStarter.mapID == 1413 and crossZoneStarter.x == 62.26,
  "cross-zone Classic starter was not found")
assert(not unknownStarter, "unmapped quest received an invented starter")
assert(atlas.Zone(2521).total == 0, "Forever zone gained invented Classic starts")
local continent = atlas.Continent("Kalimdor")
local unique = {}
for _, zone in ipairs(continent.zones) do
  for _, quest in ipairs(zone.quests) do unique[quest.group] = true end
end
local count = 0
for _ in pairs(unique) do count = count + 1 end
assert(continent.total == count, "continent count double-counted a cross-zone starter")
local alternativeChecked
for _, zone in ipairs(continent.zones) do
  for _, quest in ipairs(zone.quests) do
    local choices = addon.AtlasQuestAlternatives[quest.group]
    if choices and #choices > 1 then
      mock.completed[choices[#choices]] = true
      local updated = atlas.Zone(zone.mapID)
      for _, row in ipairs(updated.quests) do
        if row.group == quest.group then
          assert(row.status == "completed", "alternate quest completion did not satisfy its path")
          alternativeChecked = true
        end
      end
      break
    end
  end
  if alternativeChecked then break end
end
assert(alternativeChecked, "alternative quest group was not exercised")
local paths = atlas.ClassPaths()
local defensive
for _, path in ipairs(paths) do if path.key == "defensive" then defensive = path end end
assert(defensive, "warrior class path missing")
local classCatalog = atlas.ClassQuests()
assert(classCatalog.total > 0 and #classCatalog.quests >= classCatalog.total,
  "full class quest list missing")
local classStarter
for _, quest in ipairs(classCatalog.quests) do
  if quest.id == 2383 then classStarter = atlas.Starter(quest, 1411, true) break end
end
assert(classStarter and classStarter.mapID == 1411, "class quest starter was not found")

mock.quests = {{questID = 100001, title = "The New Trail", level = 12}}
mock.mapID, mock.zone = 2521, "Zephras Isle"
mock.fire("ZONE_CHANGED_NEW_AREA")
mock.fire("QUEST_ACCEPTED", 1, 100001)
local zephras = atlas.Zone(2521)
assert(zephras.foreverCount == 1 and zephras.forever[1].title == "The New Trail",
  "encountered Forever quest did not appear in the zone")
addon.ForeverQuestCatalog[2521] = {{100002, "A Confirmed Path"}}
mock.completed[100002] = true
zephras = atlas.Zone(2521)
assert(zephras.knownForever == 1 and zephras.completedForever == 1 and #zephras.forever == 2,
  "verified Forever quests did not merge with encountered discoveries")

SlashCmdList.FOREVERWAYFINDER("atlas")
local panel = assert(ForeverWayfinderAtlasFrame)
assert(panel:IsShown() and panel.art.texture:find("AtlasFrame", 1, true), "Atlas art did not load")
local durotarRow
for _, row in ipairs(panel.zoneRows) do
  if row.mapID == 1411 then durotarRow = row break end
end
assert(durotarRow, "Durotar missing from zone index")
mock.click(durotarRow)
assert(panel.overview:IsShown() and not panel.list:IsShown() and panel.tabs.zones.selected,
  "Atlas did not open with the zone overview")
assert(panel.hero.texture:find("Zones\\1411", 1, true) and durotarRow.icon.texture:find("Zones\\1411", 1, true),
  "selected zone artwork did not update")
assert(panel.progressLabel:GetText():find("CLASSIC", 1, true), "reference scope not stated")
assert(panel.caveat:GetText():find("class and event quests separate", 1, true), "class exclusion not clear")
mock.click(panel.classicBrowse)
assert(panel.list:IsShown() and not panel.overview:IsShown() and panel.tabs.quests.selected,
  "overview did not open the quest checklist")
mock.click(panel.unfinished)
for _, row in ipairs(panel.rows) do
  assert(not row.data or row.data.status ~= "completed", "unfinished filter retained a completed quest")
end
mock.click(panel.unfinished)
local toFind, mapOnly
for _, row in ipairs(panel.rows) do
  if row.data and row.data.id == 789 then toFind = row end
  if row.data and row.data.id == 787 then mapOnly = row end
end
assert(toFind and toFind.status:GetText() == "To find" and toFind.starter,
  "quest with a known starter was not marked To find")
assert(mapOnly and mapOnly.status:GetText() == "Map only" and not mapOnly.starter,
  "quest without starter data promised a marker")
mock.click(toFind)
assert(mock.openMap == 1411 and mock.waypoint and mock.waypoint.map == 1411
  and math.abs(mock.waypoint.x - .4206) < .0001 and mock.tracked and not panel:IsShown(),
  "To find quest did not open a starter waypoint")
local waypoint = mock.waypoint
panel:Show(); mock.click(mapOnly)
assert(mock.waypoint == waypoint and mock.openMap == 1411,
  "map-only quest replaced the previous waypoint")
panel:Show()
local crossZoneRow
while not crossZoneRow do
  for _, row in ipairs(panel.rows) do
    if row.data and row.data.id == 842 then crossZoneRow = row break end
  end
  if crossZoneRow or not panel.rowNext.enabled then break end
  mock.click(panel.rowNext)
end
assert(crossZoneRow and crossZoneRow.starter.mapID == 1413,
  "cross-zone quest did not use the starter's map")
mock.click(crossZoneRow)
assert(mock.openMap == 1413 and mock.waypoint.map == 1413,
  "cross-zone starter waypoint opened the catalog zone")
panel:Show()
assert(panel.movable and panel.dragButtons[1] == "LeftButton", "Atlas is not draggable")
panel.scripts.OnDragStart(panel)
assert(panel.moving, "Atlas did not start moving")
panel:ClearAllPoints()
panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -50)
panel.scripts.OnDragStop(panel)
local saved = addon.Journal.Database().atlasPosition
assert(not panel.moving and saved.point == "TOPLEFT" and saved.x == 40 and saved.y == -50,
  "Atlas did not save its dragged position")
assert(panel.zonePrev.points.TOPLEFT.y == panel.rowPrev.points.TOPLEFT.y
  and panel.rowPrev.points.TOPLEFT.y == panel.journal.points.TOPLEFT.y,
  "bottom controls are misaligned")
mock.click(panel.tabs.class)
assert(panel.title:GetText() == "Your class quests" and panel.rows[1].data,
  "class quest tab did not render")
mock.click(panel.tabs.quests)
mock.click(panel.catalogTabs.forever)
assert(panel.empty:IsShown(), "empty Forever chapter did not explain itself")
mock.click(panel.map)
assert(mock.openMap == 1411, "map action failed")
panel:Show()
mock.click(panel.journal)
assert(not panel:IsShown() and ForeverWayfinderJournalFrame:IsShown(), "journal navigation failed")
local journalAtlas
for _, object in ipairs(mock.objects) do
  if object.kind == "Button" and object.text == "Atlas" then journalAtlas = object break end
end
mock.click(assert(journalAtlas))
assert(panel:IsShown(), "journal Atlas button failed")
UIParent:SetSize(900, 600)
panel:Hide(); panel:Show()
assert(panel:GetWidth() * panel:GetScale() <= UIParent:GetWidth() - 20
  and panel:GetHeight() * panel:GetScale() <= UIParent:GetHeight() - 20,
  "Atlas did not fit a smaller screen")
UIParent:SetSize(1600, 900)
panel:Hide(); panel:Show()
mock.click(panel.reading)
assert(addon.ReadingStyle.Name() == "Large" and panel.reading.label:GetText() == "Text: Large",
  "Atlas reading control did not save the larger preset")
mock.click(panel.reading)
assert(panel.rows[1].name.fontSize == 17, "Atlas extra large type did not update")

if arg[2] == "preview" then
  addon.ReadingStyle.SetPreset(arg[4] or "standard")
  mock.click(panel.tabs[arg[3] == "atlas-class" and "class" or arg[3] == "atlas-quests" and "quests" or "zones"])
  if arg[3] == "atlas-quests" then mock.click(panel.catalogTabs.classic) end
  assert(loadfile(root .. "/tests/journal_preview_export.lua"))(mock, panel)
else
  print("PASS: Atlas overview, checklist navigation, reading sizes, unfinished filter, starter waypoints, class separation, completion and artwork")
end
