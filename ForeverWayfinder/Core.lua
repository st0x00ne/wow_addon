local _, addon = ...

function addon.IsClassicQuest(questID)
  if type(questID) ~= "number" then return false end
  local ranges = addon.ClassicQuestRanges
  local low, high = 1, #ranges
  while low <= high do
    local middle = math.floor((low + high) / 2)
    local range = ranges[middle]
    if questID < range[1] then
      high = middle - 1
    elseif questID > range[2] then
      low = middle + 1
    else
      return true
    end
  end
  return false
end

function addon.GetClassicChain(questID)
  if not addon.IsClassicQuest(questID) then return nil end
  local position = addon.ChainByQuest[questID]
  if position then return addon.ClassicChains[position[1]], position[2] end
end

function addon.IsDungeonQuest(questID)
  if not questID or not C_QuestLog or not C_QuestLog.GetQuestTagInfo then return false end
  local ok, info = pcall(C_QuestLog.GetQuestTagInfo, questID)
  local dungeonTag = Enum and Enum.QuestTag and Enum.QuestTag.Dungeon
  return ok and info and dungeonTag and info.tagID == dungeonTag or false
end

local function raceMatches(starter, raceName)
  if not starter then return true end
  if not raceName then return false end
  return string.find(string.lower(starter), string.lower(raceName), 1, true) ~= nil
end

local function hasMask(mask, value)
  return mask == 0 or (value and math.floor(mask / value) % 2 == 1)
end

local function completed(questID)
  return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    and C_QuestLog.IsQuestFlaggedCompleted(questID)
end

local function prerequisitesMet(quest)
  local oneOf = quest[9]
  if oneOf then
    local found = false
    for _, parentID in ipairs(oneOf) do
      if completed(parentID) then found = true break end
    end
    if not found then return false end
  end
  local allOf = quest[10]
  if allOf then
    for _, parentID in ipairs(allOf) do
      if not completed(parentID) then return false end
    end
  end
  return true
end

function addon.GetQuestOpportunities(mapID, limit)
  local rows = addon.QuestOpportunities[mapID] or {}
  local level = UnitLevel("player") or 1
  local faction = UnitFactionGroup("player") == "Horde" and "H" or "A"
  local _, _, raceID = UnitRace("player")
  local _, _, classID = UnitClass("player")
  local raceBit = raceID and 2 ^ (raceID - 1)
  local classBit = classID and 2 ^ (classID - 1)
  local choices = {}
  for _, quest in ipairs(rows) do
    local questID = quest[1]
    if quest[3] <= level and quest[4] >= level - 7 and quest[4] <= level + 5
      and hasMask(quest[5], raceBit) and hasMask(quest[6], classBit)
      and string.find(quest[12], faction, 1, true)
      and not completed(questID)
      and not (C_QuestLog and C_QuestLog.GetLogIndexForQuestID
        and C_QuestLog.GetLogIndexForQuestID(questID))
      and prerequisitesMet(quest) then
      choices[#choices + 1] = quest
    end
  end
  table.sort(choices, function(a, b)
    local aScore = math.abs(a[4] - level) + (a[9] and 1 or 0)
    local bScore = math.abs(b[4] - level) + (b[9] and 1 or 0)
    if aScore == bScore then return a[1] < b[1] end
    return aScore < bScore
  end)
  local count = #choices
  if limit then
    for i = count, limit + 1, -1 do choices[i] = nil end
  end
  return choices, count
end

function addon.GetZoneSuggestions()
  local level = UnitLevel("player") or 1
  local faction = UnitFactionGroup("player") == "Horde" and "H" or "A"
  local raceName = UnitRace("player")
  local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local currentZone
  local mapToCheck = currentMap
  local seenMaps = {}
  while mapToCheck and not seenMaps[mapToCheck] do
    seenMaps[mapToCheck] = true
    for _, zone in ipairs(addon.Zones) do
      if zone[1] == mapToCheck then currentZone = zone break end
    end
    if currentZone or not C_Map.GetMapInfo then break end
    local mapInfo = C_Map.GetMapInfo(mapToCheck)
    mapToCheck = mapInfo and mapInfo.parentMapID or nil
  end
  if currentZone then currentMap = currentZone[1] end
  local candidates = {}
  for _, zone in ipairs(addon.Zones) do
    if (zone[5] == faction or zone[5] == "B") and (not zone[7] or raceMatches(zone[7], raceName)) then
      local distance = 0
      if level < zone[3] then distance = zone[3] - level end
      if level > zone[4] then distance = level - zone[4] end
      if distance <= 5 or zone[1] == currentMap then
        local quests, count = addon.GetQuestOpportunities(zone[1], 3)
        local score = distance * 25 + math.abs(level - (zone[3] + zone[4]) / 2)
        if zone[1] == currentMap then score = score - 100 end
        if currentZone and zone[6] == currentZone[6] then score = score - 24 end
        if zone[7] and raceMatches(zone[7], raceName) then score = score - 20 end
        if currentZone and zone[6] ~= currentZone[6] then score = score + 20 end
        if zone[8] then score = score - 8 end
        score = score - math.min(count, 4) * 8
        candidates[#candidates + 1] = {zone = zone, quests = quests, count = count, score = score}
      end
    end
  end
  table.sort(candidates, function(a, b)
    if a.score == b.score then return a.zone[1] < b.zone[1] end
    return a.score < b.score
  end)
  local results = {}
  local selected = {}
  local function add(candidate)
    if candidate and not selected[candidate.zone[1]] and #results < 3 then
      results[#results + 1] = candidate
      selected[candidate.zone[1]] = true
    end
  end
  for _, candidate in ipairs(candidates) do
    if candidate.zone[1] == currentMap then add(candidate) break end
  end
  if currentZone then
    for _, candidate in ipairs(candidates) do
      if candidate.zone[6] == currentZone[6] and candidate.zone[1] ~= currentMap then
        add(candidate)
        break
      end
    end
  end
  for _, candidate in ipairs(candidates) do
    add(candidate)
  end
  return results, currentMap, currentZone
end
