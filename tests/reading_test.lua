local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
if arg[2]=="preview" and arg[5] then mock.fontMetrics=assert(loadfile(arg[5]))() end
mock.quests={{questID=496,title="Elixir of Suffering",level=22,
  objectiveText="Bring the ingredients to Apothecary Lydon in Tarren Mill.",
  description="Apothecary Lydon of Tarren Mill wants 10 Gray Bear Tongues and some Creeper Ichor. Follow the northern ridge and keep a record of the paths you find."}}
mock.selected=496
local addon=mock.load(root,true)
local style=addon.ReadingStyle
mock.fire("PLAYER_ENTERING_WORLD")
addon.ToggleJournal(); mock.flush()
local book=assert(ForeverWayfinderJournalFrame)
book.search:SetText("elixir"); mock.flush()
assert(style.Name()=="Standard" and book.note.fontSize==16 and book.search.fontSize==14)
assert(book.rows[1].meta.fontSize>=13 and book.zoneRows[1].label.fontSize>=14)
assert(not book.noteShell:IsShown(),"an empty personal note took the quest's reading space")
local openHeight=book.detailScroll:GetHeight()
mock.click(book.notesToggle); assert(book.noteShell:IsShown() and book.detailScroll:GetHeight()<openHeight)
book.note:SetText(string.rep("Keep this observation for a later visit.\n",30))
local draft=book.note:GetText()
mock.click(book.textSize)
assert(style.Name()=="Large" and addon.Journal.Database().readingPreset=="large")
assert(book.note:GetText()==draft and not book.save.enabled,"changing text size lost the draft or failed to save it")
assert(book.note:GetHeight()>book.noteScroll:GetHeight(),"the larger note font did not remeasure its scroll child")
mock.click(book.notesToggle)
assert(not book.noteShell:IsShown() and addon.Journal.Entry(book.rows[1].entry.id).note==draft)
mock.click(book.textSize)
assert(style.Name()=="Extra Large" and book.note.fontSize==20 and book.rows[1].meta.fontSize==15)
assert(book.next.normalFont.fontSize==16,"buttons did not use the chosen reading size")
local entry=addon.Journal.Entry(book.rows[1].entry.id)
entry.title="A Particularly Long Account of Elixir of Suffering and the Northern Hills"
addon.RefreshJournal(); mock.flush()
local titleBottom=-book.entryTitle.points.TOPLEFT.y+book.entryTitle:GetStringHeight()
assert(-book.entryMeta.points.TOPLEFT.y>=titleBottom+9,"a long title overlapped its metadata")
local descriptionTop=-book.detailScroll.points.TOPLEFT.y
assert(descriptionTop>-book.entryMeta.points.TOPLEFT.y+book.entryMeta:GetStringHeight(),"metadata overlapped the description")
assert(descriptionTop+book.detailScroll:GetHeight()<=-book.map.points.TOPLEFT.y,"description overlapped action buttons")
local count=0
for _,v in ipairs(mock.objects) do if v.kind=="Font" then count=count+1 end end
for i=1,12 do style.Cycle() end
local after=0
for _,v in ipairs(mock.objects) do if v.kind=="Font" then after=after+1 end end
assert(count==after,"changing text size leaked native font objects")
book:Hide(); addon.ShowClassicChain(496)
local panel=assert(ForeverWayfinderPanel)
assert(panel:IsShown() and panel.readingButton.normalFont.fontSize==16)
local bodyFound=false
for _,v in ipairs(mock.objects) do
  if v.kind=="FontString" and v.parent==panel.scroll.scrollChild and mock.visible(v) and v.fontSize==20 then bodyFound=true end
end
assert(bodyFound,"Classic chain descriptions did not receive the larger reading font")
mock.click(panel.readingButton); assert(style.Name()=="Standard")
addon.ShowWhereNext(); mock.click(panel.readingButton)
assert(style.Name()=="Large" and panel.mode=="where" and panel:IsShown())
UIParent:SetSize(800,520); mock.fire("DISPLAY_SIZE_CHANGED")
addon.ToggleJournal()
assert(book:GetWidth()*book:GetScale()<=776 and book:GetHeight()*book:GetScale()<=496)
UIParent:SetSize(1600,900); mock.fire("DISPLAY_SIZE_CHANGED")
local originalPrint=print
print=function(value) mock.lastPrint=value end
SlashCmdList.FOREVERWAYFINDER("text extra")
print=originalPrint
assert(style.Preset()=="extra")
if arg[2]=="preview" then
  style.SetPreset(arg[4] or "standard")
  entry.title="Elixir of Suffering"
  addon.RefreshJournal(); mock.flush()
  if arg[3]=="chain" then book:Hide(); addon.ShowClassicChain(496)
  elseif arg[3]=="where" then book:Hide(); addon.ShowWhereNext()
  else panel:Hide(); if not book:IsShown() then addon.ToggleJournal() end end
  assert(loadfile(root.."/tests/journal_preview_export.lua"))(mock,arg[3]=="book" and book or panel)
else
  local saved=style.Preset()
  local fresh=assert(loadfile(root.."/tests/wow_mock.lua"))()
  ForeverWayfinderJournal={schema=1,entries={},characters={},readingPreset=saved}
  local restored=fresh.load(root,true)
  assert(restored.ReadingStyle.Preset()=="extra","the saved reading size was not restored")
  print("PASS: shared reading presets, draft preservation, folding notes, long-title layout, font reuse, chain / zone styles, screen fit, and saved preference")
end
