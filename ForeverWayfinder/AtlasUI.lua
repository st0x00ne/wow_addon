-- Hallmark: illustrated zone overview and live quest chapters.
-- Pre-emit critique: P5 H5 E5 S5 R4 V5.
local _, addon = ...
local atlas, style = addon.Atlas, addon.ReadingStyle
local unpack = unpack or table.unpack
local frame, refreshPending, render
local WIDTH, HEIGHT, ZONE_ROWS, QUEST_ROWS = 1280, 850, 10, 8
local L, LW, C, CW, R, RW, BOTTOM = 72, 244, 372, 532, 964, 238, 746
local media = "Interface\\AddOns\\ForeverWayfinder\\Media\\"
local colors = {
  gold = {1,.82,.43}, ivory = {.96,.91,.80}, muted = {.77,.76,.69},
  green = {.57,.84,.57}, blue = {.56,.80,.96}, edge = {.51,.39,.22,1},
  leather = {.055,.075,.082,.95}, hover = {.16,.19,.19,1}, selected = {.28,.21,.10,1},
  selectedRow = {.56,.38,.13,.30}, row = {.17,.20,.21,.28}, rowAlt = {.17,.20,.21,.12},
  track = {.025,.045,.05,1}, fill = {.87,.61,.16,1}, gleam = {1,.85,.40,.65},
  shadow = {.02,.03,.04,.50},
}
local roles = {body="atlasBody",meta="atlasMeta",label="atlasLabel",control="atlasControl"}
local state = {continent="Kalimdor",zonePage=1,rowPage=1,view="zones",catalog="classic"}
local zoneNames, zoneMeta = {}, {}
for _, zone in ipairs(addon.Zones) do zoneNames[zone[1]], zoneMeta[zone[1]] = zone[2], zone end

local function paint(region, shade, texture)
  if texture then region:SetColorTexture(unpack(shade))
  else region:SetTextColor(shade[1],shade[2],shade[3]) end
end
local function label(parent,x,y,width,role,shade,value)
  local item=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
  item:SetPoint("TOPLEFT",x,-y); item:SetWidth(width); item:SetJustifyH("LEFT")
  style.Font(item,roles[role] or role); paint(item,shade); item:SetText(value or "")
  return item
end
local function position(item,x,y)
  item:ClearAllPoints(); item:SetPoint("TOPLEFT",x,-y)
end
local function rectangle(parent,x,y,width,height,shade,layer)
  local item=parent:CreateTexture(nil,layer or "BACKGROUND")
  item:SetPoint("TOPLEFT",x,-y); item:SetSize(width,height); paint(item,shade,true)
  return item
end
local function plate(parent,x,y,width,height,kind)
  local item=CreateFrame(kind or "Frame",nil,parent,"BackdropTemplate")
  item:SetPoint("TOPLEFT",x,-y); item:SetSize(width,height)
  item:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,
    insets={left=2,right=2,top=2,bottom=2}})
  item:SetBackdropColor(unpack(colors.leather)); item:SetBackdropBorderColor(unpack(colors.edge))
  return item
end
local function buttonPaint(item,hovered)
  item:SetBackdropColor(unpack(hovered and colors.hover or item.selected and colors.selected or colors.leather))
  item:SetBackdropBorderColor(unpack(item.selected and colors.gold or colors.edge))
  paint(item.label,item.selected and colors.gold or colors.ivory)
end
local function control(parent,title,x,y,width,onClick,height)
  local item=plate(parent,x,y,width,height or 32,"Button")
  item.label=label(item,0,0,width-12,"control",colors.ivory,title)
  item.label:ClearAllPoints(); item.label:SetPoint("CENTER",item,"CENTER")
  item.label:SetHeight(height or 32); item.label:SetJustifyH("CENTER")
  item.label:SetJustifyV("MIDDLE"); item.label:SetWordWrap(false)
  item:SetScript("OnClick",onClick)
  item:SetScript("OnEnter",function(self)
    buttonPaint(self,true)
    if self.tip then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(title)
      GameTooltip:AddLine(self.tip,.9,.84,.7,true); GameTooltip:Show()
    end
  end)
  item:SetScript("OnLeave",function(self) buttonPaint(self); GameTooltip:Hide() end)
  return item
end
local function enableControl(item,enabled)
  item:SetEnabled(enabled); item:SetAlpha(enabled and 1 or .45)
end
local function selectControl(item,selected)
  item.selected=selected; buttonPaint(item)
end
local function progress(parent,x,y,width,height)
  local item=plate(parent,x,y,width,height)
  item:SetBackdropColor(unpack(colors.track))
  item.fill=rectangle(item,3,3,1,height-6,colors.fill,"ARTWORK")
  item.gleam=rectangle(item,3,3,1,2,colors.gleam,"OVERLAY")
  item.innerWidth=width-6
  return item
end
local function setProgress(item,done,total)
  local ratio=total>0 and math.min(1,done/total) or 0
  local width=math.max(1,item.innerWidth*ratio)
  item.fill:SetWidth(width); item.gleam:SetWidth(width)
  item.fill:SetShown(ratio>0); item.gleam:SetShown(ratio>0)
end
local function percentage(done,total)
  if total == 0 then return "—" end
  local value = 100 * done / total
  if value > 0 and value < 1 then return string.format("%.1f%%", value) end
  return math.floor(value + .5) .. "%"
end
local function artwork(parent,x,y,width,height,file)
  local item=parent:CreateTexture(nil,"BACKGROUND")
  item:SetPoint("TOPLEFT",x,-y); item:SetSize(width,height)
  item:SetTexture(media.."Zones\\"..file); return item
end
local function openMap(mapID)
  if not mapID then return end
  frame:Hide()
  if WorldMapFrame and WorldMapFrame.SetMapID then
    if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
    WorldMapFrame:SetMapID(mapID)
  end
end
local function showStarter(starter)
  openMap(starter.mapID)
  local canSet=C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates
    and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(starter.mapID))
  local wasSet=false
  if canSet then
    local ok,result=pcall(function()
      return C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(starter.mapID,starter.x/100,starter.y/100))
    end)
    wasSet=ok and result
  end
  if wasSet then
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
  elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("Wayfinder: Classic starter at "..starter.x..", "..starter.y
      .." in "..(zoneNames[starter.mapID] or "this zone")..". The map waypoint could not be set.",1,.82,.43)
  end
end
local function switchView(view,catalog)
  state.view,state.rowPage=view,1
  if catalog then state.catalog=catalog end
  render()
end
local function fit()
  frame:SetScale(math.max(.1,math.min(1,(UIParent:GetWidth()-24)/WIDTH,(UIParent:GetHeight()-24)/HEIGHT)))
end
local function create()
  if frame then return end
  frame=CreateFrame("Frame","ForeverWayfinderAtlasFrame",UIParent)
  frame:SetSize(WIDTH,HEIGHT); frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton"); frame:SetPoint("CENTER",UIParent,"CENTER")
  frame.art=frame:CreateTexture(nil,"BACKGROUND")
  frame.art:SetAllPoints(frame); frame.art:SetTexture(media.."AtlasFrameV2")
  frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    local point,_,relativePoint,x,y=self:GetPoint()
    addon.Journal.Database().atlasPosition={point=point,relativePoint=relativePoint,x=x,y=y}
  end)
  local crest=frame:CreateTexture(nil,"ARTWORK")
  crest:SetPoint("TOPLEFT",74,-49); crest:SetSize(54,54); crest:SetTexture(media.."Icon")
  if crest.AddMaskTexture and frame.CreateMaskTexture then
    local mask=frame:CreateMaskTexture()
    mask:SetAllPoints(crest)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    crest:AddMaskTexture(mask)
  end
  label(frame,143,49,340,"display",colors.gold,"WAYFINDER")
  label(frame,145,84,410,"meta",colors.muted,"An atlas of your journey")
  label(frame,943,78,225,"meta",colors.muted,"Classic paths · Forever discoveries")
  local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",-28,-33); close:SetScript("OnClick",function() frame:Hide() end)
  frame.tabs={}
  for index,tab in ipairs({{"zones","Zones"},{"quests","Quests"},{"class","Class quests"}}) do
    local key=tab[1]
    frame.tabs[key]=control(frame,tab[2],72+(index-1)*270,128,258,function() switchView(key) end,40)
  end
  label(frame,984,140,213,"meta",colors.muted,"Drag an empty area to move")

  frame.kalimdor=control(frame,"Kalimdor",L,196,119,function()
    state.continent,state.zonePage,state.rowPage,state.mapID="Kalimdor",1,1,nil; render()
  end)
  frame.eastern=control(frame,"Eastern",L+125,196,119,function()
    state.continent,state.zonePage,state.rowPage,state.mapID="Eastern Kingdoms",1,1,nil; render()
  end)
  frame.eastern.tip="Browse the Eastern Kingdoms."
  label(frame,L+4,240,LW-8,"meta",colors.gold,"CHOOSE A ZONE")
  rectangle(frame,L+4,261,LW-8,1,colors.edge)
  frame.zoneRows={}
  for index=1,ZONE_ROWS do
    local row=CreateFrame("Button",nil,frame)
    row:SetPoint("TOPLEFT",L,-270-(index-1)*46); row:SetSize(LW,44)
    row.bg=rectangle(row,0,0,LW,44,colors.rowAlt)
    row.iconShell=plate(row,1,1,42,42)
    row.icon=artwork(row.iconShell,3,3,36,36,"2521"); row.icon:SetTexCoord(.25,.75,0,1)
    row.name=label(row,49,2,LW-55,"label",colors.ivory); row.name:SetWordWrap(false)
    row.count=label(row,49,23,120,"meta",colors.muted); row.count:SetWordWrap(false)
    row.percent=label(row,179,23,59,"meta",colors.gold); row.percent:SetJustifyH("RIGHT")
    row.track=rectangle(row,49,41,189,3,colors.track)
    row.fill=rectangle(row,49,41,1,3,colors.fill,"ARTWORK")
    row:SetScript("OnEnter",function(self)
      if self.mapID~=state.mapID then paint(self.bg,colors.row,true) end
    end)
    row:SetScript("OnLeave",function(self)
      paint(self.bg,self.mapID==state.mapID and colors.selectedRow or colors.rowAlt,true)
    end)
    row:SetScript("OnClick",function(self)
      state.mapID,state.rowPage=self.mapID,1
      if state.view=="class" then state.view="zones" end
      render()
    end)
    frame.zoneRows[index]=row
  end
  frame.zonePrev=control(frame,"<",L,BOTTOM,40,function() state.zonePage=state.zonePage-1; render() end)
  frame.zoneNext=control(frame,">",L+LW-40,BOTTOM,40,function() state.zonePage=state.zonePage+1; render() end)
  frame.zonePage=label(frame,L+48,BOTTOM+8,LW-96,"meta",colors.ivory); frame.zonePage:SetJustifyH("CENTER")

  frame.heroShell=plate(frame,C,196,CW,158)
  frame.hero=artwork(frame.heroShell,3,3,CW-6,152,"1411")
  frame.heroShade=rectangle(frame.heroShell,3,3,CW-6,152,colors.shadow,"BORDER")
  frame.title=label(frame.heroShell,19,18,CW-38,"display",colors.ivory); frame.title:SetWordWrap(false)
  frame.subtitle=label(frame.heroShell,20,58,CW-40,"meta",colors.ivory)
  frame.description=label(frame.heroShell,20,89,CW-44,"body",colors.ivory); frame.description:SetHeight(60)
  frame.progressLabel=label(frame,C,371,CW,"meta",colors.gold)
  frame.stat=label(frame,C+250,369,CW-250,"heading",colors.ivory); frame.stat:SetJustifyH("RIGHT")
  frame.progress=progress(frame,C,402,CW,18)
  frame.caveat=label(frame,C,433,CW,"meta",colors.muted); frame.caveat:SetHeight(36)

  frame.overview=CreateFrame("Frame",nil,frame); frame.overview:SetAllPoints(frame)
  frame.classicSummary=plate(frame.overview,C,480,CW,86)
  artwork(frame.classicSummary,15,20,40,40,"2521"):SetTexCoord(.25,.75,0,1)
  label(frame.classicSummary,70,15,310,"heading",colors.ivory,"Classic quests")
  frame.classicSummary.value=label(frame.classicSummary,70,48,322,"meta",colors.muted)
  frame.classicBrowse=control(frame.classicSummary,"Browse",CW-124,28,108,function() switchView("quests","classic") end)
  frame.foreverSummary=plate(frame.overview,C,584,CW,86)
  artwork(frame.foreverSummary,15,20,40,40,"2548"):SetTexCoord(.25,.75,0,1)
  label(frame.foreverSummary,70,15,310,"heading",colors.ivory,"Forever discoveries")
  frame.foreverSummary.value=label(frame.foreverSummary,70,48,322,"meta",colors.muted)
  frame.foreverBrowse=control(frame.foreverSummary,"Browse",CW-124,28,108,function() switchView("quests","forever") end)
  frame.overviewNote=label(frame.overview,C+4,695,CW-8,"meta",colors.muted); frame.overviewNote:SetHeight(58)

  frame.list=CreateFrame("Frame",nil,frame); frame.list:SetAllPoints(frame)
  frame.catalogTabs={}
  frame.catalogTabs.classic=control(frame.list,"Classic",C,420,152,function() switchView("quests","classic") end)
  frame.catalogTabs.forever=control(frame.list,"Forever",C+158,420,152,function() switchView("quests","forever") end)
  frame.unfinished=control(frame.list,"Show unfinished",C+342,420,190,function()
    state.unfinished,state.rowPage=not state.unfinished,1; render()
  end)
  frame.classIntro=label(frame.list,C,423,CW,"meta",colors.muted,"Your class quests have a separate completion record.")
  frame.listTitle=label(frame.list,C+3,470,CW-6,"meta",colors.gold)
  rectangle(frame.list,C+3,491,CW-6,1,colors.edge)
  frame.rows={}
  for index=1,QUEST_ROWS do
    local row=CreateFrame("Button",nil,frame.list)
    row:SetPoint("TOPLEFT",C,-500-(index-1)*30); row:SetSize(CW,28)
    row.bg=rectangle(row,0,0,CW,28,index%2==0 and colors.row or colors.rowAlt)
    row.name=label(row,9,4,CW-113,"label",colors.ivory); row.name:SetWordWrap(false)
    row.status=label(row,CW-98,5,87,"meta",colors.muted)
    row.status:SetWordWrap(false); row.status:SetJustifyH("RIGHT")
    row:SetScript("OnEnter",function(self)
      paint(self.bg,colors.selectedRow,true)
      if self.data then
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.data.title)
        GameTooltip:AddLine(self.tooltipText or "",.9,.84,.7,true); GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave",function(self)
      paint(self.bg,index%2==0 and colors.row or colors.rowAlt,true); GameTooltip:Hide()
    end)
    row:SetScript("OnClick",function(self)
      if not self.data then return end
      if self.data.status=="active" and QuestMapFrame_ShowQuestDetails then
        frame:Hide(); if ToggleQuestLog then ToggleQuestLog() end; QuestMapFrame_ShowQuestDetails(self.data.id)
      elseif self.data.status=="unseen" and self.starter then showStarter(self.starter)
      elseif state.view=="class" then frame:Hide(); if addon.ShowWhereNext then addon.ShowWhereNext() end
      else openMap(state.mapID) end
    end)
    frame.rows[index]=row
  end
  frame.empty=label(frame.list,C+15,527,CW-30,"body",colors.muted); frame.empty:SetHeight(148)
  frame.rowPrev=control(frame.list,"Previous",C,BOTTOM,106,function() state.rowPage=state.rowPage-1; render() end)
  frame.rowNext=control(frame.list,"Next",C+CW-106,BOTTOM,106,function() state.rowPage=state.rowPage+1; render() end)
  frame.rowPage=label(frame.list,C+120,BOTTOM+8,CW-240,"meta",colors.ivory); frame.rowPage:SetJustifyH("CENTER")

  frame.rightTitle=label(frame,R,202,RW,"meta",colors.gold,"CONTINENT RECORD")
  frame.rightZone=label(frame,R,233,RW,"title",colors.ivory); frame.rightZone:SetHeight(57)
  frame.recordArt=artwork(frame,R,296,RW,119,"2521")
  frame.recordPercent=label(frame,R,435,RW,"display",colors.gold); frame.recordPercent:SetJustifyH("CENTER")
  frame.recordLabel=label(frame,R,472,RW,"meta",colors.ivory,"Classic quest completion"); frame.recordLabel:SetJustifyH("CENTER")
  frame.recordCount=label(frame,R,501,RW,"meta",colors.muted); frame.recordCount:SetJustifyH("CENTER")
  frame.recordProgress=progress(frame,R,533,RW,12)
  frame.sideDetail=label(frame,R,565,RW,"meta",colors.ivory); frame.sideDetail:SetHeight(38)
  frame.sideNote=label(frame,R,609,RW,"meta",colors.muted); frame.sideNote:SetHeight(38)
  frame.reading=control(frame,"Text: Standard",R,660,RW,function() style.Cycle() end)
  frame.map=control(frame,"Open zone map",R,BOTTOM-40,RW,function()
    if state.view=="class" then frame:Hide(); if addon.ShowWhereNext then addon.ShowWhereNext() end
    else openMap(state.mapID) end
  end)
  frame.journal=control(frame,"Personal journal",R,BOTTOM,RW,function() frame:Hide(); addon.ToggleJournal() end)
  local saved=addon.Journal.Database().atlasPosition
  if saved and saved.point and saved.relativePoint then
    frame:ClearAllPoints(); frame:SetPoint(saved.point,UIParent,saved.relativePoint,saved.x or 0,saved.y or 0)
  end
  frame:SetScript("OnShow",function() fit(); if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end end)
  frame:SetScript("OnHide",function()
    if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_SPELLBOOK_CLOSE) end; GameTooltip:Hide()
  end)
  table.insert(UISpecialFrames,"ForeverWayfinderAtlasFrame"); frame:Hide()
end

render=function()
  if not frame then return end
  local continent=atlas.Continent(state.continent)
  local zone
  for _,item in ipairs(continent.zones) do if item.mapID==state.mapID then zone=item break end end
  if not zone then zone=continent.zones[1]; state.mapID=zone and zone.mapID end
  if not zone then return end
  local presentation=addon.AtlasPresentation[zone.mapID] or {"2521","A new chapter in your travels."}
  local zoneInfo=zoneMeta[zone.mapID]
  local isOverview,isClass=state.view=="zones",state.view=="class"
  selectControl(frame.kalimdor,state.continent=="Kalimdor")
  selectControl(frame.eastern,state.continent=="Eastern Kingdoms")
  for key,tab in pairs(frame.tabs) do selectControl(tab,state.view==key) end
  local maxZonePage=math.max(1,math.ceil(#continent.zones/ZONE_ROWS))
  state.zonePage=math.max(1,math.min(maxZonePage,state.zonePage))
  for index,row in ipairs(frame.zoneRows) do
    local item=continent.zones[(state.zonePage-1)*ZONE_ROWS+index]
    row:SetShown(item~=nil)
    if item then
      row.mapID=item.mapID; row.name:SetText(item.name)
      row.icon:SetTexture(media.."Zones\\"..(addon.AtlasPresentation[item.mapID] or {"2521"})[1])
      row.count:SetWidth(item.total>0 and 120 or 189)
      row.count:SetText(item.total>0 and (item.completed.." / "..item.total)
        or item.newZone and "Forever region" or "No Classic quests")
      row.percent:SetText(item.total>0 and percentage(item.completed,item.total) or "")
      row.track:SetShown(item.total>0); row.fill:SetShown(item.total>0 and item.completed>0)
      row.fill:SetWidth(math.max(1,item.total>0 and 189*item.completed/item.total or 1))
      paint(row.bg,item.mapID==state.mapID and colors.selectedRow or colors.rowAlt,true)
    end
  end
  frame.zonePage:SetText(state.zonePage.." / "..maxZonePage)
  enableControl(frame.zonePrev,state.zonePage>1); enableControl(frame.zoneNext,state.zonePage<maxZonePage)
  local classSnapshot=isClass and atlas.ClassQuests() or nil
  local foreverView=not isClass and state.catalog=="forever" and not isOverview
  local done=classSnapshot and classSnapshot.completed or foreverView and zone.completedForever or zone.completed
  local total=classSnapshot and classSnapshot.total or foreverView and zone.knownForever or zone.total
  local rows=classSnapshot and classSnapshot.quests or foreverView and zone.forever or zone.quests
  frame.hero:SetTexture(media.."Zones\\"..(isClass and "2521" or presentation[1]))
  frame.heroShell:SetHeight(isOverview and 158 or 110)
  frame.hero:SetHeight(isOverview and 152 or 104); frame.heroShade:SetHeight(isOverview and 152 or 104)
  frame.hero:SetTexCoord(0,1,isOverview and .18 or .28,isOverview and .82 or .72)
  frame.title:SetText(isClass and "Your class quests" or zone.name)
  frame.subtitle:SetText(isClass and ((UnitClass("player") or "Class").." · Classic quest record")
    or (state.continent.." · "..(zone.newZone and "Forever region" or "Levels "..zoneInfo[3].."–"..zoneInfo[4])))
  frame.description:SetShown(isOverview); frame.description:SetText(presentation[2])
  position(frame.progressLabel,C,isOverview and 371 or 324)
  position(frame.stat,C+250,isOverview and 369 or 322)
  position(frame.progress,C,isOverview and 402 or 355)
  position(frame.caveat,C,isOverview and 433 or 383)
  frame.progressLabel:SetText(isClass and "CLASS QUEST PROGRESS" or foreverView and "VERIFIED FOREVER QUESTS" or "CLASSIC QUEST PROGRESS")
  frame.stat:SetText(total>0 and (done.." of "..total.." complete")
    or foreverView and (zone.foreverCount.." discovered") or "No cataloged quests")
  setProgress(frame.progress,done,total)
  frame.caveat:SetText(isClass and "Repeatable, event, and gated quests are kept separate."
    or foreverView and "Your discoveries appear here as you play."
    or "One-time zone quests · class and event quests separate")

  frame.overview:SetShown(isOverview); frame.list:SetShown(not isOverview)
  frame.classicSummary.value:SetText(zone.total>0 and (zone.completed.." complete · "..(zone.total-zone.completed).." remaining")
    or "No eligible quests in this Classic reference")
  frame.foreverSummary.value:SetText(zone.knownForever>0 and (zone.completedForever.." of "..zone.knownForever.." verified complete")
    or (zone.foreverCount.." recorded in your journal"))
  local activeCount=0
  for _,quest in ipairs(zone.quests) do if quest.status=="active" then activeCount=activeCount+1 end end
  frame.overviewNote:SetText((activeCount>0 and (activeCount.." Classic "..(activeCount==1 and "quest is" or "quests are").." currently in your log.\n") or "")
    .."Class quests have their own chapter. Forever discoveries grow as you explore.")
  frame.catalogTabs.classic:SetShown(not isClass); frame.catalogTabs.forever:SetShown(not isClass)
  frame.unfinished:SetShown(not isClass); frame.classIntro:SetShown(isClass)
  selectControl(frame.catalogTabs.classic,state.catalog=="classic")
  selectControl(frame.catalogTabs.forever,state.catalog=="forever"); selectControl(frame.unfinished,state.unfinished)
  frame.unfinished.label:SetText(state.unfinished and "Show all quests" or "Show unfinished")
  if state.unfinished and not isClass then
    local filtered={}
    for _,item in ipairs(rows) do if item.status~="completed" then filtered[#filtered+1]=item end end
    rows=filtered
  end
  frame.listTitle:SetText(isClass and "CLASS QUESTS & ABILITY ROUTES" or foreverView and "FOREVER DISCOVERIES" or "CLASSIC ZONE QUESTS")
  local maxRowPage=math.max(1,math.ceil(#rows/QUEST_ROWS))
  state.rowPage=math.max(1,math.min(maxRowPage,state.rowPage))
  for index,row in ipairs(frame.rows) do
    local item=rows[(state.rowPage-1)*QUEST_ROWS+index]
    row:SetShown(item~=nil); row.data=item
    row.starter=item and item.status=="unseen" and not foreverView and atlas.Starter(item,state.mapID,isClass) or nil
    if item then
      row.name:SetText(item.title)
      local finished=item.completed==true or item.status=="completed"
      row.status:SetText(finished and "Complete" or item.status=="active" and "In log"
        or item.special and "Special" or row.starter and "To find" or isClass and "Guide" or "Map only")
      paint(row.status,finished and colors.green or item.status=="active" and colors.blue or colors.muted)
      if row.starter then
        row.tooltipText="Classic starter: "..(row.starter.name or "known location").." in "
          ..(zoneNames[row.starter.mapID] or "this zone")..". Click to set a map waypoint. Replaces your current waypoint; Forever may differ."
      elseif item.status=="active" then row.tooltipText="Click to open this quest in your log."
      elseif isClass then row.tooltipText="No starter marker in this reference. Click for class route guidance."
      else row.tooltipText="No starter coordinate in this reference. Click to open the zone map." end
    end
  end
  frame.empty:SetShown(#rows==0)
  frame.empty:SetText(state.unfinished and not isClass and not foreverView and zone.total>0 and "Every cataloged Classic quest in this zone is complete."
    or foreverView and "No Forever quests recorded here yet. Your discoveries will appear as you play."
    or isClass and "No Classic class quests are cataloged for this character."
    or "No mapped Classic quests are cataloged for this character in this zone.")
  frame.rowPage:SetText(state.rowPage.." / "..maxRowPage)
  enableControl(frame.rowPrev,state.rowPage>1); enableControl(frame.rowNext,state.rowPage<maxRowPage)
  local recordDone,recordTotal=classSnapshot and classSnapshot.completed or continent.completed,
    classSnapshot and classSnapshot.total or continent.total
  frame.rightTitle:SetText(isClass and "CLASS RECORD" or "CONTINENT RECORD")
  frame.rightZone:SetText(isClass and (UnitClass("player") or "Your class") or state.continent)
  frame.recordArt:SetTexture(media.."Zones\\"..(state.continent=="Kalimdor" and "2521" or "2548"))
  frame.recordPercent:SetText(percentage(recordDone,recordTotal))
  frame.recordCount:SetText(recordDone.." of "..recordTotal.." complete")
  setProgress(frame.recordProgress,recordDone,recordTotal)
  frame.sideDetail:SetText(isClass and (#atlas.ClassPaths().." ability routes in this reference")
    or (zone.name.."\n"..zone.completed.." / "..zone.total.." Classic quests"))
  frame.sideNote:SetText(isClass and (classSnapshot.special.." special entries kept separate")
    or (zone.foreverCount.." Forever "..(zone.foreverCount==1 and "quest" or "quests").." recorded here"))
  frame.reading.label:SetText("Text: "..style.Name())
  frame.map.label:SetText(isClass and "Where next?" or "Open zone map"); enableControl(frame.map,isClass or state.mapID~=nil)
end

function addon.ShowAtlas()
  if not addon.Journal.Initialize() then return end
  addon.Journal.Character()
  if not frame and C_Map and C_Map.GetBestMapForUnit then
    local mapID=C_Map.GetBestMapForUnit("player")
    if zoneMeta[mapID] then
      state.continent,state.mapID=zoneMeta[mapID][6],mapID
      local index=0
      for _,zone in ipairs(addon.Zones) do
        if zone[6]==state.continent then
          index=index+1
          if zone[1]==mapID then state.zonePage=math.ceil(index/ZONE_ROWS) break end
        end
      end
    end
  end
  create(); render(); frame:Show()
end
function addon.ToggleAtlas()
  if frame and frame:IsShown() then frame:Hide() else addon.ShowAtlas() end
end
function addon.RefreshAtlas()
  if not frame or not frame:IsShown() or refreshPending then return end
  refreshPending=true
  local function update()
    refreshPending=false; if frame and frame:IsShown() then render() end
  end
  if C_Timer and C_Timer.After then C_Timer.After(.05,update) else update() end
end
function addon.RefreshAtlasReadingStyle()
  if frame and frame:IsShown() then render() end
end
local events=CreateFrame("Frame")
for _,name in ipairs({"QUEST_TURNED_IN","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_LOG_UPDATE"}) do events:RegisterEvent(name) end
events:SetScript("OnEvent",addon.RefreshAtlas)
