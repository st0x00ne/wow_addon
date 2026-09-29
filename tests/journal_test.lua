local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
local addon=mock.load(root)
local j=addon.Journal
mock.fire("PLAYER_ENTERING_WORLD")
assert(#j.Query({kind="exploration"})==1)
mock.fire("ZONE_CHANGED_NEW_AREA")
assert(#j.Query({kind="exploration"})==1,"duplicate zone events added entries")
mock.dialogID,mock.dialogTitle,mock.npc=496,"Elixir of Suffering","Apothecary Lydon"
mock.dialogText="Bring Gray Bear Tongues and Creeper Ichor back to Tarren Mill."
mock.dialogObjective="Collect the ingredients for Apothecary Lydon."
mock.fire("QUEST_DETAIL")
assert(#j.Query({kind="quest"})==0,"merely viewing an offered quest recorded it")
mock.quests={{questID=496,title="Elixir of Suffering",level=22,description=mock.dialogText,objectiveText=mock.dialogObjective}}
mock.selected=496
mock.fire("QUEST_ACCEPTED",1,496)
local entry=j.Query({kind="quest"})[1]
assert(entry.questID==496 and entry.status=="active" and entry.acceptedNPC=="Apothecary Lydon")
assert(entry.x==.6144 and entry.offeredItems[1].itemID==3565)
local count=#j.Database().entries
mock.fire("QUEST_REMOVED",999999)
assert(#j.Database().entries==count,"unobserved removed quest created history")
for i=1,20 do mock.fire("QUEST_LOG_UPDATE") end
assert(#j.Database().entries==count,"quest updates duplicated entries")
assert(#j.Query({zoneKey="map:1424",class="MAGE",search="ELIXIR Lydon"})==1)
assert(#j.Query({search="%[.*"})==0,"search parsed Lua patterns")
-- Collapsed headers must not make an active quest look abandoned.
mock.quests={}; mock.onQuest={[496]=true}; mock.fire("QUEST_LOG_UPDATE")
assert(entry.status=="active")
mock.quests={{questID=888888,title="Hidden credit",isHidden=true}}
mock.fire("QUEST_LOG_UPDATE")
assert(#j.Query({search="Hidden credit"})==0,"hidden quest credit leaked into the journal")
mock.quests={}
mock.onQuest=nil
mock.fire("QUEST_TURNED_IN",496,180,150)
assert(entry.status=="completed" and entry.earnedXP==180 and entry.earnedMoney==150)
mock.completed[496]=true; mock.fire("QUEST_REMOVED",496)
assert(entry.status=="completed","removal after turn-in lost completion")
local note=j.NewNote()
assert(j.SaveNote(note.id,"Bear trail","Return at level 25 for the ridge path","class quest, hidden path"))
j.Toggle(note.id,"favorite"); j.Toggle(note.id,"revisit")
assert(#j.Query({favorite=true,revisit=true,search="RIDGE"})==1)
assert(not j.SaveNote(note.id," ","bad",""),"blank title accepted")
assert(not j.DeleteNote(entry.id),"quest history was deletable as a note")
mock.player={name="Borin",realm="Forever",guid="Player-1-Borin",class="WARRIOR",className="Warrior",race="Human",faction="Alliance",level=15}
mock.mapID,mock.zone,mock.subzone=1436,"Westfall","Sentinel Hill"
mock.fire("PLAYER_ENTERING_WORLD")
local other=j.NewNote(); j.SaveNote(other.id,"Sentinel watch","Ask about the coast.","coast")
assert(#j.Query({class="WARRIOR",race="Human",faction="Alliance",kind="note"})==1)
assert(#j.Query({class="MAGE",kind="note"})==1,"characters shared the wrong class")
assert(#j.Options("character")==2 and #j.Zones()==2)
mock.inside,mock.instanceType,mock.instanceName,mock.instanceID=true,"party","The Deadmines",36
mock.mapID,mock.zone=1581,"The Deadmines"; mock.fire("ZONE_CHANGED_NEW_AREA")
assert(#j.Query({kind="dungeon"})==1)
mock.fire("PLAYER_LEVEL_UP",16); mock.fire("PLAYER_LEVEL_UP",16)
assert(#j.Query({kind="milestone"})==1)
-- Serialize the same Lua table shape WoW writes, then load a fresh addon instance.
local function literal(value)
  if type(value)=="string" then return string.format("%q",value) end
  if type(value)~="table" then return tostring(value) end
  local out={"{"}
  for key,item in pairs(value) do out[#out+1]="["..literal(key).."]="..literal(item).."," end
  out[#out+1]="}"; return table.concat(out)
end
local saved=assert((loadstring or load)("return "..literal(j.Database())))()
ForeverWayfinderJournal=saved
-- Drop event frames from the previous simulated client.
mock.objects={UIParent,GameTooltip,WorldMapFrame}; mock.timers={}
local fresh=mock.load(root)
assert(#fresh.Journal.Query({search="ridge"})==1,"notes failed serialization / cold load")
assert(fresh.Journal.Database().sessions==2,"saved sessions did not resume")
local visits=fresh.Journal.Query({kind="dungeon"})[1].visits
mock.fire("PLAYER_ENTERING_WORLD")
assert(fresh.Journal.Query({kind="dungeon"})[1].visits==visits,"reload counted as another dungeon visit")
local newNote=fresh.Journal.NewNote()
assert(newNote.id>other.id,"entry IDs collided after reload")
assert(fresh.Journal.DeleteNote(newNote.id))
-- Newer schemas must remain untouched by an older addon.
local future={schema=999,entries={{id=999,title="Keep me"}}}
ForeverWayfinderJournal=future; mock.objects={UIParent,GameTooltip,WorldMapFrame}; mock.timers={}
local old=mock.load(root)
assert(old.Journal.error and ForeverWayfinderJournal==future and #future.entries==1)
print("PASS: journal events, deduplication, literal search, filters, notes, character isolation, cold-load persistence, schema protection")
