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

local function active(questID)
  if not C_QuestLog then return false end
  return (C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questID))
    or (C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)) or false
end

local function anyQuest(ids, predicate)
  if type(ids) == "number" then return predicate(ids) end
  for _, id in ipairs(ids or {}) do
    if predicate(id) then return true end
  end
  return false
end

local function activeOrDone(questID)
  return active(questID) or completed(questID)
end

local function spellKnown(spellID)
  local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  if bank and C_SpellBook then
    if C_SpellBook.IsSpellKnown then
      local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID, bank)
      if ok then return known end
    elseif C_SpellBook.IsSpellInSpellBook then
      local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, spellID, bank, false)
      if ok then return known end
    end
  end
  local check = IsPlayerSpell or IsSpellKnown
  if check then
    local ok, known = pcall(check, spellID)
    if ok then return known end
  end
  return false
end

local function routeFinished(route)
  if anyQuest(route[2], completed) then return true end
  if not route[3] then return false end
  for _, spellID in ipairs(route[3]) do
    local known
    if type(spellID) == "table" then known = anyQuest(spellID, spellKnown)
    else known = spellKnown(spellID) end
    if not known then return false end
  end
  return true
end

function addon.GetQuestPriority(questID)
  local info = addon.ClassQuestInfo[questID]
  if info then return info[2] and 1 or 2 end
  -- Unseen Forever quests are never bundled; a live class tag can still promote
  -- a quest the player has already accepted, without revealing future steps.
  local classTag = Enum and Enum.QuestTag and Enum.QuestTag.Class
  if classTag and active(questID) and C_QuestLog.GetQuestTagInfo then
    local ok, tag = pcall(C_QuestLog.GetQuestTagInfo, questID)
    if ok and tag and tag.tagID == classTag then return 2 end
  end
  return 3
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

local function referenceRequirementsMet(quest, info, level)
  if not info then return true end
  local route = info[2] and addon.ClassQuestRoutes[info[2]]
  return info[9] and (not info[5] or info[5] == 0 or level <= info[5])
    and not anyQuest(info[3], activeOrDone)
    and (not info[4] or active(info[4]))
    and not anyQuest(info[6], completed)
    and (not info[7] or anyQuest(info[7], activeOrDone))
    and not anyQuest(info[8], active)
    and (not route or not routeFinished(route))
end

function addon.GetSuggestionPriority(questID)
  local classPriority = addon.GetQuestPriority(questID)
  if classPriority == 1 then return 1 end
  if addon.SpecialQuestMembership[questID] then return 2 end
  return classPriority == 2 and 3 or 4
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
      and not active(questID)
      and prerequisitesMet(quest)
      and referenceRequirementsMet(quest, addon.ClassQuestInfo[questID], level)
      and referenceRequirementsMet(quest, addon.SpecialQuestGates[questID], level) then
      choices[#choices + 1] = quest
    end
  end
  table.sort(choices, function(a, b)
    local aPriority, bPriority = addon.GetSuggestionPriority(a[1]), addon.GetSuggestionPriority(b[1])
    if aPriority ~= bPriority then return aPriority < bPriority end
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

function addon.GetClassQuestPriorities(limit)
  local level = UnitLevel("player") or 1
  local faction = UnitFactionGroup("player") == "Horde" and "H" or "A"
  local _, _, raceID = UnitRace("player")
  local _, _, classID = UnitClass("player")
  local raceBit = raceID and 2 ^ (raceID - 1)
  local classBit = classID and 2 ^ (classID - 1)
  local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local byGroup, activeRoutes, finishedRoutes = {}, {}, {}
  local function choose(option)
    local key = option.routeKey or option.quest[1]
    local prior = byGroup[key]
    if not prior or (option.active and not prior.active)
      or (option.active == prior.active and (option.locality < prior.locality
        or (option.locality == prior.locality and option.quest[1] < prior.quest[1]))) then
      byGroup[key] = option
    end
  end
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for index = 1, C_QuestLog.GetNumQuestLogEntries() do
      local live = C_QuestLog.GetInfo(index)
      if live and live.questID and not live.isHeader and not completed(live.questID) then
        local info = addon.ClassQuestInfo[live.questID]
        local priority = addon.GetQuestPriority(live.questID)
        if priority < 3 and (not info or hasMask(info[1], classBit)) then
          local routeKey = info and info[2]
          if routeKey then activeRoutes[routeKey] = true end
          choose({quest = {live.questID, live.title or "Class quest", level,
              live.level and live.level > 0 and live.level or level},
            priority = priority, routeKey = routeKey, active = true, locality = 0,
            label = routeKey and addon.ClassQuestRoutes[routeKey][1] or "Class quest"})
        end
      end
    end
  end
  for key, route in pairs(addon.ClassQuestRoutes) do finishedRoutes[key] = routeFinished(route) end
  for _, quest in ipairs(addon.ClassQuestStarters) do
    local info = addon.ClassQuestInfo[quest[1]]
    local routeKey = info[2]
    local inBand = quest[4] >= level - 7 and quest[4] <= level + 5
    if (routeKey or inBand) and quest[3] <= level
      and hasMask(quest[5], raceBit) and hasMask(quest[6], classBit)
      and string.find(quest[12], faction, 1, true)
      and not activeOrDone(quest[1]) and prerequisitesMet(quest)
      and referenceRequirementsMet(quest, info, level)
      and (not routeKey or (not activeRoutes[routeKey] and not finishedRoutes[routeKey])) then
      choose({quest = quest, mapID = quest[13], priority = routeKey and 1 or 2,
        routeKey = routeKey, active = false, locality = quest[13] == currentMap and 0 or 1,
        label = routeKey and addon.ClassQuestRoutes[routeKey][1] or "Class quest"})
    end
  end
  local choices = {}
  for _, option in pairs(byGroup) do choices[#choices + 1] = option end
  table.sort(choices, function(a, b)
    if a.priority ~= b.priority then return a.priority < b.priority end
    if a.active ~= b.active then return a.active end
    -- Missed early unlocks stay ahead of optional class rewards at later levels.
    if a.quest[3] ~= b.quest[3] then return a.quest[3] < b.quest[3] end
    if a.locality ~= b.locality then return a.locality < b.locality end
    return a.quest[1] < b.quest[1]
  end)
  local count = #choices
  if limit then
    for index = count, limit + 1, -1 do choices[index] = nil end
  end
  return choices, count
end

local function starterItemHeld(itemID)
  if not itemID then return true end
  local check = C_Item and C_Item.GetItemCount or GetItemCount
  if not check then return false end
  local ok, count = pcall(check, itemID)
  return ok and type(count) == "number" and count > 0
end

function addon.GetSpecialQuestSuggestions(limit)
  local level = UnitLevel("player") or 1
  local faction = UnitFactionGroup("player") == "Horde" and "H" or "A"
  local _, _, raceID = UnitRace("player")
  local _, _, classID = UnitClass("player")
  local raceBit = raceID and 2 ^ (raceID - 1)
  local classBit = classID and 2 ^ (classID - 1)
  local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local choicesByRoute = {}
  local function eligible(route, inLog)
    return not completed(route.finale) and hasMask(route.raceMask, raceBit)
      and hasMask(route.classMask, classBit)
      and (inLog or (route.minLevel <= level and (route.utility or route.level >= level - 10)))
  end
  local function choose(key, quest, inLog, mapID)
    local route = addon.SpecialQuestRoutes[key]
    if not eligible(route, inLog) then return end
    local distance = addon.SpecialQuestMembership[quest[1]][key]
    local locality = mapID == currentMap and 0 or 1
    local prior = choicesByRoute[key]
    if not prior or (inLog and not prior.active) or (inLog == prior.active and
      (distance < prior.remaining or (distance == prior.remaining and
        (locality < prior.locality or (locality == prior.locality and quest[1] < prior.quest[1]))))) then
      choicesByRoute[key] = {key = key, route = route, quest = quest, active = inLog,
        mapID = mapID, remaining = distance, locality = locality}
    end
  end
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for index = 1, C_QuestLog.GetNumQuestLogEntries() do
      local live = C_QuestLog.GetInfo(index)
      local membership = live and not live.isHeader and addon.SpecialQuestMembership[live.questID]
      if membership and not completed(live.questID) then
        for key in pairs(membership) do
          choose(key, {live.questID, live.title or addon.SpecialQuestRoutes[key].title,
            level, live.level and live.level > 0 and live.level or level}, true)
        end
      end
    end
  end
  for _, quest in ipairs(addon.SpecialQuestStarters) do
    if quest[3] <= level and hasMask(quest[5], raceBit) and hasMask(quest[6], classBit)
      and string.find(quest[12], faction, 1, true) and not activeOrDone(quest[1])
      and prerequisitesMet(quest) and referenceRequirementsMet(quest, addon.SpecialQuestGates[quest[1]], level)
      and referenceRequirementsMet(quest, addon.ClassQuestInfo[quest[1]], level)
      and starterItemHeld(quest[14]) then
      for key in pairs(addon.SpecialQuestMembership[quest[1]]) do choose(key, quest, false, quest[13]) end
    end
  end
  local choices = {}
  for _, option in pairs(choicesByRoute) do choices[#choices + 1] = option end
  table.sort(choices, function(a, b)
    if a.active ~= b.active then return a.active end
    local aFit, bFit = math.abs(a.route.level - level), math.abs(b.route.level - level)
    if aFit ~= bFit then return aFit < bFit end
    if a.locality ~= b.locality then return a.locality < b.locality end
    if a.remaining ~= b.remaining then return a.remaining < b.remaining end
    return a.key < b.key
  end)
  local count = #choices
  if limit then
    for index = count, limit + 1, -1 do choices[index] = nil end
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
