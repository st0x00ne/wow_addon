local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
if arg[2]=="preview" and arg[5] then mock.fontMetrics=assert(loadfile(arg[5]))() end
local addon=mock.load(root,true)
local function character(class,race,faction,level,map)
  mock.player.class,mock.player.className=class,class=="WARRIOR" and "Warrior" or class=="PALADIN" and "Paladin" or "Mage"
  mock.player.race,mock.player.faction,mock.player.level=race,faction,level
  mock.mapID=map or 1436
  mock.quests,mock.completed,mock.knownSpells,mock.itemCounts={},{},{},{}
end
local function route(key,choices)
  for _,option in ipairs(choices or addon.GetSpecialQuestSuggestions()) do
    if option.key==key then return option end
  end
end
local families=0
for key,reference in pairs(addon.SpecialQuestRoutes) do
  families=families+1
  assert(addon.IsClassicQuest(reference.finale),"unseen Forever reward finale was bundled")
  assert(#reference.rewards>0 and reference.reason~="","curated chain lacks its payoff / reason")
  for _,item in ipairs(reference.rewards) do assert(type(item[1])=="number" and type(item[2])=="string") end
end
assert(families==15,"curated reward catalog changed unexpectedly")
character("MAGE","Human","Alliance",19)
local defias=assert(route("defias"))
assert(defias.quest[1]==65 and not defias.active and defias.mapID==1436,"Defias chain did not recommend its available first step")
assert(not route("sylvanas") and not route("fang"),"Horde chain suggested to Alliance")
assert(not route("verigan") and not route("whirlwind"),"another class's weapon quest suggested")
assert(not route("carrot"),"future reward offered before its required level")
local opportunities=addon.GetQuestOpportunities(1436)
assert(opportunities[1][1]==65,"special reward chain did not outrank ordinary local quests")
mock.completed[65]=true
assert(route("defias").quest[1]==132,"special chain failed to advance from completed starter")
mock.quests={{questID=155,title="The Defias Brotherhood",level=18}}
assert(route("defias").active and route("defias").quest[1]==155,"in-progress chain lost to an earlier starter")
mock.completed[166]=true
assert(not route("defias"),"completed finale resurfaced through an earlier quest")
character("MAGE","Undead","Horde",19)
assert(route("sylvanas") and route("fang"),"Horde leveling rewards missing")
assert(not route("defias") and not route("wrynn"),"Alliance chain suggested to Horde")
character("PALADIN","Human","Alliance",20)
assert(route("verigan"),"class weapon chain not available at its unlock level")
character("WARRIOR","Human","Alliance",30)
local whirlwind=assert(route("whirlwind"))
assert(whirlwind.route.level==40,"fixture must exercise an unlocked chain with a harder finale")
mock.completed[1719]=true
assert(route("whirlwind"),"finished Berserker training hid the subsequent weapon chain")
assert(addon.GetSuggestionPriority(1719)==1 and addon.GetSuggestionPriority(1792)==2,
  "class ability must outrank a special weapon reward")
character("MAGE","Human","Alliance",60)
assert(not route("defias"),"outleveled gear cluttered reward recommendations")
assert(route("carrot") and route("stopwatch"),"older utility rewards disappeared when outleveled")
assert(not route("eranikus"),"item-start quest suggested without its starter item")
local eranikusItem
for _,quest in ipairs(addon.SpecialQuestStarters) do if quest[1]==3373 then eranikusItem=quest[14] end end
mock.itemCounts[assert(eranikusItem)]=1
assert(route("eranikus") and not route("eranikus").mapID,"item-start reward did not require possession or invented a waypoint")
local wrynnItem
for _,quest in ipairs(addon.SpecialQuestStarters) do if quest[1]==373 then wrynnItem=quest[14] end end
character("MAGE","Human","Alliance",30)
assert(not route("wrynn"),"Unsent Letter starter suggested without the letter")
mock.itemCounts[assert(wrynnItem)]=1
assert(route("wrynn").quest[1]==373,"letter did not unlock its reference chain")
character("MAGE","Human","Alliance",19)
addon.ShowWhereNext()
local panel=assert(ForeverWayfinderPanel)
local function textLines()
  local result={}
  for _,v in ipairs(mock.objects) do
    if v.kind=="FontString" and v.parent==panel.scroll.scrollChild and mock.visible(v) then result[#result+1]=v end
  end
  table.sort(result,function(a,b) return a.points.TOPLEFT.y>b.points.TOPLEFT.y end)
  return result
end
local function findText(fragment)
  for _,line in ipairs(textLines()) do if line.text:find(fragment,1,true) then return line end end
end
local function controlFor(line)
  for _,v in ipairs(mock.objects) do
    if v.kind=="Button" and v.parent==line.parent and mock.visible(v) and
      (math.abs(v.points.TOPLEFT.y-line.points.TOPLEFT.y)<.1 or math.abs(v.points.TOPLEFT.y-line.points.TOPLEFT.y-10)<.1) then return v end
  end
end
mock.click(panel.whereCategories.special)
assert(panel.whereCategory=="special" and textLines()[1].text=="Special quests","Special category did not open")
assert(findText("Tunic of Westfall") and findText("Staff of Westfall"),"payoff names not shown")
assert(findText("Classic finale") and findText("Forever can change rewards"),"Classic reward provenance missing")
assert(not findText("Places to quest next"),"Special category leaked ordinary zones")
mock.click(assert(controlFor(assert(findText("Next step:")))))
assert(mock.waypoint.map==1436 and mock.tracked,"next available reward step did not set a starter waypoint")
local itemRow=assert(controlFor(assert(findText("Tunic of Westfall"))))
itemRow.scripts.OnEnter(itemRow)
assert(GameTooltip.itemID==2041,"reward hover did not show the item tooltip")
itemRow.scripts.OnLeave(itemRow)
mock.quests={{questID=155,title="The Defias Brotherhood",level=18}}
mock.fire("QUEST_LOG_UPDATE")
mock.click(assert(controlFor(assert(findText("In your log:")))))
assert(mock.openQuest==155,"active special step did not open the quest log")
mock.completed[166]=true; mock.quests={}; mock.fire("QUEST_LOG_UPDATE")
assert(findText("No unfinished reward chain"),"completed chain did not disappear from the open category")
mock.click(panel.whereCategories.zones)
assert(panel.whereCategory=="zones" and not findText("Special quests"),"Zones category did not filter reward catalog")
character("WARRIOR","Human","Alliance",30)
addon.ShowWhereNext(); mock.click(panel.whereCategories.all)
local ability=assert(findText("Warrior priorities"))
local special=assert(findText("Special quests"))
local places=assert(findText("Places to quest next"))
assert(ability.points.TOPLEFT.y>special.points.TOPLEFT.y and special.points.TOPLEFT.y>places.points.TOPLEFT.y,
  "All view did not put class essentials and reward chains before zones")
mock.click(panel.whereCategories.class)
assert(not findText("Special quests") and findText("Warrior priorities"),"Class category did not filter")
mock.click(panel.whereCategories.special)
addon.ReadingStyle.SetPreset("extra"); addon.ShowWhereNext()
assert(panel.whereCategory=="special","text size lost the selected category")
local bottom=0
for _,line in ipairs(textLines()) do
  local top=-line.points.TOPLEFT.y
  assert(top>=bottom,"special reward text overlaps at Extra Large size")
  bottom=top+line:GetStringHeight()
end
assert(addon.GetClassicChain(1718),"fixture needs a supported current chain")
addon.ShowClassicChain(1718)
for _,button in pairs(panel.whereCategories) do assert(not button:IsShown(),"Where category controls leaked onto Chain") end
addon.ShowWhereNext()
assert(panel.whereCategory=="special" and panel.whereCategories.special:IsShown(),"returning from Chain lost category state")
if arg[2]=="preview" then
  character("MAGE","Undead","Horde",19,1421)
  mock.mapNames={ [1453]="Stormwind",[1458]="Undercity" }
  for _,zone in ipairs(addon.Zones) do mock.mapNames[zone[1]]=zone[2] end
  panel.whereCategory="special"
  addon.ReadingStyle.SetPreset(arg[4] or "standard"); addon.ShowWhereNext()
  assert(loadfile(root.."/tests/journal_preview_export.lua"))(mock,panel)
else
  print("PASS: special reward catalog, faction / class / level / progress filters, utility rewards, item starters, priority order, category navigation, reward tooltips, waypoints, live updates, quest-log actions and Extra Large layout")
end
