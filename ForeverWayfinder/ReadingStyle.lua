-- Hallmark · shared native typography · parchment ink and leather controls.
-- Pre-emit critique: P5 H5 E4 S5 R5 V4 · Classic fonts, saved reading presets.
local _, addon = ...
local style = {}
addon.ReadingStyle = style
local regions = setmetatable({}, {__mode = "k"})
local buttonFonts
local ink = {gold={1, .82, .40}, highlight={1, .94, .72}, disabled={.61, .57, .47}}
local presets = {
  standard = {name="Standard", body=16, meta=13, label=14, control=14, entry=16, heading=18, title=22, display=26},
  large = {name="Large", body=18, meta=14, label=15, control=15, entry=17, heading=19, title=24, display=28},
  extra = {name="Extra Large", body=20, meta=15, label=16, control=16, entry=18, heading=20, title=26, display=30},
}

function style.Preset()
  local db = addon.Journal.Database()
  local key = db and db.readingPreset or "standard"
  return presets[key] and key or "standard"
end

function style.Name() return presets[style.Preset()].name end
function style.Size(role) return presets[style.Preset()][role] or 16 end

local function paint(region, spec)
  region:SetFont(spec.face, style.Size(spec.role), "")
  if region.SetShadowOffset then region:SetShadowOffset(0, 0) end
  if region.SetSpacing then region:SetSpacing(spec.role == "body" and 3 or 0) end
end

function style.Font(region, role)
  local spec = regions[region]
  if not spec or spec.role ~= role then
    local object = (role == "title" or role == "display") and (QuestFont_Large or GameFontNormalLarge)
      or (role == "heading" and GameFontNormal or GameFontHighlight)
    region:SetFontObject(object)
    local face = region:GetFont()
    spec = {role=role, face=face or STANDARD_TEXT_FONT}
    regions[region] = spec
  end
  paint(region, spec)
end

local function updateButtonFonts()
  if not buttonFonts then return end
  for _, font in ipairs(buttonFonts) do font:SetFont(STANDARD_TEXT_FONT, style.Size("control"), "") end
end

function style.Button(button)
  if not buttonFonts then
    buttonFonts = {CreateFont("ForeverWayfinderButtonFont"), CreateFont("ForeverWayfinderButtonHighlightFont"),
      CreateFont("ForeverWayfinderButtonDisabledFont")}
    local shades = {ink.gold, ink.highlight, ink.disabled}
    for index, font in ipairs(buttonFonts) do
      local shade = shades[index]
      font:SetTextColor(shade[1], shade[2], shade[3]); font:SetShadowOffset(1, -1)
    end
    updateButtonFonts()
  end
  button:SetNormalFontObject(buttonFonts[1])
  button:SetHighlightFontObject(buttonFonts[2])
  button:SetDisabledFontObject(buttonFonts[3])
end

function style.Refresh()
  for region, spec in pairs(regions) do paint(region, spec) end
  updateButtonFonts()
  if addon.RefreshPanelReadingStyle then addon.RefreshPanelReadingStyle() end
  if addon.RefreshJournalReadingStyle then addon.RefreshJournalReadingStyle() end
end

function style.SetPreset(key)
  if not presets[key] or not addon.Journal.Initialize() then return false end
  addon.Journal.Database().readingPreset = key
  style.Refresh()
  return true
end

function style.Cycle()
  local nextPreset = {standard="large", large="extra", extra="standard"}
  return style.SetPreset(nextPreset[style.Preset()])
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", style.Refresh)
