local addonName, addon = ...
local journal = {}
addon.Journal = journal
local db, lookup, currentCharacter, lastPlace, syncPending
local pendingQuest = {}
local SCHEMA = 1

local function secret(value)
  return issecretvalue and issecretvalue(value)
end

local function text(value, limit)
  if secret(value) or type(value) ~= "string" then return nil end
  value = value:sub(1, limit or 12000)
  return value ~= "" and value or nil
end

local function number(value)
  if not secret(value) and type(value) == "number" then return value end
end

local function call(func, ...)
  if type(func) ~= "function" then return nil end
  local ok, a, b, c, d, e, f, g, h = pcall(func, ...)
  if ok then return a, b, c, d, e, f, g, h end
end

local function now()
  return number(call(GetServerTime)) or number(call(time)) or 0
end

function journal.Changed()
  if db then db.revision = (db.revision or 0) + 1 end
  if addon.RefreshJournal then addon.RefreshJournal() end
  if addon.RefreshAtlas then addon.RefreshAtlas() end
end

function journal.Initialize()
  if db then return true end
  if type(ForeverWayfinderJournal) == "table"
    and type(ForeverWayfinderJournal.schema) == "number"
    and ForeverWayfinderJournal.schema > SCHEMA then
    journal.error = "This journal was saved by a newer Wayfinder version. Update the addon to open it."
    return false
  end
  if type(ForeverWayfinderJournal) ~= "table" then ForeverWayfinderJournal = {} end
  db = ForeverWayfinderJournal
  db.schema = SCHEMA
  if type(db.entries) ~= "table" then db.entries = {} end
  if type(db.characters) ~= "table" then db.characters = {} end
  db.nextID = number(db.nextID) or 1
  lookup = {}
  for _, entry in ipairs(db.entries) do
    if type(entry) == "table" and type(entry.id) == "number" then
      db.nextID = math.max(db.nextID, entry.id + 1)
      if entry.key then lookup[entry.key] = entry end
    end
  end
  db.createdAt = db.createdAt or now()
  return true
end

function journal.Database() return db end

function journal.Character()
  if not db and not journal.Initialize() then return nil end
  local name, realm = call(UnitFullName, "player")
  name = text(name, 80) or text(call(UnitName, "player"), 80)
  if not name then return nil end
  realm = text(realm, 120) or text(call(GetRealmName), 120) or "Unknown realm"
  local guid = text(call(UnitGUID, "player"), 120)
  local key = guid or (name .. "-" .. realm)
  local className, classToken = call(UnitClass, "player")
  local raceName = call(UnitRace, "player")
  local profile = db.characters[key] or {}
  profile.key, profile.name, profile.realm = key, name, realm
  profile.class, profile.className = text(classToken, 40), text(className, 40)
  profile.race = text(raceName, 60)
  profile.faction = text(call(UnitFactionGroup, "player"), 40)
  profile.level = number(call(UnitLevel, "player")) or profile.level or 1
  db.characters[key] = profile
  currentCharacter = key
  return profile
end

function journal.CurrentCharacterKey() return currentCharacter end

function journal.Location()
  local mapID = number(call(C_Map and C_Map.GetBestMapForUnit, "player"))
  local info = mapID and call(C_Map and C_Map.GetMapInfo, mapID)
  local zone = text(call(GetRealZoneText), 120) or text(info and info.name, 120) or "Unknown region"
  local location = {mapID = mapID, zone = zone, subzone = text(call(GetSubZoneText), 120)}
  location.zoneKey = mapID and ("map:" .. mapID) or ("zone:" .. zone)
  local position = mapID and call(C_Map and C_Map.GetPlayerMapPosition, mapID, "player")
  if position and position.GetXY then
    local x, y = call(position.GetXY, position)
    x, y = number(x), number(y)
    if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
      location.x, location.y = x, y
    end
  end
  return location
end

local function create(kind, title, key, location)
  local profile = journal.Character()
  if not profile then return nil end
  local stamp = now()
  local entry = {
    id = db.nextID, key = key, kind = kind, title = title,
    character = profile.key, characterName = profile.name, realm = profile.realm,
    class = profile.class, className = profile.className, race = profile.race,
    faction = profile.faction, level = profile.level,
    firstSeenAt = stamp, updatedAt = stamp,
    zone = location.zone, zoneKey = location.zoneKey, subzone = location.subzone,
    mapID = location.mapID, x = location.x, y = location.y,
  }
  db.nextID = db.nextID + 1
  db.entries[#db.entries + 1] = entry
  if key then lookup[key] = entry end
  return entry
end

local function infoAt(index)
  local info = call(C_QuestLog and C_QuestLog.GetInfo, index)
  if info then return info end
  local title, level, group, header, collapsed, complete, frequency, id = call(GetQuestLogTitle, index)
  if title then
    return {title = title, level = level, isHeader = header, questID = id, isComplete = complete == 1}
  end
end

local function questIndex(questID)
  return number(call(C_QuestLog and C_QuestLog.GetLogIndexForQuestID, questID))
end

local function questKey(questID)
  return "quest:" .. currentCharacter .. ":" .. questID
end

local function objectives(questID)
  local rows = call(C_QuestLog and C_QuestLog.GetQuestObjectives, questID)
  if type(rows) ~= "table" then return nil end
  local result = {}
  for _, row in ipairs(rows) do
    local value = text(row.text, 1000)
    if value then result[#result + 1] = value end
  end
  return #result > 0 and result or nil
end

local function rememberRewards(entry)
  if call(C_QuestLog and C_QuestLog.GetSelectedQuest) ~= entry.questID then return end
  local xp, money = number(call(GetQuestLogRewardXP)), number(call(GetQuestLogRewardMoney))
  if xp then entry.offeredXP = xp end
  if money then entry.offeredMoney = money end
  local items = {}
  for _, source in ipairs({{GetNumQuestLogRewards, GetQuestLogRewardInfo, false},
    {GetNumQuestLogChoices, GetQuestLogChoiceInfo, true}}) do
    local count = number(call(source[1], entry.questID, true)) or 0
    for i = 1, math.min(count, 20) do
      local name, icon, quantity, quality, usable, itemID = call(source[2], i)
      name, itemID = text(name, 240), number(itemID)
      if name or itemID then
        items[#items + 1] = {name = name, itemID = itemID, icon = number(icon) or text(icon, 260),
          count = number(quantity), choice = source[3]}
      end
    end
  end
  if #items > 0 then entry.offeredItems = items end
end

function journal.RecordQuest(questID, action, index)
  questID = number(questID)
  if not questID or questID <= 0 or not journal.Character() then return nil end
  local key = questKey(questID)
  index = index or questIndex(questID)
  local info = index and infoAt(index)
  if info and (info.isHeader or info.isHidden) then return nil end
  local observed = pendingQuest[questID]
  local title = text(info and info.title, 240) or text(observed and observed.title, 240)
    or text(call(C_QuestLog and C_QuestLog.GetTitleForQuestID, questID), 240)
    or text(call(C_QuestLog and C_QuestLog.GetQuestInfo, questID), 240)
  local entry = lookup[key]
  local isNew = not entry
  if not entry then entry = create("quest", title or ("Quest #" .. questID), key, journal.Location()) end
  if not entry then return nil end
  entry.questID = questID
  if title then entry.title = title end
  entry.questLevel = number(info and info.level) or entry.questLevel
  if addon.IsDungeonQuest(questID) then entry.dungeonQuest = true end
  entry.classic = addon.IsClassicQuest(questID)
  entry.objectives = objectives(questID) or entry.objectives
  if observed then
    entry.description = observed.description or entry.description
    entry.objectiveText = observed.objectiveText or entry.objectiveText
    entry.npc = observed.npc or entry.npc
  end
  if index then
    local description, objectiveText = call(GetQuestLogQuestText, index)
    entry.description = text(description) or entry.description
    entry.objectiveText = text(objectiveText) or entry.objectiveText
  end
  if action == "accepted" then
    entry.acceptedAt, entry.status = now(), "active"
    entry.acceptances = (entry.acceptances or 0) + 1
    entry.acceptedLocation = journal.Location()
    entry.acceptedNPC = observed and observed.npc or entry.acceptedNPC
  elseif action == "completed" then
    entry.completedAt, entry.status = now(), "completed"
    entry.turnIns = (entry.turnIns or 0) + 1
    entry.completedLocation = journal.Location()
    entry.turnedInNPC = observed and observed.npc or entry.turnedInNPC
  elseif action == "removed" then
    if call(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, questID) then
      entry.status = "completed"
    elseif entry.status ~= "completed" then
      entry.status = "archived"
    end
  elseif action == "observed" and entry.status ~= "completed" then
    entry.status = "active"
  end
  rememberRewards(entry)
  if action ~= "observed" or isNew then entry.updatedAt = now() end
  if isNew or action ~= "observed" then journal.Changed() end
  return entry
end

function journal.ObserveQuestDialog()
  local questID = number(call(GetQuestID))
  if not questID or questID <= 0 then return end
  pendingQuest[questID] = {
    title = text(call(GetTitleText), 240), description = text(call(GetQuestText)),
    objectiveText = text(call(GetObjectiveText)),
    npc = text(call(UnitName, "questnpc"), 120) or text(call(UnitName, "npc"), 120),
  }
  if currentCharacter and lookup[questKey(questID)] then
    journal.RecordQuest(questID, "detail")
  end
end

function journal.SyncQuestLog()
  syncPending = false
  if not journal.Character() then return end
  local count = number(call(C_QuestLog and C_QuestLog.GetNumQuestLogEntries))
    or number(call(GetNumQuestLogEntries))
  if not count then return end
  local seen = {}
  for index = 1, count do
    local info = infoAt(index)
    local id = info and number(info.questID)
    if info and not info.isHeader and not info.isHidden and id and id > 0 then
      seen[id] = true
      journal.RecordQuest(id, "observed", index)
    end
  end
  local changed
  for _, entry in ipairs(db.entries) do
    if entry.kind == "quest" and entry.character == currentCharacter and not seen[entry.questID]
      and entry.status ~= "completed" then
      local done = call(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, entry.questID)
      local onQuest = call(C_QuestLog and C_QuestLog.IsOnQuest, entry.questID)
      -- Collapsed headers can hide rows. Only authoritative quest state, or
      -- QUEST_REMOVED, may move a remembered quest out of the active log.
      local status = done and "completed" or (onQuest == false and entry.status == "active" and "archived")
      if status and status ~= entry.status then
        entry.status, entry.updatedAt = status, now()
        changed = true
      end
    end
  end
  if changed then journal.Changed() end
  if addon.RefreshJournal then addon.RefreshJournal() end
end

function journal.QueueSync()
  if syncPending then return end
  syncPending = true
  if C_Timer and C_Timer.After then C_Timer.After(0.25, journal.SyncQuestLog)
  else journal.SyncQuestLog() end
end

function journal.VisitZone()
  local profile = journal.Character()
  if not profile then return end
  local location = journal.Location()
  if location.zone == "Unknown region" then return end
  local instanceName, instanceType, _, _, _, _, _, instanceID = call(GetInstanceInfo)
  local inside = call(IsInInstance)
  local kind = inside and (instanceType == "party" or instanceType == "raid") and "dungeon" or "exploration"
  local key = kind .. ":" .. currentCharacter .. ":" .. location.zoneKey
  if kind == "dungeon" then key = key .. ":" .. (number(instanceID) or text(instanceName, 120) or "instance") end
  if key == lastPlace or key == profile.lastPlace then lastPlace = key; return end
  lastPlace, profile.lastPlace = key, key
  local entry = lookup[key]
  if not entry then
    local title = kind == "dungeon" and text(instanceName, 120) or location.zone
    entry = create(kind, title or location.zone, key, location)
    if not entry then return end
    entry.status = "visited"
  end
  entry.visits = (entry.visits or 0) + 1
  entry.lastVisitedAt, entry.updatedAt = now(), now()
  journal.Changed()
end

function journal.RecordLevel(level)
  level = number(level)
  if not level or not journal.Character() then return end
  local key = "level:" .. currentCharacter .. ":" .. level
  if lookup[key] then return end
  local entry = create("milestone", "Reached level " .. level, key, journal.Location())
  if entry then entry.level, entry.status = level, "earned"; journal.Changed() end
end

function journal.NewNote()
  if not journal.Character() then return nil end
  local location = journal.Location()
  local entry = create("note", "Field note · " .. location.zone, nil, location)
  if entry then entry.status = "noted"; journal.Changed() end
  return entry
end

function journal.Entry(id)
  if not db then return nil end
  for _, entry in ipairs(db.entries) do if entry.id == id then return entry end end
end

function journal.SaveNote(id, title, note, tags)
  local entry = journal.Entry(id)
  if not entry then return false end
  note, tags = text(note, 6000) or "", text(tags, 240) or ""
  if entry.kind == "note" then
    title = text(title, 160) or ""
    title = title:match("^%s*(.-)%s*$")
    if title == "" then return false, "Give this field note a title." end
    entry.title = title
  end
  entry.note, entry.tags, entry.updatedAt = note, tags, now()
  journal.Changed()
  return true
end

function journal.Toggle(id, field)
  if field ~= "favorite" and field ~= "revisit" then return end
  local entry = journal.Entry(id)
  if entry then entry[field] = not entry[field] or nil; journal.Changed() end
end

function journal.DeleteNote(id)
  if not db then return false end
  for index, entry in ipairs(db.entries) do
    if entry.id == id and entry.kind == "note" then
      table.remove(db.entries, index)
      journal.Changed()
      return true
    end
  end
  return false
end

local function matches(entry, filters, tokens)
  for _, field in ipairs({"zoneKey", "kind", "class", "character", "race", "faction", "status"}) do
    if filters[field] and filters[field] ~= entry[field] then return false end
  end
  if filters.favorite and not entry.favorite then return false end
  if filters.revisit and not entry.revisit then return false end
  if #tokens == 0 then return true end
  local fields = {}
  for _, field in ipairs({"title", "zone", "subzone", "characterName", "realm", "className", "class", "race",
    "faction", "npc", "note", "tags", "description", "objectiveText", "status", "kind"}) do
    if type(entry[field]) == "string" then fields[#fields + 1] = entry[field] end
  end
  if entry.questID then fields[#fields + 1] = tostring(entry.questID) end
  if entry.objectives then for _, objective in ipairs(entry.objectives) do fields[#fields + 1] = objective end end
  if entry.offeredItems then
    for _, item in ipairs(entry.offeredItems) do if item.name then fields[#fields + 1] = item.name end end
  end
  local haystack = string.lower(table.concat(fields, " "))
  for _, token in ipairs(tokens) do if not haystack:find(token, 1, true) then return false end end
  return true
end

function journal.Query(filters)
  filters = filters or {}
  local result, tokens = {}, {}
  for word in string.lower(filters.search or ""):gmatch("%S+") do tokens[#tokens + 1] = word end
  if not db then return result end
  for _, entry in ipairs(db.entries) do
    if type(entry) == "table" and entry.id and matches(entry, filters, tokens) then result[#result + 1] = entry end
  end
  table.sort(result, function(a, b)
    local at, bt = a.updatedAt or a.firstSeenAt or 0, b.updatedAt or b.firstSeenAt or 0
    if at == bt then return a.id > b.id end
    return at > bt
  end)
  return result
end

function journal.Zones(filters)
  local copy = {}
  for key, value in pairs(filters or {}) do if key ~= "zoneKey" then copy[key] = value end end
  local groups, result = {}, {}
  for _, entry in ipairs(journal.Query(copy)) do
    local key = entry.zoneKey or ("zone:" .. (entry.zone or "Unknown region"))
    if not groups[key] then groups[key] = {key = key, name = entry.zone or "Unknown region", count = 0}; result[#result + 1] = groups[key] end
    groups[key].count = groups[key].count + 1
  end
  table.sort(result, function(a, b) return a.name < b.name end)
  return result
end

function journal.Options(field)
  local found, result = {}, {}
  for _, entry in ipairs(db and db.entries or {}) do
    local value = entry[field]
    if value and not found[value] then
      found[value] = true
      local label = value
      if field == "class" then label = entry.className or value end
      if field == "character" then label = entry.characterName .. " · " .. (entry.realm or "") end
      result[#result + 1] = {value = value, label = label}
    end
  end
  table.sort(result, function(a, b) return a.label < b.label end)
  return result
end

local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
  "QUEST_DETAIL", "QUEST_COMPLETE", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED",
  "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP", "QUEST_DATA_LOAD_RESULT"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, a, b, c)
  if event == "ADDON_LOADED" then
    if a == addonName then journal.Initialize() end
    return
  end
  if not journal.Initialize() then return end
  if event == "PLAYER_LOGIN" then
    journal.Character()
    db.sessions = (db.sessions or 0) + 1
    db.lastLoginAt = now()
    journal.QueueSync()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    journal.VisitZone()
    journal.QueueSync()
  elseif event == "QUEST_DETAIL" or event == "QUEST_COMPLETE" then
    journal.ObserveQuestDialog()
  elseif event == "QUEST_ACCEPTED" then
    journal.RecordQuest(b or a, "accepted", b and a or nil)
    journal.QueueSync()
  elseif event == "QUEST_TURNED_IN" then
    local entry = journal.RecordQuest(a, "completed")
    if entry then entry.earnedXP, entry.earnedMoney = number(b), number(c) end
  elseif event == "QUEST_REMOVED" then
    local id = number(a)
    if id and journal.Character() and lookup[questKey(id)] then journal.RecordQuest(id, "removed") end
  elseif event == "QUEST_LOG_UPDATE" then
    journal.QueueSync()
  elseif event == "PLAYER_LEVEL_UP" then
    journal.RecordLevel(a)
  elseif event == "QUEST_DATA_LOAD_RESULT" and b and currentCharacter then
    if lookup[questKey(a)] then journal.RecordQuest(a, "detail") end
  end
end)
