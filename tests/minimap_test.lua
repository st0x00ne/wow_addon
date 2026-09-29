local root=assert(arg[1],"workspace path required")
local mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
local addon=mock.load(root,true)
local control=assert(ForeverWayfinderMinimapButton,"no minimap button was created on login")
assert(control.parent==Minimap and control.icon.texture:find("Media\\Icon",1,true))
assert(control.points.CENTER.relative==Minimap and control.points.CENTER.x<0 and control.points.CENTER.y<0)
assert(not ForeverWayfinderJournalFrame,"the minimap button eagerly created the journal")
local function click()
  control.scripts.OnMouseDown(control)
  control.scripts.OnMouseUp(control)
  mock.click(control)
end
click(); local book=assert(ForeverWayfinderJournalFrame); assert(book:IsShown())
click(); assert(not book:IsShown())
local before=#mock.objects
mock.fire("PLAYER_ENTERING_WORLD"); mock.fire("PLAYER_LOGIN")
assert(#mock.objects==before and ForeverWayfinderMinimapButton==control,"login duplicated the button")
control.scripts.OnEnter(control); assert(GameTooltip:IsShown() and GameTooltip:IsOwned(control))
control.scripts.OnLeave(control); assert(not GameTooltip:IsShown())
-- Cursor pixels must be converted using the minimap's effective scale.
UIParent:SetScale(.8); Minimap:SetScale(.75)
Minimap.centerX,Minimap.centerY=400,300
mock.cursorX,mock.cursorY=300,240 -- logical (500,400), northeast of (400,300)
control.scripts.OnMouseDown(control)
control.scripts.OnDragStart(control)
assert(control.scripts.OnUpdate and control.dragging)
control.scripts.OnUpdate(control)
control.scripts.OnDragStop(control)
assert(math.abs(addon.Journal.Database().minimapAngle-45)<.001,"drag position did not save at the scaled cursor")
assert(not control.scripts.OnUpdate and not control.dragging,"drag kept running after release")
assert(control.points.CENTER.x>0 and control.points.CENTER.y>0)
mock.click(control); assert(not book:IsShown(),"ending a drag toggled the journal")
click(); assert(book:IsShown()); click()
-- Resizing the minimap preserves the same angle on its outer edge.
local oldX=control.points.CENTER.x
Minimap:SetSize(200,200); Minimap.scripts.OnSizeChanged(Minimap,200,200)
assert(control.points.CENTER.x>oldX)
-- Hiding a dragged button stops updates and dismisses its tooltip.
control.scripts.OnEnter(control)
control.scripts.OnDragStart(control); control:Hide()
assert(not control.scripts.OnUpdate and not GameTooltip:IsShown())
local savedAngle=addon.Journal.Database().minimapAngle
local freshMock=assert(loadfile(root.."/tests/wow_mock.lua"))()
ForeverWayfinderJournal={schema=1,entries={},characters={},minimapAngle=savedAngle}
freshMock.load(root,true)
assert(math.abs(ForeverWayfinderMinimapButton.angle-savedAngle)<.001,"saved position was not restored on a fresh load")
print("PASS: minimap journal toggle, tooltip, scaled dragging, click suppression, resize anchoring, drag cleanup, and saved position")
