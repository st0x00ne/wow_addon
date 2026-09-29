-- Example-only gallery fixture. Runs the shipped UI with a mock WoW client.
-- It never reads player SavedVariables or changes the installed addon.
local root=assert(arg[1],"workspace path required")
local scene=assert(arg[2],"gallery scene required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
if arg[4] then mock.fontMetrics=assert(loadfile(arg[4]))() end
local addon=mock.load(root,true)
-- The general test double returns the current zone for every map. Gallery
-- links need each destination's real bundled name instead.
C_Map.GetMapInfo=function(mapID)
  for _,zone in ipairs(addon.Zones) do if zone[1]==mapID then return {name=zone[2]} end end
  return {name=mock.zone}
end
local j=addon.Journal
addon.ReadingStyle.SetPreset(arg[3] or "large")
local arya=mock.player
local function visit(map,zone,subzone)
  mock.clock=mock.clock+3600
  mock.mapID,mock.zone,mock.subzone=map,zone,subzone or ""
  j.VisitZone()
end
local function note(title,body,tags)
  mock.clock=mock.clock+600
  local entry=j.NewNote()
  j.SaveNote(entry.id,title,body,tags)
  return entry
end
-- Populate every currently supported entry type using the journal's own APIs.
mock.player={name="Borin",realm="Forever",guid="Player-1-Borin",class="WARRIOR",className="Warrior",race="Human",faction="Alliance",level=18}
visit(1436,"Westfall","Sentinel Hill")
note("The coast of Westfall","Walk south from Sentinel Hill and look for the lighthouse.","coast, exploration")
j.RecordLevel(18)
mock.player=arya
visit(1420,"Tirisfal Glades","Brill")
note("A road back to Brill","Keep the road in sight when returning from the woods.","travel, supplies")
visit(1421,"Silverpine Forest","The Sepulcher")
note("Silverpine field notes","Return after checking the quests in Hillsbrad. Follow the road from the Sepulcher.","silverpine, revisit")
mock.inside,mock.instanceType,mock.instanceName,mock.instanceID=true,"party","Wailing Caverns",43
visit(1413,"The Barrens","Wailing Caverns")
mock.inside,mock.instanceType,mock.instanceName,mock.instanceID=false,nil,nil,nil
visit(1424,"Hillsbrad Foothills","Tarren Mill")
local trail=note("The northern ridge","Return at level 25. Follow the ridge north of Tarren Mill and check the paths I skipped on my first visit.","ridge, revisit at 25")
j.Toggle(trail.id,"favorite"); j.Toggle(trail.id,"revisit")
j.RecordLevel(19)
mock.clock=mock.clock+600
mock.quests={{questID=496,title="Elixir of Suffering",level=22,
  objectiveText="Bring the ingredients to Apothecary Lydon in Tarren Mill.",
  description="Apothecary Lydon of Tarren Mill wants 10 Gray Bear Tongues and some Creeper Ichor."}}
mock.selected=496
local quest=j.RecordQuest(496,"observed",1)
j.Toggle(quest.id,"favorite")
mock.flush()
local function export(frame)
  assert(loadfile(root.."/tests/journal_preview_export.lua"))(mock,frame)
end
if scene=="chain-overview" or scene=="chain-details" then
  mock.player={name="Borin",realm="Forever",guid="Player-1-Borin",class="WARRIOR",className="Warrior",race="Human",faction="Alliance",level=18}
  mock.selected=65
  mock.quests={{questID=65,title="The Defias Brotherhood",level=18}}
  addon.ShowClassicChain(65)
  if scene=="chain-overview" then mock.click(ForeverWayfinderPanel.hideAll) end
  export(ForeverWayfinderPanel)
elseif scene=="where" or scene=="reading" then
  if scene=="where" then addon.ShowWhereNext() else addon.ShowClassicChain(496) end
  export(ForeverWayfinderPanel)
elseif scene=="badges" then
  -- This background is a schematic log; badges and footer buttons are the addon UI.
  function hooksecurefunc(name,callback)
    local old=_G[name]
    _G[name]=function(...) local result=old(...); callback(...); return result end
  end
  function QuestLogQuests_Update() end
  QuestMapFrame=CreateFrame("Frame","QuestMapFrame",UIParent,"BackdropTemplate")
  QuestMapFrame:SetSize(550,410)
  QuestMapFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
  QuestMapFrame:SetBackdropColor(.12,.08,.035,1)
  local title=QuestMapFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
  title:SetPoint("TOPLEFT",24,-20); title:SetSize(500,40); title:SetText("Quest log · example rows")
  title:SetFont(STANDARD_TEXT_FONT,26,""); title:SetTextColor(1,.82,.4)
  QuestMapFrame.DetailsFrame=CreateFrame("Frame",nil,QuestMapFrame)
  QuestMapFrame.DetailsFrame:Hide()
  QuestMapFrame.DetailsFrame.BackFrame=CreateFrame("Frame",nil,QuestMapFrame.DetailsFrame)
  QuestMapFrame.DetailsFrame.BackFrame.BackButton=CreateFrame("Button",nil,QuestMapFrame.DetailsFrame.BackFrame)
  local list=CreateFrame("Frame",nil,QuestMapFrame)
  list:SetPoint("TOPLEFT",20,-77); list:SetSize(510,310)
  QuestMapFrame.QuestsFrame=list
  local scroll=CreateFrame("ScrollFrame",nil,list)
  list.ScrollFrame=scroll; QuestScrollFrame=scroll
  local rows={}
  mock.dungeonQuest=914
  for i,data in ipairs({{496,"Elixir of Suffering","Known Classic quest"},{900001,"Example quest · new ID","Missing from the Classic reference"},{914,"Leaders of the Fang","Dungeon tag from the client"}}) do
    local row=CreateFrame("Button",nil,list,"BackdropTemplate")
    row:SetPoint("TOPLEFT",0,-(i-1)*82); row:SetSize(506,76); row.questID=data[1]
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.22,.14,.06,1)
    local label=row:CreateFontString(nil,"ARTWORK","GameFontNormal")
    label:SetPoint("TOPLEFT",12,-10); label:SetSize(400,25); label:SetText(data[2]); label:SetFont(STANDARD_TEXT_FONT,20,""); label:SetTextColor(1,.82,.4)
    local info=row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    info:SetPoint("TOPLEFT",12,-42); info:SetSize(400,24); info:SetText(data[3]); info:SetFont(STANDARD_TEXT_FONT,16,""); info:SetTextColor(.9,.8,.6)
    row.Checkbox=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.Checkbox:SetSize(24,24)
    rows[i]=row
  end
  QuestScrollFrame.titleFramePool={EnumerateActive=function()
    local i=0; return function() i=i+1; return rows[i] end
  end}
  mock.fire("ADDON_LOADED","Blizzard_QuestLog")
  assert(rows[2].foreverBadge:IsShown() and rows[3].dungeonBadge:IsShown())
  export(QuestMapFrame)
elseif scene=="minimap" then
  -- A diagram crop, not a captured game map.
  local rootFrame=CreateFrame("Frame",nil,UIParent); rootFrame:SetSize(260,230)
  Minimap.parent=rootFrame; Minimap:ClearAllPoints(); Minimap:SetPoint("TOPLEFT",60,-36)
  export(rootFrame)
else
  addon.ToggleJournal(); mock.flush()
  local book=assert(ForeverWayfinderJournalFrame)
  if scene=="search" then
    book.search:SetText("ridge"); mock.flush()
    mock.click(book.filters[2]); mock.click(book.menu.rows[2]) -- Mage
    mock.click(book.filters[1]) -- Show the real entry-type dropdown.
  elseif scene=="notes" then
    mock.click(book.views.favorite)
    for _,row in ipairs(book.rows) do if row.entry and row.entry.id==trail.id then mock.click(row); break end end
  else
    for _,row in ipairs(book.rows) do if row.entry and row.entry.questID==496 then mock.click(row); break end end
  end
  if book.scripts.OnUpdate then book.scripts.OnUpdate(book,.2) end
  export(book)
end
