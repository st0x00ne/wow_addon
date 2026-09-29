-- Hallmark · native journal panels · gold/brown frame, parchment, inset rows
-- Pre-emit critique: P5 H4 E4 S5 R4 V4
local _, addon = ...
local style = addon.ReadingStyle
local panel, scrollChild, titleText, footerText
local showWhere
local PANEL_WIDTH, CONTENT_WIDTH = 438, 374
local lines = {}
local clickRows = {}
local highlights = {}
local rules = {}
local surfaces = {}
local edges = {}
local installed = false
local trackerInstalled = false
local chainButton, detailLabel
local ink = {
  title = {0.22, 0.12, 0.06},
  heading = {0.25, 0.13, 0.035},
  body = {0.17, 0.105, 0.055},
  muted = {0.28, 0.19, 0.10},
  link = {0.07, 0.24, 0.29},
  success = {0.12, 0.31, 0.12},
  frame = {0.11, 0.08, 0.04},
  header = {0.18, 0.13, 0.07},
  gold = {1.00, 0.82, 0.35},
  pale = {0.91, 0.82, 0.65},
  edge = {0.51, 0.37, 0.18},
  rule = {0.43, 0.31, 0.17, 0.42},
  row = {0.20, 0.14, 0.08},
  rowSelected = {0.31, 0.22, 0.11},
  rowHover = {0.37, 0.27, 0.14},
  questRow = {0.46, 0.33, 0.16, 0.10},
  questHover = {0.46, 0.33, 0.16, 0.22},
  highlight = {0.52, 0.39, 0.16, 0.18},
  hover = {0.58, 0.22, 0.07},
  item = {0.70, 0.85, 0.96},
  completedTitle = {0.56, 0.85, 0.40},
  paper = {1.00, 0.95, 0.84},
  paperBase = {0.78, 0.67, 0.46},
}

local function colorTexture(texture, color)
  texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function drawRow(index, inset, height, rowHeight, color, selected)
  local surface = surfaces[index]
  if not surface then
    surface = scrollChild:CreateTexture(nil, "BACKGROUND")
    surfaces[index] = surface
  end
  surface:ClearAllPoints()
  surface:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", inset, -height)
  local width = CONTENT_WIDTH - inset
  surface:SetSize(width, rowHeight)
  colorTexture(surface, color)
  surface:Show()

  if not edges[index] then
    edges[index] = {}
    for side = 1, 4 do
      edges[index][side] = scrollChild:CreateTexture(nil, "BORDER")
    end
  end
  local borderColor = selected and ink.gold or ink.edge
  local border = edges[index]
  for _, edge in ipairs(border) do
    edge:ClearAllPoints()
    colorTexture(edge, borderColor)
    edge:Show()
  end
  border[1]:SetPoint("TOPLEFT", surface, "TOPLEFT")
  border[1]:SetSize(width, 1)
  border[2]:SetPoint("BOTTOMLEFT", surface, "BOTTOMLEFT")
  border[2]:SetSize(width, 1)
  border[3]:SetPoint("TOPLEFT", surface, "TOPLEFT")
  border[3]:SetSize(1, rowHeight)
  border[4]:SetPoint("TOPRIGHT", surface, "TOPRIGHT")
  border[4]:SetSize(1, rowHeight)
  return surface
end

local function renderLines(entries, preserveScroll)
  local priorScroll = preserveScroll and panel.scroll:GetVerticalScroll() or 0
  -- These pools are indexed by row number and can have gaps between entries.
  for _, line in pairs(lines) do line:Hide() end
  for _, button in pairs(clickRows) do button:Hide() end
  for _, highlight in pairs(highlights) do highlight:Hide() end
  for _, rule in pairs(rules) do rule:Hide() end
  for _, surface in pairs(surfaces) do surface:Hide() end
  for _, border in pairs(edges) do
    for _, edge in ipairs(border) do edge:Hide() end
  end
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
    local card = entry.kind == "step" or entry.kind == "zone"
      or entry.kind == "item" or entry.kind == "quest"
    local darkCard = card and entry.kind ~= "quest"
    local padding = card and 10 or 0
    local rowInset = entry.indent or 0
    local inset = rowInset + padding
    local gap = math.max(entry.gap or 7, 7)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", inset, -height - padding)
    line:SetWidth(CONTENT_WIDTH - inset - (card and padding or 4))
    local role = entry.role or ((entry.font == QuestFont_Large or entry.font == GameFontNormalLarge) and "title")
      or ((entry.kind == "step" or entry.kind == "quest") and "entry") or "body"
    style.Font(line, role)
    line:SetText(entry.text)
    line:SetAlpha(1)
    local c = entry.color or ink.body
    line:SetTextColor(c[1], c[2], c[3])
    line:Show()
    local lineHeight = math.max(line:GetStringHeight(), style.Size(role) + 3)
    local rowHeight = lineHeight + padding * 2
    local surface, surfaceColor
    if card then
      surfaceColor = darkCard and (entry.highlight and ink.rowSelected or ink.row) or ink.questRow
      surface = drawRow(index, rowInset, height, rowHeight, surfaceColor, entry.highlight)
    end
    if entry.rule then
      local rule = rules[index]
      if not rule then
        rule = scrollChild:CreateTexture(nil, "ARTWORK")
        colorTexture(rule, ink.rule)
        rules[index] = rule
      end
      rule:ClearAllPoints()
      rule:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", rowInset, -height - rowHeight - gap - 2)
      rule:SetSize(CONTENT_WIDTH - rowInset - 4, 1)
      rule:Show()
    end
    if entry.highlight and not card then
      local highlight = highlights[index]
      if not highlight then
        highlight = scrollChild:CreateTexture(nil, "BACKGROUND")
        colorTexture(highlight, ink.highlight)
        highlights[index] = highlight
      end
      highlight:ClearAllPoints()
      highlight:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", inset - 4, -height + 2)
      highlight:SetSize(CONTENT_WIDTH - inset + 1, rowHeight + 3)
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
      button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", card and rowInset or inset - 3, -height)
      button:SetSize(CONTENT_WIDTH - rowInset, rowHeight + (card and 0 or 3))
      button:SetScript("OnClick", entry.onClick)
      button:SetScript("OnEnter", function(self)
        local hoverColor = darkCard and ink.gold or ink.hover
        hoverLine:SetTextColor(hoverColor[1], hoverColor[2], hoverColor[3])
        if surface then colorTexture(surface, darkCard and ink.rowHover or ink.questHover) end
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
        if surface then colorTexture(surface, surfaceColor) end
        GameTooltip:Hide()
      end)
      button:SetScript("OnMouseDown", function() hoverLine:SetAlpha(0.75) end)
      button:SetScript("OnMouseUp", function() hoverLine:SetAlpha(1) end)
      button:SetScript("OnHide", function(self)
        if GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
      end)
      button:Show()
    end
    height = height + rowHeight + gap + (entry.rule and 8 or 0)
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
  entry.role = "heading"
  entry.before = 12
  entry.rule = true
  return entry
end

local function createPanel()
  if panel then return end
  panel = CreateFrame("Frame", "ForeverWayfinderPanel", UIParent, "BackdropTemplate")
  panel:SetSize(PANEL_WIDTH, 580)
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
  })
  panel:SetBackdropColor(ink.frame[1], ink.frame[2], ink.frame[3], 1)
  panel:SetBackdropBorderColor(ink.edge[1], ink.edge[2], ink.edge[3], 1)

  local header = panel:CreateTexture(nil, "BACKGROUND")
  header:SetPoint("TOPLEFT", 6, -6)
  header:SetPoint("TOPRIGHT", -6, -6)
  header:SetHeight(58)
  colorTexture(header, ink.header)
  local headerRule = panel:CreateTexture(nil, "BORDER")
  headerRule:SetPoint("TOPLEFT", 8, -64)
  headerRule:SetPoint("TOPRIGHT", -8, -64)
  headerRule:SetHeight(1)
  colorTexture(headerRule, ink.edge)

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(32, 32)
  icon:SetPoint("TOPLEFT", 16, -18)
  icon:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\Icon")

  local paper = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  paper:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
  })
  paper:SetBackdropColor(ink.paperBase[1], ink.paperBase[2], ink.paperBase[3], 1)
  paper:SetBackdropBorderColor(ink.edge[1], ink.edge[2], ink.edge[3], 1)
  -- QuestBG includes unused texture space in this client. Its cropped atlas
  -- fills the reading area; the opaque base also keeps text readable if the
  -- atlas is unavailable. Keep the artwork separate from Backdrop sizing.
  local parchment = paper:CreateTexture(nil, "BACKGROUND", nil, 1)
  parchment:SetPoint("TOPLEFT", paper, "TOPLEFT", 4, -4)
  parchment:SetPoint("BOTTOMRIGHT", paper, "BOTTOMRIGHT", -4, 4)
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("QuestDetailsBackgrounds") then
    parchment:SetAtlas("QuestDetailsBackgrounds")
  end
  parchment:SetVertexColor(ink.paper[1], ink.paper[2], ink.paper[3], 1)
  panel.parchment = parchment
  panel.paper = paper
  panel:Hide()

  titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 58, -12)
  titleText:SetWidth(PANEL_WIDTH - 100)
  titleText:SetJustifyH("LEFT")
  style.Font(titleText, "title")
  titleText:SetTextColor(ink.gold[1], ink.gold[2], ink.gold[3])
  panel.subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  panel.subtitle:SetPoint("TOPLEFT", 58, -43)
  panel.subtitle:SetWidth(PANEL_WIDTH - 84)
  panel.subtitle:SetJustifyH("LEFT")
  style.Font(panel.subtitle, "meta")
  panel.subtitle:SetTextColor(ink.pale[1], ink.pale[2], ink.pale[3])

  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  close:SetScript("OnClick", function() panel:Hide() end)

  local scroll = CreateFrame("ScrollFrame", nil, paper, "UIPanelScrollFrameTemplate")
  scrollChild = CreateFrame("Frame", nil, scroll)
  scrollChild:SetSize(CONTENT_WIDTH, 1)
  scroll:SetScrollChild(scrollChild)
  panel.scroll = scroll

  local showAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  showAll:SetSize(96, 28)
  showAll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -74)
  showAll:SetText("Show all")
  style.Button(showAll)
  showAll:Hide()
  panel.showAll = showAll

  local hideAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  hideAll:SetSize(96, 28)
  hideAll:SetPoint("LEFT", showAll, "RIGHT", 8, 0)
  hideAll:SetText("Hide all")
  style.Button(hideAll)
  hideAll:Hide()
  panel.hideAll = hideAll

  local reading = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  reading:SetPoint("TOPLEFT", 250, -74); reading:SetSize(172, 28)
  reading:SetText("Text: " .. style.Name()); style.Button(reading)
  reading:SetScript("OnClick", style.Cycle)
  reading:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Reading text size")
    GameTooltip:AddLine("Cycles Standard, Large, and Extra Large across Wayfinder. Your choice is saved.", .9, .8, .6, true)
    GameTooltip:Show()
  end)
  reading:SetScript("OnLeave", function() GameTooltip:Hide() end)
  reading:SetScript("OnHide", function(self) if GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
  panel.readingButton = reading
  panel.readingLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  panel.readingLabel:SetPoint("TOPLEFT", 18, -81); panel.readingLabel:SetWidth(214)
  style.Font(panel.readingLabel, "meta")
  panel.readingLabel:SetTextColor(ink.pale[1], ink.pale[2], ink.pale[3]); panel.readingLabel:SetText("Choose your reading size")

  panel.whereCategories = {}
  for index, category in ipairs({{"all", "All"}, {"class", "Class"}, {"special", "Special"}, {"zones", "Zones"}}) do
    local key, label = category[1], category[2]
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 18 + (index - 1) * 102, -114)
    button:SetSize(94, 28); button:SetText(label); style.Button(button)
    button:SetScript("OnClick", function()
      panel.whereCategory = key
      showWhere()
    end)
    button:Hide()
    panel.whereCategories[key] = button
  end

  footerText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  footerText:SetPoint("BOTTOMLEFT", 20, 10)
  footerText:SetSize(PANEL_WIDTH - 40, 42)
  footerText:SetJustifyH("LEFT")
  footerText:SetJustifyV("TOP")
  style.Font(footerText, "meta")
  footerText:SetTextColor(ink.pale[1], ink.pale[2], ink.pale[3])
  if UISpecialFrames then table.insert(UISpecialFrames, "ForeverWayfinderPanel") end
end

local function setPanelTheme(mode)
  local top = mode == "where" and 150 or 114
  panel.paper:ClearAllPoints()
  panel.paper:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -top)
  panel.paper:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 52)
  panel.scroll:ClearAllPoints()
  panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -top - 12)
  panel.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -40, 64)
  panel.showAll:SetShown(mode == "chain")
  panel.hideAll:SetShown(mode == "chain")
  panel.readingLabel:SetShown(mode ~= "chain")
  for key, button in pairs(panel.whereCategories) do
    button:SetShown(mode == "where")
    if button.SetButtonState then
      button:SetButtonState(key == (panel.whereCategory or "all") and "PUSHED" or "NORMAL", key == (panel.whereCategory or "all"))
    end
  end
  panel.mode = mode
end

local function positionPanel()
  panel:SetHeight(math.min(580, math.max(300, UIParent:GetHeight() - 50)))
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
  local image = icon and ("|T" .. icon .. ":24:24:0:0|t ") or ""
  local amount = count and count > 1 and (" x" .. count) or ""
  local entry = insetLine(entries, image .. (name or ("Item #" .. (itemID or "?"))) .. amount,
    ink.item, 6)
  entry.itemID = itemID
  entry.kind = "item"
  entry.font = GameFontHighlightSmall
  entry.role = "body"
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

  append(entries, chain[1][2], ink.title, 14).font = QuestFont_Large or GameFontNormalLarge
  panel.subtitle:SetText(completeCount .. " of " .. #chain .. " completed · Classic reference")
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
  local expandedCount = 0
  for step = 1, #chain do
    if panel.expandedSteps[step] then expandedCount = expandedCount + 1 end
  end
  panel.showAll:SetEnabled(expandedCount < #chain)
  panel.hideAll:SetEnabled(expandedCount > 0)

  for step, quest in ipairs(chain) do
    local stepNumber, stepID = step, quest[1]
    local details = addon.ClassicChainDetails and addon.ClassicChainDetails[stepID]
    local expanded = panel.expandedSteps[step]
    local completed = safeCall(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, stepID)
    local inLog = safeCall(C_QuestLog and C_QuestLog.GetLogIndexForQuestID, stepID)
    local status = completed and "Completed" or (inLog and "In your log" or "Not in log")
    local heading = append(entries,
      (expanded and "-  " or "+  ") .. step .. ". " .. quest[2],
      completed and ink.completedTitle or ink.gold, 6,
      function()
        panel.expandedSteps[stepNumber] = not panel.expandedSteps[stepNumber]
        showChain(questID)
      end, "Click to " .. (expanded and "hide" or "show") .. " this Classic step's details.")
    heading.font = GameFontNormal or GameFontHighlight
    heading.kind = "step"
    heading.highlight = expanded
    heading.anchorStep = step
    local statusLine = insetLine(entries,
      status .. "   ·   Lv " .. quest[3] .. "   ·   Starts at " .. quest[4],
      completed and ink.success or ink.muted, expanded and 12 or 13)
    statusLine.role = "meta"

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

showWhere = function(preserveScroll)
  createPanel()
  setPanelTheme("where")
  local entries = {}
  local zones, currentMap, currentZone = addon.GetZoneSuggestions()
  local level = UnitLevel("player") or 1
  local className = UnitClass("player") or "Class"
  local category = panel.whereCategory or "all"
  local priorities = addon.GetClassQuestPriorities()
  local essentials, otherClass = {}, {}
  for _, option in ipairs(priorities) do
    local target = option.priority == 1 and essentials or otherClass
    target[#target + 1] = option
  end
  panel.subtitle:SetText("Level " .. level .. " · " .. ({all="Recommended quests", class="Class quests", special="Special quests", zones="Questing zones"})[category])
  local function sectionHeading(text)
    local heading = append(entries, text, ink.gold, 8)
    heading.font = GameFontNormalLarge or GameFontNormal
    heading.kind = "zone"
  end
  local function classSection(options, title, fold)
    sectionHeading(title)
    insetLine(entries, (options[1] and options[1].priority == 1 and "Ability and training routes" or "Class quests") .. " · Classic reference", ink.muted, 8)
    local limit = fold and not panel.showAllClasses and 3 or #options
    for index, option in ipairs(options) do
      if index > limit then break end
      local selected = option
      local quest = option.quest
      local icon = option.active and "ActiveQuestIcon" or "AvailableQuestIcon"
      local onClick
      if option.active then
        onClick = function()
          if ToggleQuestLog and (not QuestMapFrame or not QuestMapFrame:IsShown()) then ToggleQuestLog() end
          if QuestMapFrame_ShowQuestDetails then QuestMapFrame_ShowQuestDetails(selected.quest[1]) end
        end
      elseif option.mapID then
        onClick = function() showQuestStarter(selected.mapID, selected.quest) end
      end
      local row = append(entries, "|TInterface\\GossipFrame\\" .. icon .. ":18:18:0:0|t [" .. quest[4] .. "] " .. quest[2],
        onClick and ink.link or ink.body, 4, onClick, option.active and "Open this quest in your log."
          or "Set a waypoint to the Classic starter. Forever may change this ability route. Replaces your current waypoint.")
      row.kind = "quest"
      insetLine(entries, option.priority == 1 and ((option.routeKey == "locks" and "Skill practice · " or "Ability route · ") .. option.label) or "Class quest",
        ink.heading, 4)
      if option.active then
        insetLine(entries, "In your log · Click to continue", ink.success, 12)
      else
        local info = option.mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(option.mapID)
        local location = info and info.name or quest[14] or ("Map " .. option.mapID)
        insetLine(entries, location .. " · " .. quest[11], ink.muted, 12)
        if not option.mapID then insetLine(entries, "No starter coordinates in the Classic reference.", ink.muted, 12) end
      end
    end
    if fold and #options > 3 then
      append(entries, panel.showAllClasses and "› Show fewer class priorities" or "› Show all " .. #options .. " class priorities",
        ink.link, 12, function() panel.showAllClasses = not panel.showAllClasses; showWhere(true) end,
        "Expand or fold the class quest list.")
    end
    insetLine(entries, "Forever can change unlocks. Check your trainer if a Classic route is unavailable.", ink.muted, 18)
  end
  if category == "class" then
    if #priorities > 0 then classSection(priorities, className .. " priorities", true)
    else
      sectionHeading(className .. " priorities")
      insetLine(entries, "No available class quest matched this reference. Check your live trainer for Forever changes.", ink.muted, 12)
    end
  elseif category == "all" and #essentials > 0 then
    classSection(essentials, className .. " priorities", true)
  end
  if category == "all" or category == "special" then
    local specials, specialCount = addon.GetSpecialQuestSuggestions(category == "all" and 3 or nil)
    if specialCount > 0 or category == "special" then
      sectionHeading("Special quests")
      insetLine(entries, "Standout reward chains · Classic reference", ink.muted, 8)
      for _, option in ipairs(specials) do
        local selected, quest, route = option, option.quest, option.route
        local heading = append(entries, route.title, ink.heading, 5)
        heading.role = "heading"
        insetLine(entries, route.reason, ink.body, 5)
        insetLine(entries, "Classic finale · Lv " .. route.level .. " · Reward references", ink.muted, 5)
        for _, reward in ipairs(route.rewards) do
          local icon = safeCall(GetItemIcon, reward[1]) or safeCall(C_Item and C_Item.GetItemIconByID, reward[1])
          local row = insetLine(entries, (icon and "|T" .. icon .. ":18:18:0:0|t " or "") .. reward[2], ink.link, 4)
          row.itemID = reward[1]
          row.role = "entry"
        end
        local onClick
        if option.active then
          onClick = function()
            if ToggleQuestLog and (not QuestMapFrame or not QuestMapFrame:IsShown()) then ToggleQuestLog() end
            if QuestMapFrame_ShowQuestDetails then QuestMapFrame_ShowQuestDetails(selected.quest[1]) end
          end
        elseif option.mapID then onClick = function() showQuestStarter(selected.mapID, selected.quest) end end
        local step = append(entries, "› " .. (option.active and "In your log: " or "Next step: ") .. quest[2],
          onClick and ink.link or ink.body, 4, onClick,
          option.active and "Open your current quest in the log." or "Set a waypoint to this Classic starter. Replaces your current waypoint.")
        step.kind = "quest"
        if not option.active then
          local mapInfo = option.mapID and safeCall(C_Map and C_Map.GetMapInfo, option.mapID)
          insetLine(entries, option.mapID and ((mapInfo and mapInfo.name or "Map " .. option.mapID) .. " · " .. quest[11])
            or ("Start with the item in your bags: " .. quest[11]), ink.muted, 6)
        end
        if addon.GetClassicChain(quest[1]) then
          insetLine(entries, "› View current Classic chain", ink.link, 8,
            function() showChain(selected.quest[1]) end, "Open the Classic reference segment for this step.")
        end
        entries[#entries].gap = 20
      end
      if specialCount == 0 then insetLine(entries, "No unfinished reward chain matched your class, level, and progress. More chains become available as you level.", ink.muted, 12) end
      if category == "all" and specialCount > 3 then
        append(entries, "› Browse all " .. specialCount .. " special quests", ink.link, 12,
          function() panel.whereCategory = "special"; showWhere() end, "Open the Special category.")
      end
      insetLine(entries, "Forever can change rewards. Check the offer in your live quest log.", ink.muted, 18)
    end
  end
  if category == "all" and #otherClass > 0 then
    local preview = {}
    for index = 1, math.min(#otherClass, 2) do preview[index] = otherClass[index] end
    classSection(preview, "Other " .. className .. " quests", false)
    if #otherClass > 2 then append(entries, "› Browse class quests", ink.link, 14,
      function() panel.whereCategory = "class"; showWhere() end) end
  end
  local showZones = category == "all" or category == "zones"
  if showZones and #entries > 0 then sectionHeading("Places to quest next") end
  if showZones and #zones == 0 then
    append(entries, "No nearby level bands in this small guide yet.", ink.muted)
  end
  for index, option in ipairs(showZones and zones or {}) do
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
      ink.gold, 8,
      function() openZoneMap(mapID) end, "Click to view this zone on the map.")
    heading.font = GameFontNormalLarge or GameFontNormal
    heading.kind = "zone"
    insetLine(entries, travel .. " · " .. countText, ink.muted, 8)
    for _, quest in ipairs(option.quests) do
      local selectedQuest = quest
      local questEntry = append(entries,
        "|TInterface\\GossipFrame\\AvailableQuestIcon:18:18:0:0|t [" .. quest[4] .. "] " .. quest[2], ink.link, 4,
        function() showQuestStarter(mapID, selectedQuest) end,
        "Click for a map waypoint to the Classic quest starter. Replaces your current waypoint.")
      questEntry.font = QuestFontNormalSmall or GameFontHighlightSmall
      questEntry.kind = "quest"
      insetLine(entries, quest[11] .. " · " .. quest[7] .. ", " .. quest[8], ink.muted, 10)
    end
    if #option.quests == 0 then
      local message = zone[8] and "Explore for Forever quests; names stay hidden."
        or "No unstarted Classic quest matched your character."
      insetLine(entries, message, ink.muted, 5)
    end
    entries[#entries].gap = 20
  end
  titleText:SetText("Where next?")
  footerText:SetText(category == "special" and "Hover rewards for item details. Click the next step to continue."
    or "Click a Classic quest for its starter waypoint. Forever quests stay a surprise.")
  positionPanel()
  renderLines(entries, preserveScroll)
  panel.mode = "where"
  panel.questID = nil
  panel:Show()
end

addon.ShowClassicChain = showChain
addon.ShowWhereNext = showWhere

function addon.RefreshPanelReadingStyle()
  if not panel then return end
  panel.readingButton:SetText("Text: " .. style.Name())
  if not panel:IsShown() then return end
  if panel.mode == "chain" and panel.questID then showChain(panel.questID)
  elseif panel.mode == "where" then showWhere(true) end
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
  chainButton:SetSize(82, 26)
  chainButton:SetPoint("LEFT", details.BackFrame.BackButton, "RIGHT", 8, 0)
  chainButton:SetText("Chain")
  style.Button(chainButton)
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
  style.Font(detailLabel, "meta")
  detailLabel:Hide()

  local quests = QuestMapFrame.QuestsFrame
  local questScroll = quests.ScrollFrame
  questScroll:ClearAllPoints()
  questScroll:SetPoint("TOPLEFT", quests, "TOPLEFT", 0, -29)
  questScroll:SetPoint("BOTTOMRIGHT", quests, "BOTTOMRIGHT", 0, 34)
  local whereButton = CreateFrame("Button", nil, quests, "UIPanelButtonTemplate")
  whereButton:SetSize(116, 28)
  whereButton:SetPoint("BOTTOMLEFT", quests, "BOTTOMLEFT", 9, 2)
  whereButton:SetText("Where next?")
  style.Button(whereButton)
  whereButton:SetScript("OnClick", function()
    if panel and panel:IsShown() and panel.mode == "where" then
      panel:Hide()
    else
      showWhere()
    end
  end)
  local journalButton = CreateFrame("Button", nil, quests, "UIPanelButtonTemplate")
  journalButton:SetSize(96, 28)
  journalButton:SetPoint("LEFT", whereButton, "RIGHT", 6, 0)
  journalButton:SetText("Journal")
  style.Button(journalButton)
  journalButton:SetScript("OnClick", function() addon.ToggleJournal() end)
  local function updateWhereButton()
    whereButton:SetShown(questScroll:IsShown() and not details:IsShown())
    journalButton:SetShown(questScroll:IsShown() and not details:IsShown())
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
  elseif command == "journal" or command == "journey" then
    addon.ToggleJournal()
  elseif command == "journal status" then
    local db = addon.Journal.Database()
    print("Forever Wayfinder: " .. (db and #db.entries or 0) .. " journal entries; "
      .. (db and db.sessions or 0) .. " saved sessions.")
  elseif command == "text" or command:match("^text ") then
    local choice = command:match("^text%s+(.+)$")
    if choice == "extra large" then choice = "extra" end
    local ok = choice and style.SetPreset(choice) or (not choice and style.Cycle())
    if ok then print("Forever Wayfinder: Text size · " .. style.Name())
    else print("Forever Wayfinder: /fw text standard, large, or extra") end
  else
    print("Forever Wayfinder: /fw where, /fw chain, /fw journal, or /fw text")
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("QUEST_LOG_UPDATE")
loader:RegisterEvent("SPELLS_CHANGED")
loader:RegisterEvent("PLAYER_LEVEL_UP")
loader:RegisterEvent("ZONE_CHANGED_NEW_AREA")
local whereRefreshPending = false
loader:SetScript("OnEvent", function(_, event)
  if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
    tryInstall()
    tryInstallTracker()
  elseif panel and panel:IsShown() and panel.mode == "where" and not whereRefreshPending then
    whereRefreshPending = true
    C_Timer.After(0, function()
      whereRefreshPending = false
      if panel:IsShown() and panel.mode == "where" then showWhere(true) end
    end)
  end
end)
tryInstall()
tryInstallTracker()
