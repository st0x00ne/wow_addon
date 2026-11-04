local _, addon = ...
local expeditions = {}
addon.Expeditions = expeditions
local byKey, knownItems = {}, {}
for _, entry in ipairs(addon.ExpeditionCatalog) do
  byKey[entry.key] = entry
  for _, boss in ipairs(entry.bosses or {}) do
    for _, item in ipairs(boss.loot or {}) do knownItems[item.id] = true end
  end
end
function expeditions.Get(key) return byKey[key] end
function expeditions.Source(key) return addon.ExpeditionSources[key] end
function expeditions.Maps(entry)
  return entry and addon.ExpeditionMaps[entry.key] or {}
end
function expeditions.Map(entry, page) return expeditions.Maps(entry)[page or 1] end
function expeditions.BossForPin(entry, pin)
  if not pin then return nil end
  for index, boss in ipairs(entry and entry.bosses or {}) do
    if (pin.npcID and boss.npcID == pin.npcID) or boss.name == pin.name then return index end
  end
end
function expeditions.Settings()
  if not addon.Journal.Initialize() then return nil end
  local db = addon.Journal.Database()
  if type(db.expeditions) ~= "table" then db.expeditions = {} end
  if type(db.expeditions.wishlist) ~= "table" then db.expeditions.wishlist = {} end
  return db.expeditions
end
function expeditions.IsWished(itemID)
  local settings = expeditions.Settings()
  return settings and settings.wishlist[itemID] == true or false
end
function expeditions.ToggleWish(itemID)
  local settings = expeditions.Settings()
  if not settings or not knownItems[itemID] then return false end
  settings.wishlist[itemID] = not settings.wishlist[itemID] or nil
  return true
end
function expeditions.Query(filters)
  filters = filters or {}
  local result = {}
  for _, entry in ipairs(addon.ExpeditionCatalog) do
    local matches = (not filters.kind or filters.kind == entry.kind)
      and (not filters.origin or filters.origin == entry.origin)
    local haystack = (entry.name .. " " .. entry.zone .. " " .. entry.continent):lower()
    for word in (filters.search or ""):lower():gmatch("%S+") do
      if not haystack:find(word, 1, true) then matches = false; break end
    end
    if matches then result[#result+1] = entry end
  end
  table.sort(result, function(a,b)
    if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
    return a.name < b.name
  end)
  return result
end
function expeditions.Loot(entry, filters)
  filters = filters or {}
  local result = {}
  for index, boss in ipairs(entry and entry.bosses or {}) do
    for _, item in ipairs(boss.loot or {}) do
      if (not filters.boss or filters.boss == index)
        and (not filters.armor or filters.armor == item.armor)
        and (not filters.wishlist or expeditions.IsWished(item.id)) then
        result[#result+1] = {id=item.id, name=item.name, slot=item.slot, armor=item.armor,
          boss=boss.name, source=item.source, status=item.status}
      end
    end
  end
  return result
end
function expeditions.QuestStatus(quest)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, quest.id)
    if ok and done then return "Completed" end
  end
  if C_QuestLog and C_QuestLog.IsOnQuest then
    local ok, active = pcall(C_QuestLog.IsOnQuest, quest.id)
    if ok and active then return "In your log" end
  end
  return "Beta reference"
end
