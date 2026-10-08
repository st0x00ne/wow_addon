-- Export the actual mocked JournalUI frame geometry for an offline layout preview.
-- This is a layout check; it does not emulate the WoW renderer or game textures.
local mock,book=...
local cache={}
local fractions={TOPLEFT={0,0},TOP={.5,0},TOPRIGHT={1,0},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},BOTTOMLEFT={0,1},BOTTOM={.5,1},BOTTOMRIGHT={1,1}}
local function rect(v)
  if cache[v] then return cache[v] end
  if v==book then local r={x=0,y=0,w=book:GetWidth(),h=book:GetHeight()}; cache[v]=r; return r end
  if v.allPoints then local r=rect(v.allPoints); cache[v]=r; return r end
  local w,h=v:GetWidth(),v:GetHeight()
  local point,p
  for _,name in ipairs({"TOPLEFT","TOPRIGHT","TOP","CENTER","LEFT","RIGHT","BOTTOMLEFT","BOTTOMRIGHT","BOTTOM"}) do
    if v.points[name] then point,p=name,v.points[name]; break end
  end
  local parent=rect(p and p.relative or v.parent)
  local own=fractions[point or "TOPLEFT"] or fractions.TOPLEFT
  local relative=fractions[p and p.relativePoint or "TOPLEFT"] or fractions.TOPLEFT
  local r={x=parent.x+parent.w*relative[1]+(p and p.x or 0)-w*own[1],
    y=parent.y+parent.h*relative[2]-(p and p.y or 0)-h*own[2],w=w,h=h}
  if v.scrollParent then r.y=r.y-v.scrollParent:GetVerticalScroll() end
  cache[v]=r; return r
end
local function json(value)
  if value==nil then return "null" end
  if type(value)=="string" then
    return '"'..value:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"'
  end
  if type(value)~="table" then return tostring(value) end
  local result={}
  if #value>0 then for _,item in ipairs(value) do result[#result+1]=json(item) end; return "["..table.concat(result,",").."]" end
  for key,item in pairs(value) do result[#result+1]=json(tostring(key))..":"..json(item) end
  return "{"..table.concat(result,",").."}"
end
local result={}
for order,v in ipairs(mock.objects) do
  local p=v
  while p and p~=book do p=p.parent end
  if p==book and mock.visible(v) and v.alpha~=0 then
    local layer=({BACKGROUND=0,BORDER=1,ARTWORK=2,OVERLAY=3})[v.layer or "BACKGROUND"] or 0
    local level=(v.kind=="Texture" or v.kind=="FontString") and v.parent:GetFrameLevel() or v:GetFrameLevel()
    local stratum,parent=0,v
    while parent do
      if parent.strata then
        stratum=({BACKGROUND=0,LOW=1,MEDIUM=2,HIGH=3,DIALOG=4,FULLSCREEN=5,FULLSCREEN_DIALOG=6,TOOLTIP=7})[parent.strata] or 0
        break
      end
      parent=parent.parent
    end
    local clip=rect(book)
    local ancestor=v.parent
    while ancestor and ancestor~=book do
      if ancestor.kind=="ScrollFrame" then
        local a=rect(ancestor)
        local x,y=math.max(clip.x,a.x),math.max(clip.y,a.y)
        clip={x=x,y=y,w=math.max(0,math.min(clip.x+clip.w,a.x+a.w)-x),h=math.max(0,math.min(clip.y+clip.h,a.y+a.h)-y)}
      end
      ancestor=ancestor.parent
    end
    result[#result+1]={rect=rect(v),clip=clip,kind=v.kind,template=v.template,layer=layer,subLevel=v.subLevel or 0,level=level,strata=stratum,order=order,
      text=v.text,color=v.color,texture=v.texture,texCoord=v.texCoord,vertexColor=v.vertexColor,backdrop=v.backdropColor,border=v.borderColor,
      fontSize=v.fontSize or (v.normalFont and v.normalFont.fontSize),font=v.font,spacing=v.spacing,
      wrap=v.wrap,justify=v.justifyH,vjustify=v.justifyV,checked=v.checked,enabled=v.enabled,alpha=v.alpha,masked=v.mask~=nil}
  end
end
print(json(result))
