-- Hallmark · pre-emit critique: P5 H4 E4 S5 R4 V3
local _, addon = ...
local panel, scrollChild, titleText, footerText
local PANEL_WIDTH, CONTENT_WIDTH = 386, 328
local lines = {}
local clickRows = {}
local highlights = {}
local rules = {}
local installed = false
local trackerInstalled = false
local chainButton, detailLabel
local ink = {
  title = {0.22, 0.12, 0.06},
  heading = {0.36, 0.19, 0.05},
  body = {0.24, 0.17, 0.10},
  muted = {0.34, 0.26, 0.17},
  link = {0.15, 0.30, 0.35},
  success = {0.12, 0.31, 0.12},
}

local function renderLines(entries, preserveScroll)
  local priorScroll = preserveScroll and panel.scroll:GetVerticalScroll() or 0
  -- These pools are indexed by row number and can have gaps between entries.
  for _, line in pairs(lines) do line:Hide() end
  for _, button in pairs(clickRows) do button:Hide() end
  for _, highlight in pairs(highlights) do highlight:Hide() end
  for _, rule in pairs(rules) do rule:Hide() end
  local height = 0
  local anchorOffsets = {}
  for index, entry in ipairs(entries) do
    height = height + (entry.before or 0)
    if entry.anchorStep then anchorOffsets[entry.anchorStep] = height end
    local line = lines[index]
    if not line then
      line = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
      line:SetJustifyH("LEFT")
      lines[index] = line
    end
    local inset = entry.indent or 0
    local gap = entry.gap or 5
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", inset, -height)
    line:SetWidth(CONTENT_WIDTH - inset - 4)
    line:SetFontObject(entry.font or QuestFontNormalSmall or GameFontHighlightSmall)
    line:SetText(entry.text)
    local c = entry.color or ink.body
    line:SetTextColor(c[1], c[2], c[3])
    line:Show()
    local lineHeight = math.max(line:GetStringHeight(), 17)
    if entry.rule then
      local rule = rules[index]
      if not rule then
        rule = scrollChild:CreateTexture(nil, "ARTWORK")
        rule:SetColorTexture(0.43, 0.31, 0.17, 0.42)
        rules[index] = rule
      end
      rule:ClearAllPoints()
      rule:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -height - lineHeight - gap - 2)
      rule:SetSize(CONTENT_WIDTH - 4, 1)
      rule:Show()
    end
    if entry.highlight then
      local highlight = highlights[index]
      if not highlight then
        highlight = scrollChild:CreateTexture(nil, "BACKGROUND")
        highlight:SetColorTexture(0.52, 0.39, 0.16, 0.18)
        highlights[index] = highlight
      end
      highlight:ClearAllPoints()
      highlight:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", inset - 4, -height + 2)
      highlight:SetSize(CONTENT_WIDTH - inset + 1, lineHeight + 3)
      highlight:Show()
    end
    if entry.onClick or entry.itemID then
      local hoverLine = line
      local baseColor = c
      local tip = entry.tip
      local itemID = entry.itemID
      local button = clickRows[index]
      if not button then
        button = CreateFrame("Button", nil, scrollChild)
        clickRows[index] = button
      end
      button:ClearAllPoints()
      button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", inset - 3, -height)
      button:SetSize(CONTENT_WIDTH - inset + 2, lineHeight + 3)
      button:SetScript("OnClick", entry.onClick)
      button:SetScript("OnEnter", function(self)
        hoverLine:SetTextColor(0.58, 0.22, 0.07)
        if itemID and GameTooltip.SetItemByID then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetItemByID(itemID)
          GameTooltip:Show()
        elseif tip then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText(tip)
          GameTooltip:Show()
        end
      end)
      button:SetScript("OnLeave", function()
        hoverLine:SetTextColor(baseColor[1], baseColor[2], baseColor[3])
        GameTooltip:Hide()
      end)
      button:Show()
    end
    height = height + lineHeight + gap + (entry.rule and 8 or 0)
  end
  scrollChild:SetHeight(math.max(height + 4, 1))
  local wanted = anchorOffsets[panel.scrollToStep] or priorScroll
  panel.scroll:SetVerticalScroll(math.min(wanted, math.max(0, height - panel.scroll:GetHeight())))
  panel.scrollToStep = nil
end

local function append(entries, text, color, gap, onClick, tip)
  local entry = {text = text, color = color, gap = gap, onClick = onClick, tip = tip}
  entries[#entries + 1] = entry
  return entry
end

local function insetLine(entries, text, color, gap, onClick, tip)
  local entry = append(entries, text, color, gap, onClick, tip)
  entry.indent = 14
  return entry
end

local function subheading(entries, text)
  local entry = insetLine(entries, text, ink.heading, 5)
  entry.font = GameFontNormalSmall or GameFontNormal
  entry.before = 8
  return entry
end

local function createPanel()
  if panel then return end
  panel = CreateFrame("Frame", "ForeverWayfinderPanel", UIParent)
  panel:SetSize(PANEL_WIDTH, 550)
  panel:SetFrameStrata("DIALOG")

  local paper = panel:CreateTexture(nil, "BACKGROUND")
  paper:SetAllPoints(panel)
  paper:SetAtlas("QuestDetailsBackgrounds")
  paper:Hide()
  panel.paper = paper

  local header = panel:CreateTexture(nil, "BORDER")
  header:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -3)
  header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
  header:SetHeight(52)
  header:SetAtlas("questlog-reward-top-frame")
  header:Hide()
  panel.paperHeader = header

  local border = panel:CreateTexture(nil, "BORDER")
  border:SetAllPoints(panel)
  border:SetAtlas("questlog-frame")
  border:Hide()
  panel.paperBorder = border

  local filigree = panel:CreateTexture(nil, "ARTWORK")
  filigree:SetPoint("TOP", panel, "TOP", 0, 2)
  filigree:SetAtlas("questlog-frame-filigree", true)
  filigree:Hide()
  panel.paperFiligree = filigree
  panel:Hide()

  titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 16, -17)
  titleText:SetWidth(CONTENT_WIDTH - 8)
  titleText:SetJustifyH("LEFT")

  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  close:SetScript("OnClick", function() panel:Hide() end)

  local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 17, -49)
  scroll:SetPoint("BOTTOMRIGHT", -32, 45)
  scrollChild = CreateFrame("Frame", nil, scroll)
  scrollChild:SetSize(CONTENT_WIDTH, 1)
  scroll:SetScrollChild(scrollChild)
  panel.scroll = scroll

  local showAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  showAll:SetSize(82, 21)
  showAll:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -58)
  showAll:SetText("Show all")
  showAll:Hide()
  panel.showAll = showAll

  local hideAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  hideAll:SetSize(82, 21)
  hideAll:SetPoint("LEFT", showAll, "RIGHT", 5, 0)
  hideAll:SetText("Hide all")
  hideAll:Hide()
  panel.hideAll = hideAll

  footerText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  footerText:SetPoint("BOTTOMLEFT", 17, 15)
  footerText:SetWidth(CONTENT_WIDTH)
  footerText:SetJustifyH("LEFT")
end

local function setPanelTheme(mode)
  local details = QuestMapFrame and QuestMapFrame.DetailsFrame
  if details and details.Bg and details.Bg.GetAtlas then
    local atlas = details.Bg:GetAtlas()
    if atlas then panel.paper:SetAtlas(atlas) end
  end
  local border = details and details.BorderFrame and details.BorderFrame.Border
  if border and border.GetAtlas then
    local atlas = border:GetAtlas()
    if atlas then panel.paperBorder:SetAtlas(atlas) end
  end
  panel.paper:Show()
  panel.paperHeader:Show()
  panel.paperBorder:Show()
  panel.paperFiligree:Show()
  panel.showAll:SetShown(mode == "chain")
  panel.hideAll:SetShown(mode == "chain")
  titleText:SetTextColor(1, 0.84, 0.42)
  footerText:SetTextColor(0.34, 0.26, 0.18)
  panel.mode = mode
end

local function positionPanel()
  panel:SetHeight(math.min(550, math.max(300, UIParent:GetHeight() - 50)))
  panel:ClearAllPoints()
  if QuestMapFrame and QuestMapFrame:IsShown() then
    local right = QuestMapFrame:GetRight() or 0
    local left = QuestMapFrame:GetLeft() or 0
    local screenWidth = UIParent:GetWidth()
    if right + panel:GetWidth() + 12 <= screenWidth then
      panel:SetPoint("TOPLEFT", QuestMapFrame, "TOPRIGHT", 8, -22)
    elseif left - panel:GetWidth() - 12 >= 0 then
      panel:SetPoint("TOPRIGHT", QuestMapFrame, "TOPLEFT", -8, -22)
    else
      panel:SetHeight(math.min(panel:GetHeight(), math.max(300, UIParent:GetHeight() - 100)))
      panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -12, -72)
    end
  else
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end

local function safeCall(func, ...)
  if type(func) ~= "function" then return nil end
  local ok, a, b, c, d, e, f = pcall(func, ...)
  if ok then return a, b, c, d, e, f end
end

local function itemLine(entries, name, count, icon, itemID)
  local image = icon and ("|T" .. icon .. ":16:16:0:0|t ") or ""
  local amount = count and count > 1 and (" x" .. count) or ""
  local entry = insetLine(entries, image .. (name or ("Item #" .. (itemID or "?"))) .. amount,
    ink.link, 4)
  entry.itemID = itemID
end

local function liveRewards(entries, questID)
  local selectedID = safeCall(C_QuestLog and C_QuestLog.GetSelectedQuest)
  if selectedID ~= questID then return false end
  local canShow = safeCall(C_QuestLog and C_QuestLog.ShouldShowQuestRewards, questID)
  if canShow == false then return false end

  local xp = safeCall(GetQuestLogRewardXP)
  local money = safeCall(GetQuestLogRewardMoney)
  local rewards = safeCall(GetNumQuestLogRewards)
  local choices = safeCall(GetNumQuestLogChoices, questID, true)
  if xp == nil and money == nil and rewards == nil and choices == nil then return false end
  subheading(entries, "Forever rewards in your log")
  if type(xp) == "number" then
    insetLine(entries, "XP · " .. xp, ink.body, 3)
  end
  if type(money) == "number" then
    local formatted = safeCall(GetCoinTextureString, money)
    insetLine(entries, "Money · " .. (money > 0 and (formatted or (money .. " copper")) or "none listed"),
      ink.body, 6)
  end

  rewards = rewards or 0
  choices = choices or 0
  if rewards > 0 then insetLine(entries, "Also receive", ink.muted, 3) end
  for index = 1, math.min(rewards, 20) do
    local name, icon, count, _, _, itemID = safeCall(GetQuestLogRewardInfo, index)
    if name or itemID then itemLine(entries, name, count, icon, itemID) end
  end
  if choices > 0 then insetLine(entries, "Choose one", ink.muted, 3) end
  for index = 1, math.min(choices, 20) do
    local name, icon, count, _, _, itemID = safeCall(GetQuestLogChoiceInfo, index)
    if name or itemID then itemLine(entries, name, count, icon, itemID) end
  end
  if rewards == 0 and choices == 0 then
    insetLine(entries, "No item reward listed", ink.muted, 4)
  end
  return true
end

local showReferenceLocation
local showChain

local function sourceNames(sources)
  if not sources then return nil end
  local names = {}
  for _, source in ipairs(sources) do
    local kind = source[1] == 2 and " (object)" or (source[1] == 3 and " (item)" or "")
    names[#names + 1] = source[2] .. kind
  end
  return table.concat(names, "; ")
end

local function locationLine(entries, label, location)
  if not location then return end
  local mapID, x, y = location[1], location[2], location[3]
  local info = safeCall(C_Map and C_Map.GetMapInfo, mapID)
  local mapName = info and info.name or ("Map " .. mapID)
  insetLine(entries, "› " .. label .. " on map · " .. mapName .. " " .. x .. ", " .. y,
    ink.link, 8, function() showReferenceLocation(mapID, x, y, label) end,
    "Classic reference location. Click to open the map and replace your current waypoint.")
end

local function prerequisitesLine(entries, label, quests)
  if not quests or #quests == 0 then return end
  subheading(entries, label)
  for _, prerequisite in ipairs(quests) do
    insetLine(entries, "• " .. prerequisite[2], ink.body, 4)
  end
end

local function factionName(factionID)
  local faction = safeCall(C_Reputation and C_Reputation.GetFactionDataByID, factionID)
  if faction and faction.name then return faction.name end
  return safeCall(GetFactionInfoByID, factionID) or ("Faction " .. factionID)
end

showChain = function(questID, focusedStep, originID)
  local chain, currentStep = addon.GetClassicChain(questID)
  if not chain then return end
  createPanel()
  local sameChain = panel.mode == "chain" and panel.chainStartID == chain[1][1]
  local backQuestID = originID or (sameChain and panel.backQuestID)
  if not sameChain then
    panel.expandedSteps = {[currentStep] = true}
    panel.scrollToStep = currentStep
  end
  if sameChain and questID ~= panel.questID then
    panel.expandedSteps[currentStep] = true
    panel.scrollToStep = currentStep
  end
  if focusedStep and focusedStep >= 1 and focusedStep <= #chain then
    panel.expandedSteps[focusedStep] = true
  end
  setPanelTheme("chain")
  local entries = {}
  local completeCount = 0
  for _, quest in ipairs(chain) do
    if safeCall(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, quest[1]) then
      completeCount = completeCount + 1
    end
  end

  append(entries, chain[1][2], ink.title, 4).font = QuestFont_Large or GameFontNormalLarge
  append(entries, completeCount .. " of " .. #chain .. " completed · Classic reference",
    ink.muted, 20)
  if backQuestID then
    append(entries, "‹ Previous chain segment", ink.link, 12,
      function() showChain(backQuestID) end, "Return to the previous Classic segment.")
  end
  panel.showAll:SetScript("OnClick", function()
    for step = 1, #chain do panel.expandedSteps[step] = true end
    showChain(questID)
  end)
  panel.hideAll:SetScript("OnClick", function()
    panel.expandedSteps = {}
    showChain(questID)
  end)

  panel.scroll:ClearAllPoints()
  panel.scroll:SetPoint("TOPLEFT", 17, -91)
  panel.scroll:SetPoint("BOTTOMRIGHT", -32, 45)

  for step, quest in ipairs(chain) do
    local stepNumber, stepID = step, quest[1]
    local details = addon.ClassicChainDetails and addon.ClassicChainDetails[stepID]
    local expanded = panel.expandedSteps[step]
    local completed = safeCall(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, stepID)
    local inLog = safeCall(C_QuestLog and C_QuestLog.GetLogIndexForQuestID, stepID)
    local status = completed and "Completed" or (inLog and "In your log" or "Not in log")
    local heading = append(entries,
      (expanded and "-  " or "+  ") .. step .. ". " .. quest[2],
      completed and ink.success or ink.title, 2,
      function()
        panel.expandedSteps[stepNumber] = not panel.expandedSteps[stepNumber]
        showChain(questID)
      end, "Click to " .. (expanded and "hide" or "show") .. " this Classic step's details.")
    heading.font = QuestFontNormalSmall or GameFontHighlight
    heading.highlight = expanded
    heading.anchorStep = step
    insetLine(entries,
      status .. "   ·   Lv " .. quest[3] .. "   ·   Starts at " .. quest[4],
      completed and ink.success or ink.muted, expanded and 12 or 13)

    if expanded then
      if details and details[1] and #details[1] > 0 then
        subheading(entries, "What to do")
        for _, paragraph in ipairs(details[1]) do
          insetLine(entries, paragraph, ink.body, 7)
        end
      end
      if details then
        local starts = sourceNames(details[2])
        local ends = sourceNames(details[3])
        if starts or ends then
          subheading(entries, "People & places")
          if starts then insetLine(entries, "Start · " .. starts, ink.body, 4) end
          locationLine(entries, "Start", details[6])
          if ends then insetLine(entries, "Turn in · " .. ends, ink.body, 4) end
          locationLine(entries, "Turn-in", details[7])
        end
        if details[10] then
          subheading(entries, "Supplied item")
          itemLine(entries, details[10][2], nil,
            safeCall(GetItemIcon, details[10][1]), details[10][1])
        end
        prerequisitesLine(entries, "Required first · all", details[9])
        prerequisitesLine(entries, "Required first · one", details[8])
      end

      local hasLiveRewards = liveRewards(entries, stepID)
      if not hasLiveRewards then
        subheading(entries, "Classic reward reference")
        if quest[5] and quest[5] > 0 then
          insetLine(entries, "XP estimate · " .. quest[5], ink.body, 4)
        else
          insetLine(entries, "XP estimate unavailable", ink.muted, 4)
        end
        local verified = addon.VerifiedRewards[stepID]
        if verified then
          subheading(entries, "Verified Forever item choices")
          for _, reward in ipairs(verified) do
            itemLine(entries, safeCall(GetItemInfo, reward[1]) or reward[2], nil,
              safeCall(GetItemIcon, reward[1]), reward[1])
          end
        elseif details and details[4] and #details[4] > 0 then
          subheading(entries, "Possible Classic items")
          for _, reward in ipairs(details[4]) do
            itemLine(entries, safeCall(GetItemInfo, reward[1]) or reward[2], nil,
              safeCall(GetItemIcon, reward[1]), reward[1])
          end
        end
        if details and details[5] and #details[5] > 0 then
          subheading(entries, "Classic reputation")
          for _, reward in ipairs(details[5]) do
            insetLine(entries, factionName(reward[1]) .. " " .. string.format("%+d", reward[2]),
              ink.body, 4)
          end
        end
      end
      if inLog and safeCall(C_QuestLog and C_QuestLog.GetSelectedQuest) ~= stepID then
        insetLine(entries, "› Open this quest in your log", ink.link, 9,
          function()
            if QuestMapFrame_ShowQuestDetails then QuestMapFrame_ShowQuestDetails(stepID) end
            showChain(stepID)
          end, "Select this quest in the Forever log to read its live rewards.")
      end
      if step < #chain then
        local nextStep = step + 1
        insetLine(entries, "Next › " .. chain[nextStep][2],
          ink.link, 12, function()
            panel.scrollToStep = nextStep
            showChain(questID, nextStep)
          end,
          "Expand the next Classic step.")
      else
        local more = addon.ClassicContinuations[stepID]
        if more then
          subheading(entries, "Possible follow-ups")
          for _, followup in ipairs(more) do
            local nextQuestID = followup[1]
            local nextChain = addon.GetClassicChain(nextQuestID)
            insetLine(entries, "› " .. followup[2] .. "  (Lv " .. followup[3] .. ")",
              ink.link, 4, nextChain and function() showChain(nextQuestID, nil, questID) end or nil,
              nextChain and "Open this linked Classic segment." or nil)
          end
          insetLine(entries, "Classic links can branch; Forever may differ.", ink.muted, 8)
        end
      end
    end
    entries[#entries].gap = 18
  end

  titleText:SetText("Classic chain")
  footerText:SetText("Future gold and exact rewards appear in your Forever log.")
  positionPanel()
  renderLines(entries, sameChain)
  panel.mode = "chain"
  panel.chainStartID = chain[1][1]
  panel.questID = questID
  panel.backQuestID = backQuestID
  panel:Show()
end

local function openZoneMap(mapID)
  if WorldMapFrame and WorldMapFrame.SetMapID then
    if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
    WorldMapFrame:SetMapID(mapID)
  end
  if panel and panel:IsShown() then positionPanel() end
end

showReferenceLocation = function(mapID, x, y, label)
  openZoneMap(mapID)
  local canSet = C_Map and C_Map.SetUserWaypoint and UiMapPoint
    and UiMapPoint.CreateFromCoordinates
    and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(mapID))
  local wasSet = false
  if canSet then
    local ok, result = pcall(function()
      return C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
    end)
    wasSet = ok and result
  end
  if wasSet then
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    footerText:SetText(label .. " waypoint set from Classic data. Your previous waypoint was replaced.")
  else
    footerText:SetText(label .. " Classic location: " .. x .. ", " .. y .. ".")
  end
end

local function showQuestStarter(mapID, quest)
  openZoneMap(mapID)
  local canSet = C_Map and C_Map.SetUserWaypoint and UiMapPoint
    and UiMapPoint.CreateFromCoordinates
    and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(mapID))
  local wasSet = false
  if canSet then
    local ok, result = pcall(function()
      return C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, quest[7] / 100, quest[8] / 100))
    end)
    wasSet = ok and result
  end
  if wasSet then
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    footerText:SetText("Waypoint set to the Classic starter. Your previous waypoint was replaced.")
  else
    footerText:SetText("Map centered. Starter location: " .. quest[7] .. ", " .. quest[8] .. ".")
  end
end

local function showWhere()
  createPanel()
  setPanelTheme("where")
  panel.scroll:ClearAllPoints()
  panel.scroll:SetPoint("TOPLEFT", 17, -49)
  panel.scroll:SetPoint("BOTTOMRIGHT", -32, 45)
  local entries = {}
  local zones, currentMap, currentZone = addon.GetZoneSuggestions()
  local level = UnitLevel("player") or 1
  append(entries, "Level " .. level .. " · Classic quests you could try", {0.30, 0.20, 0.11}, 14).font = QuestFontNormalSmall or GameFontHighlightSmall
  if #zones == 0 then
    append(entries, "No nearby level bands in this small guide yet.", {0.38, 0.29, 0.21})
  end
  for index, option in ipairs(zones) do
    local zone = option.zone
    local mapID = zone[1]
    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local name = mapInfo and mapInfo.name or zone[2]
    local travel = mapID == currentMap and "Here now"
      or (currentZone and zone[6] == currentZone[6] and "Same continent" or "Travel to another continent")
    local questCount = option.count
    local countText = questCount == 1 and "1 possible Classic start"
      or questCount .. " possible Classic starts"
    local heading = append(entries, index .. ". " .. name .. "  (" .. zone[3] .. "–" .. zone[4] .. ")",
      {0.36, 0.20, 0.08}, 14,
      function() openZoneMap(mapID) end, "Click to view this zone on the map.")
    heading.font = QuestFont_Large or GameFontNormal
    heading.rule = true
    append(entries, "    " .. travel .. " · " .. countText, {0.44, 0.33, 0.22}, 7)
    for _, quest in ipairs(option.quests) do
      local selectedQuest = quest
      local questEntry = append(entries, "    › [" .. quest[4] .. "] " .. quest[2], {0.12, 0.34, 0.49}, 2,
        function() showQuestStarter(mapID, selectedQuest) end,
        "Click for a map waypoint to the Classic quest starter. Replaces your current waypoint.")
      questEntry.font = QuestFontNormalSmall or GameFontHighlightSmall
      append(entries, "       " .. quest[11] .. " · " .. quest[7] .. ", " .. quest[8],
        {0.45, 0.35, 0.26}, 5)
    end
    if #option.quests == 0 then
      local message = zone[8] and "    Explore for Forever quests; names stay hidden."
        or "    No unstarted Classic quest matched your character."
      append(entries, message, {0.45, 0.35, 0.26}, 5)
    end
    append(entries, " ", nil, 8)
  end
  titleText:SetText("Where next?")
  footerText:SetText("Click a Classic quest for its starter waypoint. Forever quests stay a surprise.")
  positionPanel()
  renderLines(entries)
  panel.mode = "where"
  panel.questID = nil
  panel:Show()
end

local function makeBadge(parent, symbol, red, green, blue, title, description)
  local badge = CreateFrame("Frame", nil, parent)
  badge:SetSize(22, 22)
  badge:EnableMouse(true)
  if badge.SetMouseClickEnabled then badge:SetMouseClickEnabled(false) end

  local label = badge:CreateFontString(nil, "OVERLAY")
  label:SetAllPoints(badge)
  label:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
  label:SetJustifyH("CENTER")
  label:SetText(symbol)
  label:SetTextColor(red, green, blue)

  badge:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(description)
    GameTooltip:Show()
  end)
  local function hideBadgeTooltip(self)
    if GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end
  badge:SetScript("OnLeave", hideBadgeTooltip)
  badge:SetScript("OnHide", hideBadgeTooltip)
  return badge
end

local function updateBadges()
  if not QuestScrollFrame or not QuestScrollFrame.titleFramePool then return end
  for button in QuestScrollFrame.titleFramePool:EnumerateActive() do
    if not button.foreverBadge then
      button.foreverBadge = makeBadge(button, "∞", 0.55, 0.91, 1,
        "Possible Forever quest",
        "This quest ID is absent from the Classic reference. Its story and later steps stay a surprise.")
    end
    if not button.dungeonBadge then
      button.dungeonBadge = makeBadge(button, "D", 0.87, 0.72, 1,
        "Dungeon quest", "The game marks this quest as a dungeon quest.")
    end
    local questID = button.questID
    local isNew = questID ~= nil and not addon.IsClassicQuest(questID)
    local isDungeon = addon.IsDungeonQuest(questID)
    local reservedWidth = (isNew and 25 or 0) + (isDungeon and 25 or 0)
    local checkbox = button.Checkbox
    checkbox:ClearAllPoints()
    checkbox:SetPoint("TOPRIGHT", button, "TOPRIGHT", -reservedWidth, -8)
    button.dungeonBadge:ClearAllPoints()
    button.dungeonBadge:SetPoint("CENTER", checkbox, "RIGHT", 13, 2)
    button.foreverBadge:ClearAllPoints()
    button.foreverBadge:SetPoint("CENTER", checkbox, "RIGHT", isDungeon and 37 or 13, 2)
    button.foreverBadge:SetShown(isNew)
    button.dungeonBadge:SetShown(isDungeon)
  end
end

local function updateTrackerHeader(block, text)
  if block.parentModule ~= QuestObjectiveTracker then
    if block.wayfinderDungeonBadge then block.wayfinderDungeonBadge:Hide() end
    if block.wayfinderForeverBadge then block.wayfinderForeverBadge:Hide() end
    return
  end
  local questID = block.id
  local isNew = type(questID) == "number" and not addon.IsClassicQuest(questID)
  local isDungeon = addon.IsDungeonQuest(questID)
  if not block.wayfinderDungeonBadge then
    block.wayfinderDungeonBadge = makeBadge(block, "D", 0.87, 0.72, 1,
      "Dungeon quest", "The game marks this quest as a dungeon quest.")
    block.wayfinderForeverBadge = makeBadge(block, "∞", 0.55, 0.91, 1,
      "Possible Forever quest",
      "This quest ID is absent from the Classic reference. Its story and later steps stay a surprise.")
  end
  block.wayfinderDungeonBadge:ClearAllPoints()
  block.wayfinderDungeonBadge:SetPoint("TOPRIGHT", block, "TOPRIGHT", block.rightEdgeOffset - (isNew and 28 or 2), 1)
  block.wayfinderForeverBadge:ClearAllPoints()
  block.wayfinderForeverBadge:SetPoint("TOPRIGHT", block, "TOPRIGHT", block.rightEdgeOffset - 2, 1)
  block.wayfinderDungeonBadge:SetShown(isDungeon)
  block.wayfinderForeverBadge:SetShown(isNew)

  local reservedWidth = (isNew and 26 or 0) + (isDungeon and 26 or 0)
  if reservedWidth > 0 then
    block.HeaderText:SetPoint("RIGHT", block, "RIGHT", block.rightEdgeOffset - reservedWidth, 0)
    block.height = block:SetStringText(block.HeaderText, text, nil, OBJECTIVE_TRACKER_COLOR["Header"], block.isHighlighted)
  end
end

local function tryInstallTracker()
  if trackerInstalled or not QuestObjectiveTracker
    or type(QuestObjectiveTracker.GetBlock) ~= "function" then return end
  trackerInstalled = true
  local function hookBlock(block)
    if block and not block.wayfinderHeaderHooked and type(block.SetHeader) == "function" then
      block.wayfinderHeaderHooked = true
      hooksecurefunc(block, "SetHeader", updateTrackerHeader)
    end
  end
  hooksecurefunc(QuestObjectiveTracker, "GetBlock", function(self, questID)
    hookBlock(self:GetExistingBlock(questID))
  end)
  if QuestObjectiveTracker.EnumerateActiveBlocks then
    QuestObjectiveTracker:EnumerateActiveBlocks(hookBlock)
  end
  if QuestObjectiveTracker.MarkDirty then QuestObjectiveTracker:MarkDirty() end
end

local function updateDetails()
  if not QuestMapFrame or not QuestMapFrame.DetailsFrame then return end
  local details = QuestMapFrame.DetailsFrame
  local questID = details.questID
  if not questID then
    chainButton:Hide()
    detailLabel:Hide()
    return
  end
  local chain = addon.GetClassicChain(questID)
  chainButton:SetShown(chain ~= nil)
  detailLabel:ClearAllPoints()
  detailLabel:SetPoint("LEFT", chain and chainButton or details.BackFrame.BackButton, "RIGHT", 8, 0)
  local isNew = not addon.IsClassicQuest(questID)
  local dungeon = addon.IsDungeonQuest(questID)
  if isNew and dungeon then
    detailLabel:SetText("∞ New · Dungeon")
  elseif isNew then
    detailLabel:SetText("∞ New")
  elseif dungeon then
    detailLabel:SetText("Dungeon")
  else
    detailLabel:SetText("")
  end
  detailLabel:SetShown(isNew or dungeon)
  if panel and panel:IsShown() and panel.mode == "chain" then
    if chain then
      showChain(questID)
    else
      panel:Hide()
    end
  end
end

local function tryInstall()
  if installed or not QuestMapFrame or not QuestScrollFrame
    or not QuestMapFrame.DetailsFrame or not QuestMapFrame.QuestsFrame
    or not QuestLogQuests_Update or not QuestMapFrame_ShowQuestDetails then return end
  installed = true
  local details = QuestMapFrame.DetailsFrame
  chainButton = CreateFrame("Button", nil, details.BackFrame, "UIPanelButtonTemplate")
  chainButton:SetSize(78, 22)
  chainButton:SetPoint("LEFT", details.BackFrame.BackButton, "RIGHT", 8, 0)
  chainButton:SetText("Chain")
  chainButton:SetScript("OnClick", function()
    local questID = details.questID
    if panel and panel:IsShown() and panel.mode == "chain" and panel.questID == questID then
      panel:Hide()
    else
      showChain(questID)
    end
  end)
  chainButton:Hide()

  detailLabel = details.BackFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  detailLabel:SetPoint("LEFT", chainButton, "RIGHT", 4, 0)
  detailLabel:SetTextColor(0.55, 0.91, 1)
  detailLabel:Hide()

  local quests = QuestMapFrame.QuestsFrame
  local questScroll = quests.ScrollFrame
  questScroll:ClearAllPoints()
  questScroll:SetPoint("TOPLEFT", quests, "TOPLEFT", 0, -29)
  questScroll:SetPoint("BOTTOMRIGHT", quests, "BOTTOMRIGHT", 0, 27)
  local whereButton = CreateFrame("Button", nil, quests, "UIPanelButtonTemplate")
  whereButton:SetSize(104, 22)
  whereButton:SetPoint("BOTTOMLEFT", quests, "BOTTOMLEFT", 9, 2)
  whereButton:SetText("Where next?")
  whereButton:SetScript("OnClick", function()
    if panel and panel:IsShown() and panel.mode == "where" then
      panel:Hide()
    else
      showWhere()
    end
  end)
  local function updateWhereButton()
    whereButton:SetShown(questScroll:IsShown() and not details:IsShown())
  end
  questScroll:HookScript("OnShow", updateWhereButton)
  questScroll:HookScript("OnHide", updateWhereButton)
  details:HookScript("OnShow", updateWhereButton)
  details:HookScript("OnHide", updateWhereButton)
  updateWhereButton()

  hooksecurefunc("QuestLogQuests_Update", updateBadges)
  hooksecurefunc("QuestMapFrame_ShowQuestDetails", updateDetails)
  details:HookScript("OnHide", function()
    if panel and panel.mode == "chain" then panel:Hide() end
  end)
  QuestMapFrame:HookScript("OnHide", function()
    if panel then panel:Hide() end
  end)
  updateBadges()
  updateDetails()
end

SLASH_FOREVERWAYFINDER1 = "/fw"
SLASH_FOREVERWAYFINDER2 = "/fway"
SlashCmdList.FOREVERWAYFINDER = function(message)
  local command = string.lower((message or ""):match("^%s*(.-)%s*$"))
  if command == "where" or command == "" then
    showWhere()
  elseif command == "chain" then
    local questID = QuestMapFrame and QuestMapFrame.DetailsFrame and QuestMapFrame.DetailsFrame.questID
    if questID and addon.GetClassicChain(questID) then
      showChain(questID)
    else
      print("Forever Wayfinder: Select a Classic chain quest in the quest log first.")
    end
  else
    print("Forever Wayfinder: /fw where or /fw chain")
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  tryInstall()
  tryInstallTracker()
end)
tryInstall()
tryInstallTracker()
