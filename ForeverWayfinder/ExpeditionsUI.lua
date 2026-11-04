-- Hallmark: native Wayfinder workbench; parchment, leather, shared game fonts.
-- Pre-emit critique: P5 H5 E5 S5 R5 V4. Atlas sheet coordinates are not world waypoints.
local _, addon = ...
local guide, style = addon.Expeditions, addon.ReadingStyle
local unpack = unpack or table.unpack
local frame, render, tooltipOwner
local WIDTH, HEIGHT, ROWS = 1280, 850, 9
local L, LW, C, CW, R, RW = 72, 244, 372, 532, 964, 238
local state = {kind="dungeon", page=1, tab="route", boss=1, route=1, search="", mapPage=1, view="map"}
local colors = {
  gold={1,.82,.43}, ivory={.96,.91,.80}, muted={.77,.76,.69}, edge={.51,.39,.22,1},
  leather={.055,.075,.082,1}, hover={.16,.19,.19,1}, selected={.28,.21,.10,1},
  paper={.82,.72,.52,1}, paperLight={.91,.83,.65,1}, ink={.20,.13,.07},
  brown={.37,.25,.12}, rule={.49,.36,.19,1}, route={.57,.31,.09,1},
}
local roles = {body="atlasBody",meta="atlasMeta",control="atlasControl"}
local function color(object, shade) object:SetTextColor(shade[1],shade[2],shade[3]) end
local function label(parent,x,y,width,role,shade,text)
  local object=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
  object:SetPoint("TOPLEFT",x,-y); object:SetWidth(width); object:SetJustifyH("LEFT")
  style.Font(object,roles[role] or role); color(object,shade); object:SetText(text or "")
  return object
end
local function plate(parent,x,y,width,height,shade,kind)
  local object=CreateFrame(kind or "Frame",nil,parent,"BackdropTemplate")
  object:SetPoint("TOPLEFT",x,-y); object:SetSize(width,height)
  object:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  object:SetBackdropColor(unpack(shade or colors.leather)); object:SetBackdropBorderColor(unpack(colors.edge))
  return object
end
local function buttonPaint(object,hover)
  object:SetBackdropColor(unpack(hover and colors.hover or object.selected and colors.selected or colors.leather))
  object:SetBackdropBorderColor(unpack(object.selected and colors.gold or colors.edge))
end
local function button(parent,text,x,y,width,callback,height)
  local object=plate(parent,x,y,width,height or 34,nil,"Button")
  object.label=label(object,8,0,width-16,"control",colors.ivory,text)
  object.label:SetHeight(height or 34); object.label:SetJustifyH("CENTER"); object.label:SetJustifyV("MIDDLE")
  object.label:SetWordWrap(false)
  object:SetScript("OnClick",callback)
  object:SetScript("OnEnter",function(self) buttonPaint(self,true) end)
  object:SetScript("OnLeave",function(self) buttonPaint(self) end)
  return object
end
local function enabled(object,value) object:SetEnabled(value); object:SetAlpha(value and 1 or .4) end
local function selected(object,value) object.selected=value; buttonPaint(object) end
local function hideTooltip()
  tooltipOwner=nil; GameTooltip:Hide()
end
local function itemTooltip(object,item)
  tooltipOwner=object
  GameTooltip:SetOwner(object,"ANCHOR_RIGHT")
  local ok,name=false,nil
  if GetItemInfo then ok,name=pcall(GetItemInfo,item.id) end
  if ok and name and GameTooltip.SetItemByID then GameTooltip:SetItemByID(item.id)
  else
    GameTooltip:SetText(item.name)
    GameTooltip:AddLine("Item data is not cached yet. Item #"..item.id,.9,.84,.7,true)
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID,item.id) end
  end
  GameTooltip:AddLine("Beta-reported drop. Click to toggle your account wishlist.",.9,.84,.7,true)
  GameTooltip:Show()
end
local function scrollBy(scroll,delta)
  scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,scroll.scrollChild:GetHeight()-scroll:GetHeight()),
    scroll:GetVerticalScroll()-delta*style.Size("atlasBody")*3)))
end
local function scrollFrame(parent,x,y,width,height)
  local scroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",x,-y); scroll:SetSize(width,height)
  local child=CreateFrame("Frame",nil,scroll); child:SetSize(width,1); scroll:SetScrollChild(child)
  scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",scrollBy)
  return scroll,child
end
local function card(parent,width)
  local object=plate(parent,0,0,width,72,nil,"Button")
  object.title=label(object,12,10,width-24,"body",colors.ivory)
  object.meta=label(object,12,38,width-24,"meta",colors.muted)
  object:SetScript("OnClick",function(self) if self.action then hideTooltip(); self.action() end end)
  object:SetScript("OnEnter",function(self)
    buttonPaint(self,true)
    if self.item then itemTooltip(self,self.item) end
  end)
  object:SetScript("OnLeave",function(self) buttonPaint(self); hideTooltip() end)
  return object
end
local function fillCard(object,y,title,meta,action,item)
  object:SetPoint("TOPLEFT",0,-y); object.title:SetText(title); object.title:SetHeight(0)
  local titleHeight=object.title:GetStringHeight()
  object.meta:ClearAllPoints(); object.meta:SetPoint("TOPLEFT",12,-(16+titleHeight))
  object.meta:SetText(meta); object.meta:SetHeight(0)
  local height=26+titleHeight+object.meta:GetStringHeight()
  object:SetHeight(height); object.action,object.item=action,item
  selected(object,item and guide.IsWished(item.id)); object:Show()
  return height+8
end
local function selectEntry(key)
  state.key,state.boss,state.route,state.armor,state.wishlist=key,1,1,nil,nil
  state.mapPage,state.pin,state.view=1,nil,"map"
  state.revealKey=key
  frame.mainScroll:SetVerticalScroll(0); frame.detailScroll:SetVerticalScroll(0)
  hideTooltip(); render()
end
local function switchTab(tab)
  state.tab=tab; frame.mainScroll:SetVerticalScroll(0); hideTooltip(); render()
end
local function fit()
  frame:SetScale(math.max(.1,math.min(1,(UIParent:GetWidth()-24)/WIDTH,(UIParent:GetHeight()-24)/HEIGHT)))
end
local function changeMap(delta)
  state.mapPage=math.max(1,math.min(#guide.Maps(frame.entry),state.mapPage+delta))
  state.pin,state.boss=nil,1; frame.detailScroll:SetVerticalScroll(0); render()
end
local function pinPaint(pin,hover)
  pin:SetBackdropColor(0,0,0,0)
  pin:SetBackdropBorderColor(colors.gold[1],colors.gold[2],colors.gold[3],(hover or pin.selected) and 1 or 0)
end
local function drawMap(surface,entry,sheet,width,height)
  local scale=math.min(width/sheet.width,height/sheet.height)
  local w,h=sheet.width*scale,sheet.height*scale
  local left,top=(width-w)/2,(height-h)/2
  surface.image:ClearAllPoints(); surface.image:SetPoint("TOPLEFT",left,-top); surface.image:SetSize(w,h)
  surface.image:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\Maps\\"..sheet.texture)
  for _,pin in ipairs(surface.pins) do pin:Hide() end
  for index,point in ipairs(sheet.pins) do
    local pin=surface.pins[index]
    if not pin then
      pin=plate(surface,0,0,24,24,nil,"Button"); surface.pins[index]=pin
      pin:SetScript("OnClick",function(self)
        state.pin=self.point; state.boss=guide.BossForPin(frame.entry,self.point)
        frame.detailScroll:SetVerticalScroll(0); render()
      end)
      pin:SetScript("OnEnter",function(self)
        pinPaint(self,true); GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.point.name)
        GameTooltip:AddLine("Atlas marker "..self.point.label.." · Beta reference",.9,.84,.7,true); GameTooltip:Show()
      end)
      pin:SetScript("OnLeave",function(self) pinPaint(self); GameTooltip:Hide() end)
    end
    -- Atlas's x/y anchor the printed glyph's top left. Offset the hit target
    -- over that glyph; keep both the source art and source positions unchanged.
    local size=math.max(20,24*scale)
    pin:ClearAllPoints(); pin:SetPoint("TOPLEFT",left+(point.x+4)*scale-size/2,-(top+(point.y+7)*scale-size/2))
    pin:SetSize(size,size); pin.point=point
    pin.selected=state.pin==point or (not state.pin and state.boss and guide.BossForPin(entry,point)==state.boss)
    pinPaint(pin); pin:Show()
  end
end
local function mapSurface(parent,x,y,width,height)
  local surface=plate(parent,x,y,width,height,colors.paper)
  surface.image=surface:CreateTexture(nil,"ARTWORK"); surface.pins={}
  return surface
end
local function create()
  if frame then return end
  frame=CreateFrame("Frame","ForeverWayfinderExpeditionsFrame",UIParent)
  frame:SetSize(WIDTH,HEIGHT); frame:SetPoint("CENTER",UIParent,"CENTER"); frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  local art=frame:CreateTexture(nil,"BACKGROUND"); art:SetAllPoints(frame)
  art:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\AtlasFrameV2")
  frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    local point,_,relativePoint,x,y=self:GetPoint()
    guide.Settings().position={point=point,relativePoint=relativePoint,x=x,y=y}
  end)
  local icon=frame:CreateTexture(nil,"ARTWORK")
  icon:SetPoint("TOPLEFT",74,-49); icon:SetSize(54,54)
  icon:SetTexture("Interface\\AddOns\\ForeverWayfinder\\Media\\Icon")
  if icon.AddMaskTexture and frame.CreateMaskTexture then
    local mask=frame:CreateMaskTexture(); mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)
  end
  label(frame,143,49,500,"display",colors.gold,"EXPEDITIONS")
  label(frame,145,88,700,"meta",colors.muted,"Dungeons, raids, and the road beneath Azeroth")
  local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",-28,-33); close:SetScript("OnClick",function() frame:Hide() end)
  frame.kinds={}
  for index,kind in ipairs({{"dungeon","Dungeons"},{"raid","Raids"},{"all","All"}}) do
    local key=kind[1]
    frame.kinds[key]=button(frame,kind[2],L+(index-1)*180,128,168,function()
      state.kind=key~="all" and key or nil; state.page=1; state.key=nil; render()
    end,40)
  end
  local searchShell=plate(frame,668,128,534,40)
  frame.search=CreateFrame("EditBox",nil,searchShell)
  frame.search:SetPoint("TOPLEFT",12,-5); frame.search:SetSize(510,30); frame.search:SetAutoFocus(false)
  frame.search:SetMaxLetters(160); style.Font(frame.search,"atlasBody"); color(frame.search,colors.ivory)
  frame.search:SetScript("OnTextChanged",function(self)
    if state.loading then return end
    state.search=self:GetText(); state.page=1; state.key=nil; render()
  end)
  frame.search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  frame.searchHint=label(searchShell,12,10,510,"meta",colors.muted,"Search dungeon, raid, or region...")
  frame.origin=button(frame,"All origins",L,198,LW,function()
    state.origin=state.origin==nil and "forever" or state.origin=="forever" and "classic" or nil
    state.page=1; state.key=nil; render()
  end)
  frame.count=label(frame,L,244,LW,"meta",colors.muted)
  frame.catalogRows={}
  for index=1,ROWS do
    local row=plate(frame,L,276+(index-1)*46,LW,44,nil,"Button")
    row.title=label(row,9,4,LW-18,"body",colors.ivory); row.title:SetHeight(22); row.title:SetWordWrap(false)
    row.meta=label(row,9,26,LW-18,"meta",colors.muted); row.meta:SetHeight(18); row.meta:SetWordWrap(false)
    row:SetScript("OnClick",function(self) selectEntry(self.entry.key) end)
    row:SetScript("OnEnter",function(self)
      buttonPaint(self,true); GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.entry.name)
      GameTooltip:AddLine(self.entry.zone,.9,.84,.7,true); GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function(self) buttonPaint(self); GameTooltip:Hide() end)
    frame.catalogRows[index]=row
  end
  frame.previous=button(frame,"Previous",L,704,116,function() state.page=state.page-1; render() end)
  frame.next=button(frame,"Next",L+128,704,116,function() state.page=state.page+1; render() end)
  frame.page=label(frame,L,746,LW,"meta",colors.muted); frame.page:SetJustifyH("CENTER")
  frame.heading=label(frame,C,198,CW,"title",colors.ivory); frame.heading:SetHeight(60)
  frame.meta=label(frame,C,264,CW,"meta",colors.muted); frame.meta:SetHeight(38)
  frame.tabs={}
  for index,tab in ipairs({{"route","Map"},{"loot","Loot"},{"quests","Quests"}}) do
    local key=tab[1]
    frame.tabs[key]=button(frame,tab[2],C+(index-1)*180,308,172,function() switchTab(key) end)
  end
  frame.diagram=plate(frame,C,354,CW,358,colors.paper)
  frame.diagram.title=label(frame.diagram,20,20,290,"meta",colors.ink,"ENCOUNTER SEQUENCE")
  frame.routeMode=button(frame.diagram,"Quest circuit",332,12,180,function()
    state.route=state.route==1 and 2 or 1; render()
  end)
  local function line(x,y,w,h)
    local texture=frame.diagram:CreateTexture(nil,"ARTWORK")
    texture:SetPoint("TOPLEFT",x,-y); texture:SetSize(w,h); texture:SetColorTexture(unpack(colors.route))
  end
  line(238,121,58,3); line(400,163,3,73); line(238,278,58,3)
  label(frame.diagram,263,96,30,"display",colors.brown,">")
  label(frame.diagram,391,184,30,"title",colors.brown,"v")
  label(frame.diagram,263,253,30,"display",colors.brown,"<")
  frame.bossButtons={}
  local positions={{28,79},{296,79},{296,236},{28,236}}
  for index,position in ipairs(positions) do
    local bossIndex=index
    local node=plate(frame.diagram,position[1],position[2],210,84,colors.paperLight,"Button")
    node.number=label(node,12,20,32,"display",colors.brown,tostring(index))
    node.title=label(node,50,10,150,"body",colors.ink); node.title:SetHeight(52)
    node.mark=label(node,50,64,150,"meta",colors.brown)
    node:SetScript("OnClick",function() state.boss=bossIndex; state.pin=nil; frame.detailScroll:SetVerticalScroll(0); render() end)
    node:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(colors.route)) end)
    node:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(colors.edge)) end)
    frame.bossButtons[index]=node
  end
  frame.diagram.mapReturn=button(frame.diagram,"Map",20,323,76,function() state.view="map"; render() end,28)
  frame.mapPanel=mapSurface(frame,C,354,CW,358)
  frame.mapPage=label(frame.mapPanel,8,18,76,"meta",colors.ink); frame.mapPage:SetHeight(32)
  frame.mapPrevious=button(frame.mapPanel,"<",8,156,56,function() changeMap(-1) end)
  frame.mapNext=button(frame.mapPanel,">",CW-64,156,56,function() changeMap(1) end)
  frame.mapSketch=button(frame.mapPanel,"Sketch",8,310,76,function() state.view="sketch"; state.pin=nil; state.boss=state.boss or 1; render() end)
  frame.mapZoom=button(frame.mapPanel,"Zoom",CW-76,310,68,function() frame.mapViewer:Show() end)
  frame.mapViewer=CreateFrame("Frame","ForeverWayfinderExpeditionMapViewer",frame,"BackdropTemplate")
  frame.mapViewer:SetSize(700,740); frame.mapViewer:SetPoint("CENTER",frame,"CENTER")
  frame.mapViewer:SetFrameLevel(frame:GetFrameLevel()+30); frame.mapViewer:EnableMouse(true)
  frame.mapViewer:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
  frame.mapViewer:SetBackdropColor(unpack(colors.leather)); frame.mapViewer:SetBackdropBorderColor(unpack(colors.edge))
  frame.mapViewer.title=label(frame.mapViewer,24,20,540,"title",colors.gold); frame.mapViewer.title:SetHeight(52)
  frame.mapViewer.close=button(frame.mapViewer,"Close",588,18,88,function() frame.mapViewer:Hide() end)
  frame.mapViewer.surface=mapSurface(frame.mapViewer,50,76,600,600)
  frame.mapViewer.caption=label(frame.mapViewer,24,692,440,"meta",colors.muted); frame.mapViewer.caption:SetHeight(38)
  frame.mapViewer.previous=button(frame.mapViewer,"<",490,690,88,function() changeMap(-1) end)
  frame.mapViewer.next=button(frame.mapViewer,">",590,690,88,function() changeMap(1) end)
  frame.mapViewer:Hide()
  frame.toolbar=CreateFrame("Frame",nil,frame); frame.toolbar:SetPoint("TOPLEFT",C,-354); frame.toolbar:SetSize(CW,34)
  frame.wishlist=button(frame.toolbar,"All items",0,0,228,function()
    state.wishlist=not state.wishlist; frame.mainScroll:SetVerticalScroll(0); render()
  end)
  frame.armor=button(frame.toolbar,"All item types",240,0,292,function()
    local types={"Cloth","Leather","Mail","Weapons"}
    local nextType
    if state.armor==nil then nextType=types[1]
    else for index,kind in ipairs(types) do if kind==state.armor then nextType=types[index+1]; break end end end
    state.armor=nextType; frame.mainScroll:SetVerticalScroll(0); render()
  end)
  frame.mainScroll,frame.mainChild=scrollFrame(frame,C,400,CW-20,312)
  frame.cards={}
  for index=1,12 do frame.cards[index]=card(frame.mainChild,CW-24) end
  frame.empty=label(frame,C+24,426,CW-48,"body",colors.ivory); frame.empty:SetHeight(210)
  frame.caption=label(frame,C,728,CW,"meta",colors.muted); frame.caption:SetHeight(56)
  frame.sideHeading=label(frame,R,202,RW,"meta",colors.gold)
  frame.bossName=label(frame,R,236,RW,"title",colors.ivory); frame.bossName:SetHeight(68)
  frame.detailScroll,frame.detailChild=scrollFrame(frame,R,316,RW-20,350)
  frame.bossNote=label(frame.detailChild,0,0,RW-24,"body",colors.ivory)
  frame.lootHeading=label(frame.detailChild,0,0,RW-24,"meta",colors.gold,"BOSS LOOT")
  frame.bossLoot={}
  for index=1,3 do frame.bossLoot[index]=card(frame.detailChild,RW-24) end
  frame.bossPrevious=button(frame,"< Boss",R,688,113,function()
    state.boss=state.boss-1; state.pin=nil; frame.detailScroll:SetVerticalScroll(0); render()
  end)
  frame.bossNext=button(frame,"Boss >",R+125,688,113,function()
    state.boss=state.boss+1; state.pin=nil; frame.detailScroll:SetVerticalScroll(0); render()
  end)
  frame.reading=button(frame,"Text: Standard",R,746,RW,function() style.Cycle() end)
  frame.zoneMap=button(frame,"Region map",L,790,116,function()
    local entry=frame.entry
    if entry and entry.zoneMapID and WorldMapFrame and WorldMapFrame.SetMapID then
      frame:Hide()
      if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
      WorldMapFrame:SetMapID(entry.zoneMapID)
    end
  end)
  frame.journal=button(frame,"Journal",L+128,790,116,function() frame:Hide(); addon.ToggleJournal() end)
  frame.atlas=button(frame,"Atlas",R,790,RW,function() frame:Hide(); addon.ShowAtlas() end)
  frame.source=label(frame,C,772,CW,"meta",colors.muted); frame.source:SetHeight(22)
  frame:SetScript("OnShow",fit)
  frame:SetScript("OnHide",function() hideTooltip(); frame.search:ClearFocus(); frame.mapViewer:Hide() end)
  frame:RegisterEvent("DISPLAY_SIZE_CHANGED"); frame:RegisterEvent("UI_SCALE_CHANGED")
  frame:RegisterEvent("GET_ITEM_INFO_RECEIVED"); frame:RegisterEvent("QUEST_LOG_UPDATE")
  frame:RegisterEvent("QUEST_TURNED_IN")
  frame:SetScript("OnEvent",function(_,event,itemID,success)
    if event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then fit()
    elseif event=="GET_ITEM_INFO_RECEIVED" then
      if success and tooltipOwner and tooltipOwner.item and tooltipOwner.item.id==itemID then
        itemTooltip(tooltipOwner,tooltipOwner.item)
      end
    elseif frame:IsShown() and state.tab=="quests" then render() end
  end)
  table.insert(UISpecialFrames,"ForeverWayfinderExpeditionsFrame")
  table.insert(UISpecialFrames,"ForeverWayfinderExpeditionMapViewer")
  frame:Hide()
end
local function drawDetails(entry)
  local boss=entry and entry.bosses and entry.bosses[state.boss]
  local pin=state.pin
  if not pin and state.view=="map" and state.tab=="route" then
    local map=guide.Map(entry,state.mapPage)
    for _,point in ipairs(map and map.pins or {}) do
      if state.boss and guide.BossForPin(entry,point)==state.boss then pin=point; break end
    end
  end
  frame.sideHeading:SetText(pin and ("MAP MARKER "..pin.label) or boss and ("BOSS "..state.boss.." / "..#entry.bosses) or "FIELD GUIDE")
  frame.bossName:SetText(boss and boss.name or pin and pin.name or "Before you go")
  frame.bossName:SetHeight(0)
  local top=math.max(316,236+frame.bossName:GetStringHeight()+12)
  frame.detailScroll:ClearAllPoints(); frame.detailScroll:SetPoint("TOPLEFT",R,-top); frame.detailScroll:SetHeight(666-top)
  local text=boss and (boss.family.." · "..boss.area.."\n\n"..boss.note)
    or pin and ("Atlas map reference.\n\n"..(pin.kind=="entrance" and "Entrance marked on the reference sheet." or "The marked location comes from Atlas. Live position and encounter details still need checking."))
    or entry and ((entry.summary or (guide.Map(entry) and "Select a map marker to see its name. Encounter strategies and loot are still being checked."
      or "Detailed encounters, loot and interior maps have not been cataloged yet."))
      ..(entry.entrance and "\n\n"..entry.entrance or "")
      ..(entry.wings and "\n\nWings: "..table.concat(entry.wings,", ") or ""))
    or "Try another search or reset the origin filter."
  frame.bossNote:SetText(text); frame.bossNote:SetHeight(0)
  -- Leave one line of breathing room for font substitution and client hinting.
  frame.bossNote:SetHeight(frame.bossNote:GetStringHeight()+style.Size("atlasBody")*1.18+3)
  local y=frame.bossNote:GetHeight()+8
  frame.lootHeading:SetShown(boss~=nil)
  if boss then
    frame.lootHeading:SetPoint("TOPLEFT",0,-y); y=y+32
  end
  for index,row in ipairs(frame.bossLoot) do
    local item=boss and boss.loot[index]
    if item then
      y=y+fillCard(row,y,item.name,item.armor.." · "..item.slot,function() guide.ToggleWish(item.id); render() end,item)
    else row:Hide() end
  end
  frame.detailChild:SetHeight(y)
  frame.detailScroll:SetVerticalScroll(math.min(frame.detailScroll:GetVerticalScroll(),math.max(0,y-frame.detailScroll:GetHeight())))
  enabled(frame.bossPrevious,boss and state.boss>1 or false)
  enabled(frame.bossNext,boss and state.boss<#entry.bosses or false)
end
render=function()
  if not frame then return end
  hideTooltip()
  local entries=guide.Query(state)
  local found
  for _,entry in ipairs(entries) do if entry.key==state.key then found=entry; break end end
  if not found and entries[1] then
    found=entries[1]; state.key=found.key; state.boss,state.route=1,1
    state.mapPage,state.pin,state.view=1,nil,"map"
    state.revealKey=found.key
    frame.mainScroll:SetVerticalScroll(0); frame.detailScroll:SetVerticalScroll(0)
  end
  if not found then state.key=nil; state.pin=nil end
  frame.entry=found
  local settings=guide.Settings(); settings.selectedKey=state.key; settings.tab=state.tab
  local rowHeight=math.ceil((style.Size("atlasBody")+style.Size("atlasMeta"))*1.18)+10
  local rowCount=math.min(ROWS,math.floor(414/rowHeight))
  if state.revealKey then
    for index,entry in ipairs(entries) do
      if entry.key==state.revealKey then state.page=math.ceil(index/rowCount); break end
    end
    state.revealKey=nil
  end
  local pages=math.max(1,math.ceil(#entries/rowCount)); state.page=math.max(1,math.min(state.page,pages))
  for key,control in pairs(frame.kinds) do selected(control,state.kind==key or (key=="all" and not state.kind)) end
  frame.origin.label:SetText(state.origin=="forever" and "New in Forever" or state.origin=="classic" and "Returning Classic" or "All origins")
  frame.count:SetText(#entries.." destinations")
  frame.searchHint:SetShown(state.search=="")
  for index,row in ipairs(frame.catalogRows) do
    local entry=index<=rowCount and entries[(state.page-1)*rowCount+index] or nil
    row.entry=entry; row:SetShown(entry~=nil)
    row:SetPoint("TOPLEFT",L,-(276+(index-1)*rowHeight)); row:SetHeight(rowHeight-2)
    row.title:SetHeight(style.Size("atlasBody")*1.18+1)
    row.meta:SetPoint("TOPLEFT",9,-(6+style.Size("atlasBody")*1.18))
    row.meta:SetHeight(style.Size("atlasMeta")*1.18+1)
    if entry then
      row.title:SetText(entry.name)
      row.meta:SetText(entry.minLevel..(entry.maxLevel~=entry.minLevel and "–"..entry.maxLevel or "")
        .." · "..(entry.origin=="forever" and "Forever" or "Classic"))
      selected(row,entry==found)
    end
  end
  frame.page:SetText(state.page.." / "..pages); enabled(frame.previous,state.page>1); enabled(frame.next,state.page<pages)
  frame.heading:SetText(found and found.name or "No destinations found")
  frame.meta:SetText(found and ("Level "..found.minLevel..(found.maxLevel~=found.minLevel and "–"..found.maxLevel or "")
    .." · "..(found.players and found.players.." players · " or "")..found.zone) or "Change your search to keep exploring.")
  for key,control in pairs(frame.tabs) do selected(control,key==state.tab); enabled(control,found~=nil) end
  local sheet=guide.Map(found,state.mapPage)
  local showMap=sheet and state.view~="sketch" and state.tab=="route"
  frame.diagram:SetShown(found and found.map and state.tab=="route" and not showMap or false)
  frame.diagram.mapReturn:SetShown(sheet~=nil)
  frame.mapPanel:SetShown(showMap or false)
  if sheet then
    local count=#guide.Maps(found)
    drawMap(frame.mapPanel,found,sheet,CW,358)
    drawMap(frame.mapViewer.surface,found,sheet,600,600)
    frame.mapPage:SetText(state.mapPage.." / "..count)
    frame.mapPrevious:SetShown(count>1); frame.mapNext:SetShown(count>1)
    enabled(frame.mapPrevious,state.mapPage>1); enabled(frame.mapNext,state.mapPage<count)
    frame.mapSketch:SetShown(found.map~=nil)
    frame.mapViewer.title:SetText(found.name)
    frame.mapViewer.caption:SetText(sheet.title.." · "..state.mapPage.." / "..count.."\nAtlas Team · Beta map reference")
    enabled(frame.mapViewer.previous,state.mapPage>1); enabled(frame.mapViewer.next,state.mapPage<count)
  else frame.mapViewer:Hide() end
  frame.toolbar:SetShown(found and state.tab=="loot" or false)
  frame.mainScroll:SetShown(found~=nil and state.tab~="route")
  frame.mainScroll:ClearAllPoints(); frame.mainScroll:SetPoint("TOPLEFT",C,-(state.tab=="quests" and 354 or 400))
  frame.mainScroll:SetHeight(state.tab=="quests" and 358 or 312)
  for _,row in ipairs(frame.cards) do row:Hide() end
  local records,y={},0
  if found and state.tab=="loot" then
    records=guide.Loot(found,{wishlist=state.wishlist,armor=state.armor~="Weapons" and state.armor or nil})
    if state.armor=="Weapons" then
      local weapons={Dagger=true,Staff=true,Axe=true}; local filtered={}
      for _,item in ipairs(records) do if weapons[item.armor] then filtered[#filtered+1]=item end end
      records=filtered
    end
    frame.wishlist.label:SetText(state.wishlist and "Account wishlist" or "All items")
    frame.armor.label:SetText(state.armor or "All item types"); selected(frame.wishlist,state.wishlist)
    for index,item in ipairs(records) do
      if not frame.cards[index] then frame.cards[index]=card(frame.mainChild,CW-24) end
      y=y+fillCard(frame.cards[index],y,(guide.IsWished(item.id) and "* " or "")..item.name,
        item.armor.." · "..item.slot.."\n"..item.boss.." · Beta reported",
        function() guide.ToggleWish(item.id); hideTooltip(); render() end,item)
    end
  elseif found and state.tab=="quests" then
    records=found.quests or {}
    for index,quest in ipairs(records) do
      local status=guide.QuestStatus(quest)
      if not frame.cards[index] then frame.cards[index]=card(frame.mainChild,CW-24) end
      y=y+fillCard(frame.cards[index],y,quest.name,quest.faction.." · "..status.."\n"..quest.note,
        status=="In your log" and function()
          frame:Hide()
          if QuestMapFrame and not QuestMapFrame:IsShown() and ToggleQuestLog then ToggleQuestLog() end
          if QuestMapFrame_ShowQuestDetails then QuestMapFrame_ShowQuestDetails(quest.id) end
        end or nil)
    end
  elseif found and found.map and not showMap then
    local route=found.routes[state.route]
    frame.routeMode.label:SetText(state.route==1 and "Quest circuit" or "Boss circuit")
    frame.diagram.title:SetText(state.route==1 and "BOSS CIRCUIT" or "QUEST CIRCUIT")
    for index,node in ipairs(frame.bossButtons) do
      node.title:SetText(found.bosses[index].name)
      node.mark:SetText(route.stops and route.stops[index] and "Quest stop" or found.bosses[index].family)
      node:SetBackdropColor(unpack(index==state.boss and colors.paperLight or colors.paper))
      node:SetBackdropBorderColor(unpack(index==state.boss and colors.route or colors.edge))
    end
  end
  frame.mainChild:SetHeight(math.max(1,y))
  frame.mainScroll:SetVerticalScroll(math.min(frame.mainScroll:GetVerticalScroll(),math.max(0,y-frame.mainScroll:GetHeight())))
  local isEmpty=not found or (state.tab=="route" and not found.map and not sheet) or (state.tab~="route" and #records==0)
  frame.empty:SetShown(isEmpty)
  frame.empty:SetText(not found and "No matching destination.\n\nTry a shorter name or choose All origins."
    or state.tab=="route" and "The interior is still uncharted.\n\n"..(found and found.opens and "Scheduled to open "..found.opens..".\n\n" or "")
      .."A surveyed floor plan and checked boss positions will appear here as they become available."
    or state.tab=="loot" and (state.wishlist and "Your wishlist is empty for this destination and filter.\n\nSwitch to All items and click a loot entry to save it."
      or "No loot records match this selection. Drop tables will grow as sources are checked.")
    or "Dungeon quests have not been cataloged for this destination yet.")
  local source=found and guide.Source(showMap and "atlas" or found.source)
  frame.source:SetText(source and source.label or "Forever Wayfinder · Expeditions")
  frame.caption:SetText(found and (showMap and (sheet.title.." · Atlas reference. Check passages and boss positions against live.")
    or state.tab=="route" and found.map and found.map.caption
    or state.tab=="loot" and "Beta-reported drops; rates are unknown. Hover for item details; click to wishlist."
    or state.tab=="quests" and "Beta quest references. Check faction and prerequisites before traveling."
    or "Reference entry. Interior map, encounters and loot still need verification.") or "")
  enabled(frame.zoneMap,found and found.zoneMapID~=nil or false)
  frame.reading.label:SetText("Text: "..style.Name())
  drawDetails(found); fit()
end
function addon.ShowExpeditions(key)
  local settings=guide.Settings(); if not settings then return end
  if not frame then
    local saved=guide.Get(settings.selectedKey)
    state.key=saved and saved.key or "hall-of-thanes"; state.kind=saved and saved.kind or "dungeon"
    state.revealKey=state.key
    state.tab=({route=true,loot=true,quests=true})[settings.tab] and settings.tab or "route"
    create()
    local position=settings.position
    if type(position)=="table" and position.point and position.relativePoint then
      frame:ClearAllPoints(); frame:SetPoint(position.point,UIParent,position.relativePoint,position.x or 0,position.y or 0)
    end
  end
  if guide.Get(key) then
    state.key,state.kind,state.origin,state.search=key,guide.Get(key).kind,nil,""
    state.page,state.boss,state.route,state.armor,state.wishlist=1,1,1,nil,nil
    state.mapPage,state.pin,state.view=1,nil,"map"
    state.revealKey=key
    state.loading=true; frame.search:SetText(""); state.loading=false
    frame.mainScroll:SetVerticalScroll(0); frame.detailScroll:SetVerticalScroll(0)
  end
  hideTooltip(); render(); frame:Show()
end
function addon.ToggleExpeditions()
  if frame and frame:IsShown() then frame:Hide() else addon.ShowExpeditions() end
end
function addon.RefreshExpeditionsReadingStyle() if frame then state.revealKey=state.key; render() end end
