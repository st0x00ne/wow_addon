-- Bounded WoW API test double. Unknown methods fail instead of silently passing.
local mock = {objects = {}, timers = {}, clock = 1790500000, quests = {}, completed = {}, mapID = 1424,
  zone = "Hillsbrad Foothills", subzone = "Tarren Mill", player = {name="Arya",realm="Forever",guid="Player-1-Arya",
  class="MAGE",className="Mage",race="Undead",faction="Horde",level=19}}
local methods = {}
function mock.object(kind,name,parent,template,layer)
  local value=setmetatable({kind=kind,name=name,parent=parent,template=template,layer=layer,
    points={},scripts={},events={},shown=true,text="",alpha=1}, {__index=methods})
  mock.objects[#mock.objects+1]=value
  if name then _G[name]=value end
  return value
end
function CreateFrame(kind,name,parent,template) return mock.object(kind,name,parent,template) end
function methods:CreateTexture(name,layer) return mock.object("Texture",name,self,nil,layer) end
function methods:CreateMaskTexture() return mock.object("MaskTexture",nil,self) end
function methods:AddMaskTexture(mask) self.mask=mask end
function methods:CreateFontString(name,layer,font) local v=mock.object("FontString",name,self,nil,layer); v.font=font; return v end
function methods:SetPoint(point,relative,relativePoint,x,y)
  if type(relative)=="number" then relative,relativePoint,x,y=self.parent,point,relative,relativePoint
  elseif not relative then relative,relativePoint=self.parent,point end
  self.points[point]={relative=relative,relativePoint=relativePoint or point,x=x or 0,y=y or 0}
end
function methods:ClearAllPoints() self.points={}; self.allPoints=nil end
function methods:SetAllPoints(parent) self.allPoints=parent or self.parent end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth()
  if self.allPoints then return self.allPoints:GetWidth() end
  if self.width then return self.width end
  local left,right=self.points.TOPLEFT,self.points.BOTTOMRIGHT or self.points.TOPRIGHT
  if left and right and left.relative==right.relative then return left.relative:GetWidth()+right.x-left.x end
  return 120
end
function methods:GetHeight()
  if self.allPoints then return self.allPoints:GetHeight() end
  if self.height then return self.height end
  local top,bottom=self.points.TOPLEFT,self.points.BOTTOMRIGHT
  if top and bottom and top.relative==bottom.relative then return top.relative:GetHeight()+top.y-bottom.y end
  if self.kind=="FontString" then return self:GetStringHeight() end
  return 24
end
function methods:GetLeft() return self.left or 80 end
function methods:GetRight() return self.right or 820 end
function methods:GetPoint() for point,p in pairs(self.points) do return point,p.relative,p.relativePoint,p.x,p.y end end
function methods:GetFrameLevel() return self.frameLevel or ((self.parent and self.parent:GetFrameLevel() or 0)+1) end
function methods:SetFrameLevel(value) self.frameLevel=value end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return self:GetScale()*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetCenter() return self.centerX or 400,self.centerY or 400 end
function methods:SetScale(value) self.scale=value end
function methods:SetText(value)
  self.text=tostring(value or "")
  if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end
end
function methods:GetText() return self.text end
function methods:SetFontObject(font) self.font=font end
function methods:SetFont(file,size,flags) self.fontFile,self.fontSize,self.fontFlags=file,size,flags end
function methods:GetStringHeight()
  local t=self.text:gsub("|T.-|t","   "):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  local h=self.fontSize or ((self.font=="QuestFont_Large" or self.font=="GameFontNormalLarge") and 20 or 12)
  local lines=0
  for p in (t.."\n"):gmatch("(.-)\n") do
    lines=lines+(self.wrap==false and 1 or math.max(1,math.ceil(#p*h*0.47/self:GetWidth())))
  end
  return lines*h*1.15
end
function methods:SetTextColor(...) self.color={...} end
function methods:SetColorTexture(...) self.color={...}; self.texture=nil end
function methods:SetTexture(value) self.texture=value end
function methods:SetHighlightTexture(value) self.highlightTexture=value end
function methods:SetAtlas(value) self.atlas=value end
function methods:SetVertexColor(...) self.vertexColor={...} end
function methods:SetBackdrop(value) self.backdrop=value end
function methods:SetBackdropColor(...) self.backdropColor={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:SetAlpha(value) self.alpha=value end
function methods:SetJustifyH(value) self.justifyH=value end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetWordWrap(value) self.wrap=value end
function methods:SetFrameStrata(value) self.strata=value end
function methods:SetClampedToScreen(value) self.clamped=value end
function methods:SetMovable(value) self.movable=value end
function methods:EnableMouse(value) self.mouse=value end
function methods:EnableMouseWheel(value) self.wheel=value end
function methods:RegisterForDrag() end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:SetMouseClickEnabled() end
function methods:StartMoving() end
function methods:StopMovingOrSizing() end
function methods:SetScrollChild(value) self.scrollChild=value; value.scrollParent=self end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) assert(value>=0); self.scroll=value end
function methods:SetScript(event,callback) self.scripts[event]=callback end
function methods:HookScript(event,callback)
  local old=self.scripts[event]; self.scripts[event]=function(...) if old then old(...) end; callback(...) end
end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:SetEnabled(value) self.enabled=value end
function methods:SetChecked(value) self.checked=value end
function methods:SetAutoFocus(value) self.autoFocus=value end
function methods:SetMultiLine(value) self.multiline=value end
function methods:SetMaxLetters(value) self.maxLetters=value end
function methods:SetFocus()
  if mock.focus and mock.focus~=self then mock.focus:ClearFocus() end
  mock.focus=self; self.focus=true
  if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end
end
function methods:ClearFocus()
  local hadFocus=self.focus; self.focus=false
  if mock.focus==self then mock.focus=nil end
  if hadFocus and self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:HasFocus() return self.focus end
function methods:HighlightText() end
function methods:SetOwner(owner) self.owner=owner end
function methods:IsOwned(owner) return self.owner==owner end
function methods:SetItemByID(id) self.itemID=id end
function methods:AddLine() end
function methods:Show()
  local was=self.shown; self.shown=true
  if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
  local was=self.shown; self.shown=false
  if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function mock.visible(object)
  while object do if not object.shown then return false end; object=object.parent end
  return true
end
function mock.fire(event,...)
  mock.clock=mock.clock+1
  local count=#mock.objects
  for i=1,count do local v=mock.objects[i]; if v.events[event] and v.scripts.OnEvent then v.scripts.OnEvent(v,event,...) end end
  mock.flush()
end
function mock.flush()
  for n=1,100 do
    if #mock.timers==0 then return end
    local queued=mock.timers; mock.timers={}
    for _,callback in ipairs(queued) do callback() end
  end
  error("timer loop")
end
function mock.click(control)
  assert(mock.visible(control),"clicked hidden control")
  assert(control.enabled~=false,"clicked disabled control")
  if control.scripts.OnClick then control.scripts.OnClick(control) end
  mock.flush()
end
for _,name in ipairs({"GameFontHighlightSmall","GameFontNormalLarge","GameFontNormalSmall","GameFontNormal",
  "GameFontHighlight","QuestFontNormalSmall","QuestFont_Large"}) do _G[name]=name end
STANDARD_TEXT_FONT="Friz"
UIParent=mock.object("Frame","UIParent"); UIParent:SetSize(1600,900)
Minimap=mock.object("Frame","Minimap",UIParent); Minimap:SetSize(140,140)
function GetCursorPosition() return mock.cursorX or 400,mock.cursorY or 400 end
GameTooltip=mock.object("Tooltip","GameTooltip")
UISpecialFrames={}; SlashCmdList={}
C_Timer={After=function(_,callback) mock.timers[#mock.timers+1]=callback end}
C_Texture={GetAtlasInfo=function() return {} end}
Enum={QuestTag={Dungeon=81}}
function GetServerTime() return mock.clock end
function time() return mock.clock end
function date(format) return format:find("%%Y") and "Sep 27, 2026 · 18:42" or "Sep 27" end
function UnitFullName() return mock.player.name,mock.player.realm end
function UnitName(unit) return unit=="player" and mock.player.name or mock.npc end
function UnitGUID() return mock.player.guid end
function GetRealmName() return mock.player.realm end
function UnitLevel() return mock.player.level end
function UnitClass() return mock.player.className,mock.player.class,mock.player.class=="MAGE" and 8 or 1 end
function UnitRace() return mock.player.race,mock.player.race,mock.player.race=="Undead" and 5 or 1 end
function UnitFactionGroup() return mock.player.faction end
function GetRealZoneText() return mock.zone end
function GetSubZoneText() return mock.subzone end
function IsInInstance() return mock.inside or false,mock.instanceType end
function GetInstanceInfo() return mock.instanceName,mock.instanceType,nil,nil,nil,nil,nil,mock.instanceID end
C_Map={GetBestMapForUnit=function() return mock.mapID end,GetMapInfo=function() return {name=mock.zone} end,
  GetPlayerMapPosition=function() return {GetXY=function() return .6144,.1906 end} end,
  CanSetUserWaypointOnMap=function() return true end,SetUserWaypoint=function(point) mock.waypoint=point; return true end}
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {map=map,x=x,y=y} end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function() mock.tracked=true end}
C_QuestLog={GetSelectedQuest=function() return mock.selected end,
  GetNumQuestLogEntries=function() return #mock.quests end,
  GetInfo=function(index) return mock.quests[index] end,
  GetLogIndexForQuestID=function(id) for i,q in ipairs(mock.quests) do if q.questID==id then return i end end end,
  GetQuestInfo=function(id) return mock.titles and mock.titles[id] end,
  GetTitleForQuestID=function(id) return mock.titles and mock.titles[id] end,
  GetQuestObjectives=function(id) return {{text="Collect 10 Gray Bear Tongues",numFulfilled=0,numRequired=10}} end,
  IsOnQuest=function(id) return mock.onQuest and mock.onQuest[id] or C_QuestLog.GetLogIndexForQuestID(id)~=nil end,
  IsQuestFlaggedCompleted=function(id) return mock.completed[id] or false end,
  GetQuestTagInfo=function(id) return mock.dungeonQuest==id and {tagID=81} or nil end,
  ShouldShowQuestRewards=function() return true end}
function GetQuestID() return mock.dialogID end
function GetTitleText() return mock.dialogTitle end
function GetQuestText() return mock.dialogText end
function GetObjectiveText() return mock.dialogObjective end
function GetQuestLogQuestText(index) local q=mock.quests[index]; return q and q.description,q and q.objectiveText end
function GetQuestLogRewardXP() return 180 end
function GetQuestLogRewardMoney() return 150 end
function GetNumQuestLogRewards() return 1 end
function GetNumQuestLogChoices() return 0 end
function GetQuestLogRewardInfo() return "Apothecary's Gloves",134400,1,nil,nil,3565 end
function GetItemInfo(id) return "Item "..id end
function GetItemIcon() return 134400 end
function GetCoinTextureString(money) return money.." copper" end
SOUNDKIT={IG_SPELLBOOK_OPEN=1,IG_SPELLBOOK_CLOSE=2,IG_ABILITY_PAGE_TURN=3}
function PlaySound(id) mock.lastSound=id end
WorldMapFrame=mock.object("Frame","WorldMapFrame"); WorldMapFrame:Hide()
function WorldMapFrame:SetMapID(id) mock.openMap=id end
function ToggleWorldMap() WorldMapFrame:Show() end
function ToggleQuestLog() if QuestMapFrame then QuestMapFrame:Show() end end
function QuestMapFrame_ShowQuestDetails(id) mock.openQuest=id end
-- The native quest-log integration is tested separately; prevent its hooks here.
QuestMapFrame=nil; QuestScrollFrame=nil
function mock.load(root, withUI)
  local addon={}
  for _,file in ipairs({"Data/ClassicQuests.lua","Data/ClassicChainDetails.lua","Data/QuestOpportunities.lua","Data/Zones.lua","Data/VerifiedRewards.lua","Core.lua","Journal.lua"}) do
    assert(loadfile(root.."/ForeverWayfinder/"..file))("ForeverWayfinder",addon)
  end
  if withUI then
    assert(loadfile(root.."/ForeverWayfinder/UI.lua"))("ForeverWayfinder",addon)
    assert(loadfile(root.."/ForeverWayfinder/JournalUI.lua"))("ForeverWayfinder",addon)
  end
  mock.fire("ADDON_LOADED","ForeverWayfinder")
  mock.fire("PLAYER_LOGIN")
  return addon
end
return mock
