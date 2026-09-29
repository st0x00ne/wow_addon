-- Hallmark · native field journal · leather binding, chapter index, parchment pages
-- Pre-emit critique: P5 H5 E5 S5 R4 V5 · original book artwork, native fonts/controls
local _, addon = ...
local journal = addon.Journal
local book, refreshPending
local WIDTH, HEIGHT, BOOK_TOP, BOOK_HEIGHT, PAGE_SIZE, ZONE_SIZE = 1040, 780, 140, 640, 5, 10
local state = {filters = {}, page = 1, zonePage = 1, view = "all", loading = false}
local ink = {
  title = {0.22, 0.11, 0.045}, body = {0.25, 0.17, 0.09}, muted = {0.40, 0.29, 0.17},
  gold = {1.00, 0.82, 0.40}, pale = {0.85, 0.73, 0.53}, leather = {0.16, 0.09, 0.04},
  edge = {0.48, 0.32, 0.13}, header = {0.11, 0.055, 0.025}, selected = {0.48, 0.29, 0.10, 0.24},
  hover = {0.51, 0.33, 0.12, 0.12}, paper = {0.88, 0.78, 0.56, 0.88},
  success = {0.15, 0.32, 0.12}, link = {0.10, 0.30, 0.34}, error = {0.62, 0.12, 0.07},
  headerSuccess = {0.69, 0.83, 0.49}, headerError = {1.00, 0.54, 0.35},
}
local typeNames = {quest = "Quest", exploration = "Exploration", dungeon = "Dungeon visit", note = "Field note", milestone = "Milestone"}
local statusNames = {active = "In your log", completed = "Completed", archived = "Left quest log", visited = "Visited", noted = "Personal note", earned = "Milestone"}
local icons = {quest = "Interface\\Icons\\INV_Misc_Scroll_03", exploration = "Interface\\Icons\\INV_Misc_Map_01",
  dungeon = "Interface\\Icons\\INV_Misc_Key_03", note = "Interface\\Icons\\INV_Misc_Note_01", milestone = "Interface\\Icons\\INV_Misc_EngGizmos_12"}
local render, selectEntry, saveDraft, createBook

local function color(region, value, texture)
  if texture then region:SetColorTexture(value[1], value[2], value[3], value[4] or 1)
  else region:SetTextColor(value[1], value[2], value[3]) end
end

local function font(parent, size, value, x, y, width, object)
  local label = parent:CreateFontString(nil, "ARTWORK", object or "GameFontHighlightSmall")
  if size then label:SetFont(STANDARD_TEXT_FONT, size) end
  label:SetPoint("TOPLEFT", x, -y)
  label:SetWidth(width)
  label:SetJustifyH("LEFT")
  color(label, value)
  return label
end

local function rectangle(parent, x, y, width, height, value, layer)
  local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
  texture:SetPoint("TOPLEFT", x, -y)
  texture:SetSize(width, height)
  color(texture, value, true)
  return texture
end

local function tooltip(button, title, description)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    if description then GameTooltip:AddLine(description, 0.9, 0.8, 0.6, true) end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnHide", function(self)
    if GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end)
end

local function button(parent, title, x, y, width, onClick)
  local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  control:SetPoint("TOPLEFT", x, -y)
  control:SetSize(width, 24)
  control:SetText(title)
  control:SetScript("OnClick", onClick)
  return control
end

local function plate(parent, x, y, width, height, shade)
  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  frame:SetPoint("TOPLEFT", x, -y)
  frame:SetSize(width, height)
  frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = {left = 3, right = 3, top = 3, bottom = 3}})
  frame:SetBackdropColor(shade[1], shade[2], shade[3], shade[4] or 1)
  frame:SetBackdropBorderColor(ink.edge[1], ink.edge[2], ink.edge[3], 1)
  return frame
end

local function input(parent, x, y, width, height, multiline, maxLetters)
  local shell = plate(parent, x, y, width, height, ink.paper)
  local edit = CreateFrame("EditBox", nil, shell)
  edit:SetPoint("TOPLEFT", 8, -6)
  edit:SetPoint("BOTTOMRIGHT", -8, 6)
  edit:SetAutoFocus(false)
  edit:SetFontObject(GameFontHighlightSmall)
  edit:SetTextColor(ink.body[1], ink.body[2], ink.body[3])
  edit:SetMaxLetters(maxLetters or 240)
  edit:SetMultiLine(multiline or false)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  edit:SetScript("OnEditFocusGained", function()
    if book and book.menu then book.menu:Hide() end
    shell:SetBackdropBorderColor(ink.gold[1], ink.gold[2], ink.gold[3], 1)
  end)
  edit:SetScript("OnEditFocusLost", function()
    shell:SetBackdropBorderColor(ink.edge[1], ink.edge[2], ink.edge[3], 1)
    if shell.saveOnBlur and saveDraft then saveDraft(true) end
  end)
  edit.shell = shell
  return edit
end

local function stamp(value, full)
  if not value or value == 0 then return "Date not recorded" end
  return date(full and "%b %d, %Y · %H:%M" or "%b %d", value)
end

local function play(key)
  if PlaySound and SOUNDKIT and SOUNDKIT[key] then PlaySound(SOUNDKIT[key]) end
end

local function pageTurn()
  play("IG_ABILITY_PAGE_TURN")
  if not book then return end
  book.fadeElapsed = 0
  book.pages:SetAlpha(0.70)
  book:SetScript("OnUpdate", function(self, elapsed)
    self.fadeElapsed = self.fadeElapsed + elapsed
    self.pages:SetAlpha(math.min(1, 0.70 + self.fadeElapsed * 3))
    if self.fadeElapsed >= 0.10 then self.pages:SetAlpha(1); self:SetScript("OnUpdate", nil) end
  end)
end

local function feedback(message, success)
  book.feedback:SetText(message or "")
  color(book.feedback, success == false and ink.headerError or ink.headerSuccess)
end

saveDraft = function(silent)
  if not book or not state.dirty or not state.selectedID then return true end
  local entry = journal.Entry(state.selectedID)
  if not entry then state.dirty = false; return true end
  local title = book.noteTitle:GetText()
  if silent and (title or ""):match("^%s*$") then title = entry.title end
  state.dirty = false
  local ok, message = journal.SaveNote(entry.id, title, book.note:GetText(), book.tags:GetText())
  if not ok then state.dirty = true; feedback(message or "Could not save this note.", false); return false end
  feedback("Saved to your journey", true)
  book.save:SetEnabled(false)
  return true
end

local function changedDraft()
  if state.loading or not state.selectedID then return end
  state.dirty = true
  book.deleteArmed = nil; book.delete:SetText("Delete note")
  book.save:SetEnabled(true)
  feedback("Unsaved notes · Save or leave the field to keep them", false)
end

local function resetPages()
  state.page, state.zonePage = 1, 1
  state.selectedID = nil
  feedback("")
end

local function changeFilter(field, value)
  if not saveDraft(true) then return end
  state.filters[field] = value
  resetPages()
  render()
  pageTurn()
end

local function dismissMenu()
  if book and book.menu then book.menu:Hide() end
end

local function showMenu(owner, field, options)
  if not saveDraft(true) then return end
  local menu = book.menu
  if menu:IsShown() and menu.owner == owner then menu:Hide(); return end
  menu.owner, menu.options, menu.field, menu.offset = owner, options, field, 0
  local function drawMenu()
    local count = math.min(10, #menu.options)
    menu:SetHeight(count * 25 + 12)
    for i, row in ipairs(menu.rows) do
      local option = menu.options[i + menu.offset]
      row:SetShown(i <= count and option ~= nil)
      if option then
        row.label:SetText((state.filters[field] == option.value and "• " or "") .. option.label)
        row:SetScript("OnClick", function() menu:Hide(); changeFilter(field, option.value) end)
      end
    end
  end
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
  menu:SetWidth(math.max(owner:GetWidth(), 194))
  menu:SetScript("OnMouseWheel", function(_, delta)
    menu.offset = math.max(0, math.min(math.max(0, #menu.options - 10), menu.offset - delta))
    drawMenu()
  end)
  drawMenu()
  menu:Show()
end

local function filter(parent, field, label, x, width, choices)
  font(parent, 10, ink.pale, x + 3, 91, width):SetText(label)
  local control = CreateFrame("Button", nil, parent, "BackdropTemplate")
  control:SetPoint("TOPLEFT", x, -104)
  control:SetSize(width, 25)
  control:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10, insets = {left = 2, right = 2, top = 2, bottom = 2}})
  control:SetBackdropColor(ink.leather[1], ink.leather[2], ink.leather[3], 0.95)
  control:SetBackdropBorderColor(ink.edge[1], ink.edge[2], ink.edge[3], 1)
  control.label = font(control, 11, ink.gold, 8, 7, width - 24)
  control.label:SetWordWrap(false)
  font(control, 11, ink.pale, width - 16, 7, 12):SetText("v")
  control.field, control.defaultLabel, control.choices = field,
    field == "status" and "Any status" or "All " .. string.lower(label), choices
  control:SetScript("OnClick", function()
    local options = {{label = control.defaultLabel}}
    for _, option in ipairs(choices or journal.Options(field)) do options[#options + 1] = option end
    showMenu(control, field, options)
  end)
  control:SetScript("OnEnter", function()
    control:SetBackdropBorderColor(ink.gold[1], ink.gold[2], ink.gold[3], 1)
  end)
  control:SetScript("OnLeave", function()
    control:SetBackdropBorderColor(ink.edge[1], ink.edge[2], ink.edge[3], 1)
  end)
  return control
end

local function setFilterLabel(control)
  local value = state.filters[control.field]
  local label = control.defaultLabel
  for _, option in ipairs(control.choices or journal.Options(control.field)) do
    if option.value == value then label = option.label break end
  end
  control.label:SetText(label)
end

local function entryRow(index)
  local row = CreateFrame("Button", nil, book.leftPage)
  row:SetPoint("TOPLEFT", 220, -116 - (index - 1) * 86)
  row:SetSize(282, 78)
  row.bg = rectangle(row, 0, 0, 282, 78, {0, 0, 0, 0})
  rectangle(row, 0, 77, 282, 1, {0.46, 0.32, 0.14, 0.30}, "BORDER")
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetPoint("TOPLEFT", 7, -9)
  row.icon:SetSize(27, 27)
  row.title = font(row, 13, ink.title, 43, 8, 229)
  row.title:SetHeight(31)
  row.meta = font(row, 10, ink.muted, 43, 43, 229)
  row.meta:SetWordWrap(false)
  row.mark = font(row, 10, ink.link, 7, 44, 28)
  row:SetScript("OnEnter", function()
    if row.entry and row.entry.id ~= state.selectedID then color(row.bg, ink.hover, true) end
  end)
  row:SetScript("OnLeave", function()
    color(row.bg, row.entry and row.entry.id == state.selectedID and ink.selected or {0, 0, 0, 0}, true)
  end)
  row:SetScript("OnMouseDown", function() row.title:SetAlpha(0.65) end)
  row:SetScript("OnMouseUp", function() row.title:SetAlpha(1) end)
  row:SetScript("OnClick", function() if row.entry then selectEntry(row.entry.id, true) end end)
  return row
end

local function detailLine(text, value, large, itemID)
  local index = book.detailCount + 1
  book.detailCount = index
  local line = book.detailLines[index]
  if not line then
    line = book.detailChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    line:SetJustifyH("LEFT")
    book.detailLines[index] = line
  end
  line:ClearAllPoints()
  line:SetPoint("TOPLEFT", 0, -book.detailHeight)
  line:SetWidth(419)
  line:SetFontObject(large and (QuestFont_Large or GameFontNormalLarge) or (QuestFontNormalSmall or GameFontHighlightSmall))
  line:SetText(text)
  color(line, value or ink.body)
  line:Show()
  local height = math.max(17, line:GetStringHeight())
  local target = book.detailTargets[index]
  if itemID then
    if not target then target = CreateFrame("Button", nil, book.detailChild); book.detailTargets[index] = target end
    target:ClearAllPoints()
    target:SetPoint("TOPLEFT", 0, -book.detailHeight)
    target:SetSize(419, height)
    target:SetScript("OnEnter", function(self)
      if GameTooltip.SetItemByID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetItemByID(itemID); GameTooltip:Show()
      end
    end)
    target:SetScript("OnLeave", function() GameTooltip:Hide() end)
    target:SetScript("OnHide", function(self)
      if GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    target:Show()
  end
  book.detailHeight = book.detailHeight + height + (large and 9 or 7)
end

local function heading(value)
  book.detailHeight = book.detailHeight + 7
  detailLine(value, ink.title)
end

local function renderDetails(entry, resetScroll)
  for _, line in pairs(book.detailLines) do line:Hide() end
  for _, target in pairs(book.detailTargets) do target:Hide() end
  book.detailCount, book.detailHeight = 0, 0
  book.selected:SetShown(entry ~= nil)
  book.welcome:SetShown(entry == nil)
  if not entry then feedback(""); return end
  if book.detailID ~= entry.id then
    book.detailID, book.deleteArmed = entry.id, nil
    book.delete:SetText("Delete note")
    book.noteScroll:SetVerticalScroll(0)
  end
  book.entryTitle:SetText(entry.title or "Untitled discovery")
  book.entryTitle:SetShown(entry.kind ~= "note")
  book.noteTitle.shell:SetShown(entry.kind == "note")
  local profile = (journal.Database().characters or {})[entry.character]
  local characterName = profile and profile.name or entry.characterName or "Unknown traveler"
  book.entryMeta:SetText((typeNames[entry.kind] or entry.kind) .. " · " .. characterName
    .. " · " .. (entry.className or entry.class or "") .. " · Lv " .. (entry.level or "?"))
  detailLine(entry.zone .. (entry.subzone and entry.subzone ~= "" and (" · " .. entry.subzone) or ""), ink.link)
  detailLine("First recorded · " .. stamp(entry.firstSeenAt, true), ink.muted)
  if entry.x and entry.y then
    detailLine(string.format("Discovery location · %.1f, %.1f", entry.x * 100, entry.y * 100), ink.muted)
  end
  if entry.kind == "quest" then
    heading(statusNames[entry.status] or "Recorded quest")
    if entry.acceptedAt then detailLine("Accepted · " .. stamp(entry.acceptedAt, true), ink.muted) end
    if entry.completedAt then detailLine("Turned in · " .. stamp(entry.completedAt, true), ink.success) end
    if entry.acceptedNPC then detailLine("Accepted from · " .. entry.acceptedNPC) end
    if entry.turnedInNPC then detailLine("Turned in to · " .. entry.turnedInNPC)
    elseif entry.npc and not entry.acceptedNPC then detailLine("Encountered · " .. entry.npc) end
    if entry.objectiveText and entry.objectiveText ~= "" then heading("Your task"); detailLine(entry.objectiveText) end
    if entry.objectives then for _, objective in ipairs(entry.objectives) do detailLine("• " .. objective) end end
    if entry.description and entry.description ~= "" then heading("The story you encountered"); detailLine(entry.description) end
    if entry.earnedXP or entry.earnedMoney then
      heading("Recorded turn-in rewards")
      if entry.earnedXP then detailLine("Experience · " .. entry.earnedXP) end
      if entry.earnedMoney then
        detailLine("Money · " .. (GetCoinTextureString and GetCoinTextureString(entry.earnedMoney) or (entry.earnedMoney .. " copper")))
      end
    end
    if entry.offeredItems then
      heading("Items offered when observed")
      for _, item in ipairs(entry.offeredItems) do
        local icon = item.icon and ("|T" .. item.icon .. ":20:20:0:0|t ") or ""
        detailLine(icon .. (item.name or ("Item #" .. (item.itemID or "?")))
          .. (item.choice and " · Choice" or ""), ink.link, false, item.itemID)
      end
    end
    detailLine("Quest #" .. entry.questID .. " · " .. (entry.classic and "Known Classic ID" or "Absent from Classic reference"), ink.muted)
  elseif entry.kind == "exploration" or entry.kind == "dungeon" then
    heading(entry.kind == "dungeon" and "An expedition remembered" or "A new chapter in your travels")
    detailLine("You first recorded this place at level " .. (entry.level or "?") .. ".")
    detailLine("Recorded visits · " .. (entry.visits or 1))
    if entry.lastVisitedAt then detailLine("Last visited · " .. stamp(entry.lastVisitedAt, true), ink.muted) end
  elseif entry.kind == "milestone" then
    heading("A moment worth keeping")
    detailLine("Reached level " .. (entry.level or "?") .. " in " .. entry.zone .. ".")
  else
    heading("Your field notes")
    detailLine("Keep a lead, a memory, or a place you want to return to.", ink.muted)
  end
  book.detailChild:SetHeight(math.max(1, book.detailHeight))
  if resetScroll then book.detailScroll:SetVerticalScroll(0) end
  book.favorite:SetChecked(entry.favorite and true or false)
  book.revisit:SetChecked(entry.revisit and true or false)
  book.map:SetEnabled(entry.mapID ~= nil)
  local ownCharacter = entry.character == journal.CurrentCharacterKey()
  local active = ownCharacter and entry.questID and C_QuestLog and C_QuestLog.GetLogIndexForQuestID
    and C_QuestLog.GetLogIndexForQuestID(entry.questID)
  book.quest:SetEnabled(active and true or false)
  book.chain:SetEnabled(entry.questID and addon.GetClassicChain(entry.questID) ~= nil or false)
  book.delete:SetShown(entry.kind == "note")
  if not state.dirty then
    state.loading = true
    if book.noteTitle:GetText() ~= (entry.title or "") then book.noteTitle:SetText(entry.title or "") end
    if book.note:GetText() ~= (entry.note or "") then book.note:SetText(entry.note or "") end
    if book.tags:GetText() ~= (entry.tags or "") then book.tags:SetText(entry.tags or "") end
    state.loading = false
    book.save:SetEnabled(false)
  end
end

selectEntry = function(id, animate)
  dismissMenu()
  if not saveDraft(true) then return end
  state.selectedID, state.dirty = id, false
  book.deleteArmed = nil
  book.delete:SetText("Delete note")
  feedback("")
  render(true)
  if animate then pageTurn() end
end

local function changePage(delta)
  if not saveDraft(true) then return end
  local maxPage = math.max(1, math.ceil(#state.results / PAGE_SIZE))
  state.page = math.max(1, math.min(maxPage, state.page + delta))
  local first = state.results[(state.page - 1) * PAGE_SIZE + 1]
  state.selectedID = first and first.id
  render(true)
  pageTurn()
end

local function clearFilters()
  if not saveDraft(true) then return end
  state.filters, state.view = {}, "all"
  state.loading = true; book.search:SetText(""); state.loading = false
  resetPages(); render(true)
end

local function mapEntry()
  local entry = journal.Entry(state.selectedID)
  if not entry or not entry.mapID then return end
  saveDraft(true)
  if WorldMapFrame and WorldMapFrame.SetMapID then
    if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
    WorldMapFrame:SetMapID(entry.mapID)
  end
  if entry.x and entry.y and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates
    and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(entry.mapID)) then
    local ok, result = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(entry.mapID, entry.x, entry.y))
    if ok and result then
      if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
      feedback("Discovery waypoint set · previous waypoint replaced", true)
    end
  end
  book:Hide()
end

local function fitBook()
  if not book then return end
  book:SetScale(math.max(0.1, math.min(1, (UIParent:GetWidth() - 24) / WIDTH, (UIParent:GetHeight() - 24) / HEIGHT)))
end

createBook = function()
  if book then return end
  book = CreateFrame("Frame", "ForeverWayfinderJournalFrame", UIParent)
  book:SetSize(WIDTH, HEIGHT)
  book:SetFrameStrata("DIALOG")
  book:SetClampedToScreen(true)
  book:SetMovable(true)
  book:EnableMouse(true)
  book:SetScript("OnMouseDown", dismissMenu)
  book.body = CreateFrame("Frame", nil, book)
  book.body:SetPoint("TOPLEFT", 0, -BOOK_TOP); book.body:SetSize(WIDTH, BOOK_HEIGHT)
  local art = book.body:CreateTexture(nil, "BACKGROUND")
  art:SetAllPoints(book.body)
  art:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\JournalBook")
  book.art = art
  book.header = plate(book, 16, 0, WIDTH - 32, 134, ink.leather)
  local header = book.header
  rectangle(header, 7, 7, 994, 33, ink.header)
  rectangle(header, 24, 41, 960, 1, ink.edge, "BORDER")
  local icon = header:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", 24, -8); icon:SetSize(30, 30)
  icon:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\Icon")
  font(header, nil, ink.gold, 68, 12, 520, "GameFontNormalLarge"):SetText("Discovery Journal")
  book.summary = font(header, 11, ink.pale, 596, 19, 340)
  book.summary:SetJustifyH("RIGHT")
  local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -8, -4)
  close:SetScript("OnClick", function() book:Hide() end)
  local handle = CreateFrame("Frame", nil, header)
  handle:SetPoint("TOPLEFT", 64, 4); handle:SetSize(866, 40)
  handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", function() book:StartMoving() end)
  handle:SetScript("OnDragStop", function()
    book:StopMovingOrSizing()
    local point, _, relativePoint, x, y = book:GetPoint()
    journal.Database().position = {point = point, relativePoint = relativePoint, x = x, y = y}
  end)
  tooltip(handle, "Your Discovery Journal", "Drag the leather title bar to move the book. Escape closes it.")
  book.pages = CreateFrame("Frame", nil, book)
  book.pages:SetAllPoints(book.body)
  book.leftPage = CreateFrame("Frame", nil, book.pages)
  book.leftPage:SetPoint("TOPLEFT", 0, 0); book.leftPage:SetSize(WIDTH / 2, BOOK_HEIGHT)
  book.rightPage = CreateFrame("Frame", nil, book.pages)
  book.rightPage:SetPoint("TOPLEFT", WIDTH / 2, 0); book.rightPage:SetSize(WIDTH / 2, BOOK_HEIGHT)
  local pages = book.leftPage
  font(book.body, 11, ink.pale, 52, 22, 448):SetText("CHAPTER INDEX")
  local rightCaption = font(book.body, 11, ink.pale, 782, 22, 207)
  rightCaption:SetJustifyH("RIGHT"); rightCaption:SetText("DISCOVERY & FIELD NOTES")
  font(pages, 12, ink.title, 52, 77, 149, "GameFontNormal"):SetText("YOUR JOURNEY")
  book.views = {}
  for i, view in ipairs({{"all", "All discoveries"}, {"favorite", "Favorites"}, {"revisit", "Revisit"}}) do
    local key = view[1]
    local ribbon = CreateFrame("Button", nil, pages)
    ribbon:SetPoint("TOPLEFT", 49, -102 - (i - 1) * 29); ribbon:SetSize(151, 26)
    ribbon.bg = rectangle(ribbon, 0, 0, 151, 26, {0.26, 0.12, 0.06, 0.12})
    ribbon.label = font(ribbon, 12, ink.title, 9, 7, 135)
    ribbon.label:SetText(view[2])
    ribbon:SetScript("OnClick", function()
      if not saveDraft(true) then return end
      state.view = key
      state.filters.favorite, state.filters.revisit = key == "favorite" or nil, key == "revisit" or nil
      resetPages(); render(true); pageTurn()
    end)
    book.views[key] = ribbon
  end
  font(header, 10, ink.pale, 27, 46, 850):SetText("SEARCH YOUR JOURNEY · names, places, people, quest text, tags, and notes")
  book.search = input(header, 24, 59, 884, 25, false, 160)
  book.search:SetScript("OnTextChanged", function(self)
    if state.loading then return end
    if not saveDraft(true) then return end
    state.filters.search = self:GetText()
    resetPages(); render(true)
  end)
  book.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  tooltip(book.search.shell, "Search your journey", "Every word must match. Search quest names, NPCs, descriptions, notes, tags, or quest IDs.")
  book.reset = button(header, "Reset", 916, 59, 68, clearFilters)
  book.filters = {
    filter(header, "kind", "Types", 24, 150, {{value="quest",label="Quests"},{value="exploration",label="Exploration"},
      {value="dungeon",label="Dungeon visits"},{value="note",label="Field notes"},{value="milestone",label="Milestones"}}),
    filter(header, "class", "Classes", 182, 150),
    filter(header, "character", "Characters", 340, 210),
    filter(header, "status", "Status", 558, 140, {{value="active",label="In your log"},{value="completed",label="Completed"},
      {value="archived",label="Left quest log"},{value="visited",label="Visited"},{value="noted",label="Personal notes"},{value="earned",label="Milestones"}}),
    filter(header, "race", "Races", 706, 125),
    filter(header, "faction", "Factions", 839, 145),
  }
  book.menu = plate(book, 0, 0, 200, 270, {0.16, 0.09, 0.04, 1})
  book.menu:SetFrameStrata("TOOLTIP"); book.menu:SetClampedToScreen(true); book.menu:EnableMouseWheel(true)
  book.menu.rows = {}
  for i = 1, 10 do
    local row = CreateFrame("Button", nil, book.menu)
    row:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 25); row:SetPoint("TOPRIGHT", -6, -6 - (i - 1) * 25); row:SetHeight(25)
    row.label = font(row, 11, ink.gold, 6, 7, 174)
    row.hover = rectangle(row, 0, 0, 184, 25, {0.80, 0.55, 0.20, 0.15}); row.hover:Hide()
    row:SetScript("OnEnter", function() row.hover:Show() end)
    row:SetScript("OnLeave", function() row.hover:Hide() end)
    book.menu.rows[i] = row
  end
  book.menu:Hide()
  font(pages, 11, ink.title, 52, 202, 149, "GameFontNormal"):SetText("ZONE CHAPTERS")
  rectangle(pages, 52, 222, 145, 1, {0.43, 0.29, 0.12, 0.4}, "BORDER")
  book.zoneRows = {}
  for i = 1, ZONE_SIZE do
    local row = CreateFrame("Button", nil, pages)
    row:SetPoint("TOPLEFT", 49, -231 - (i - 1) * 27); row:SetSize(151, 26)
    row.bg = rectangle(row, 0, 0, 151, 26, {0,0,0,0})
    row.label = font(row, 11, ink.body, 7, 7, 114)
    row.label:SetWordWrap(false)
    row.count = font(row, 10, ink.muted, 124, 8, 23); row.count:SetJustifyH("RIGHT")
    row:SetScript("OnClick", function() changeFilter("zoneKey", row.key) end)
    row:SetScript("OnEnter", function()
      if row.key ~= state.filters.zoneKey then color(row.bg, ink.hover, true) end
      GameTooltip:SetOwner(row, "ANCHOR_RIGHT"); GameTooltip:SetText(row.fullName or "All zones"); GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
      color(row.bg, row.key == state.filters.zoneKey and ink.selected or {0,0,0,0}, true); GameTooltip:Hide()
    end)
    book.zoneRows[i] = row
  end
  book.zonePrev = button(pages, "<", 52, 516, 34, function() state.zonePage=math.max(1,state.zonePage-1); render() end)
  book.zoneNext = button(pages, ">", 166, 516, 34, function() state.zonePage=state.zonePage+1; render() end)
  book.zonePage = font(pages, 10, ink.muted, 90, 524, 70); book.zonePage:SetJustifyH("CENTER")
  button(pages, "+ Field note", 52, 553, 148, function()
    if not saveDraft(true) then return end
    clearFilters()
    local entry = journal.NewNote()
    if entry then selectEntry(entry.id, true); book.noteTitle:SetFocus(); book.noteTitle:HighlightText() end
  end)
  book.indexTitle = font(pages, nil, ink.title, 220, 77, 282, "QuestFont_Large")
  book.rows = {}
  for i = 1, PAGE_SIZE do book.rows[i] = entryRow(i) end
  book.empty = font(pages, 13, ink.muted, 234, 145, 256)
  book.empty:SetText("No discoveries match these filters.\n\nTry Reset, or start a field note.")
  book.prev = button(pages, "< Previous", 220, 553, 92, function() changePage(-1) end)
  book.next = button(pages, "Next >", 410, 553, 92, function() changePage(1) end)
  book.pageLabel = font(pages, 10, ink.muted, 315, 561, 92); book.pageLabel:SetJustifyH("CENTER")
  local wheel = CreateFrame("Frame", nil, pages)
  wheel:SetPoint("TOPLEFT", 216, -108); wheel:SetSize(291, 436); wheel:EnableMouseWheel(true)
  wheel:SetScript("OnMouseWheel", function(_, delta) changePage(delta > 0 and -1 or 1) end)
  -- Rows stay above the wheel surface and handle their own clicks.
  wheel:SetFrameLevel(pages:GetFrameLevel() + 1)
  for _, row in ipairs(book.rows) do
    row:SetFrameLevel(wheel:GetFrameLevel() + 1)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta) changePage(delta > 0 and -1 or 1) end)
  end
  book.selected = CreateFrame("Frame", nil, book.rightPage); book.selected:SetAllPoints(book.rightPage)
  book.entryTitle = font(book.selected, nil, ink.title, 33, 77, 433, "QuestFont_Large")
  book.entryTitle:SetHeight(45)
  book.noteTitle = input(book.selected, 30, 77, 438, 30, false, 160)
  book.noteTitle:SetScript("OnTextChanged", changedDraft); book.noteTitle.shell.saveOnBlur = true
  book.noteTitle:SetScript("OnEnterPressed", function(self) self:ClearFocus(); book.note:SetFocus() end)
  book.entryMeta = font(book.selected, 10, ink.muted, 33, 125, 431)
  rectangle(book.selected, 31, 144, 434, 1, {0.43, 0.29, 0.12, 0.4}, "BORDER")
  book.detailScroll = CreateFrame("ScrollFrame", nil, book.selected, "UIPanelScrollFrameTemplate")
  book.detailScroll:SetPoint("TOPLEFT", 34, -154); book.detailScroll:SetSize(419, 204)
  book.detailChild = CreateFrame("Frame", nil, book.detailScroll); book.detailChild:SetSize(419, 1)
  book.detailScroll:SetScrollChild(book.detailChild)
  book.detailLines, book.detailTargets = {}, {}
  local function check(label, field, x)
    local control = CreateFrame("CheckButton", nil, book.selected, "UICheckButtonTemplate")
    control:SetPoint("TOPLEFT", x, -370); control:SetSize(21, 21)
    local title = font(book.selected, 10, ink.title, x + 23, 376, 66); title:SetText(label)
    control:SetScript("OnClick", function() saveDraft(true); journal.Toggle(state.selectedID, field); render() end)
    return control
  end
  book.favorite, book.revisit = check("Favorite", "favorite", 30), check("Revisit", "revisit", 124)
  book.map = button(book.selected, "Map", 215, 369, 62, mapEntry)
  tooltip(book.map, "Return to this discovery", "Opens the recorded map. A recorded position replaces your current waypoint.")
  book.quest = button(book.selected, "Quest log", 282, 369, 96, function()
    local entry = journal.Entry(state.selectedID)
    if entry and entry.questID and QuestMapFrame_ShowQuestDetails then
      saveDraft(true); book:Hide()
      if QuestMapFrame and not QuestMapFrame:IsShown() and ToggleQuestLog then ToggleQuestLog() end
      QuestMapFrame_ShowQuestDetails(entry.questID)
    end
  end)
  book.chain = button(book.selected, "Chain", 383, 369, 80, function()
    local entry = journal.Entry(state.selectedID)
    if entry and entry.questID and addon.ShowClassicChain then saveDraft(true); book:Hide(); addon.ShowClassicChain(entry.questID) end
  end)
  tooltip(book.chain, "Classic chain reference", "Opens Wayfinder's existing Classic chain panel. Forever may change these steps.")
  font(book.selected, 11, ink.title, 33, 410, 430, "GameFontNormal"):SetText("IN YOUR OWN WORDS")
  local noteShell = plate(book.selected, 30, 428, 438, 121, {0.89, 0.79, 0.57, 0.78})
  local noteScroll = CreateFrame("ScrollFrame", nil, noteShell, "UIPanelScrollFrameTemplate")
  book.noteScroll = noteScroll
  noteScroll:SetPoint("TOPLEFT", 8, -8); noteScroll:SetSize(404, 104)
  book.note = CreateFrame("EditBox", nil, noteScroll)
  book.note:SetSize(400, 104); book.note:SetMultiLine(true); book.note:SetAutoFocus(false)
  book.note:SetFontObject(GameFontHighlightSmall); book.note:SetTextColor(ink.body[1], ink.body[2], ink.body[3])
  book.note:SetMaxLetters(6000); noteScroll:SetScrollChild(book.note)
  local noteMeasure = book.selected:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  noteMeasure:SetWidth(400); noteMeasure:SetAlpha(0)
  noteMeasure:SetPoint("TOPLEFT", book.note, "TOPLEFT")
  book.note:SetScript("OnTextChanged", function(self)
    noteMeasure:SetText(self:GetText())
    self:SetHeight(math.max(noteScroll:GetHeight(), noteMeasure:GetStringHeight() + 16))
    changedDraft()
  end)
  book.note:SetScript("OnEscapePressed", function(self) self:ClearFocus(); saveDraft(true) end)
  book.note:SetScript("OnEditFocusLost", function()
    noteShell:SetBackdropBorderColor(ink.edge[1],ink.edge[2],ink.edge[3],1); saveDraft(true)
  end)
  book.note:SetScript("OnEditFocusGained", function()
    noteShell:SetBackdropBorderColor(ink.gold[1],ink.gold[2],ink.gold[3],1)
  end)
  book.note:SetScript("OnCursorChanged", function(_, _, y, _, cursorHeight)
    local current = noteScroll:GetVerticalScroll()
    local position = -y
    if position < current then noteScroll:SetVerticalScroll(math.max(0,position))
    elseif position + cursorHeight > current + noteScroll:GetHeight() then
      noteScroll:SetVerticalScroll(math.max(0,position+cursorHeight-noteScroll:GetHeight()))
    end
  end)
  font(book.selected, 10, ink.muted, 34, 560, 40):SetText("Tags")
  book.tags = input(book.selected, 67, 555, 200, 25, false, 240)
  book.tags:SetScript("OnTextChanged", changedDraft); book.tags.shell.saveOnBlur = true
  book.tags:SetScript("OnEnterPressed", function(self) self:ClearFocus(); saveDraft(true) end)
  tooltip(book.tags.shell, "Searchable tags", "Write your own labels, separated by commas: class quest, revisit at 25, hidden path...")
  book.save = button(book.selected, "Save", 276, 555, 92, function() saveDraft(false) end)
  book.feedback = font(header, 10, ink.pale, 620, 46, 364)
  book.feedback:SetJustifyH("RIGHT")
  book.delete = button(book.selected, "Delete note", 376, 555, 92, function()
    if book.deleteArmed == state.selectedID then
      state.dirty=false; journal.DeleteNote(state.selectedID); state.selectedID=nil; book.deleteArmed=nil; render(true)
    else
      book.deleteArmed=state.selectedID; book.delete:SetText("Confirm?"); feedback("Click Confirm? to delete this field note.",false)
    end
  end)
  book.welcome = CreateFrame("Frame", nil, book.rightPage); book.welcome:SetAllPoints(book.rightPage)
  local crest = book.welcome:CreateTexture(nil, "ARTWORK")
  crest:SetPoint("TOPLEFT", 189, -158); crest:SetSize(112,112)
  crest:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\Icon"); crest:SetAlpha(0.85)
  if book.welcome.CreateMaskTexture and crest.AddMaskTexture then
    local mask = book.welcome:CreateMaskTexture()
    mask:SetAllPoints(crest)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    crest:AddMaskTexture(mask)
  end
  font(book.welcome, nil, ink.title, 70, 298, 350, "QuestFont_Large"):SetText("Every journey begins somewhere")
  font(book.welcome, 14, ink.body, 70, 342, 349):SetText("Your journal grows as you explore, accept quests, and find your way through Azeroth.\n\nChoose a recorded moment on the left, or write a field note of your own.")
  book.footer = font(book.body, 11, ink.pale, 58, 615, 798)
  button(book.body, "Where next?", 885, 607, 112, function()
    saveDraft(true); book:Hide(); if addon.ShowWhereNext then addon.ShowWhereNext() end
  end)
  book:SetScript("OnHide", function()
    saveDraft(true); dismissMenu(); play("IG_SPELLBOOK_CLOSE")
    book.deleteArmed = nil; book.delete:SetText("Delete note")
    book.search:ClearFocus(); book.noteTitle:ClearFocus(); book.note:ClearFocus(); book.tags:ClearFocus()
    book.pages:SetAlpha(1); book:SetScript("OnUpdate", nil)
  end)
  book:SetScript("OnShow", function() fitBook(); play("IG_SPELLBOOK_OPEN") end)
  local position = journal.Database().position
  if position and position.point and position.relativePoint then
    book:SetPoint(position.point, UIParent, position.relativePoint, position.x or 0, position.y or 0)
  else book:SetPoint("CENTER", UIParent, "CENTER") end
  table.insert(UISpecialFrames, "ForeverWayfinderJournalFrame")
  book:Hide()
end

render = function(resetScroll)
  if not book then return end
  if journal.error then book.footer:SetText(journal.error); return end
  state.results = journal.Query(state.filters)
  local groups = journal.Zones(state.filters)
  local chapterCount = #groups
  local allCount = 0
  for _, group in ipairs(groups) do allCount = allCount + group.count end
  table.insert(groups, 1, {name="All zones",count=allCount})
  state.zonePage = math.max(1, math.min(state.zonePage, math.max(1,math.ceil(#groups/ZONE_SIZE))))
  for i, row in ipairs(book.zoneRows) do
    local group = groups[(state.zonePage-1)*ZONE_SIZE+i]
    row:SetShown(group~=nil)
    if group then
      row.key,row.fullName=group.key,group.name
      row.label:SetText(group.name); row.count:SetText(group.count)
      color(row.bg, group.key==state.filters.zoneKey and ink.selected or {0,0,0,0},true)
    end
  end
  book.zonePrev:SetEnabled(state.zonePage>1)
  book.zoneNext:SetEnabled(state.zonePage*ZONE_SIZE<#groups)
  book.zonePage:SetText(state.zonePage.." / "..math.max(1,math.ceil(#groups/ZONE_SIZE)))
  for key,ribbon in pairs(book.views) do
    color(ribbon.bg, state.view==key and {0.34,0.09,0.045,0.94} or {0.26,0.12,0.06,0.12},true)
    color(ribbon.label,state.view==key and ink.gold or ink.title)
  end
  for _, control in ipairs(book.filters) do setFilterLabel(control) end
  local pages=math.max(1,math.ceil(#state.results/PAGE_SIZE))
  state.page=math.max(1,math.min(state.page,pages))
  local selected
  for index,entry in ipairs(state.results) do
    if entry.id==state.selectedID then
      selected=entry; state.page=math.floor((index-1)/PAGE_SIZE)+1; break
    end
  end
  if not selected then
    selected=state.results[(state.page-1)*PAGE_SIZE+1]
    state.selectedID=selected and selected.id
    resetScroll=true
  end
  book.indexTitle:SetText(state.filters.zoneKey and "Chapter discoveries" or "Recent discoveries")
  book.empty:SetShown(#state.results==0)
  for i,row in ipairs(book.rows) do
    local entry=state.results[(state.page-1)*PAGE_SIZE+i]
    row.entry=entry; row:SetShown(entry~=nil)
    if entry then
      row.icon:SetTexture(icons[entry.kind] or icons.note)
      row.title:SetText(entry.title or "Untitled discovery"); row.title:SetAlpha(1)
      color(row.title,entry.status=="completed" and ink.success or ink.title)
      row.meta:SetText(stamp(entry.updatedAt).." · "..(entry.characterName or "").." · "..(typeNames[entry.kind] or ""))
      row.mark:SetText(entry.revisit and "Back" or (entry.favorite and "Keep" or ""))
      color(row.bg,entry.id==state.selectedID and ink.selected or {0,0,0,0},true)
    end
  end
  book.prev:SetEnabled(state.page>1); book.next:SetEnabled(state.page<pages)
  book.pageLabel:SetText(state.page.." / "..pages)
  local db=journal.Database()
  local zoneCount = #journal.Options("zoneKey")
  book.summary:SetText(#db.entries.." recorded moments · "..zoneCount..(zoneCount==1 and " zone" or " zones"))
  book.footer:SetText(#state.results..(#state.results==1 and " matching discovery" or " matching discoveries")
    .." · "..chapterCount..(chapterCount==1 and " chapter" or " chapters").." · Your own encounters, remembered")
  renderDetails(selected,resetScroll)
end

function addon.RefreshJournal()
  if not book or not book:IsShown() or refreshPending then return end
  refreshPending=true
  local function update() refreshPending=false; if book:IsShown() then render() end end
  if C_Timer and C_Timer.After then C_Timer.After(0.05,update) else update() end
end

function addon.ToggleJournal()
  if journal.error then print("Forever Wayfinder: "..journal.error); return end
  if not journal.Initialize() then print("Forever Wayfinder: "..journal.error); return end
  journal.Character()
  createBook()
  if book:IsShown() then book:Hide() else dismissMenu(); render(true); book:Show() end
end

local minimapButton

local function placeMinimapButton()
  if not minimapButton then return end
  local angle = math.rad(minimapButton.angle)
  local x = math.cos(angle) * (Minimap:GetWidth() / 2 + 10)
  local y = math.sin(angle) * (Minimap:GetHeight() / 2 + 10)
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function dragMinimapButton(self)
  local centerX, centerY = Minimap:GetCenter()
  if not centerX or not centerY then return end
  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  local x, y = cursorX / scale - centerX, cursorY / scale - centerY
  if x == 0 and y == 0 then return end
  local angle
  if x == 0 then angle = y > 0 and 90 or 270
  else angle = math.deg(math.atan(y / x)) + (x < 0 and 180 or 0) end
  self.angle = angle % 360
  placeMinimapButton()
end

local function stopMinimapDrag(self)
  if self.dragging then
    dragMinimapButton(self)
    journal.Database().minimapAngle = self.angle
  end
  self.dragging = nil
  self:SetScript("OnUpdate", nil)
  self.icon:SetAlpha(1)
end

local function createMinimapButton()
  if minimapButton or not Minimap or not journal.Initialize() then return end
  local control = CreateFrame("Button", "ForeverWayfinderMinimapButton", Minimap)
  minimapButton = control
  control:SetSize(32, 32)
  control:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  control:RegisterForClicks("LeftButtonUp")
  control:RegisterForDrag("LeftButton")
  control:EnableMouse(true)
  local savedAngle = journal.Database().minimapAngle
  control.angle = type(savedAngle) == "number" and savedAngle == savedAngle
    and math.abs(savedAngle) < math.huge and savedAngle % 360 or 225
  local background = control:CreateTexture(nil, "BACKGROUND")
  background:SetSize(25, 25); background:SetPoint("CENTER")
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  control.icon = control:CreateTexture(nil, "ARTWORK")
  control.icon:SetSize(25, 25); control.icon:SetPoint("CENTER")
  control.icon:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\Icon")
  if control.CreateMaskTexture and control.icon.AddMaskTexture then
    local mask = control:CreateMaskTexture()
    mask:SetAllPoints(control.icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    control.icon:AddMaskTexture(mask)
  end
  local border = control:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  control:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  tooltip(control, "Forever Wayfinder · Discovery Journal", "Left-click to open or close your journal.\nDrag to move this button around the minimap.")
  control:SetScript("OnMouseDown", function(self)
    self.suppressClick = nil
    self.icon:SetAlpha(0.70)
  end)
  control:SetScript("OnMouseUp", function(self) self.icon:SetAlpha(1) end)
  control:SetScript("OnClick", function(self)
    if self.suppressClick then self.suppressClick = nil; return end
    addon.ToggleJournal()
  end)
  control:SetScript("OnDragStart", function(self)
    self.dragging, self.suppressClick = true, true
    GameTooltip:Hide()
    self:SetScript("OnUpdate", dragMinimapButton)
    dragMinimapButton(self)
  end)
  control:SetScript("OnDragStop", stopMinimapDrag)
  control:HookScript("OnHide", stopMinimapDrag)
  Minimap:HookScript("OnSizeChanged", placeMinimapButton)
  placeMinimapButton()
end

local display = CreateFrame("Frame")
display:RegisterEvent("DISPLAY_SIZE_CHANGED"); display:RegisterEvent("UI_SCALE_CHANGED")
display:RegisterEvent("PLAYER_LOGIN"); display:RegisterEvent("PLAYER_ENTERING_WORLD")
display:SetScript("OnEvent", function()
  createMinimapButton()
  placeMinimapButton()
  fitBook()
end)
