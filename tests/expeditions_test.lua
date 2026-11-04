local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
if arg[2]=="preview" and arg[5] then mock.fontMetrics=assert(loadfile(arg[5]))() end
if arg[2]=="layout" and arg[3] then mock.fontMetrics=assert(loadfile(arg[3]))() end
local addon=mock.load(root,true)
local guide=addon.Expeditions
if arg[2]=="preview" then
  addon.ReadingStyle.SetPreset(arg[4] or "standard")
  addon.ShowExpeditions("hall-of-thanes")
  local f=ForeverWayfinderExpeditionsFrame
  if arg[3]=="expeditions-loot" then
    mock.click(f.tabs.loot); mock.click(f.cards[1])
  elseif arg[3]=="expeditions-quests" then mock.click(f.tabs.quests)
  elseif arg[3]=="expeditions-route" then mock.click(f.mapSketch); mock.click(f.routeMode); mock.click(f.bossButtons[4])
  elseif arg[3]=="expeditions-fullmap" then mock.click(f.mapZoom)
  elseif arg[3]=="expeditions-lordaeron" then addon.ShowExpeditions("ruins-of-lordaeron")
  elseif arg[3]=="expeditions-dalaran" then addon.ShowExpeditions("city-of-dalaran"); mock.click(f.mapNext)
  elseif arg[3]=="expeditions-raid" then addon.ShowExpeditions("hyjal-summit")
  elseif arg[3]=="expeditions-empty" then f.search:SetText("[no matching destination]") end
  assert(loadfile(root.."/tests/journal_preview_export.lua"))(mock,f)
  return
end

local dungeons=guide.Query({kind="dungeon"})
assert(#dungeons==29 and #guide.Query({kind="raid"})==3,"announced roster is incomplete")
assert(#guide.Query({kind="dungeon",origin="forever"})==9,"new dungeon roster is incomplete")
assert(not guide.Get("molten-core"),"unannounced Classic raid was presented as available")
assert(#guide.Query({search="["})==0,"search interpreted Lua patterns")
assert(#guide.Query({search="hall ironforge"})==1,"multiword region search failed")
local keys,items={},{}
for _,entry in ipairs(addon.ExpeditionCatalog) do
  assert(not keys[entry.key],"duplicate destination key"); keys[entry.key]=true
  assert(guide.Source(entry.source) and entry.status~="live","missing source or invented live verification")
  for _,boss in ipairs(entry.bosses or {}) do
    for _,item in ipairs(boss.loot) do
      assert(not items[item.id],"duplicate item record"); items[item.id]=true
      assert(item.status=="beta" and guide.Source(item.source) and not item.chance,"drop provenance lost")
    end
  end
end
local hall=guide.Get("hall-of-thanes")
assert(#hall.bosses==4 and #guide.Loot(hall)==12 and #hall.quests==5)
assert(hall.map.kind=="schematic" and hall.map.status=="unverified","diagram masquerades as a surveyed map")
local mapCount,sheetCount=0,0
for key,maps in pairs(addon.ExpeditionMaps) do
  assert(guide.Get(key),"map is attached to a destination outside the catalog")
  mapCount=mapCount+1
  for _,map in ipairs(maps) do
    sheetCount=sheetCount+1
    assert(map.texture:match("^[A-Za-z0-9_]+$"),"unsafe map texture path")
    assert(map.status=="beta-reference" and guide.Source(map.source),"map was presented as live verified")
    for _,pin in ipairs(map.pins) do assert(pin.x>=0 and pin.x<=512 and pin.y>=0 and pin.y<=512) end
  end
end
assert(mapCount==25 and sheetCount==34,"map coverage changed without updating the review fixtures")
assert(#guide.Loot(hall,{armor="Cloth"})==3,"armor filter mixed incompatible item categories")
assert(not guide.ToggleWish(999999),"unknown item entered the saved wishlist")
assert(guide.ToggleWish(270256) and guide.IsWished(270256))
assert(#guide.Loot(hall,{wishlist=true})==1,"wishlist filtering failed")
guide.ToggleWish(270256)

addon.ShowExpeditions("hall-of-thanes")
local f=ForeverWayfinderExpeditionsFrame
assert(f:IsShown() and f.entry==hall and mock.visible(f.mapPanel) and not mock.visible(f.diagram))
assert(f.mapPanel.image:GetWidth()==f.mapPanel.image:GetHeight(),"square floor plan was stretched")
mock.click(f.mapPanel.pins[4])
assert(f.bossName:GetText()=="Magmatus","Atlas marker 3 was confused with guide boss 3")
mock.click(f.mapPanel.pins[3])
assert(f.bossName:GetText()=="Plunder","Atlas marker 2 was confused with guide boss 2")
mock.click(f.mapPanel.pins[1])
assert(f.bossName:GetText()=="Entrance" and not f.bossLoot[1]:IsShown(),"entrance inherited boss loot")
mock.click(f.mapZoom); assert(f.mapViewer:IsShown())
mock.click(f.mapViewer.close); assert(not f.mapViewer:IsShown())
mock.click(f.mapSketch)
mock.click(f.bossButtons[4])
assert(f.bossName:GetText()=="Durgen Dirgehammer","boss pin did not open its details")
mock.click(f.routeMode)
assert(f.bossButtons[1].mark:GetText()=="Quest stop" and f.bossButtons[4].mark:GetText()=="Quest stop")
mock.click(f.tabs.loot)
assert(mock.visible(f.cards[1]) and not mock.visible(f.diagram))
mock.click(f.cards[1])
assert(guide.IsWished(f.cards[1].item.id),"loot click did not save a wishlist entry")
mock.click(f.wishlist)
assert(f.cards[1]:IsShown() and not f.cards[2]:IsShown(),"wishlist did not narrow the visible loot")
mock.click(f.cards[1])
assert(f.empty:IsShown() and not f.cards[1]:IsShown(),"removing the final wish left a stale row")
mock.click(f.wishlist)
mock.click(f.armor)
assert(f.cards[1].item.armor=="Cloth" and not f.cards[5]:IsShown())
for _=1,4 do mock.click(f.armor) end
-- Native item data can arrive late. Do not update a tooltip after the pointer leaves.
local getItemInfo=GetItemInfo
GetItemInfo=function() return nil end
f.cards[1].scripts.OnEnter(f.cards[1])
assert(GameTooltip:GetText()==f.cards[1].item.name,"uncached item has no readable fallback")
GetItemInfo=getItemInfo
mock.fire("GET_ITEM_INFO_RECEIVED",f.cards[1].item.id,true)
assert(GameTooltip.itemID==f.cards[1].item.id,"loaded item tooltip did not refresh")
f.cards[1].scripts.OnLeave(f.cards[1])
mock.fire("GET_ITEM_INFO_RECEIVED",f.cards[1].item.id,true)
assert(not GameTooltip:IsShown(),"late item event reopened a dismissed tooltip")
-- Quest states come from the client; reference rows never create quest progress.
mock.onQuest={[96403]=true}; mock.completed[96394]=true
mock.click(f.tabs.quests)
assert(f.cards[1].meta:GetText():find("In your log",1,true))
assert(f.cards[2].meta:GetText():find("Completed",1,true))
mock.click(f.cards[1]); assert(mock.openQuest==96403)
addon.ShowExpeditions("hall-of-thanes")
mock.click(f.tabs.route)
local waypoint=mock.waypoint
mock.click(f.zoneMap)
assert(mock.openMap==1455 and mock.waypoint==waypoint,"schematic created an invented waypoint")
addon.ShowExpeditions("hyjal-summit")
assert(f.entry.kind=="raid" and f.empty:GetText():find("9 Dec 2026",1,true))
assert(not mock.visible(f.diagram) and not mock.visible(f.mapPanel) and not f.bossNext.enabled,"raid inherited stale boss pins")
mock.click(f.tabs.loot)
assert(f.empty:IsShown() and not f.cards[1]:IsShown(),"raid inherited dungeon loot")
mock.click(f.tabs.route)
f.search:SetText("[missing]")
assert(f.entry==nil and f.empty:IsShown() and not f.zoneMap.enabled)
f.search:SetText("")
mock.click(f.kinds.dungeon)
local firstKey=f.catalogRows[1].entry.key
mock.click(f.next); assert(f.catalogRows[1].entry.key~=firstKey)
mock.click(f.previous); assert(f.catalogRows[1].entry.key==firstKey)
mock.click(f.origin); assert(#guide.Query({kind="dungeon",origin="forever"})==9)
for _,row in ipairs(f.catalogRows) do if row:IsShown() then assert(row.entry.origin=="forever") end end
mock.click(f.origin)
for _,row in ipairs(f.catalogRows) do if row:IsShown() then assert(row.entry.origin=="classic") end end

addon.ShowExpeditions("hall-of-thanes")
mock.click(f.tabs.route)
mock.click(f.mapSketch)
local objects=#mock.objects
for _=1,12 do
  mock.click(f.tabs.loot); mock.click(f.tabs.quests); mock.click(f.tabs.route)
  mock.click(f.bossButtons[4]); mock.click(f.bossButtons[1])
end
assert(#mock.objects==objects,"browsing leaked native frames")
for _,preset in ipairs({"standard","large","extra"}) do
  addon.ReadingStyle.SetPreset(preset)
  for _,node in ipairs(f.bossButtons) do
    assert(node.title:GetStringHeight()<=node.title:GetHeight()+1,"boss name clipped at "..preset)
  end
  for _,row in ipairs(f.catalogRows) do
    if row:IsShown() then
      assert(row.title:GetStringHeight()<=row.title:GetHeight()+1,"index text clipped")
      assert(-row.points.TOPLEFT.y+row:GetHeight()<=696,"index overlapped pagination")
    end
  end
  mock.click(f.tabs.loot)
  f.mainScroll.scripts.OnMouseWheel(f.mainScroll,-100)
  assert(f.mainScroll:GetVerticalScroll()>0,"long loot list could not scroll")
  mock.click(f.tabs.route)
end
-- Page changes retain sheet geometry, clear stale markers, and fit every map.
addon.ShowExpeditions("city-of-dalaran")
assert(#guide.Maps(f.entry)==2 and not f.mapPrevious.enabled)
local visibleSelection
for _,row in ipairs(f.catalogRows) do if row:IsShown() and row.selected and row.entry.key=="city-of-dalaran" then visibleSelection=true end end
assert(visibleSelection,"opening a destination did not reveal it in the index")
local firstTexture=f.mapPanel.image.texture
mock.click(f.mapNext)
assert(f.mapPanel.image.texture~=firstTexture and not f.mapNext.enabled)
mock.click(f.mapZoom); assert(f.mapViewer:IsShown())
addon.ShowExpeditions("hyjal-summit")
assert(not f.mapViewer:IsShown(),"uncharted destination left the previous map window open")
for pass=1,2 do
  for key in pairs(addon.ExpeditionMaps) do
    addon.ShowExpeditions(key)
    for page=1,#guide.Maps(f.entry) do
      assert(mock.visible(f.mapPanel))
      if page<#guide.Maps(f.entry) then mock.click(f.mapNext) end
    end
  end
  if pass==1 then objects=#mock.objects else assert(#mock.objects==objects,"map browsing leaked frame objects") end
end
addon.ShowExpeditions("hall-of-thanes")
mock.click(f.tabs.route)
UIParent:SetSize(800,600); mock.fire("DISPLAY_SIZE_CHANGED")
assert(f:GetWidth()*f:GetScale()<=776.1 and f:GetHeight()*f:GetScale()<=576.1,"window escaped a small screen")
mock.click(f.journal)
mock.click(ForeverWayfinderJournalFrame.expeditions)
assert(f:IsShown(),"personal journal could not open Expeditions")
mock.click(f.atlas); mock.click(ForeverWayfinderAtlasFrame.expeditions)
assert(f:IsShown(),"Atlas could not open Expeditions")
SlashCmdList.FOREVERWAYFINDER("expeditions"); assert(not f:IsShown())
SlashCmdList.FOREVERWAYFINDER("dungeons"); assert(f:IsShown())
f.scripts.OnDragStop(f)
assert(guide.Settings().position.point,"window position was not saved")
guide.ToggleWish(270256)
local saved=guide.Settings()
assert(saved.wishlist[270256] and saved.selectedKey=="hall-of-thanes" and saved.tab=="route")
-- Round-trip the SavedVariables shape into a fresh addon, including its reading
-- preset and window position, rather than keeping the existing Lua table alive.
local function serialize(value)
  if type(value)=="string" then return string.format("%q",value) end
  if type(value)~="table" then return tostring(value) end
  local fields={}
  for key,item in pairs(value) do fields[#fields+1]="["..serialize(key).."]="..serialize(item) end
  return "{"..table.concat(fields,",").."}"
end
local serialized=serialize(addon.Journal.Database())
local restored=assert((loadstring or load)("return "..serialized))()
local freshMock=assert(loadfile(root.."/tests/wow_mock.lua"))()
ForeverWayfinderJournal=restored
local fresh=freshMock.load(root,true)
fresh.ShowExpeditions()
assert(fresh.Expeditions.IsWished(270256),"wishlist did not survive a cold load")
assert(ForeverWayfinderExpeditionsFrame.entry.key=="hall-of-thanes","last destination did not survive a cold load")
assert(fresh.Expeditions.Settings().position.point,"window position did not survive a cold load")
print("PASS: Expeditions roster / provenance, 34 real map sheets, correct boss identities, map paging / zoom / isolation, literal filters, schematic routes, loot / wishlist / cold loads, late tooltips, quest states, frame reuse, reading sizes and screen fit")
