local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
if arg[2]=="preview" and arg[5] then mock.fontMetrics=assert(loadfile(arg[5]))() end
local addon=mock.load(root,true)
local names={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",
  SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid"}
local function character(class,race,faction,level,map)
  mock.player.class,mock.player.className=class,names[class]
  mock.player.race,mock.player.faction,mock.player.level=race,faction,level
  mock.mapID=map or 1424
  mock.quests,mock.completed,mock.knownSpells,mock.onQuest={},{},{},{}
  mock.classQuest=nil
end
local function route(key,choices)
  for _,option in ipairs(choices or addon.GetClassQuestPriorities()) do
    if option.routeKey==key then return option end
  end
end
local function contains(id,choices)
  for _,option in ipairs(choices or addon.GetClassQuestPriorities()) do
    if option.quest[1]==id then return option end
  end
end
local scenarios={
  {"WARRIOR","Human","Alliance",30,"defensive"},
  {"PALADIN","Human","Alliance",40,"redemption"},
  {"HUNTER","Orc","Horde",19,"pets"},
  {"ROGUE","Orc","Horde",24,"poisons"},
  {"PRIEST","Dwarf","Alliance",20,"priest_a_lack_of_fear"},
  {"SHAMAN","Orc","Horde",30,"earth"},
  {"MAGE","Human","Alliance",60,"water_rank"},
  {"WARLOCK","Human","Alliance",30,"voidwalker"},
  {"DRUID","Tauren","Horde",19,"bear"},
}
for _,s in ipairs(scenarios) do
  character(s[1],s[2],s[3],s[4])
  local choices=addon.GetClassQuestPriorities()
  assert(route(s[5],choices),"missing important route for "..s[1]..": "..s[5])
  local seen,last={},0
  for _,option in ipairs(choices) do
    assert(option.priority>=last,"optional class quest outranked an ability route")
    last=option.priority
    assert(not seen[option.routeKey or option.quest[1]],"duplicate route / breadcrumb")
    seen[option.routeKey or option.quest[1]]=true
    assert(option.quest[3]<=s[4],"future quest was suggested before its required level")
    assert(option.quest[12]:find(s[3]=="Horde" and "H" or "A",1,true),"hostile starter suggested")
  end
end
character("DRUID","Tauren","Horde",19)
local bear=assert(route("bear"))
assert(bear.quest[4]<mock.player.level-7,"fixture must exercise an overdue unlock")
assert(bear.mapID==1456,"Thunder Bluff class start omitted outside the zone bands")
assert(not contains(6002),"final quest offered before prerequisites")
mock.completed[6002]=true
assert(not route("bear"),"completed ability route resurfaced through another breadcrumb")
character("DRUID","NightElf","Alliance",19,1450)
mock.completed[5921]=true
local nextBear=assert(route("bear"))
assert(nextBear.quest[1]==5929 and nextBear.mapID==1450,"Moonglade follow-up did not replace earlier starts")
mock.knownSpells[5487]=true
assert(not route("bear"),"already learned ability was suggested as a new unlock")
mock.knownSpells={ [9634]=true }
assert(not route("bear"),"Dire Bear Form did not suppress the obsolete Bear route")
character("WARLOCK","Human","Alliance",30,1453)
local void=assert(route("voidwalker"))
assert(void.mapID==1453,"capital city class quest not found")
mock.quests={{questID=1688,title="Surena Caledon",level=10}}
local active=assert(route("voidwalker"))
assert(active.active and active.quest[1]==1688,"active route did not replace alternate starts")
mock.completed[1685]=true
mock.quests={}
assert(route("voidwalker").quest[1]==1688,"completed starter did not advance to available follow-up")
mock.knownSpells[697]=true
assert(not route("voidwalker"),"known Voidwalker spell did not suppress its route")
character("HUNTER","Orc","Horde",19)
mock.knownSpells={ [1515]=true }
assert(route("pets"),"partial taming knowledge hid the rest of pet training")
mock.knownSpells={ [1515]=true,[883]=true,[982]=true,[6991]=true }
assert(not route("pets"),"complete pet training still suggested")
character("PRIEST","Dwarf","Alliance",20)
assert(not route("priest_devouring_plague"),"Undead racial ability suggested to a Dwarf")
local fear=assert(route("priest_a_lack_of_fear"))
mock.knownSpells[19337]=true
assert(route("priest_a_lack_of_fear"),"server teaching spell mistaken for a learned ability")
mock.knownSpells[6346]=true
assert(not route("priest_a_lack_of_fear"),"learned Fear Ward not detected")
mock.knownSpells={}
mock.completed[fear.quest[1]]=true
assert(not route("priest_a_lack_of_fear"),"completed priest alternative resurfaced")
character("PALADIN","Undead","Horde",20)
assert(not route("redemption"),"fabricated a Classic trainer route for a new Forever combination")
character("MAGE","Human","Alliance",19)
assert(not route("water_rank") and not route("pig"),"future level-60 mage quest suggested")
local zones=addon.GetZoneSuggestions()
assert(#zones>0,"ordinary zone suggestions disappeared without an available ability quest")
mock.classQuest=900001
mock.quests={{questID=900001,title="A Newly Discovered Class Quest",level=19}}
assert(contains(900001).active,"native class tag did not promote an accepted Forever quest")
assert(not addon.IsClassicQuest(900001),"fixture must be outside the bundled Classic reference")
character("SHAMAN","Orc","Horde",30)
addon.ShowWhereNext()
local panel=assert(ForeverWayfinderPanel)
local function visibleText()
  local result={}
  for _,v in ipairs(mock.objects) do
    if v.kind=="FontString" and v.parent==panel.scroll.scrollChild and mock.visible(v) then result[#result+1]=v end
  end
  table.sort(result,function(a,b) return a.points.TOPLEFT.y>b.points.TOPLEFT.y end)
  return result
end
local function clickText(fragment)
  for _,line in ipairs(visibleText()) do
    if line.text:find(fragment,1,true) then
      for _,button in ipairs(mock.objects) do
        if button.kind=="Button" and button.parent==line.parent and mock.visible(button)
          and (math.abs(button.points.TOPLEFT.y-(line.points.TOPLEFT.y+10))<.1
            or math.abs(button.points.TOPLEFT.y-line.points.TOPLEFT.y)<.1) then
          mock.click(button); return
        end
      end
    end
  end
  error("missing clickable text: "..fragment)
end
local texts=visibleText()
assert(texts[1].text=="Shaman priorities","class priorities not above zone suggestions")
clickText("Call of Earth")
assert(mock.waypoint and mock.waypoint.map==1411 and mock.tracked,"class starter click did not set its waypoint")
local before=#texts
clickText("Show all")
assert(panel.showAllClasses and #visibleText()>before,"show-all class priorities did not expand")
clickText("Show fewer")
assert(not panel.showAllClasses,"show-fewer class priorities did not fold")
character("DRUID","Tauren","Horde",19)
addon.ShowWhereNext()
mock.knownSpells[5487]=true
mock.fire("SPELLS_CHANGED")
for _,line in ipairs(visibleText()) do assert(not line.text:find("Bear Form",1,true),"open panel kept a learned ability reminder") end
mock.completed[6130]=true
mock.fire("QUEST_LOG_UPDATE")
for _,line in ipairs(visibleText()) do assert(not line.text:find("Cure Poison",1,true),"open panel kept a completed route") end
character("WARLOCK","Human","Alliance",30)
mock.quests={{questID=1688,title="Surena Caledon",level=10}}
addon.ShowWhereNext()
clickText("Surena Caledon")
assert(mock.openQuest==1688,"active priority click did not open the quest log")
addon.ReadingStyle.SetPreset("extra"); addon.ShowWhereNext()
local bottom=0
for _,line in ipairs(visibleText()) do
  local top=-line.points.TOPLEFT.y
  assert(top>=bottom,"priority text overlaps at Extra Large size")
  bottom=top+line:GetStringHeight()
end
character("WARLOCK","Human","Alliance",30)
assert(route("voidwalker"),"legacy API fixture has no available Voidwalker route")
local modern=C_SpellBook
C_SpellBook=nil
IsPlayerSpell=function(id) return id==697 end
assert(not route("voidwalker"),"legacy spell API fallback failed")
C_SpellBook=modern; IsPlayerSpell=nil
if arg[2]=="preview" then
  character("DRUID","Tauren","Horde",19)
  mock.zone="Thunder Bluff"
  mock.mapNames={ [1450]="Moonglade",[1456]="Thunder Bluff" }
  for _,zone in ipairs(addon.Zones) do mock.mapNames[zone[1]]=zone[2] end
  addon.ReadingStyle.SetPreset(arg[4] or "standard")
  addon.ShowWhereNext()
  assert(loadfile(root.."/tests/journal_preview_export.lua"))(mock,panel)
  return
end
-- Exercise data gates independently of route labels using a small synthetic set.
character("WARRIOR","Human","Alliance",30)
local function q(id) return {id,"Gate "..id,10,10,1,1,50,50,nil,nil,"Trainer","A",1453} end
addon.ClassQuestStarters={q(900101),q(900102),q(900103),q(900104),q(900105),q(900106)}
addon.ClassQuestRoutes.test={"Test ability",{900199},nil}
for _,quest in ipairs(addon.ClassQuestStarters) do addon.ClassQuestInfo[quest[1]]={1,"test",nil,nil,nil,nil,nil,nil,true} end
addon.ClassQuestInfo[900101][3]={900201}; mock.onQuest[900201]=true
addon.ClassQuestInfo[900102][4]=900202
addon.ClassQuestInfo[900103][5]=20
addon.ClassQuestInfo[900104][6]={900204}; mock.completed[900204]=true
addon.ClassQuestInfo[900105][7]={900205}
addon.ClassQuestInfo[900106][8]={900206}; mock.onQuest[900206]=true
assert(not route("test"),"unsupported phase, level, alternative or parent gates ignored")
mock.onQuest[900202]=true
assert(route("test").quest[1]==900102,"parent-active gate did not allow the quest")
addon.ClassQuestInfo[900102][9]=false
assert(not route("test"),"unsupported requirements were offered")
mock.completed[900205]=true
assert(route("test").quest[1]==900105,"available-starting-with gate did not allow a completed prerequisite")
print("PASS: all nine classes, overdue unlocks, capitals / Moonglade, prerequisites, alternatives, learned abilities, active quests, Forever class tags, zone fallback, phase gates, priority UI / waypoints, folding and Extra Large text")
