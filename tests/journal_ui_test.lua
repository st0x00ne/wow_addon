local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
mock.quests={{questID=496,title="Elixir of Suffering",level=22,
  description="Apothecary Lydon of Tarren Mill wants 10 Gray Bear Tongues and some Creeper Ichor. The bears roam the hills. Keep a record of the paths you find.",
  objectiveText="Bring the ingredients to Apothecary Lydon in Tarren Mill."}}
mock.selected=496
local addon=mock.load(root,true)
local j=addon.Journal
mock.fire("PLAYER_ENTERING_WORLD")
local arya=mock.player
for i=1,9 do local n=j.NewNote(); j.SaveNote(n.id,"Trail note "..i,"Follow the ridge at dusk.","trail, revisit") end
mock.player={name="Borin",realm="Forever",guid="Player-1-Borin",class="WARRIOR",className="Warrior",race="Human",faction="Alliance",level=15}
mock.mapID,mock.zone,mock.subzone=1436,"Westfall","Sentinel Hill"
local other=j.NewNote(); j.SaveNote(other.id,"The coast of Westfall","Look for the lighthouse.","coast")
mock.player=arya; mock.mapID,mock.zone,mock.subzone=1424,"Hillsbrad Foothills","Tarren Mill"; j.Character()
SlashCmdList.FOREVERWAYFINDER("journal"); mock.flush()
local book=assert(ForeverWayfinderJournalFrame)
assert(book:IsShown() and book.art.texture:find("JournalBook",1,true))
-- Search and categories belong to the header, above both independent book pages.
assert(book.search.shell.parent==book.header and book.reset.parent==book.header)
local bodyTop=-book.body.points.TOPLEFT.y
assert(book.header:GetHeight()<bodyTop,"the header overlaps the book")
for _,control in ipairs(book.filters) do
  assert(control.parent==book.header and -control.points.TOPLEFT.y+control:GetHeight()<=book.header:GetHeight())
end
assert(book.leftPage.parent==book.pages and book.rightPage.parent==book.pages)
assert(book.leftPage:GetWidth()==book.rightPage.points.TOPLEFT.x,"page halves overlap or leave a gap")
assert(book.selected.parent==book.rightPage and book.welcome.parent==book.rightPage)
for _,row in ipairs(book.rows) do
  assert(row.parent==book.leftPage and row.points.TOPLEFT.x+row:GetWidth()<book.leftPage:GetWidth(),"the index crosses the spine")
end
assert(book.next.enabled and not book.prev.enabled)
local firstID=book.rows[1].entry.id
mock.click(book.next)
assert(book.prev.enabled and book.rows[1].entry.id~=firstID)
mock.click(book.prev)
book.rows[1].scripts.OnMouseWheel(book.rows[1],-1); mock.flush()
assert(book.prev.enabled,"entry rows did not support mouse wheel paging")
book.search:SetText("ELIXIR"); mock.flush()
assert(book.rows[1].entry.questID==496 and not book.rows[2].shown)
assert(book.entryTitle:GetText()=="Elixir of Suffering")
mock.click(book.favorite); mock.click(book.revisit)
assert(j.Query({kind="quest"})[1].favorite and j.Query({kind="quest"})[1].revisit)
book.search:SetText("trail"); mock.flush()
local edited=book.rows[1].entry
book.note:SetFocus(); book.note:SetText("Return at level 25. The northern trail is quiet.")
book.tags:SetText("class quest, northern trail")
assert(book.save.enabled)
mock.click(book.rows[2])
assert(j.Entry(edited.id).note:find("northern trail",1,true),"changing entries lost the draft")
local selected=book.rows[2].entry
book.noteTitle:SetText(""); mock.click(book.save)
assert(book.feedback:GetText():find("title",1,true),"blank note title lacked feedback")
book.noteTitle:SetText("Trail with a view"); book.note:SetText(string.rep("A long field observation.\n",90))
assert(book.note:GetHeight()>book.noteScroll:GetHeight(),"long notes did not grow their scroll child")
mock.click(book.save)
assert(not book.save.enabled and j.Entry(selected.id).title=="Trail with a view")
local oldCount=#j.Database().entries
mock.click(book.delete); assert(#j.Database().entries==oldCount,"first delete click removed a note")
mock.click(book.delete); assert(#j.Database().entries==oldCount-1)
-- Search, class, character, race, faction, status and chapter filters combine.
book.search:SetText(""); mock.flush()
mock.click(book.filters[2]); assert(book.menu:IsShown())
mock.click(book.menu.rows[3]) -- Warrior (All, Mage, Warrior)
assert(book.rows[1].entry.class=="WARRIOR" and not book.rows[2].shown)
mock.click(book.zoneRows[2]); assert(book.rows[1].entry.zone=="Westfall")
-- Reset is a real native button, not a model shortcut.
local reset=book.reset
mock.click(reset)
local stableCount
-- Warm every page once: pooled detail lines may legitimately grow for longer entries.
book.search:SetText("elixir"); mock.flush(); book.search:SetText("trail"); mock.flush(); mock.click(reset)
stableCount=#mock.objects
for i=1,25 do book.search:SetText("elixir"); mock.flush(); book.search:SetText("trail"); mock.flush(); mock.click(reset) end
assert(#mock.objects==stableCount,"searching leaked native UI objects")
UIParent:SetSize(800,520); mock.fire("DISPLAY_SIZE_CHANGED")
assert(book:GetWidth()*book:GetScale()<=776 and book:GetHeight()*book:GetScale()<=496)
assert(book.clamped,"book could leave the screen")
UIParent:SetSize(1600,900); mock.fire("UI_SCALE_CHANGED")
book.search:SetText("elixir"); mock.flush()
mock.click(book.map)
assert(mock.openMap==1424 and mock.waypoint.map==1424 and mock.tracked and not book:IsShown())
addon.ToggleJournal(); mock.flush(); mock.click(book.chain)
assert(ForeverWayfinderPanel:IsShown() and ForeverWayfinderPanel.mode=="chain" and not book:IsShown())
-- Late-loaded native quest log installs a working Journal button.
function hooksecurefunc(name,callback)
  local old=_G[name]; _G[name]=function(...) local result=old(...); callback(...); return result end
end
function QuestLogQuests_Update() end
QuestMapFrame=CreateFrame("Frame","QuestMapFrame",UIParent)
QuestMapFrame.DetailsFrame=CreateFrame("Frame",nil,QuestMapFrame); QuestMapFrame.DetailsFrame:Hide()
QuestMapFrame.DetailsFrame.BackFrame=CreateFrame("Frame",nil,QuestMapFrame.DetailsFrame)
QuestMapFrame.DetailsFrame.BackFrame.BackButton=CreateFrame("Button",nil,QuestMapFrame.DetailsFrame.BackFrame)
QuestMapFrame.QuestsFrame=CreateFrame("Frame",nil,QuestMapFrame)
QuestMapFrame.QuestsFrame.ScrollFrame=CreateFrame("ScrollFrame",nil,QuestMapFrame.QuestsFrame)
QuestScrollFrame=CreateFrame("ScrollFrame",nil,QuestMapFrame)
QuestScrollFrame.titleFramePool={EnumerateActive=function() return function() end end}
mock.fire("ADDON_LOADED","Blizzard_QuestLog")
local journalButton
for _,v in ipairs(mock.objects) do if v.kind=="Button" and v.text=="Journal" then journalButton=v break end end
mock.click(assert(journalButton)); assert(book:IsShown())
if arg[2]=="preview" then
  book.search:SetText("elixir"); mock.flush()
  book.note:SetText("The northern ridge is quiet at dusk. Return when the next chapter sends me back through Hillsbrad.")
  mock.click(book.save)
  if arg[3]=="empty" then book.search:SetText("a place I have not discovered"); mock.flush()
  elseif arg[3]=="note" then book.search:SetText("trail"); mock.flush() end
  if book.scripts.OnUpdate then book.scripts.OnUpdate(book,.2) end
  assert(loadfile(root.."/tests/journal_preview_export.lua"))(mock,book)
else
  print("PASS: journal native UI, paging, search, filters, draft saving, long notes, deletion confirmation, object reuse, screen fit, map / chain / quest-log integration")
end
