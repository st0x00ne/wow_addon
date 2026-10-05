-- The Atlas shows progress through the bundled reference, never a claim that
-- every quest available on Forever has been cataloged.
local _, addon = ...
local atlas = {}
addon.Atlas = atlas
local journalDone, cacheRevision, cacheCharacter = {}, nil, nil
local starterFactions, starterLocations = {}, {}
local mapContinents = {}
for _, zone in ipairs(addon.Zones) do mapContinents[zone[1]] = zone[6] end
for mapID, placements in pairs(addon.QuestOpportunities) do
  for _, quest in ipairs(placements) do
    local factions = starterFactions[quest[1]] or ""
    for faction in (quest[12] or ""):gmatch("[AH]") do
      if not factions:find(faction, 1, true) then factions = factions .. faction end
    end
    starterFactions[quest[1]] = factions
    if type(quest[7]) == "number" and type(quest[8]) == "number"
      and quest[7] > 0 and quest[7] < 100 and quest[8] > 0 and quest[8] < 100 then
      local locations = starterLocations[quest[1]] or {}
      locations[#locations + 1] = {mapID = mapID, x = quest[7], y = quest[8],
        name = quest[11], races = quest[5], classes = quest[6], factions = quest[12]}
      starterLocations[quest[1]] = locations
    end
  end
end

local function eligible(mask, bit)
  return mask == 0 or (bit and math.floor(mask / bit) % 2 == 1)
end

local function identity()
  local _, _, raceID = UnitRace("player")
  local _, _, classID = UnitClass("player")
  return raceID and 2 ^ (raceID - 1), classID and 2 ^ (classID - 1),
    UnitFactionGroup("player") == "Horde" and "H" or "A"
end

function atlas.Starter(quest, preferredMapID, classQuest)
  if not quest or not quest.id then return nil end
  local alternatives = classQuest and addon.AtlasClassQuestAlternatives
    or addon.AtlasQuestAlternatives
  local ids = alternatives[quest.group] or {quest.id}
  local raceBit, classBit, faction = identity()
  local fallback, fallbackRank
  for _, id in ipairs(ids) do
    for _, location in ipairs(starterLocations[id] or {}) do
      if eligible(location.races or 0, raceBit) and eligible(location.classes or 0, classBit)
        and type(location.factions) == "string" and location.factions:find(faction, 1, true) then
        if location.mapID == preferredMapID then return location end
        local rank = mapContinents[location.mapID] == mapContinents[preferredMapID] and 0 or 1
        if not fallback or rank < fallbackRank
          or (rank == fallbackRank and location.mapID < fallback.mapID) then
          fallback, fallbackRank = location, rank
        end
      end
    end
  end
  return fallback
end

local function completed(questID)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    local ok, value = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
    if ok and value then return true end
  end
  local db = addon.Journal.Database()
  local character = addon.Journal.CurrentCharacterKey()
  if db and (cacheRevision ~= db.revision or cacheCharacter ~= character) then
    journalDone, cacheRevision, cacheCharacter = {}, db.revision, character
    for _, entry in ipairs(db.entries or {}) do
      if entry.kind == "quest" and entry.character == character and entry.status == "completed" then
        journalDone[entry.questID] = true
      end
    end
  end
  return journalDone[questID] or false
end

local function active(questID)
  if not C_QuestLog or not C_QuestLog.IsOnQuest then return false end
  local ok, value = pcall(C_QuestLog.IsOnQuest, questID)
  return ok and value or false
end

function atlas.Zone(mapID)
  local raceBit, _, faction = identity()
  local seen, quests, done = {}, {}, 0
  for _, quest in ipairs(addon.AtlasQuestCatalog[mapID] or {}) do
    local id = quest[1]
    local group = quest[6] or id
    local allowedFaction = starterFactions[id]
    if not seen[group] and eligible(quest[5], raceBit)
      and (not allowedFaction or allowedFaction == "" or allowedFaction:find(faction, 1, true)) then
      seen[group] = true
      local isDone, isActive = false, false
      for _, alternative in ipairs(addon.AtlasQuestAlternatives[group] or {id}) do
        if completed(alternative) then isDone = true end
        if active(alternative) then isActive = true end
      end
      quests[#quests + 1] = {id = id, group = group, title = quest[2], level = quest[4],
        alternative = quest[6] ~= nil,
        status = isDone and "completed" or (isActive and "active" or "unseen")}
      if isDone then done = done + 1 end
    end
  end
  local forever, foreverSeen = {}, {}
  local knownForever, completedForever, discoveredForever = 0, 0, 0
  for _, row in ipairs(addon.ForeverQuestCatalog[mapID] or {}) do
    if not foreverSeen[row[1]] then
      foreverSeen[row[1]] = true
      local isDone = completed(row[1])
      forever[#forever + 1] = {id = row[1], title = row[2], verified = true,
        status = isDone and "completed" or (active(row[1]) and "active" or "unseen")}
      knownForever = knownForever + 1
      if isDone then completedForever = completedForever + 1 end
    end
  end
  local db = addon.Journal.Database()
  local character = addon.Journal.CurrentCharacterKey()
  for _, entry in ipairs(db and db.entries or {}) do
    if entry.kind == "quest" and entry.character == character and entry.mapID == mapID
      and not entry.classic then
      discoveredForever = discoveredForever + 1
      if not foreverSeen[entry.questID] then
        foreverSeen[entry.questID] = true
        forever[#forever + 1] = {id = entry.questID, title = entry.title,
          status = entry.status, encountered = true}
      end
    end
  end
  table.sort(forever, function(a, b) return (a.title or "") < (b.title or "") end)
  return {mapID = mapID, quests = quests, completed = done, total = #quests,
    forever = forever, foreverCount = discoveredForever, knownForever = knownForever,
    completedForever = completedForever}
end

function atlas.Continent(name)
  local result = {name = name, zones = {}, completed = 0, total = 0, foreverCount = 0}
  local seen = {}
  for _, zone in ipairs(addon.Zones) do
    if zone[6] == name then
      local snapshot = atlas.Zone(zone[1])
      snapshot.name, snapshot.newZone = zone[2], zone[8] and true or false
      result.zones[#result.zones + 1] = snapshot
      for _, quest in ipairs(snapshot.quests) do
        if not seen[quest.group] then
          seen[quest.group] = true
          result.total = result.total + 1
          if quest.status == "completed" then result.completed = result.completed + 1 end
        end
      end
      result.foreverCount = result.foreverCount + snapshot.foreverCount
    end
  end
  return result
end

function atlas.ClassQuests()
  local raceBit, classBit, faction = identity()
  local result = {quests = {}, completed = 0, total = 0, special = 0}
  local scoredGroups = {}
  for _, quest in ipairs(addon.AtlasClassQuestCatalog or {}) do
    local id, group = quest[1], quest[7] or quest[1]
    local allowedFaction = starterFactions[id]
    if eligible(quest[5], raceBit) and eligible(quest[6], classBit)
      and (not allowedFaction or allowedFaction == "" or allowedFaction:find(faction, 1, true)) then
      local isDone, isActive = false, false
      for _, alternative in ipairs(addon.AtlasClassQuestAlternatives[group] or {id}) do
        if completed(alternative) then isDone = true end
        if active(alternative) then isActive = true end
      end
      local scored = quest[8] and not scoredGroups[group]
      if scored then
        scoredGroups[group] = true
        result.total = result.total + 1
        if isDone then result.completed = result.completed + 1 end
      elseif not quest[8] then
        result.special = result.special + 1
      end
      result.quests[#result.quests + 1] = {id = id, group = group, title = quest[2], level = quest[4],
        alternative = quest[7] ~= nil, special = not quest[8], scored = scored,
        status = isDone and "completed" or (isActive and "active" or "unseen")}
    end
  end
  return result
end

function atlas.ClassPaths()
  local raceBit, classBit, faction = identity()
  local routeMask, starterSeen, starterEligible = {}, {}, {}
  for _, info in pairs(addon.ClassQuestInfo) do
    if info[2] then routeMask[info[2]] = info[1] end
  end
  for _, starter in ipairs(addon.ClassQuestStarters or {}) do
    local info = addon.ClassQuestInfo[starter[1]]
    local key = info and info[2]
    if key then
      starterSeen[key] = true
      if eligible(starter[5], raceBit) and type(starter[12]) == "string"
        and starter[12]:find(faction, 1, true) then starterEligible[key] = true end
    end
  end
  local result = {}
  for key, route in pairs(addon.ClassQuestRoutes) do
    if eligible(routeMask[key] or 0, classBit) and (not starterSeen[key] or starterEligible[key]) then
      local isDone = false
      for _, id in ipairs(route[2]) do
        if completed(id) then isDone = true break end
      end
      result[#result + 1] = {key = key, title = route[1], completed = isDone}
    end
  end
  table.sort(result, function(a, b) return a.title < b.title end)
  return result
end
