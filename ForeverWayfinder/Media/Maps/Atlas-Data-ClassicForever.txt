--[[

	Atlas, a World of Warcraft instance map browser
	Copyright 2011 ~ 2026 - Arith Hsu, Atlas Team 

	This file is part of Atlas.

	Atlas is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	Atlas is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Atlas; if not, write to the Free Software
	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

--]]
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
-- Libraries
-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local _, private = ...
local LibStub = _G.LibStub
---@type AtlasAddon
local Atlas = LibStub("AceAddon-3.0"):GetAddon("Atlas")

local Client = Atlas.Client

if not Client.isForever then
	return
end

local BZ = Atlas_GetLocaleLibBabble("LibBabble-SubZone-3.0")
local BF = Atlas_GetLocaleLibBabble("LibBabble-Faction-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local ALC = LibStub("AceLocale-3.0"):GetLocale("Atlas")

---@type AtlasDataModule
local addon = Atlas:GetModule(private.module_name)

local db = {}
addon.db = db

local constants = Atlas.constants
local labelcolors = constants.colors.labels
local BLUE = labelcolors.BLUE
local GREN = labelcolors.GREN
local GREY = labelcolors.GREY
local LBLU = labelcolors.LBLU
local _RED = labelcolors._RED
local ORNG = labelcolors.ORNG
local PINK = labelcolors.PINK
local PURP = labelcolors.PURP
local WHIT = labelcolors.WHIT
local YLOW = labelcolors.YLOW
local INDENT = labelcolors.INDENT

-- local helper functions
local function getBossName(bossname, encounterID, creatureIndex)
	return Atlas:GetBossName(bossname, encounterID, creatureIndex, private.module_name)
end

local function getCreatureName(creatureName, creatureID)
	return Atlas:GetCreatureName(creatureName, creatureID)
end

local function getQuestTitlebyID(title, id)
	return Atlas:GetQuestTitlebyID(title, id)
end

local function getItemTitlebyID(title, id)
	return Atlas:GetItemTitlebyID(title, id)
end

-- local constants for easier access
local SLASH = ALC["Slash"]
local COLON = ALC["Colon"]
local COMMA = ALC["Comma"]
local L_PAREN = ALC["L-Parenthesis"]
local R_PAREN = ALC["R-Parenthesis"]
local ENTRANCE = ALC["Entrance"]
local WANDERS = ALC["Wanders"]
local UPPER = ALC["Upper"]
local CONNECTION = ALC["Connection"]
local RARE = ALC["Rare"]
local RANDOM = ALC["Random"]
local VARIES = ALC["Varies"]

db.AtlasMaps = {
--************************************************
-- Eastern Kingdoms Instances (Classic)
--************************************************
	CL_BlackrockMountainEnt = {
		ZoneName = { BZ["Blackrock Mountain"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Searing Gorge"]..SLASH..BZ["Burning Steppes"] },
		LevelRange = "52-60",
		PlayerLimit = { 5, 10, 25, 40},
		Acronym = L["BRM"],
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..BZ["Searing Gorge"] },
		{ BLUE.." B) "..BZ["Burning Steppes"] },
		{ BLUE.." C) "..BZ["Blackrock Depths"]..L_PAREN..L["BRD"]..R_PAREN },
		{ BLUE..INDENT..BZ["Molten Core"]..L_PAREN..L["MC"]..R_PAREN },
		{ BLUE.." D) "..BZ["Blackrock Spire"]..L_PAREN..L["Lower"]..COMMA..L["LBRS"]..R_PAREN },
		{ BLUE..INDENT..BZ["Blackrock Spire"]..L_PAREN..L["Upper"]..COMMA..L["UBRS"]..R_PAREN },
		{ BLUE..INDENT..BZ["Blackwing Lair"]..L_PAREN..L["BWL"]..R_PAREN },
		{ BLUE..INDENT..L["Bodley"]..L_PAREN..ALC["Ghost"]..R_PAREN },
		{ WHIT.." 1) "..L["Overmaster Pyron"]..L_PAREN..WANDERS..R_PAREN },
		{ WHIT.." 2) "..L["Lothos Riftwaker"] },
		{ WHIT.." 3) "..L["Franclorn Forgewright"]..L_PAREN..ALC["Ghost"]..R_PAREN },
		{ WHIT.." 4) "..ALC["Meeting Stone"]..L_PAREN..L["BRD"]..R_PAREN },
		{ WHIT.." 5) "..L["Orb of Command"] },
		{ WHIT.." 6) "..ALC["Meeting Stone"]..L_PAREN..L["LBRS"]..COMMA..L["UBRS"]..R_PAREN },
		{ WHIT.." 7) "..L["Scarshield Quartermaster <Scarshield Legion>"] },
	},
	CL_BlackrockDepths = {
		ZoneName = { BZ["Blackrock Mountain"]..COLON..BZ["Blackrock Depths"] },
		Location = { BZ["Searing Gorge"]..SLASH..BZ["Burning Steppes"] },
		LevelRange = "52-60",
		PlayerLimit = { 5 },
		Acronym = L["BRD"],
		DungeonID = 29,
		WorldMapID = 230,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Lord Roccor", 370)..L_PAREN..WANDERS..R_PAREN, 370 },
		{ WHIT.." 2) "..getCreatureName("Kharan Mighthammer", 9021), 10002 },
		{ WHIT.." 3) "..getCreatureName("Commander Gor'shak", 9020), 10003 },
		{ WHIT.." 4) "..getItemTitlebyID("Marshal Windsor", 11464), 10004 },
		{ WHIT.." 5) "..getBossName("High Interrogator Gerstahn", 369), 369 },
		{ WHIT.." 6) "..getBossName("Ring of Law", 372), 372 },
		{ WHIT..INDENT..getCreatureName("Anub'shiah", 9031)..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Eviscerator", 9029)..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Gorosh the Dervish", 9027)..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Grizzle", 9028)..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Hedrum the Creeper", 9032)..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Ok'thor the Breaker", 9030)..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Theldren", 16059)..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT..INDENT..getCreatureName("Lefty", 16049) },
		{ WHIT..INDENT..getCreatureName("Malgen Longspear", 16095) },
		{ WHIT..INDENT..getCreatureName("Gnashjaw", 16095) },
		{ WHIT..INDENT..getCreatureName("Rotfang", 16050) },
		{ WHIT..INDENT..getCreatureName("Va'jashni", 16055) },
		{ WHIT..INDENT..getBossName("Houndmaster Grebmar", 371), 371 },
		{ WHIT..INDENT..getCreatureName(L["Elder Morndeep"], 15549)..L_PAREN..ALC["Lunar Festival"]..R_PAREN },
		{ WHIT..INDENT..getBossName("High Justice Grimstone", 372, 1), 372 },
		{ WHIT.." 7) "..getBossName("Pyromancer Loregrain", 373), 373 },
		{ WHIT..INDENT..L["Monument of Franclorn Forgewright"] },
		{ WHIT.." 8) "..getBossName("Warder Stilgiss", 375), 375 },
		{ WHIT..INDENT..L["The Vault"] },
		{ WHIT..INDENT..getCreatureName("Verek", 9042) },
		{ WHIT..INDENT..getCreatureName(L["Watchman Doomgrip"], 9476) },
		{ WHIT.." 9) "..getBossName("Fineous Darkvire", 376)..L_PAREN..WANDERS..R_PAREN, 376 },
		{ WHIT.."10) "..getBossName("Lord Incendius", 374), 374 },
		{ WHIT..INDENT..getCreatureName(L["The Black Anvil"], 67326)  },
		{ WHIT.."11) "..getBossName("Bael'Gar", 377), 377 },
		{ WHIT.."12) "..L["The Shadowforge Lock"], 10005 },
		{ WHIT.."13) "..getBossName("General Angerforge", 378), 378 },
		{ WHIT.."14) "..getBossName("Golem Lord Argelmach", 379), 379 },
		{ WHIT..INDENT..getItemTitlebyID(L["Schematic: Field Repair Bot 74A"], 18235) },
		{ WHIT..INDENT..ALC["Blacksmithing Plans"] },
		{ WHIT.."15) "..getBossName("Hurley Blackbreath", 380), 380 },
		{ WHIT..INDENT..getCreatureName("Lokhtos Darkbargainer", 12944) },
		{ WHIT..INDENT..getCreatureName("Mistress Nagmara", 9500) },
		{ WHIT..INDENT..getBossName("Phalanx", 381), 381 },
		{ WHIT..INDENT..getBossName("Plugger Spazzring", 383), 383 },
		{ WHIT..INDENT..getCreatureName("Private Rocknot", 9503) },
		{ WHIT..INDENT..getBossName("Ribbly Screwspigot", 382), 382 },
		{ WHIT.."16) "..getBossName("Ambassador Flamelash", 384), 384 },
		{ WHIT.."17) "..getCreatureName("Panzor the Invincible", 8923)..L_PAREN..RARE..COMMA..WANDERS..R_PAREN, 10006 },
		{ WHIT..INDENT..ALC["Blacksmithing Plans"] },
		{ WHIT.."18) "..L["Summoner's Tomb"], 10007 },
		{ WHIT.."19) "..L["The Lyceum"], 10008 },
		{ WHIT.."20) "..getBossName("Magmus", 386), 386 },
		{ WHIT.."21) "..getBossName("Emperor Dagran Thaurissan", 387), 387 },
		{ WHIT..INDENT..getCreatureName("Princess Moira Bronzebeard", 8929) },
		{ WHIT.."22) "..L["The Black Forge"], 10009 },
		{ WHIT.."23) "..BZ["The Molten Core"], 10010 },
		{ WHIT..INDENT..L["Core Fragment"] },
		{ WHIT.."24) "..getCreatureName("Overmaster Pyron", 9026), 10011 },
		{ WHIT.."25) "..ALC["Blacksmithing Plans"], 10012 },
	},
	CL_BlackrockSpireLower = {
		ZoneName = { BZ["Blackrock Mountain"]..COLON..BZ["Lower Blackrock Spire"] },
		Location = { BZ["Searing Gorge"]..SLASH..BZ["Burning Steppes"] },
		LevelRange = "52-60",
		PlayerLimit = { 10 },
		DungeonID = 31,
		Acronym = L["LBRS"],
		WorldMapID = 229,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.."B) "..BZ["Blackrock Spire"]..L_PAREN..UPPER..R_PAREN },
		{ BLUE.."C-F) "..CONNECTION },
		{ WHIT.." 1) "..getBossName("Vaelan") },
		{ WHIT.." 2) "..getBossName("Warosh") },
		{ WHIT..INDENT..L["Elder Stonefort"]..L_PAREN..ALC["Lunar Festival"]..R_PAREN, 10012 },
		{ WHIT.." 3) "..L["Roughshod Pike"] },
		{ WHIT.." 4) "..getBossName("Spirestone Butcher")..L_PAREN..RARE..R_PAREN, 10006 },
		{ WHIT.." 5) "..getBossName("Highlord Omokk", 388), 388 }, -- 267
		{ WHIT.." 6) "..getBossName("Spirestone Battle Lord")..L_PAREN..RARE..R_PAREN, 10007 },
		{ WHIT..INDENT..getBossName("Spirestone Lord Magus")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 7) "..getBossName("Shadow Hunter Vosh'gajin", 389), 389 }, -- 268
		{ WHIT..INDENT..L["Fifth Mosh'aru Tablet"] },
		{ WHIT.." 8) "..L["Bijou"] },
		{ WHIT.." 9) "..getBossName("War Master Voone", 390), 390 }, -- 269
		{ WHIT..INDENT..L["Sixth Mosh'aru Tablet"] },
		{ WHIT..INDENT..getBossName("Mor Grayhoof")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT.."10) "..L["Bijou's Belongings"] },
		{ WHIT.."11) "..L["Human Remains"] },
		{ WHIT..INDENT..L["Unfired Plate Gauntlets"]..L_PAREN..ALC["Lower"]..R_PAREN },
		{ WHIT.."12) "..getBossName("Bannok Grimaxe")..L_PAREN..RARE..R_PAREN, 10008 },
		{ WHIT.."13) "..getBossName("Mother Smolderweb", 391), 391 }, -- 270
		{ WHIT.."14) "..getBossName("Crystal Fang")..L_PAREN..RARE..R_PAREN, 10009 },
		{ WHIT.."15) "..L["Urok's Tribute Pile"]..L_PAREN..ALC["Summon"]..R_PAREN, 392 },
		{ WHIT..INDENT..getBossName("Urok Doomhowl")..L_PAREN..ALC["Summon"]..R_PAREN }, -- 271
		{ WHIT.."16) "..getBossName("Quartermaster Zigris", 393), 393 }, -- 272
		{ WHIT.."17) "..getBossName("Halycon", 394), 394 }, -- 274
		{ WHIT..INDENT..getBossName("Gizrul the Slavener", 395), 395 }, -- 273
		{ WHIT.."18) "..getBossName("Ghok Bashguud")..L_PAREN..RARE..R_PAREN, 10010 },
		{ WHIT.."19) "..getBossName("Overlord Wyrmthalak", 396), 396 }, -- 275
		{ GREN.." 1) "..getBossName("Burning Felguard")..L_PAREN..RARE..COMMA..ALC["Summon"]..R_PAREN, 10005 },
	},
	CL_BlackrockSpireUpper = {
		ZoneName = { BZ["Blackrock Mountain"]..COLON..BZ["Upper Blackrock Spire"] },
		Location = { BZ["Searing Gorge"]..SLASH..BZ["Burning Steppes"] },
		DungeonID = 43,
		LevelRange = "56-60",
		PlayerLimit = { 10 },
		Acronym = L["UBRS"],
		WorldMapID = 229,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE },
		{ BLUE.." B) "..BZ["Blackrock Spire"]..L_PAREN..ALC["Lower"]..R_PAREN },
		{ BLUE.."C-E) "..CONNECTION },
		{ WHIT.." 1) "..getBossName("Pyroguard Emberseer") }, -- 3062
		{ WHIT.." 2) "..getBossName("Solakar Flamewreath") },
		{ WHIT..INDENT..L["Father Flame"] },
		{ WHIT.." 3) "..L["Darkstone Tablet"] },
		{ WHIT..INDENT..L["Doomrigger's Coffer"] },
		{ WHIT.." 4) "..getBossName("Jed Runewatcher")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 5) "..getBossName("Goraluk Anvilcrack") },
		{ WHIT.." 6) "..getBossName("Warchief Rend Blackhand")  }, -- 3063
		{ WHIT..INDENT..getBossName("Gyth") },
		{ WHIT.." 7) "..L["Awbee"] },
		{ WHIT.." 8) "..getBossName("The Beast") }, -- 3068,
		{ WHIT..INDENT..getBossName("Lord Valthalak"), L_PAREN..ALC["Summon"]..R_PAREN }, -- 3070
		{ WHIT..INDENT..L["Finkle Einhorn"] },
		{ WHIT.." 9) "..getBossName("General Drakkisath") }, -- 3069
		{ WHIT..INDENT..L["Drakkisath's Brand"] },
		{ WHIT.."10) "..BZ["Blackwing Lair"] },
	},
	CL_BlackwingLair = {
		ZoneName = { BZ["Blackrock Mountain"]..COLON..BZ["Blackwing Lair"] },
		Location = { BZ["Searing Gorge"]..SLASH..BZ["Burning Steppes"] },
		LevelRange = "60",
		DungeonID = 49,
		PlayerLimit = { 40 },
		WorldMapID = 469,
		Acronym = L["BWL"],
		Module = "Atlas_ClassicWoW",
		{ ORNG..ALC["Attunement Required"] },
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B-C) "..CONNECTION, 10002 },
		{ WHIT.." 1) "..getBossName("Razorgore the Untamed", 1529), 1529 }, -- 610
		{ WHIT.." 2) "..getBossName("Vaelastrasz the Corrupt", 1530), 1530 }, -- 611
		{ WHIT.." 3) "..getBossName("Broodlord Lashlayer", 1531), 1531 }, -- 612
		{ WHIT.." 4) "..getBossName("Firemaw", 1532), 1532 }, -- 613
		{ WHIT.." 5) "..getBossName("Ebonroc", 1533), 1533 }, -- 614
		{ WHIT.." 6) "..getBossName("Flamegor", 1534), 1534 }, -- 615
		{ WHIT.." 7) "..getBossName("Chromaggus", 1535), 1535 }, -- 616
		{ WHIT.." 8) "..getBossName("Nefarian", 1536), 1536 }, -- 617
		{ WHIT.." 9) "..getCreatureName("Master Elemental Shaper Krixix", 14401) },
	},
	CF_CityofDalaranA = {
		ZoneName = { BZ["City of Dalaran"]..ALC["MapA"] },
		Location = { BZ["Alterac Mountains"] },
		LevelRange = "28-33",
		PlayerLimit = { 5 },
		DungeonID = 3271,
		Acronym = L["CoD"],
		WorldMapID = 2959,
		Module = "Atlas_ClassicWoW",
		NextMap = "CF_CityofDalaranB",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getCreatureName("Atrexis the Grave Knight", 247126), 247126 },
		{ WHIT.." 2) "..getCreatureName("Lyn the Ignored", 247032), 247032 },
	},
	CF_CityofDalaranB = {
		ZoneName = { BZ["City of Dalaran"]..ALC["MapB"] },
		Location = { BZ["Alterac Mountains"] },
		LevelRange = "28-33",
		PlayerLimit = { 5 },
		DungeonID = 3271,
		Acronym = L["CoD"],
		WorldMapID = 2959,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CF_CityofDalaranA",
		{ WHIT.." 3) "..getCreatureName("Arcane Anomaly", 245999), 245999 },
		{ WHIT.." 4) "..getCreatureName("Arcanic Enigma", 246016), 246016 },
		{ WHIT.." 5) "..getCreatureName("Unstable Sentinel", 246017), 246017 },
		{ WHIT.." 6) "..getCreatureName("Mana Devourer", 246008), 246008 },
		{ WHIT.." 7) "..getCreatureName("Fel Ancient", 246003), 246003 },
		{ WHIT.." 8) "..getCreatureName("Shade of the Archmage", 246020), 246020 },
		
	},
	CL_GnomereganEnt = {
		ZoneName = { BZ["Gnomeregan"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Dun Morogh"] },
		LevelRange = "26-36",
		PlayerLimit = { 5 },
		DungeonID = 13,
		Acronym = L["Gnome"],
		WorldMapID = 90,
		Module = "Atlas_ClassicWoW",
		NextMap = "CF_Gnomeregan",
		{ BLUE.."A) "..ENTRANCE },
		{ BLUE..INDENT..ALC["Meeting Stone"] },
		{ BLUE.."B) "..BZ["Gnomeregan"]..L_PAREN..ALC["Front"]..R_PAREN },
		{ BLUE.."C) "..BZ["Gnomeregan"]..L_PAREN..ALC["Back"]..R_PAREN },
		{ WHIT.."1) "..ALC["Elevator"] },
		{ WHIT.."2) "..L["Transpolyporter"] },
		{ WHIT..INDENT..getBossName("Sprok <Away Team>") },
		{ WHIT.."3) "..getBossName("Matrix Punchograph 3005-A") },
		{ WHIT..INDENT..getBossName("Namdo Bizzfizzle <Engineering Supplies>") },
		{ WHIT.."4) "..getBossName("Techbot") },
	},
	CF_Gnomeregan = {
		ZoneName = { BZ["Gnomeregan"] },
		Location = { BZ["Dun Morogh"] },
		LevelRange = "26-36",
		PlayerLimit = { 5 },
		DungeonID = 13,
		Acronym = L["Gnome"],
		WorldMapID = 90,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_GnomereganEnt",
		{ BLUE.." A) "..ENTRANCE..L_PAREN..ALC["Front"]..R_PAREN, 10001 },
		{ BLUE.." B) "..ENTRANCE..L_PAREN..ALC["Back"]..R_PAREN, 10002 },
		{ WHIT.." 1) "..L["Blastmaster Emi Shortfuse"], 10003 },
		{ WHIT..INDENT..getBossName("Grubbis", 419), 419 }, -- 2768
		{ WHIT..INDENT..L["Chomper"] },
		{ WHIT.." 2) "..BZ["The Clean Zone"], 10004 },
		{ WHIT..INDENT..L["Tink Sprocketwhistle <Engineering Supplies>"] },
		{ WHIT..INDENT..L["The Sparklematic 5200"] },
		{ WHIT..INDENT..L["Mail Box"] },
		{ WHIT.." 3) "..L["Kernobee"], 10005 },
		{ WHIT..INDENT..L["Alarm-a-bomb 2600"] },
		{ WHIT..INDENT..L["Matrix Punchograph 3005-B"] },
		{ WHIT.." 4) "..getBossName("Viscous Fallout", 420)..L_PAREN..WANDERS..R_PAREN, 420 }, -- 2769
		{ WHIT.." 5) "..getBossName("Electrocutioner 6000", 421), 421 }, -- 2770
		{ WHIT..INDENT..L["Matrix Punchograph 3005-C"] },
		{ WHIT.." 6) "..getBossName("Crowd Pummeler 9-60", 418), 418 }, -- 2771
		{ WHIT..INDENT..L["Matrix Punchograph 3005-D"] },
		{ WHIT.." 7) "..L["Dark Iron Ambassador"], 10006 },
		{ WHIT.." 8) "..getBossName("Mekgineer Thermaplugg", 422), 422 }, -- 2772
	},
	CF_HallofThanes = {
		ZoneName = { BZ["Hall of Thanes"] },
		Location = { BZ["Ironforge"]..COMMA..BZ["Dun Morogh"] },
		LevelRange = "13-18",
		MinLevel = 13,
		MaxLevel = 18,
		PlayerLimit = { 5 },
		DungeonID = 3273,
		Acronym = L["HoT"],
		WorldMapID = 3065,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getCreatureName("Faldrim Anvilmar", 261306), 3493 }, -- 261306
		{ WHIT.." 2) "..getCreatureName("Plunder", 261311), 3494 }, -- 261311
		{ WHIT.." 3) "..getCreatureName("Magmatus", 261316), 3495 }, -- 261316
		{ WHIT.." 4) "..getCreatureName("Durgen Dirgehammer", 261319), 3496 }, -- 261319
		{ GREN.." 1') "..getCreatureName("Ghostly Attendant", 265002), 10002 }, -- 265002
		{ INDENT..WHIT..QUESTS_COLON..getQuestTitlebyID(L["An Ancient Grudge"], 96395 ) },
		{ GREN.." 2') "..getItemTitlebyID(L["Treaty of Understanding"], 281030), 281030, "Treaty of Understanding" }, -- itemID: 281030
		{ INDENT..WHIT..QUESTS_COLON..getQuestTitlebyID(L["The Treaty of Understanding"], 98423) },
	},
	CF_MoltenCore = {
		ZoneName = { BZ["Blackrock Mountain"]..COLON..BZ["The Molten Core"] },
		Location = { BZ["Searing Gorge"]..SLASH..BZ["Burning Steppes"] },
		DungeonID = 47,
		LevelRange = "60",
		Acronym = L["MC"],
		PlayerLimit = { 40 },
		WorldMapID = 409,
		Module = "Atlas_ClassicWoW",
		{ ORNG..ALC["Attunement Required"] },
		{ ORNG..REPUTATION..COLON..BF["Hydraxian Waterlords"] },
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Lucifron", 1519), 1519 }, -- 663
		{ WHIT.." 2) "..getBossName("Magmadar", 1520), 1520 }, -- 664
		{ WHIT.." 3) "..getBossName("Gehennas", 1521), 1521 }, -- 665
		{ WHIT.." 4) "..getBossName("Garr", 1522), 1522 }, -- 666
		{ WHIT.." 5) "..getBossName("Shazzrah", 1523), 1523 }, -- 667
		{ WHIT.." 6) "..getBossName("Baron Geddon", 1524), 1524 }, -- 668
		{ WHIT.." 7) "..getBossName("Golemagg the Incinerator", 1526), 1526 }, -- 670
		{ WHIT.." 8) "..getBossName("Sulfuron Harbinger", 1525), 1525 }, -- 669
		{ WHIT.." 9) "..getBossName("Majordomo Executus", 1527), 1527 }, -- 671
		{ WHIT.."10) "..getBossName("Ragnaros", 1528), 1528 }, -- 672
	},
	CF_RuinsofLordaeron = {
		ZoneName = { BZ["Ruins of Lordaeron"] },
		Location = { BZ["Tirisfal Glades"] },
		LevelRange = "15-20",
		MinLevel = 15,
		MaxLevel = 20,
		PlayerLimit = { 5 },
		DungeonID = 3272,
		WorldMapID = 2999,
		Acronym = L["RoL"],
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getCreatureName("The Baron", 250660), 10002 },
		{ WHIT.." 2) "..getCreatureName("Witherfang", 250483), 10003 },
		{ WHIT.." 3) "..getCreatureName("The Abandoned", 250631), 10004 },
		{ WHIT.." 4) "..getCreatureName("Bjork", 256097), 10005 },
		{ WHIT.." 5) "..getCreatureName("Rath'mael", 250657), 10006 },
		{ WHIT.." 6) "..getCreatureName("Viktor the Vile", 256035), 10007 },
		{ WHIT.." 7) "..getCreatureName("Lordaeron Captain", 255699)..L_PAREN..RARE..R_PAREN, 10008 },
		{ GREN.." 1') "..getCreatureName("Captain Truman", 265701), 10009 },
		{ INDENT..WHIT..QUESTS_COLON..getQuestTitlebyID(L["Abominable Creatures"], 95250) }
	},
	CL_ScarletMonasteryEnt = {
		ZoneName = { BZ["Scarlet Monastery"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Tirisfal Glades"] },
		LevelRange = "26-45",
		PlayerLimit = { 5 },
		DungeonID = 17,
		WorldMapID = 189,
		Acronym = L["SM"],
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_ScarletMonastery",
		NextMap = "CL_ScarletHalls",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B) "..ALC["Graveyard"] },
		{ BLUE.." C) "..L["Cathedral"] },
		{ BLUE.." D) "..L["Armory"] },
		{ BLUE.." E) "..L["Library"] },
	},
	CL_SMLibrary = {
		ZoneName = { BZ["Scarlet Monastery"]..COLON..L["Library"] },
		Location = { BZ["Tirisfal Glades"] },
		LevelRange = "26-45",
		PlayerLimit = { 5 },
		DungeonID = 17,
		WorldMapID = 189,
		Acronym = L["Lib"],
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE },
		{ WHIT.." 1) "..getBossName("Houndmaster Loksey") }, -- 446
		{ WHIT.." 2) "..getBossName("Arcanist Doan") }, -- 447
	},
	CL_SMArmory = {
		ZoneName = { BZ["Scarlet Monastery"]..COLON..L["Armory"] },
		Location = { BZ["Tirisfal Glades"] },
		LevelRange = "26-45",
		PlayerLimit = { 5 },
		DungeonID = 17,
		WorldMapID = 189,
		Acronym = L["Armory"],
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE },
		{ WHIT.." 1) "..getBossName("Herod") }, -- 448
	},
	CL_SMCathedral = {
		ZoneName = { BZ["Scarlet Monastery"]..COLON..L["Cathedral"] },
		Location = { BZ["Tirisfal Glades"] },
		LevelRange = "26-45",
		PlayerLimit = { 5 },
		DungeonID = 17,
		WorldMapID = 189,
		Acronym = L["Cath"],
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE },
		{ WHIT.." 1) "..getBossName("High Inquisitor Fairbanks") }, -- 449
		{ WHIT.." 2) "..getBossName("Scarlet Commander Mograine") },
		{ WHIT.." 3) "..getBossName("High Inquisitor Whitemane") }, -- 450
	},
	CL_SMGraveyard = {
		ZoneName = { BZ["Scarlet Monastery"]..COLON..ALC["Graveyard"] },
		Location = { BZ["Tirisfal Glades"] },
		LevelRange = "29-48",
		PlayerLimit = { 5 },
		DungeonID = 17,
		Acronym = L["GY"],
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE },
		{ WHIT.." 1) "..getBossName("Interrogator Vishas") }, -- 444
		{ WHIT..INDENT..L["Vorrel Sengutz"] },
		{ WHIT.." 2) "..getBossName("Ironspine")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 3) "..getBossName("Azshir the Sleepless")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 4) "..getBossName("Fallen Champion")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 5) "..getBossName("Bloodmage Thalnos") }, -- 2779
	},
	CL_Scholomance = {
		ZoneName = { BZ["Scholomance"] },
		Location = { BZ["Western Plaguelands"] },
		DungeonID = 2,
		LevelRange = "55-60",
		PlayerLimit = { 5 },
		Acronym = L["Scholo"],
		WorldMapID = 289,
		Module = "Atlas_ClassicWoW",
		{ ORNG..ALC["Key"]..COLON..L["Blood of Innocents"]..L_PAREN..getBossName("Kirtonos the Herald")..R_PAREN },
		{ ORNG..ALC["Key"]..COLON..L["Divination Scryer"]..L_PAREN..getBossName("Death Knight Darkreaver")..R_PAREN },
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B-C) "..ALC["Stairs"] },
		{ WHIT.." 1) "..getBossName("Blood Steward of Kirtonos") },
		{ WHIT..INDENT..L["The Deed to Southshore"] },
		{ WHIT.." 2) "..getBossName("Kirtonos the Herald")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT.." 3) "..getBossName("Jandice Barov") }, -- 2804
		{ WHIT.." 4) "..L["The Deed to Tarren Mill"] },
		{ WHIT.." 5) "..getBossName("Rattlegore")..L_PAREN..ALC["Lower"]..R_PAREN }, -- 2811
		{ WHIT..INDENT..getBossName("Death Knight Darkreaver")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT.." 6) "..getBossName("Marduk Blackpool") }, -- 2809
		{ WHIT..INDENT..getBossName("Vectus") }, -- 2813
		{ WHIT.." 7) "..getBossName("Ras Frostwhisper") },
		{ WHIT..INDENT..L["The Deed to Brill"] },
		{ WHIT..INDENT..getBossName("Kormok")..L_PAREN..ALC["Summon"]..R_PAREN }, -- 3055
		{ WHIT.." 8) "..getBossName("Instructor Malicia") }, -- 2803
		{ WHIT.." 9) "..getBossName("Doctor Theolen Krastinov") }, -- 2802
		{ WHIT.."10) "..getBossName("Lorekeeper Polkelt") }, -- 2808
		{ WHIT.."11) "..getBossName("The Ravenian") }, -- 2812
		{ WHIT.."12) "..getBossName("Lord Alexei Barov") }, -- 2807
		{ WHIT..INDENT..L["The Deed to Caer Darrow"] },
		{ WHIT.."13) "..getBossName("Lady Illucia Barov") }, -- 2806
		{ WHIT.."14) "..getBossName("Darkmaster Gandling") }, -- 2801
		{ GREN.." 1') "..L["Torch Lever"] },
		{ GREN.." 2') "..L["Secret Chest"] },
		{ GREN.." 3') "..L["Alchemy Lab"] },
		-- Missing encounter: Kirtonos, 2805
		-- Missing encounter: Ras Frostwhisperer, 2810
	},
	CL_ShadowfangKeep = {
		ZoneName = { BZ["Shadowfang Keep"] },
		Location = { BZ["Silverpine Forest"] },
		DungeonID = 7,
		LevelRange = "22-30",
		PlayerLimit = { 5 },
		Acronym = L["SFK"],
		WorldMapID = 33,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B-C) "..L["Walkway"] },
		{ BLUE..INDENT..getBossName("Deathsworn Captain")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 1) "..getBossName("Deathstalker Adamant") },
		{ WHIT..INDENT..getBossName("Sorcerer Ashcrombe") },
		{ WHIT..INDENT..getBossName("Rethilgore")..L_PAREN..RANDOM..COMMA..ALC["Summon"]..R_PAREN }, -- 2748
		{ WHIT.." 2) "..getBossName("Razorclaw the Butcher")..L_PAREN..RANDOM..COMMA..ALC["Summon"]..R_PAREN }, -- 2749
		{ WHIT.." 3) "..getBossName("Baron Silverlaine", 97), 97 }, -- 2750
		{ WHIT.." 4) "..getBossName("Commander Springvale", 98), 98 }, -- 2751
		{ WHIT.." 5) "..getBossName("Odo the Blindwatcher")..L_PAREN..RANDOM..COMMA..ALC["Summon"]..R_PAREN }, -- 2752
		{ WHIT.." 6) "..getBossName("Fenrus the Devourer") }, -- 2753
		{ WHIT.." 7) "..getBossName("Wolf Master Nandos")..L_PAREN..RANDOM..COMMA..ALC["Summon"]..R_PAREN }, -- 2754
		{ WHIT.." 8) "..getBossName("Archmage Arugal") }, -- 2755
		{ WHIT.." 9) "..getBossName("Fel Steed") },
		{ WHIT..INDENT..L["Jordan's Hammer"] },
	},
	CL_Stratholme = {
		ZoneName = { BZ["Stratholme"] },
		Location = { BZ["Eastern Plaguelands"] },
		Acronym = L["Strat"],
		DungeonID = 39,
		WorldMapID = 329,
		LevelRange = "48-58",
		PlayerLimit = { 5 },
		Module = "Atlas_ClassicWoW",
		{ ORNG..ALC["Key"]..COLON..L["Various Postbox Keys"]..L_PAREN..getBossName("Postmaster Malown")..R_PAREN },
		{ BLUE.." A) "..ENTRANCE..L_PAREN..ALC["Front"]..R_PAREN },
		{ BLUE.." B) "..ENTRANCE..L_PAREN..ALC["Side"]..R_PAREN },
		{ WHIT.." 1) "..getBossName("Skul")..L_PAREN..RARE..R_PAREN }, -- 2799
		{ WHIT..INDENT..L["Stratholme Courier"], 10002 },
		{ WHIT..INDENT..L["Fras Siabi"] },
		{ WHIT.." 2) "..getBossName("Atiesh")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT.." 3) "..getBossName("Hearthsinger Forresten", 443)..L_PAREN..VARIES..R_PAREN, 10003 , 443 }, -- 473
		{ WHIT.." 4) "..getBossName("The Unforgiven", 450), 450 }, -- 472
		{ WHIT.." 5) "..L["Elder Farwhisper"]..L_PAREN..ALC["Lunar Festival"]..R_PAREN, 10007 },
		{ WHIT.." 6) "..getBossName("Timmy the Cruel", 445), 445 }, -- 474
		{ WHIT.." 7) "..getBossName("Malor the Zealous") }, -- 476
		{ WHIT..INDENT..L["Medallion of Faith"] },
		{ WHIT.." 8) "..getBossName("Crimson Hammersmith")..L_PAREN..ALC["Summon"]..R_PAREN }, -- 2796
		{ WHIT..INDENT..ALC["Blacksmithing Plans"] },
		{ WHIT.." 9) "..getBossName("Cannon Master Willey") }, -- 475
		{ WHIT.."10) "..getBossName("Archivist Galford") }, -- 477
		{ WHIT.."11) "..getBossName("Grand Crusader Dathrohan") },
		{ WHIT..INDENT..getBossName("Balnazzar", 449), 449 }, -- 478
		{ WHIT..INDENT..getBossName("Sothos")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT..INDENT..getBossName("Jarien")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT.."12) "..getBossName("Magistrate Barthilas", 454)..L_PAREN..VARIES..R_PAREN, 454 }, -- 482
		{ WHIT.."13) "..getBossName("Aurius", 10917) },
		{ WHIT.."14) "..getBossName("Stonespine")..L_PAREN..RARE..R_PAREN }, -- 2800
		{ WHIT.."15) "..getBossName("Baroness Anastari", 451), 451 }, -- 479
		{ WHIT..INDENT..getBossName("Black Guard Swordsmith")..L_PAREN..ALC["Summon"]..R_PAREN, 10003 }, -- 2795
		{ WHIT..INDENT..ALC["Blacksmithing Plans"] },
		{ WHIT.."16) "..getBossName("Nerub'enkan", 452), 452 }, -- 480
		{ WHIT.."17) "..getBossName("Maleki the Pallid", 453), 453 }, -- 481
		{ WHIT.."18) "..getBossName("Ramstein the Gorger", 455), 455 }, -- 483
		{ WHIT.."19) "..getBossName("Baron Rivendare") }, -- 484
		{ WHIT..INDENT..L["Ysida Harmon"] },
		{ GREN.." 1') "..L["Crusaders' Square Postbox"] },
		{ GREN.." 2') "..L["Market Row Postbox"] },
		{ GREN.." 3') "..L["Festival Lane Postbox"] },
		{ GREN.." 4') "..L["Elders' Square Postbox"] },
		{ GREN.." 5') "..L["King's Square Postbox"] },
		{ GREN.." 6') "..L["Fras Siabi's Postbox"] },
		{ GREN..L["3rd Box Opened: Postmaster Malown"] }, -- 2798
		-- We are missing Ezra Grimm's position, his dungeon encounter id is 2797
	},
	CL_TheDeadminesEnt = {
		ZoneName = { BZ["The Deadmines"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Westfall"] },
		DungeonID = 5,
		LevelRange = "15-25",
		PlayerLimit = { 5 },
		Acronym = L["VC"],
		WorldMapID = 291,
		Module = "Atlas_ClassicWoW",
		NextMap = "CL_TheDeadmines",
		{ BLUE.."A) "..ENTRANCE },
		{ BLUE.."B) "..BZ["The Deadmines"] },
		{ WHIT.."1) "..getBossName("Marisa du'Paige")..L_PAREN..VARIES..R_PAREN },
		{ WHIT.."2) "..getBossName("Brainwashed Noble")..L_PAREN..RARE..R_PAREN },
		{ WHIT.."3) "..getBossName("Foreman Thistlenettle") },
	},
	CL_TheDeadmines = {
		ZoneName = { BZ["The Deadmines"] },
		Location = { BZ["Westfall"] },
		DungeonID = 5,
		LevelRange = "15-25",
		PlayerLimit = { 5 },
		Acronym = L["VC"],
		WorldMapID = 36,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE },
		{ BLUE.." B) "..ALC["Exit"] },
		{ WHIT.." 1) "..getBossName("Rhahk'Zor") }, --2741
		{ WHIT.." 2) "..getBossName("Miner Johnson")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 3) "..getBossName("Sneed") }, --2742
		{ WHIT..INDENT..L["Sneed's Shredder"] },
		{ WHIT.." 4) "..getBossName("Gilnid") }, -- 2743
		{ WHIT.." 5) "..L["Defias Gunpowder"] },
		{ WHIT.." 6) "..getBossName("Captain Greenskin") }, -- 2744
		{ WHIT..INDENT..getBossName("Mr. Smite") }, -- 2745
		{ WHIT..INDENT..getBossName("Cookie") }, -- 2746
		{ WHIT..INDENT..getBossName("Edwin VanCleef") }, --2747
	},
	CF_TheStockade = {
		ZoneName = { BZ["Stormwind Stockades"] },
		Location = { BZ["Stormwind City"] },
		DungeonID = 11,
		LevelRange = "22-32",
		PlayerLimit = { 5 },
		Acronym = L["Stocks"],
		WorldMapID = 225,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Targorr the Dread")..L_PAREN..VARIES..R_PAREN, 10002 }, -- 2756
		{ WHIT.." 2) "..getBossName("Kam Deepfury"), 10003 }, -- 2757
		{ WHIT.." 3) "..getBossName("Hamhock"), 10004 }, -- 2758
		{ WHIT.." 4) "..getBossName("Bazil Thredd"), 10005 }, -- 2760
		{ WHIT.." 5) "..getBossName("Dextren Ward"), 10006 }, -- 2759
		{ WHIT.." 6) "..getBossName("Bruegal Ironknuckle")..L_PAREN..RARE..R_PAREN, 10007 },
	},
	CL_TheSunkenTempleEnt = {
		ZoneName = { BZ["Sunken Temple"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Swamp of Sorrows"] },
		DungeonID = 27,
		LevelRange = "50-60",
		PlayerLimit = { 5 },
		Acronym = L["ST"],
		WorldMapID = 109,
		Module = "Atlas_ClassicWoW",
		NextMap = "CL_TheSunkenTemple",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ GREN..INDENT..ALC["Meeting Stone"] },
		{ GREN..INDENT..L["Jade"]..L_PAREN..RARE..R_PAREN },
		{ BLUE.." B) "..BZ["Sunken Temple"], 10002 },
		{ WHIT.." 1) "..L["Kazkaz the Unholy"]..L_PAREN..UPPER..R_PAREN, 10003 },
		{ WHIT.." 2) "..L["Zekkis"]..L_PAREN..RARE..COMMA..ALC["Lower"]..R_PAREN, 10004 },
	},
	CL_TheSunkenTemple = {
		ZoneName = { BZ["Sunken Temple"] },
		Location = { BZ["Swamp of Sorrows"] },
		DungeonID = 27,
		LevelRange = "50-60",
		PlayerLimit = { 5 },
		Acronym = L["ST"],
		WorldMapID = 109,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_TheSunkenTempleEnt",
		{ ORNG..ALC["AKA"]..COLON..BZ["The Temple of Atal'Hakkar"] },
		{ BLUE.." A) "..ENTRANCE },
		{ BLUE.." B) "..ALC["Stairs"] },
		{ BLUE.." C) "..L["Troll Minibosses"]..L_PAREN..UPPER..R_PAREN },
		{ WHIT.." 1) "..getBossName("Altar of Hakkar") },
		{ WHIT..INDENT..L["Atal'alarion"] }, -- 2952
		-- We are missing the following dungeon encounters:
		--     Festering Rotslime, encounter id is 2953
		--     Atal'ai Defenders, encounter id is 2954
		{ WHIT.." 2) "..getCreatureName("Dreamscythe", 5721), 2955 }, -- 2955
		{ WHIT..INDENT..getCreatureName("Weaver", 5720) }, -- 2955
		{ WHIT.." 3) "..getBossName("Avatar of Hakkar", 457), 457 }, -- 2956
		{ WHIT.." 4) "..getBossName("Jammal'an the Prophet", 458), 458 }, -- 2957
		{ WHIT..INDENT..getBossName("Ogom the Wretched") },
		{ WHIT.." 5) "..getCreatureName("Morphaz", 5719)..L_PAREN..WANDERS..R_PAREN, 459 }, -- 2958
		{ WHIT..INDENT..getCreatureName("Hazzas", 5722) }, -- 2958
		{ WHIT.." 6) "..getBossName("Shade of Eranikus", 463), 463 }, -- 2959
		{ WHIT..INDENT..L["Essence Font"] },
		{ WHIT.." 7) "..getBossName("Spawn of Hakkar")..L_PAREN..RARE..R_PAREN },
		{ WHIT.." 8) "..L["Elder Starsong"]..L_PAREN..ALC["Lunar Festival"]..R_PAREN, 10003 },
		{ GREN.."1'-6') "..L["Statue Activation Order"] },
	},
	CL_UldamanEnt = {
		ZoneName = { BZ["Uldaman"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Badlands"] },
		DungeonID = 21,
		LevelRange = "38-53",
		PlayerLimit = { 5 },
		Acronym = L["Ulda"],
		WorldMapID = 70,
		Module = "Atlas_ClassicWoW",
		NextMap = "CF_Uldaman",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B) "..BZ["Uldaman"], 10002 },
		{ WHIT.." 1) "..getBossName("Hammertoe Grez", 2909), 10003 },
		{ WHIT.." 2) "..getBossName("Magregan Deepshadow", 2932)..L_PAREN..WANDERS..R_PAREN, 10004 },
		{ WHIT.." 3) "..L["Tablet of Ryun'Eh"], 10005 },
		{ WHIT.." 4) "..L["Krom Stoutarm's Chest"], 10006 },
		{ WHIT.." 5) "..L["Garrett Family Chest"], 10007 },
		{ GREN.." 1') "..getBossName("Digmaster Shovelphlange", 7057)..L_PAREN..RARE..R_PAREN, 10008 },
	},
	CF_Uldaman = {
		ZoneName = { BZ["Uldaman"] },
		Location = { BZ["Badlands"] },
		DungeonID = 21,
		LevelRange = "38-53",
		PlayerLimit = { 5 },
		Acronym = L["Ulda"],
		WorldMapID = 70,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_UldamanEnt",
		{ BLUE.." A) "..ENTRANCE..L_PAREN..ALC["Front"]..R_PAREN, 10001 },
		{ BLUE.." B) "..ENTRANCE..L_PAREN..ALC["Back"]..R_PAREN, 10002 },
		{ WHIT.." 1) "..getBossName("Baelog", 468, 1), 10003 },
		{ WHIT..INDENT..getBossName("Eric \"The Swift\"", 468, 2), 468 },
		{ WHIT..INDENT..getBossName("Olaf", 468, 3), 468 },
		{ WHIT..INDENT..L["Baelog's Chest"] },
		{ WHIT..INDENT..L["Conspicuous Urn"] },
		{ WHIT.." 2) "..L["Remains of a Paladin"], 10004 },
		{ WHIT.." 3) "..getBossName("Revelosh", 467), 10005 }, -- 547
		{ WHIT.." 4) "..getBossName("Ironaya", 469), 10006 },
		{ WHIT.." 5) "..getBossName("Obsidian Sentinel", 748), 10007 },
		{ WHIT.." 6) "..getBossName("Annora <Master Enchanter>"), 10008 },
		{ WHIT.." 7) "..getBossName("Ancient Stone Keeper", 470), 10009 },
		{ WHIT.." 8) "..getBossName("Galgann Firehammer", 471), 10010 },
		{ WHIT..INDENT..L["Tablet of Will"] },
		{ WHIT..INDENT..L["Shadowforge Cache"] },
		{ WHIT.." 9) "..getBossName("Grimlok", 472), 10011 },
		{ WHIT.."10) "..getBossName("Archaedas", 473), 10012 },
		{ WHIT.."11) "..L["The Discs of Norgannon"], 10013 },
		{ WHIT..INDENT..L["Ancient Treasure"] },

	},
	CF_ExcavationSiteWetlands = {
		ZoneName = { BZ["Excavation Site: Wetlands"] },
		Location = { BZ["Wetlands"] },
		DungeonID = 3274,
		LevelRange = "26-31",
		PlayerLimit = { 5 },
		Acronym = L["ES"],
		WorldMapID = 2998,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getCreatureName("Saltspine", 260322), 260322 },
		{ WHIT.." 2) "..getCreatureName("Shadetooth", 260325), 260325 },
		{ WHIT.." 3) "..getCreatureName("Relic Guardian", 260326), 260326 },
		{ WHIT.." 4) "..getCreatureName("Highland Horror", 260808), 260808 },
	},
	CL_ZulGurub = {
		ZoneName = { BZ["Zul'Gurub"] },
		Location = { BZ["Stranglethorn Vale"] },
		Acronym = L["ZG"],
		DungeonID = 41,
		WorldMapID = 309,
		LevelRange = "56-60",
		PlayerLimit = { 20 },
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("High Priestess Jeklik")..L_PAREN..L["Bat"]..R_PAREN, 10002 }, -- 785
		{ WHIT.." 2) "..getBossName("High Priest Venoxis")..L_PAREN..L["Snake"]..R_PAREN, 10003 }, -- 784
		{ WHIT.." 3) "..getBossName("Zanza the Restless"), 10004 },
		{ WHIT.." 4) "..getBossName("High Priestess Mar'li")..L_PAREN..L["Spider"]..R_PAREN }, -- 786
		{ WHIT.." 5) "..getBossName("Bloodlord Mandokir")..L_PAREN..L["Raptor"]..", "..L["Optional"]..R_PAREN, 10006 }, --787
		{ WHIT..INDENT..getBossName("Ohgan") },
		{ WHIT.." 6) "..getBossName("Edge of Madness")..L_PAREN..ALC["Optional"]..R_PAREN, 100007 }, -- 788
		{ WHIT..INDENT..getBossName("Gri'lek")..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getBossName("Hazza'rah")..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getBossName("Renataki")..L_PAREN..RANDOM..R_PAREN },
		{ WHIT..INDENT..getBossName("Wushoolay")..L_PAREN..RANDOM..R_PAREN },
		{ WHIT.." 7) "..getBossName("Gahz'ranka")..L_PAREN..ALC["Optional"]..", "..ALC["Summon"]..R_PAREN, 10008 }, -- 790
		{ WHIT.." 8) "..getBossName("High Priest Thekal")..L_PAREN..L["Tiger"]..R_PAREN, 10009 }, -- 789
		{ WHIT..INDENT..getBossName("Zealot Zath") },
		{ WHIT..INDENT..getBossName("Zealot Lor'Khan") },
		{ WHIT.." 9) "..getBossName("High Priestess Arlokk")..L_PAREN..L["Panther"]..R_PAREN, 10010 }, -- 791
		{ WHIT.."10) "..getBossName("Jin'do the Hexxer")..L_PAREN..L["Undead"]..", "..ALC["Optional"]..R_PAREN, 10011 }, -- 792
		{ WHIT.."11) "..getBossName("Hakkar"), 10012 }, -- 793
		{ GREN.." 1') "..getBossName("Muddy Churning Waters"), 10013 },
	},
--[[ Naxxramas
	CL_Naxxramas = {
		ZoneName = { BZ["Naxxramas"], 3456 },
		Location = { BZ["Eastern Plaguelands"], 139 },
		LevelRange = "60+",
		PlayerLimit = { 40 },
		Module = "Atlas_ClassicWoW",
		{ BLUE.."A) "..ENTRANCE },
		{ BLUE..INDENT..getBossName("Archmage Tarsis Kir-Moldir"), 16381 },
		{ BLUE..INDENT..getBossName("Mr. Bigglesworth")..L_PAREN..WANDERS..R_PAREN, 16998 },
		{ WHIT..L["Abomination Wing"] },
		{ WHIT..INDENT.."1) "..getBossName("Patchwerk"), 16028 },
		{ WHIT..INDENT.."2) "..getBossName("Grobbulus"), 15931 },
		{ WHIT..INDENT.."3) "..getBossName("Gluth"), 15932 },
		{ WHIT..INDENT.."4) "..getBossName("Thaddius"), 15928 },
		{ ORNG..L["Spider Wing"] },
		{ ORNG..INDENT.."1) "..getBossName("Anub'Rekhan"), 15956 },
		{ ORNG..INDENT.."2) "..getBossName("Grand Widow Faerlina"), 15953 },
		{ ORNG..INDENT.."3) "..getBossName("Maexxna"), 15952 },
		{ _RED..L["Deathknight Wing"] },
		{ _RED..INDENT.."1) "..getBossName("Instructor Razuvious"), 16061 },
		{ _RED..INDENT.."2) "..getBossName("Gothik the Harvester"), 16060 },
		{ _RED..INDENT.."3) "..getBossName("The Four Horsemen") },
		{ _RED..INDENT..INDENT..getBossName("Thane Korth'azz"), 16064 },
		{ _RED..INDENT..INDENT..getBossName("Lady Blaumeux"), 16065 },
		{ _RED..INDENT..INDENT..getBossName("Highlord Mograine <The Ashbringer>"), 16062 },
		{ _RED..INDENT..INDENT..getBossName("Sir Zeliek"), 16063 },
		{ _RED..INDENT..INDENT..L["Four Horsemen Chest"], 181366 },
		{ PURP..L["Plague Wing"] },
		{ PURP..INDENT.."1) "..getBossName("Noth the Plaguebringer"), 15954 },
		{ PURP..INDENT.."2) "..getBossName("Heigan the Unclean"), 15936 },
		{ PURP..INDENT.."3) "..getBossName("Loatheb"), 16011 },
		{ GREN..L["Frostwyrm Lair"] },
		{ GREN..INDENT.."1) "..getBossName("Sapphiron"), 15989 },
		{ GREN..INDENT.."2) "..getBossName("Kel'Thuzad"), 15990 },
	},]]

--************************************************
-- Kalimdor Instances (Classic)
--************************************************
	CL_BlackfathomDeepsEnt = {
		ZoneName = { BZ["Blackfathom Deeps"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Ashenvale"] },
		DungeonID = 9,
		LevelRange = "22-32",
		PlayerLimit = { 5 },
		Acronym = L["BFD"],
		WorldMapID = 48,
		Module = "Atlas_ClassicWoW",
		NextMap = "CL_BlackfathomDeepsA",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B) "..BZ["Blackfathom Deeps"], 10002 },
	},
	CL_BlackfathomDeepsA = {
		ZoneName = { BZ["Blackfathom Deeps"]..ALC["MapA"] },
		Location = { BZ["Ashenvale"] },
		DungeonID = 9,
		LevelRange = "22-32",
		PlayerLimit = { 5 },
		Acronym = L["BFD"],
		WorldMapID = 48,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_BlackfathomDeepsEnt",
		NextMap = "CL_BlackfathomDeepsB",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Ghamoo-ra"), 10002 }, -- 2761
		{ WHIT.." 2) "..L["Lorgalis Manuscript"], 10003 },
		{ WHIT.." 3) "..getBossName("Lady Sarevess"), 10004 }, -- 2762
		{ WHIT.." 4) "..L["Argent Guard Thaelrid"], 10005 },
		{ WHIT.." 5) "..getBossName("Gelihast"), 10006 }, -- 2763
		{ WHIT.." 6) "..getBossName("Lorgus Jett")..L_PAREN..VARIES..R_PAREN, 10007 }, -- 2764
	},
	CL_BlackfathomDeepsB = {
		ZoneName = { BZ["Blackfathom Deeps"]..ALC["MapB"] },
		Location = { BZ["Ashenvale"] },
		DungeonID = 9,
		LevelRange = "22-32",
		PlayerLimit = { 5 },
		Acronym = L["BFD"],
		WorldMapID = 48,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_BlackfathomDeepsA",
		NextMap = "CL_BlackfathomDeepsC",
		{ WHIT.." 6) "..getBossName("Lorgus Jett")..L_PAREN..VARIES..R_PAREN, 10007 }, -- 2764
		{ WHIT.." 7) "..getBossName("Baron Aquanis")..L_PAREN..ALC["Summon"]..R_PAREN },
		{ WHIT..INDENT..L["Fathom Core"] },
		{ WHIT.." 8) "..getBossName("Twilight Lord Kelris"), 10009 }, -- 2766
		{ WHIT.."10) "..getBossName("Aku'mai"), 10010 }, -- 2767
	},
	CL_BlackfathomDeepsC = {
		ZoneName = { BZ["Blackfathom Deeps"]..ALC["MapC"] },
		Location = { BZ["Ashenvale"] },
		DungeonID = 9,
		LevelRange = "22-32",
		PlayerLimit = { 5 },
		Acronym = L["BFD"],
		WorldMapID = 48,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_BlackfathomDeepsB",
		{ WHIT.." 9) "..getBossName("Old Serra'kis"), 10011 }, -- 2765
	},
	CL_DireMaulEnt = {
		ZoneName = { BZ["Dire Maul"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Feralas"] },
		LevelRange = "44-54",
		DungeonID = 33,
		PlayerLimit = { 5 },
		Acronym = L["DM"],
		WorldMapID = 429,
		Module = "Atlas_ClassicWoW",
		NextMap = "CL_DireMaulEast",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B) "..BZ["Dire Maul"]..L_PAREN..ALC["East"]..R_PAREN, 10002 },
		{ BLUE.." C) "..BZ["Dire Maul"]..L_PAREN..ALC["North"]..R_PAREN, 10003 },
		{ BLUE.." D) "..BZ["Dire Maul"]..L_PAREN..ALC["West"]..R_PAREN, 10004 },
		{ GREN.." 1') "..L["Dire Pool"], 10005 },
		{ GREN.." 2') "..L["Dire Maul Arena"], 10006 },
		{ GREN..INDENT..L["Elder Mistwalker"]..L_PAREN..ALC["Lunar Festival"]..R_PAREN },
	},
	CL_DireMaulEast = {
		ZoneName = { BZ["Dire Maul"]..L_PAREN..ALC["East"]..R_PAREN },
		Location = { BZ["Feralas"] },
		DungeonID = 33,
		LevelRange = "44-54",
		PlayerLimit = { 5 },
		Acronym = L["DM"],
		WorldMapID = 429,
		DungeonLevel = 6,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_DireMaulEnt",
		NextMap = "CL_DireMaulNorth",
		{ BLUE.." A-C) "..ENTRANCE },
		{ BLUE.." D) "..ALC["Exit"] },
		{ WHIT.." 1) "..getBossName("Pusillin")..L_PAREN..L["Chase Begins"]..R_PAREN }, -- 2792
		{ WHIT.." 2) "..getBossName("Pusillin")..L_PAREN..L["Chase Ends"]..R_PAREN }, -- 2792
		{ WHIT.." 3) "..getBossName("Zevrim Thornhoof", 402)..L_PAREN..UPPER..R_PAREN, 402 }, -- 343
		{ WHIT..INDENT..getBossName("Hydrospawn", 403), 403 }, -- 344
		{ WHIT..INDENT..getBossName("Lethtendris", 404), 404 }, -- 345
		{ WHIT..INDENT..getBossName("Pimgib") },
		{ WHIT.." 4) "..L["Old Ironbark"]..SLASH..L["Ironbark the Redeemed"] },
		{ WHIT.." 5) "..getBossName("Alzzin the Wildshaper", 405), 405 }, -- 346
		{ WHIT..INDENT..getBossName("Isalien")..L_PAREN..ALC["Summon"]..R_PAREN },
	},
	CL_DireMaulWest = {
		ZoneName = { BZ["Dire Maul"]..L_PAREN..ALC["West"]..R_PAREN },
		Location = { BZ["Feralas"] },
		DungeonID = 35,
		LevelRange = "44-54",
		PlayerLimit = { 5 },
		Acronym = L["DM"],
		WorldMapID = 429,
		DungeonLevel = 4,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_DireMaulNorth",
		{ ORNG..ALC["Key"]..COLON..getItemTitlebyID("J'eevee's Jar", 18663)..L_PAREN..getBossName("Lord Hel'nurath")..R_PAREN }, -- 2793
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B) "..L["Pylons"], 10002 },
		{ WHIT.." 1) "..L["Shen'dralar Ancient"], 10006 },
		{ WHIT.." 2) "..getBossName("Tendris Warpwood", 406), 406 }, -- 350
		{ WHIT..INDENT..L["Ancient Equine Spirit"], 10005 },
		{ WHIT.." 3) "..getBossName("Illyanna Ravenoak", 407), 407 }, -- 347
		{ WHIT..INDENT..L["Ferra"] },
		{ WHIT.." 4) "..getBossName("Magister Kalendris", 408), 408 }, -- 348
		{ WHIT.." 5) "..getBossName("Tsu'zee")..L_PAREN..RARE..R_PAREN, 10008 }, -- 2794
		{ WHIT.." 6) "..getBossName("Immol'thar", 409), 409 }, -- 349
		{ WHIT..INDENT..getBossName("Lord Hel'nurath")..L_PAREN..ALC["Summon"]..R_PAREN }, -- 2793
		{ WHIT.." 7) "..getBossName("Prince Tortheldrin", 410), 410 }, -- 361
		{ GREN.." 1') "..L["Library"] },
		{ GREN..INDENT..L["Falrin Treeshaper"] },
		{ GREN..INDENT..L["Lorekeeper Lydros"] },
		{ GREN..INDENT..L["Lorekeeper Javon"] },
		{ GREN..INDENT..L["Lorekeeper Kildrath"] },
		{ GREN..INDENT..L["Lorekeeper Mykos"] },
		{ GREN..INDENT..L["Shen'dralar Provisioner"] },
		{ GREN..INDENT..L["Skeletal Remains of Kariel Winthalus"] },
	},
	CL_DireMaulNorth = {
		ZoneName = { BZ["Dire Maul"]..L_PAREN..ALC["North"]..R_PAREN },
		Location = { BZ["Feralas"] },
		DungeonID = 37,
		LevelRange = "44-54",
		PlayerLimit = { 5 },
		Acronym = L["DM"],
		WorldMapID = 429,
		DungeonLevel = 1,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_DireMaulEast",
		NextMap = "CL_DireMaulWest",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Guard Mol'dar", 411), 411 }, -- 362
		{ WHIT.." 2) "..getBossName("Stomper Kreeg", 412), 412 }, -- 363
		{ WHIT.." 3) "..getBossName("Guard Fengus", 413), 413 }, -- 364
		{ WHIT.." 4) "..L["Knot Thimblejack"] },
		{ WHIT..INDENT..getBossName("Guard Slip'kik", 414), 414 }, -- 365
		{ WHIT.." 5) "..getBossName("Captain Kromcrush", 415), 415 },	-- 366
		{ WHIT.." 6) "..getBossName("King Gordok", 417), 417 }, -- 368
		{ WHIT..INDENT..getBossName("Cho'Rush the Observer", 416), 416 }, -- 367
	},
	CF_TheDrownedCity = {
		ZoneName = { BZ["The Drowned City"] },
		Location = { BZ["Stranglethorn Vale"] },
		--DungeonID = 0,
		LevelRange = "35-40",
		PlayerLimit = { 5 },
		Acronym = L["TDC"],
		--WorldMapID = 500,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getCreatureName("Zul'Alai", 270882), 10006 },
		{ WHIT.." 2) "..getCreatureName("Var'Taka", 270883), 10007 },
		{ WHIT.." 3) "..getCreatureName("Captain Dreadrise", 270884), 10008 },
		{ WHIT.." 4) "..getCreatureName("Deathless Marrow", 270885), 10009 },
		{ WHIT.." 5) "..getCreatureName("Gill", 270888), 10010 },
		{ WHIT.." 6) "..getCreatureName("Min'loth the Serpent", 270886), 10011 },
	},
	CL_MaraudonEnt = {
		ZoneName = { BZ["Maraudon"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["Desolace"] },
		DungeonID = 25,
		LevelRange = "42-52",
		PlayerLimit = { 5 },
		Acronym = L["Mara"],
		WorldMapID = 280,
		Module = "Atlas_ClassicWoW",
		NextMap = "CF_MaraudonA",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT..INDENT..L["The Nameless Prophet"]..L_PAREN..ALC["Lower"]..R_PAREN },
		{ BLUE.." B) "..BZ["Maraudon"]..L_PAREN..ALC["Purple"]..R_PAREN, 10002 },
		{ BLUE.." C) "..BZ["Maraudon"]..L_PAREN..ALC["Orange"]..R_PAREN, 10003 },
		{ BLUE.." D) "..BZ["Maraudon"]..L_PAREN..ALC["Portal"]..COMMA..ALC["Lower"]..R_PAREN, 10004 },
		{ WHIT.."1) "..getBossName("Kolk <The First Kahn>"), 10005 };
		{ WHIT.."2) "..getBossName("Gelk <The Second Kahn>"), 10006 };
		{ WHIT.."3) "..getBossName("Magra <The Third Kahn>") };
		{ WHIT.."4) "..getBossName("Cavindra"), 10008 };
	},
	CF_MaraudonA = {
		ZoneName = { BZ["Maraudon"]..ALC["MapA"] },
		Location = { BZ["Desolace"] },
		DungeonID = 25,
		LevelRange = "42-52",
		PlayerLimit = { 5 },
		Acronym = L["Mara"],
		WorldMapID = 349,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CL_MaraudonEnt",
		NextMap = "CF_MaraudonB",
		{ BLUE.." A) "..ENTRANCE..L_PAREN..ALC["Orange"]..R_PAREN, 10001 },
		{ BLUE.." B) "..ENTRANCE..L_PAREN..ALC["Purple"]..R_PAREN, 10002 },
		{ WHIT.." 1) "..L["Veng (The Fifth Khan)"], 10003 },
		{ WHIT.." 2) "..getBossName("Noxxion", 423), 10004 }, -- 422
		{ WHIT.." 3) "..getBossName("Razorlash", 424), 10005 }, -- 423
		{ WHIT.." 4) "..L["Maraudos (The Fourth Khan)"], 10006 },
		{ WHIT.." 5) "..getBossName("Lord Vyletongue", 427), 10007 }, -- 424
		{ WHIT.." 6) "..getBossName("Meshlok the Harvester")..L_PAREN..RARE..COMMA..WANDERS..R_PAREN, 10008 },
		{ WHIT.." 7) "..getBossName("Celebras the Cursed", 428), 10009 }, -- 425
	},
	CF_MaraudonB = {
		ZoneName = { BZ["Maraudon"]..ALC["MapB"] },
		Location = { BZ["Desolace"] },
		DungeonID = 25,
		LevelRange = "42-52",
		PlayerLimit = { 5 },
		Acronym = L["Mara"],
		WorldMapID = 349,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CF_MaraudonA",
		{ BLUE.." C) "..ENTRANCE..L_PAREN..ALC["Portal"]..R_PAREN, 10001 },
		{ WHIT.." 8) "..getBossName("Landslide", 429), 10002 }, -- 426
		{ WHIT.." 9) "..getBossName("Tinkerer Gizlock", 425), 10003 }, -- 427
		{ WHIT.."10) "..getBossName("Rotgrip", 430), 10004 }, -- 428
		{ WHIT.."11) "..getBossName("Princess Theradras", 431), 10005 }, -- 429
		{ WHIT.."12) "..L["Elder Splitrock"]..L_PAREN..ALC["Lunar Festival"]..R_PAREN, 10006 },
	},
	CL_OnyxiasLair = {
		ZoneName = { BZ["Onyxia's Lair"] },
		Acronym = L["Ony"],
		Location = { BZ["Dustwallow Marsh"] },
		DungeonID = 45,
		WorldMapID = 249,
		LevelRange = "60",
		PlayerLimit = { 40 },
		Module = "Atlas_ClassicWoW",
		{ ORNG..ALC["Attunement Required"] },
		{ ORNG..ALC["Key"]..COLON..L["Drakefire Amulet"] },
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Onyxian Warders"), 10002 },
		{ WHIT.." 2) "..getBossName("Whelp Eggs"), 10003 },
		{ WHIT.." 3) "..getBossName("Onyxia") }, -- 1084
	},
--[[
	CL_TheRuinsofAhnQiraj = {
		ZoneName = { BZ["Ahn'Qiraj"]..COLON..BZ["Ruins of Ahn'Qiraj"] },
		Location = { BZ["Silithus"] },
		DungeonID = 160,
		Acronym = L["AQ20"],
		LevelRange = "60",
		PlayerLimit = { 20 },
		WorldMapID = 247,
		JournalInstanceID = 743,
		Module = "Atlas_ClassicWoW",
		{ ORNG..REPUTATION..COLON..BF["Cenarion Circle"] },
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Kurinnaxx", 1537), 1537 },
		{ GREN..INDENT..getBossName("Lieutenant General Andorov") },
		{ GREN..INDENT..L["Four Kaldorei Elites"] },
		{ WHIT.." 2) "..getBossName("General Rajaxx", 1538), 1538 },
		{ WHIT..INDENT..L["Captain Qeez"] },
		{ WHIT..INDENT..L["Captain Tuubid"] },
		{ WHIT..INDENT..L["Captain Drenn"] },
		{ WHIT..INDENT..L["Captain Xurrem"] },
		{ WHIT..INDENT..L["Major Yeggeth"] },
		{ WHIT..INDENT..L["Major Pakkon"] },
		{ WHIT..INDENT..L["Colonel Zerran"] },
		{ WHIT.." 3) "..getBossName("Moam", 1539)..L_PAREN..ALC["Optional"]..R_PAREN, 1539 },
		{ WHIT.." 4) "..getBossName("Buru the Gorger", 1540)..L_PAREN..ALC["Optional"]..R_PAREN, 1540 },
		{ WHIT.." 5) "..getBossName("Ayamiss the Hunter", 1541)..L_PAREN..ALC["Optional"]..R_PAREN, 1541 },
		{ WHIT.." 6) "..getBossName("Ossirian the Unscarred", 1542), 1542 },
		{ GREN.." 1') "..L["Safe Room"], 10008 },
	},
	CL_TheTempleofAhnQiraj = {
		ZoneName = { BZ["Ahn'Qiraj"]..COLON..BZ["Temple of Ahn'Qiraj"] },
		Location = { BZ["Silithus"] },
		DungeonID = 161,
		Acronym = L["AQ40"],
		LevelRange = "60",
		PlayerLimit = { 40 },
		WorldMapID = 319,
		JournalInstanceID = 744,
		Module = "Atlas_ClassicWoW",
		{ ORNG..REPUTATION..COLON..BF["Brood of Nozdormu"] },
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B-D) "..CONNECTION, 10002 },
		{ WHIT.." 1) "..getBossName("The Prophet Skeram", 1543)..L_PAREN..ALC["Outside"]..R_PAREN, 1543 },
		{ WHIT.." 2) "..L["The Bug Family"]..L_PAREN..ALC["Optional"]..R_PAREN, 10004 },
		{ WHIT..INDENT..getBossName("Vem") },
		{ WHIT..INDENT..getBossName("Lord Kri") },
		{ WHIT..INDENT..getBossName("Princess Yauj") },
		{ WHIT.." 3) "..getBossName("Battleguard Sartura", 1544), 1544 },
		{ WHIT.." 4) "..getBossName("Fankriss the Unyielding", 1545), 1545 },
		{ WHIT.." 5) "..getBossName("Viscidus", 1548)..L_PAREN..ALC["Optional"]..R_PAREN, 1548 },
		{ WHIT.." 6) "..getBossName("Princess Huhuran", 1546), 1546 },
		{ WHIT.." 7) "..getBossName("The Twin Emperors", 1549), 1549 },
		{ WHIT..INDENT..getBossName("Emperor Vek'lor") },
		{ WHIT..INDENT..getBossName("Emperor Vek'nilash") },
		{ GREN..INDENT..ALC["Teleporter destination"] },
		{ WHIT.." 8) "..getBossName("Ouro", 1550)..L_PAREN..ALC["Optional"]..R_PAREN, 1550 },
		{ WHIT.." 9) "..getBossName("C'Thun", 1551), 1551 },
		{ GREN.." 1') "..L["Andorgos <Brood of Malygos>"]..L_PAREN..ALC["Teleporter"]..R_PAREN, 10012 },
		{ GREN..INDENT..L["Vethsera <Brood of Ysera>"] },
		{ GREN..INDENT..L["Kandrostrasz <Brood of Alexstrasza>"] },
		{ GREN.." 2') "..L["Arygos"], 10013 },
		{ GREN..INDENT..L["Caelestrasz"] },
		{ GREN..INDENT..L["Merithra of the Dream"] },
		{ GREN..INDENT..ALC["Teleporter destination"] },
		--getBossName("Silithid Royalty", 1547)
	},
]]
	CF_RagefireChasm = {
		ZoneName = { BZ["Ragefire Chasm"] },
		Location = { BZ["Orgrimmar"] },
		DungeonID = 3,
		LevelRange = "15-25", -- checked from wowhead
		PlayerLimit = { 5 },
		Acronym = L["RFC"],
		WorldMapID = 389,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getCreatureName("Oggleflint", 11517), 10002 }, -- 2732
		{ WHIT.." 2) "..getCreatureName("Taragaman the Hungerer", 11517), 10003 }, -- 2733
		{ WHIT.." 3) "..getCreatureName("Jergosh the Invoker", 11518), 10004 }, -- 2734
		{ WHIT.." 4) "..getCreatureName("Bazzalan", 11519), 10005 }, -- 2735
	},
	CF_RazorfenDowns = {
		ZoneName = { BZ["Razorfen Downs"] },
		Location = { BZ["The Barrens"] },
		DungeonID = 19,
		LevelRange = "33-47",
		PlayerLimit = { 5 },
		Acronym = L["RFD"],
		WorldMapID = 129,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Tuten'kash") }, -- 2780
		{ WHIT.." 2) "..getBossName("Henry Stern") },
		{ WHIT..INDENT..L["Belnistrasz"] },
		{ WHIT.." 3) "..getBossName("Mordresh Fire Eye") }, -- 2782
		{ WHIT.." 4) "..getBossName("Glutton") }, -- 2784
		{ WHIT.." 5) "..getBossName("Ragglesnout")..L_PAREN..RARE..COMMA..VARIES..R_PAREN }, -- 2783
		{ WHIT.." 6) "..getBossName("Amnennar the Coldbringer") }, -- 2785
		{ WHIT.." 7) "..getBossName("Plaguemaw the Rotting") }, -- 2781
	},
	CF_RazorfenKraul = {
		ZoneName = { BZ["Razorfen Kraul"] },
		Location = { BZ["The Barrens"] },
		DungeonID = 15,
		LevelRange = "32-42",
		PlayerLimit = { 5 },
		Acronym = L["RFK"],
		WorldMapID = 47,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Roogug"), 10002 }, -- 2773
		{ WHIT.." 2) "..getBossName("Aggem Thorncurse"), 10003 }, -- 2774
		{ WHIT.." 3) "..getBossName("Death Speaker Jargba"), 10004 }, -- 2775
		{ WHIT.." 4) "..getBossName("Overlord Ramtusk"), 10005 }, -- 2776
		{ WHIT.." 5) "..getBossName("Agathelos the Raging"), 10006 }, -- 2777
		{ WHIT.." 6) "..getBossName("Blind Hunter")..L_PAREN..RARE..R_PAREN, 10007 },
		{ WHIT.." 7) "..getBossName("Charlga Razorflank"), 10008 }, -- 2778
		{ WHIT.." 8) "..L["Willix the Importer"], 10009 },
		{ WHIT..INDENT..L["Heralath Fallowbrook"] },
		{ WHIT.." 9) "..getBossName("Earthcaller Halmgar")..L_PAREN..RARE..R_PAREN, 10010 },
	},
	CF_WailingCavernsEnt = {
		ZoneName = { BZ["Wailing Caverns"]..L_PAREN..ENTRANCE..R_PAREN },
		Location = { BZ["The Barrens"] },
		DungeonID = 1,
		LevelRange = "17-27",
		PlayerLimit = { 5 },
		Acronym = L["WC"],
		WorldMapID = 43,
		Module = "Atlas_ClassicWoW",
		NextMap = "CF_WailingCaverns",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ BLUE.." B) "..BZ["Wailing Caverns"], 10002 },
		{ WHIT.." 1) "..getBossName("Mad Magglish")..L_PAREN..VARIES..R_PAREN, 10003 },
		{ WHIT.." 2) "..getBossName("Trigore the Lasher")..L_PAREN..RARE..R_PAREN, 10004 },
		{ WHIT.." 3) "..getBossName("Boahn")..L_PAREN..RARE..R_PAREN, 10005 },
	},
	CF_WailingCaverns = {
		ZoneName = { BZ["Wailing Caverns"] },
		Location = { BZ["The Barrens"] },
		DungeonID = 1,
		LevelRange = "17-27",
		PlayerLimit = { 5 },
		Acronym = L["WC"],
		WorldMapID = 43,
		Module = "Atlas_ClassicWoW",
		PrevMap = "CF_WailingCavernsEnt",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..L["Disciple of Naralex"], 10002 },
		{ WHIT.." 2) "..getBossName("Lord Cobrahn", 475), 10003 }, -- 586
		{ WHIT.." 3) "..getBossName("Lady Anacondra", 474), 10004 }, -- 585
		{ WHIT.." 4) "..getBossName("Mutanus the Devourer", 481), 10005 }, -- 592
		{ WHIT.." 5) "..getBossName("Kresh", 477)..L_PAREN..VARIES..R_PAREN, 10006 }, -- 587
		{ WHIT.." 6) "..getBossName("Lord Pythas", 476), 10007 }, -- 588
		{ WHIT.." 7) "..getBossName("Skum", 478), 10008 }, -- 589
		{ WHIT.." 8) "..getBossName("Lord Serpentis", 479)..L_PAREN..UPPER..R_PAREN, 10009 }, -- 590
		{ WHIT.." 9) "..getBossName("Verdan the Everliving", 480)..L_PAREN..UPPER..R_PAREN, 10010 }, -- 591
		{ WHIT..INDENT..L["Naralex"] },
		{ WHIT.."10) "..getBossName("Deviate Faerie Dragon")..L_PAREN..RARE..COMMA..VARIES..R_PAREN, 10011 },
	},
	CL_ZulFarrak = {
		ZoneName = { BZ["Zul'Farrak"] },
		Location = { BZ["Tanaris"] },
		DungeonID = 23,
		LevelRange = "46-56",
		PlayerLimit = { 5 },
		Acronym = L["ZF"],
		WorldMapID = 209,
		Module = "Atlas_ClassicWoW",
		{ BLUE.." A) "..ENTRANCE, 10001 },
		{ WHIT.." 1) "..getBossName("Antu'sul", 484), 484 }, -- 595
		{ WHIT.." 2) "..getBossName("Theka the Martyr", 485), 485 }, -- 596
		{ WHIT.." 3) "..getBossName("Witch Doctor Zum'rah", 486), 486 }, -- 597
		{ WHIT..INDENT..L["Zul'Farrak Dead Hero"] },
		{ WHIT.." 4) "..getBossName("Nekrum Gutchewer") }, -- 598
		{ WHIT..INDENT..getBossName("Shadowpriest Sezz'ziz") }, -- 599
		{ WHIT..INDENT..getBossName("Dustwraith")..L_PAREN..RARE..COMMA..VARIES..R_PAREN, 10003 },
		{ WHIT.." 5) "..getBossName("Sergeant Bly") },
		{ WHIT..INDENT..L["Weegli Blastfuse"] },
		{ WHIT..INDENT..getBossName("Murta Grimgut") },
		{ WHIT..INDENT..L["Raven"] },
		{ WHIT..INDENT..getBossName("Oro Eyegouge") },
		{ WHIT..INDENT..getBossName("Sandfury Executioner") },
		{ WHIT.." 6) "..getBossName("Hydromancer Velratha", 482), 482 }, -- 593
		{ WHIT..INDENT..getBossName("Gahz'rilla", 483)..L_PAREN..ALC["Summon"]..R_PAREN, 483 }, -- 594
		{ WHIT..INDENT..L["Elder Wildmane"]..L_PAREN..ALC["Lunar Festival"]..R_PAREN, 10005 },
		{ WHIT.." 7) "..getBossName("Chief Ukorz Sandscalp", 489), 489 }, -- 600
		{ WHIT..INDENT..getBossName("Ruuzlu") },
		{ WHIT.." 8) "..getBossName("Zerillis")..L_PAREN..RARE..COMMA..WANDERS..R_PAREN, 10004 },
		{ WHIT.." 9) "..getBossName("Sandarr Dunereaver")..L_PAREN..RARE..R_PAREN, 10002 },
	},
}


-- Atlas Map NPC Description Data
db.AtlasMaps_NPC_DB = {
--************************************************
-- Eastern Kingdoms Instances (Classic)
--************************************************
    CL_BlackrockDepths = {
        { "A", 10001, 120, 415 },
        { "1", 370, 247, 361 },
        { "2", 10002, 263, 411 },
        { "3", 10003, 270, 440 },
        { "4", 10004, 272, 472 },
        { "5", 369, 194, 484 },
        { "6", 372, 209, 361 },
        { "7", 373, 239, 385 },
        { "8", 375, 278, 274 },
        { "9", 376, 283, 217 },
        { "10", 374, 239, 244 },
        { "11", 377, 46, 314 },
        { "12", 10005, 159, 363 },
        { "13", 378, 120, 328 },
        { "14", 379, 111, 251 },
        { "15", 380, 203, 257 },
        { "16", 384, 226, 196 },
        { "17", 10006, 196, 145 },
        { "18", 10007, 223, 93 },
        { "19", 10008, 298, 49 },
        { "20", 386, 381, 49 },
        { "21", 387, 446, 50 },
        { "22", 10009, 312, 107 },
        { "23", 10010, 334, 163 },
        { "24", 10011, 103, 443 },
        { "25", 10012, 99, 288 },
    },
    CF_Gnomeregan = {
        { "A", 10001, 354, 52 },
        { "B", 10002, 439, 302 },
        { "1", 10003, 491, 221 },
        { "2", 10004, 314, 225 },
        { "3", 10005, 357, 244 },
        { "4", 420, 363, 176 },
        { "5", 421, 146, 244 },
        { "6", 418, 228, 396 },
        { "7", 10006, 34, 302 },
        { "8", 422, 54, 229 },
    },
    CL_UldamanEnt = {
        { "A", 10001, 497, 171 },
        { "B", 10002, 150, 112 },
        { "1", 10003, 256, 116 },
        { "2", 10004, 286, 244 },
        { "3", 10005, 296, 327 },
        { "4", 10006, 135, 441 },
        { "5", 10007, 95, 322 },
        { "1'", 10008, 292, 307 },
        { "1'", 10008, 101, 301 },
    },
    CF_Uldaman = {
        { "A", 10001, 392, 372 }, -- blue
        { "B", 10002, 102, 359 }, -- blue
        { "1", 10003, 318, 464 }, -- white
        { "2", 10004, 272, 323 }, -- white
        { "3", 10005, 274, 371 }, -- white
        { "4", 10006, 150, 377 }, -- white
        { "5", 10007, 87, 322 }, -- white
        { "6", 10008, 234, 315 }, -- white
        { "7", 10009, 231, 223 }, -- white
        { "8", 10010, 66, 175 }, -- white
        { "9", 10011, 41, 109 }, -- white
        { "10", 10012, 183, 88 }, -- white
        { "11", 10013, 164, 46 }, -- white
    },
    CL_ZulGurub = {
        { "A", 10001, 82, 251 },
        { "1", 10002, 194, 409 },
        { "2", 10003, 314, 290 },
        { "3", 10014, 368, 299 },
        { "4", 10015, 291, 443 },
        { "5", 10016, 431, 384 },
        { "6", 10007, 411, 236 },
        { "7", 10008, 374, 150 },
        { "8", 10009, 422, 152 },
        { "9", 10010, 276, 58 },
        { "10", 10011, 105, 85 },
        { "11", 10012, 286, 190 },
        { "1'", 10013, 206, 226 },
        { "1'", 10013, 171, 191 },
        { "1'", 10013, 321, 234 },
        { "1'", 10013, 346, 148 },
        { "1'", 10013, 299, 126 },
    },
    CF_CityofDalaranA = {
        { "A", 10001, 23, 410 },
        { "1", 247126, 372, 310 },
        { "2", 247032, 440, 56 },
    },
    CF_CityofDalaranB = {
        { "3", 245999, 357, 379 },
        { "4", 246016, 379, 202 },
        { "5", 246017, 317, 187 },
        { "6", 246008, 281, 357 },
        { "7", 246003, 300, 262 },
        { "8", 246020, 259, 132 },
    },
	CF_HallofThanes = {
		{ "A", 10001, 251, 478 },
		{ 1, 3493, 252, 382 },
		{ 2, 3494, 252, 318 },
		{ 3, 3495, 318, 309 },
		{ 4, 3496, 252, 198 },
		{ "1'", 10002, 188, 378 },
		{ "2'", 281030, 270, 182 },
	},
    CF_MoltenCore = {
        { "A", 10001, 93, 142 }, -- blue
        { "1", 1519, 353, 214 }, -- white
        { "2", 1520, 384, 133 }, -- white
        { "3", 1521, 135, 261 }, -- white
        { "4", 1522, 120, 364 }, -- white
        { "5", 1523, 272, 409 }, -- white
        { "6", 1524, 301, 367 }, -- white
        { "7", 1526, 369, 313 }, -- white
        { "8", 1525, 457, 412 }, -- white
        { "9", 1527, 456, 324 }, -- white
        { "10", 1528, 281, 289 }, -- white
    },
    CF_RuinsofLordaeron = {
        { "A", 10001, 324, 87 },
        { 1, 10002, 305, 330 },
        { 2, 10003, 377, 187 },
        { 3, 10004, 154, 271 },
        { 4, 10005, 136, 211 },
        { 5, 10006, 194, 321 },
        { 6, 10007, 119, 325 },
        { 7, 10008, 129, 123 },
        { "1'", 10009, 334, 132 },
    },
    CF_ExcavationSiteWetlands = {
        { "A", 10001, 473, 202 },
        { "1", 260322, 278, 256 },
        { "2", 260325, 239, 271 },
        { "3", 260326, 77, 241 },
        { "4", 260808, 197, 340 },
    },
    CF_TheStockade = {
        { "A", 10001, 251, 334 }, -- blue
        { "1", 10002, 252, 145 }, -- white
        { "1", 10002, 146, 205 }, -- white
        { "1", 10002, 205, 231 }, -- white
        { "1", 10002, 298, 269 }, -- white
        { "2", 10003, 369, 161 }, -- white
        { "3", 10004, 424, 233 }, -- white
        { "4", 10005, 477, 259 }, -- white
        { "5", 10006, 77, 154 }, -- white
        { "6", 10017, 119, 223 }, -- white
    },
--************************************************
-- Kalimdor Instances (Classic)
--************************************************
    CL_BlackfathomDeepsEnt = {
        { "A", 10001, 183, 382 },
        { "B", 10002, 356, 209 },
    },
    CL_BlackfathomDeepsA = {
        { "A", 10001, 295, 60 },
        { "1", 10002, 208, 313 },
        { "2", 10003, 208, 207 },
        { "3", 10004, 37, 207 },
        { "4", 10005, 106, 387 },
        { "5", 10006, 373, 295 },
        { "6", 10007, 430, 339 },
        { "6", 10007, 473, 356 },
    },
    CL_BlackfathomDeepsB = {
        { "6", 10007, 55, 190 },
        { "6", 10007, 29, 310 },
        { "6", 10007, 129, 76 },
        { "6", 10007, 88, 58 },
        { "7", 10008, 100, 351 },
        { "8", 10009, 189, 369 },
        { "10", 10010, 447, 393 },
    },
    CL_BlackfathomDeepsC = {
        { "9", 10011, 440, 241 },
    },
    CL_MaraudonEnt = {
        { "A", 10001, 91, 280 },
        { "B", 10002, 205, 61 },
        { "C", 10003, 414, 363 },
        { "D", 10004, 132, 236 },
        { "1", 10005, 164, 218 },
        { "2", 10006, 134, 138 },
        { "3", 10007, 398, 232 },
        { "4", 10008, 248, 328 },
    },
    CF_MaraudonA = {
        { "A", 10001, 318, 140 }, -- blue
        { "B", 10002, 404, 279 }, -- blue
        { "1", 10003, 234, 115 }, -- white
        { "2", 10004, 188, 86 }, -- white
        { "3", 10005, 85, 161 }, -- white
        { "4", 10006, 264, 236 }, -- white
        { "5", 10007, 199, 288 }, -- white
        { "6", 10008, 127, 264 }, -- white
        { "7", 10009, 47, 309 }, -- white
    },
    CF_MaraudonB = {
        { "C", 10001, 184, 154 }, -- blue
        { "8", 10002, 301, 197 }, -- white
        { "9", 10003, 390, 305 }, -- white
        { "10", 10004, 249, 370 }, -- white
        { "11", 10005, 156, 387 }, -- white
        { "12", 10006, 399, 476 }, -- white
    },
    CL_OnyxiasLair = {
        { "A", 10001, 91, 68 },
        { "1", 10002, 263, 383 },
        { "1", 10002, 162, 206 },
        { "1", 10002, 221, 339 },
        { "1", 10002, 193, 299 },
        { "2", 10003, 452, 201 },
        { "2", 10003, 266, 201 },
        { "2", 10003, 422, 281 },
        { "2", 10003, 296, 281 },
        { "3", 10004, 359, 141 },
    },
    CF_RazorfenDowns = {
        { "A", 10001, 24, 148 }, -- blue
        { "1", 10002, 265, 211 }, -- white
        { "2", 10003, 390, 169 }, -- white
        { "3", 10004, 443, 271 }, -- white
        { "4", 10005, 104, 366 }, -- white
        { "5", 10006, 113, 296 }, -- white
        { "5", 10007, 205, 383 }, -- white
        { "6", 10008, 163, 337 }, -- white
    },
    CF_RazorfenKraul = {
        { "A", 10001, 358, 370 }, -- blue
        { "1", 10002, 360, 234 }, -- white
        { "2", 10003, 448, 265 }, -- white
        { "3", 10004, 478, 218 }, -- white
        { "4", 10005, 305, 163 }, -- white
        { "5", 10006, 37, 323 }, -- white
        { "6", 10007, 42, 164 }, -- white
        { "7", 10008, 128, 171 }, -- white
        { "8", 10009, 191, 169 }, -- white
        { "9", 10010, 260, 230 }, -- white
    },
    CF_RagefireChasm = {
        { "A", 10001, 337, 26 },
        { "1", 10002, 362, 272 },
        { "2", 10003, 175, 299 },
        { "3", 10004, 130, 437 },
        { "4", 10005, 185, 463 },
    },
    CF_WailingCavernsEnt = {
        { "A", 10001, 47, 406 }, -- blue
        { "B", 10002, 264, 340 }, -- blue
        { "1", 10003, 113, 366 }, -- white
        { "1", 10003, 155, 289 }, -- white
        { "1", 10003, 26, 209 }, -- white
        { "2", 10004, 290, 234 }, -- white
        { "3", 10005, 274, 304 }, -- white
    },
    CF_WailingCaverns = {
        { "A", 10001, 229, 286 }, -- blue
        { "1", 10002, 227, 257 }, -- white
        { "2", 10003, 69, 274 }, -- white
        { "3", 10004, 194, 179 }, -- white
        { "4", 10005, 161, 127 }, -- white
        { "5", 10006, 232, 217 }, -- white
        { "6", 10007, 429, 174 }, -- white
        { "7", 10008, 466, 346 }, -- white
        { "8", 10009, 310, 258 }, -- white
        { "9", 10010, 282, 242 }, -- white
        { "10", 10011, 317, 213 }, -- white
    },
}

--[[
	AssocDefaults{}

	Default map to be auto-selected when no SubZone data is available.

	For example, "Dire Maul" has a subzone called "Warpwood Quarter" located in East Dirl Maul, however, there are also 
	some areas which have not been named with any subzone, and we would like to pick a proper default map in this condition.

	Define this table entries only when the instance has multiple maps.

	Table index is zone name, it need to be localized value, but we will handle the localization with BabbleSubZone library.
	The table value is map's key-name.
]]
db.AssocDefaults = {
	[BZ["Blackrock Mountain"]] =	"CL_BlackrockMountainEnt",
	[BZ["Blackrock Spire"]] =		"CL_BlackrockSpireLower",
	[BZ["Hall of Blackhand"]] =		"CL_BlackrockSpireLower",
	[BZ["Dire Maul"]] =				"CL_DireMaulNorth",
	[BZ["The Deadmines"]] = 		"CL_TheDeadmines",
	[BZ["The Wailing Caverns"]] = 	"CF_WailingCavernsEnt",
	[BZ["Sunken Temple"]] = 		"CL_TheSunkenTemple",
	[BZ["Ironforge"]] = 			"CF_HallofThanes",
}

--[[
	SubZoneData{}

	Define SubZone data for default map to be selected for instance which has multiple maps.
	Subzone data should be able to be pulled out from WMOAreaTable for indoor areas, or from AreaTable for outdoor areas.

	Array Syntax: 
	["localized zone name"] = {
		["atlas map name"] = {
			["localized subzone name 1"],
			["localized subzone name 2"],
		},
	},
]]
db.SubZoneData = {
	-- Blackrock Spire
	[BZ["Hall of Blackhand"]] = {
		-- Lower Blackrock Spire
		["CL_BlackrockSpireLower"] = {
			BZ["Hordemar City"],
			BZ["Mok'Doom"],
			BZ["Tazz'Alor"],
			BZ["Skitterweb Tunnels"],
			BZ["The Storehouse"],
			BZ["Halycon's Lair"],
			BZ["Chamber of Battle"],
		},
	},
	-- Dire Maul
	[BZ["Dire Maul"]] = {
		-- Dire Maul, Entrance
		["CL_DireMaulEnt"] = {
			BZ["Broken Commons"],
			-- Comment out below as they are currently redundant due to the Zone is Feralas
			--BZ["Eldreth Row"],
			--BZ["The Maul"],
		},
		-- Dire Maul, North
		["CL_DireMaulNorth"] = {
			BZ["Halls of Destruction"],
			BZ["Gordok's Seat"],
		},
		-- Dire Maul, East
		["CL_DireMaulEast"] = {
			BZ["Warpwood Quarter"],
			BZ["The Hidden Reach"],
			BZ["The Conservatory"],
			BZ["The Shrine of Eldretharr"],
		},
		-- Dire Maul, West
		["CL_DireMaulWest"] = {
			BZ["Capital Gardens"],
			BZ["Court of the Highborne"],
			BZ["Prison of Immol'thar"],
			BZ["The Athenaeum"],
		},
	},
	-- Stratholme
	[BZ["Stratholme"]] = {
		-- Stratholme
		["CL_Stratholme"] = {
			BZ["King's Square"],
			BZ["Festival Lane"],
			BZ["Market Row"],
			BZ["Crusaders' Square"],
			BZ["The Scarlet Bastion"],
			BZ["The Hall of Lights"],
			BZ["The Hoard"],
			BZ["The Crimson Throne"],
			BZ["Elders' Square"],
			BZ["The Gauntlet"],
			BZ["Slaughter Square"],
			BZ["The Slaughter House"],
		},
	},
	-- The Deadmines
	[BZ["The Deadmines"]] = {
		["CL_TheDeadmines"] = {
			BZ["Goblin Foundry"],
			BZ["Mast Room"],
			BZ["Ironclad Cove"],
		},
	},
	-- The Stockade
	[BZ["The Stockade"]] = {
		-- The Stockade
		["CF_TheStockade"] = {
			BZ["Stormwind Stockade"],
		},
	},
	-- Wailing Caverns
	[BZ["Wailing Caverns"]] = {
		-- Wailing Caverns, Entrance
		["CF_WailingCavernsEnt"] = {
			BZ["Cavern of Mists"],
		},
		-- Wailing Caverns
		["CF_WailingCaverns"] = {
			BZ["Screaming Gully"],
			BZ["Dreamer's Rock"],
			BZ["Pit of Fangs"],
			BZ["Crag of the Everliving"],
			BZ["Pit of Fangs"],
		},
	},
}

--[[
	OutdoorZoneToAtlas{}

	Maps to auto-select to from outdoor zones.

	Table index is sub-zone name, it need to be localized value, but we will handle
	the localization with BabbleSubZone library.
	The table value is map's key-name.

	Duplicates are commented out.
	Not for localization.
]]
db.OutdoorZoneToAtlas = {
	[BZ["Burning Steppes"]] = 		"CL_BlackrockMountainEnt",
	[BZ["Searing Gorge"]] = 		"CL_BlackrockMountainEnt",
	[BZ["Ashenvale"]] = 			"CL_BlackfathomDeepsEnt",
	[BZ["Feralas"]] = 				"CL_DireMaulEnt",
	[BZ["Dun Morogh"]] = 			"CL_GnomereganEnt",
	[BZ["Desolace"]] = 				"CL_MaraudonEnt",
	[BZ["Ironforge"]] = 			"CF_HallofThanes",
	[BZ["Orgrimmar"]] = 			"CF_RagefireChasm",
	[BZ["Thousand Needles"]] = 		"CF_RazorfenDowns",
	[BZ["Southern Barrens"]] = 		"CF_RazorfenKraul",
	[BZ["Silverpine Forest"]] = 	"CL_ShadowfangKeep",
	[BZ["Tirisfal Glades"]] = 		"CF_RuinsofLordaeron",
	[BZ["Western Plaguelands"]] = 	"CL_Scholomance",
	[BZ["Eastern Plaguelands"]] = 	"CL_Stratholme",
	[BZ["Westfall"]] = 				"CL_TheDeadminesEnt",
	[BZ["Stormwind City"]] = 		"CF_TheStockade",
	[BZ["Swamp of Sorrows"]] = 		"CL_TheSunkenTempleEnt",
	[BZ["Badlands"]] = 				"CL_UldamanEnt",
	[BZ["Northern Barrens"]] = 		"CF_WailingCavernsEnt",
	[BZ["Tanaris"]] = 				"CL_ZulFarrak",
	--[BZ["Ahn'Qiraj: The Fallen Kingdom"]] = "CL_TheTempleofAhnQiraj",
	--[BZ["Silithus"]] = 			"CL_TheTempleofAhnQiraj",
	[BZ["Dustwallow Marsh"]] = 		"CL_OnyxiasLair",
	[BZ["Alterac Mountains"]] = 	"CF_CityofDalaranA",
	[BZ["Wetlands"]] = 				"CF_ExcavationSiteWetlands",
}

-- Yes, the following two tables are redundant, but they're both here in case there's ever more than one entrance map for an instance
-- Entrance maps to instance maps
db.EntToInstMatches = {
	["CL_BlackfathomDeepsEnt"] =	{"CL_BlackfathomDeepsA","CL_BlackfathomDeepsB","CL_BlackfathomDeepsC"},
	["CL_BlackrockMountainEnt"] =	{"CL_BlackrockDepths","CL_BlackwingLair","CL_BlackrockSpireLower","CL_BlackrockSpireUpper","CF_MoltenCore"},
	["CL_DireMaulEnt"] =			{"CL_DireMaulEast","CL_DireMaulNorth","CL_DireMaulWest"},
	["CL_GnomereganEnt"] =			{"CF_Gnomeregan"},
	["CL_MaraudonEnt"] =			{"CF_MaraudonA","CF_MaraudonB"},
	["CL_ScarletMonasteryEnt"] = 	{"CL_SMArmory", "CL_SMCathedral", "CL_SMGraveyard", "CL_SMLibrary"},
	["CL_TheDeadminesEnt"] =		{"CL_TheDeadmines"},
	["CL_TheSunkenTempleEnt"] =		{"CL_TheSunkenTemple"},
	["CL_UldamanEnt"] =				{"CF_Uldaman"},
	["CF_WailingCavernsEnt"] =		{"CF_WailingCaverns"},
}

-- Instance maps to entrance maps
db.InstToEntMatches = {
	["CL_BlackfathomDeepsA"] =		{"CL_BlackfathomDeepsEnt"},
	["CL_BlackfathomDeepsB"] =		{"CL_BlackfathomDeepsEnt"},
	["CL_BlackfathomDeepsC"] =		{"CL_BlackfathomDeepsEnt"},
	["CL_BlackrockDepths"] =		{"CL_BlackrockMountainEnt"},
	["CL_BlackwingLair"] =			{"CL_BlackrockMountainEnt"},
	["CL_BlackrockSpireLower"] =	{"CL_BlackrockMountainEnt"},
	["CL_BlackrockSpireUpper"] =	{"CL_BlackrockMountainEnt"},
	["CF_MoltenCore"] =				{"CL_BlackrockMountainEnt"},
	["CL_DireMaulEast"] =			{"CL_DireMaulEnt"},
	["CL_DireMaulNorth"] =			{"CL_DireMaulEnt"},
	["CL_DireMaulWest"] =			{"CL_DireMaulEnt"},
	["CF_Gnomeregan"] =				{"CL_GnomereganEnt"},
	["CF_MaraudonA"] =				{"CL_MaraudonEnt"},
	["CF_MaraudonB"] =				{"CL_MaraudonEnt"},
	["CL_SMArmory"] =				{"CL_ScarletMonasteryEnt"},
	["CL_SMCathedral"] =			{"CL_ScarletMonasteryEnt"},
	["CL_SMGraveyard"] =			{"CL_ScarletMonasteryEnt"},
	["CL_SMLibrary"] =				{"CL_ScarletMonasteryEnt"},
	["CL_TheDeadmines"] =			{"CL_TheDeadminesEnt"},
	["CL_TheSunkenTemple"] =		{"CL_TheSunkenTempleEnt"},
	["CF_Uldaman"] =				{"CL_UldamanEnt"},
	["CF_WailingCaverns"] =			{"CF_WailingCavernsEnt"},
}

db.MapSeries = {
	["CL_BlackfathomDeepsA"] = 		{"CL_BlackfathomDeepsA","CL_BlackfathomDeepsB","CL_BlackfathomDeepsC"},
	["CL_BlackfathomDeepsB"] = 		{"CL_BlackfathomDeepsA","CL_BlackfathomDeepsB","CL_BlackfathomDeepsC"},
	["CL_BlackfathomDeepsC"] = 		{"CL_BlackfathomDeepsA","CL_BlackfathomDeepsB","CL_BlackfathomDeepsC"},
	["CF_CityofDalaranA"] = 		{"CF_CityofDalaranA","CF_CityofDalaranB"},
	["CF_CityofDalaranB"] = 		{"CF_CityofDalaranA","CF_CityofDalaranB"},
	["CF_MaraudonA"] =				{"CF_MaraudonA","CF_MaraudonB"},
	["CF_MaraudonB"] =				{"CF_MaraudonA","CF_MaraudonB"},
}

-- Links maps together that are part of the same instance
db.SubZoneAssoc = {
	["CL_DireMaulNorth"] =			BZ["Dire Maul"],
	["CL_DireMaulEast"] =			BZ["Dire Maul"],
	["CL_DireMaulWest"] =			BZ["Dire Maul"],
	["CL_DireMaulEnt"] =			BZ["Dire Maul"],
	["CL_BlackfathomDeepsA"] = 		BZ["Blackfathom Deeps"],
	["CL_BlackfathomDeepsB"] = 		BZ["Blackfathom Deeps"],
	["CL_BlackfathomDeepsC"] = 		BZ["Blackfathom Deeps"],
}

db.DropDownLayouts_Order = {
	[ATLAS_DDL_CONTINENT] = {
		ATLAS_DDL_CONTINENT_EASTERN,
		ATLAS_DDL_CONTINENT_KALIMDOR,
	},
	[ATLAS_DDL_LEVEL] = {
		ATLAS_DDL_LEVEL_10TO20,
		ATLAS_DDL_LEVEL_20TO40,
		ATLAS_DDL_LEVEL_40TO60,
		ATLAS_DDL_LEVEL_60TO70,
	},
	[ATLAS_DDL_EXPANSION] = {
		ATLAS_DDL_EXPANSION_OLD,
	},
}

db.DropDownLayouts = {
	[ATLAS_DDL_CONTINENT] = {
		[ATLAS_DDL_CONTINENT_EASTERN] = {
			"CL_BlackrockMountainEnt",
			"CL_BlackrockDepths",
			"CL_BlackwingLair",
			"CL_TheDeadmines",
			"CL_TheDeadminesEnt",
			"CF_Gnomeregan",
			"CL_GnomereganEnt",
			"CL_BlackrockSpireLower",
			"CL_BlackrockSpireUpper",
			"CF_MoltenCore",
			"CL_ShadowfangKeep",
			"CL_Stratholme",
			"CF_TheStockade",
			"CL_TheSunkenTemple",
			"CL_TheSunkenTempleEnt",
			"CF_Uldaman",
			"CL_UldamanEnt",
			"CF_RuinsofLordaeron",
			"CL_Scholomance",
			"CL_ScarletMonasteryEnt",
			"CL_SMArmory",
			"CL_SMCathedral",
			"CL_SMGraveyard",
			"CL_SMLibrary",
			"CL_ZulGurub",
			"CF_HallofThanes",
			"CF_ExcavationSiteWetlands",
			"CF_CityofDalaranA",
			"CF_CityofDalaranB",
			--"CL_Naxxramas",
		},
		[ATLAS_DDL_CONTINENT_KALIMDOR] = {
			"CL_BlackfathomDeepsA",
			"CL_BlackfathomDeepsB",
			"CL_BlackfathomDeepsC",
			"CL_BlackfathomDeepsEnt",
			"CL_DireMaulEast",	
			"CL_DireMaulEnt",	
			"CL_DireMaulNorth",
			"CL_DireMaulWest",	
			"CF_MaraudonA",
			"CF_MaraudonB",
			"CL_MaraudonEnt",	
			"CL_OnyxiasLair",
			"CF_RagefireChasm",
			"CF_RazorfenDowns",
			"CF_RazorfenKraul",
			--"CL_TheTempleofAhnQiraj",
			--"CL_TheRuinsofAhnQiraj",
			"CF_WailingCaverns",
			"CF_WailingCavernsEnt",
			"CL_ZulFarrak",	
		},
	},
	[ATLAS_DDL_EXPANSION] = {
		[ATLAS_DDL_EXPANSION_OLD] = {
			"CL_BlackfathomDeepsA",
			"CL_BlackfathomDeepsB",
			"CL_BlackfathomDeepsC",
			"CL_BlackfathomDeepsEnt",
			"CL_BlackrockMountainEnt",
			"CL_BlackrockDepths",
			"CL_BlackwingLair",
			"CL_DireMaulEast",
			"CL_DireMaulEnt",
			"CL_DireMaulNorth",
			"CL_DireMaulWest",
			"CF_Gnomeregan",
			"CL_GnomereganEnt",
			"CL_BlackrockSpireLower",
			"CL_BlackrockSpireUpper",
			"CF_MaraudonA",
			"CF_MaraudonB",
			"CL_MaraudonEnt",
			"CF_MoltenCore",
			"CL_OnyxiasLair",
			"CL_TheDeadmines",
			"CL_TheDeadminesEnt",
			"CF_RagefireChasm",
			"CF_RazorfenDowns",
			"CF_RazorfenKraul",
			"CF_RuinsofLordaeron",
			"CL_Scholomance",
			"CL_ShadowfangKeep",
			"CL_ScarletMonasteryEnt",
			"CL_SMArmory",
			"CL_SMCathedral",
			"CL_SMGraveyard",
			"CL_SMLibrary",
			"CL_Stratholme",
			"CF_TheStockade",
			"CL_TheSunkenTemple",
			"CL_TheSunkenTempleEnt",
			--"CL_TheTempleofAhnQiraj",
			--"CL_TheRuinsofAhnQiraj",
			"CF_Uldaman",
			"CL_UldamanEnt",
			"CF_WailingCaverns",
			"CF_WailingCavernsEnt",
			"CL_ZulFarrak",
			"CL_ZulGurub",
			"CF_HallofThanes",
			"CF_ExcavationSiteWetlands",
			"CF_CityofDalaranA",
			"CF_CityofDalaranB",
			--"CL_Naxxramas",
		},
	},
	[ATLAS_DDL_LEVEL] = {
		[ATLAS_DDL_LEVEL_10TO20] = {
			"CF_RagefireChasm",
			"CL_TheDeadmines",
			"CL_TheDeadminesEnt",
			"CF_WailingCaverns",
			"CF_WailingCavernsEnt",
			"CF_HallofThanes",
			"CF_RuinsofLordaeron",
		},
		[ATLAS_DDL_LEVEL_20TO40] = {
			"CL_BlackfathomDeepsA",
			"CL_BlackfathomDeepsB",
			"CL_BlackfathomDeepsC",
			"CL_BlackfathomDeepsEnt",
			"CF_Gnomeregan",
			"CL_GnomereganEnt",
			"CF_RagefireChasm",
			"CL_ShadowfangKeep",
			"CL_TheDeadmines",
			"CL_TheDeadminesEnt",
			"CF_TheStockade",
			"CF_WailingCaverns",
			"CF_WailingCavernsEnt",
			"CF_RazorfenDowns",
			"CF_RazorfenKraul",
			"CF_RuinsofLordaeron",
			"CL_ScarletMonasteryEnt",
			"CL_SMArmory",
			"CL_SMCathedral",
			"CL_SMGraveyard",
			"CL_SMLibrary",
			"CF_ExcavationSiteWetlands",
			"CF_CityofDalaranA",
			"CF_CityofDalaranB"
		},
		[ATLAS_DDL_LEVEL_40TO60] = {
			"CF_RazorfenDowns",
			"CF_RazorfenKraul",
			"CL_ScarletMonasteryEnt",
			"CL_SMArmory",	
			"CL_SMCathedral",	
			"CL_SMGraveyard",	
			"CL_SMLibrary",	
			"CL_BlackrockMountainEnt",
			"CL_BlackrockDepths",
			"CL_BlackrockSpireLower",
			"CL_BlackrockSpireUpper",
			"CL_DireMaulEast",	
			"CL_DireMaulEnt",	
			"CL_DireMaulNorth",
			"CL_DireMaulWest",	
			"CF_MaraudonA",	
			"CF_MaraudonB",
			"CL_MaraudonEnt",	
			"CL_Scholomance",	
			"CL_Stratholme",	
			"CL_TheSunkenTemple",
			"CL_TheSunkenTempleEnt",
			"CF_Uldaman",	
			"CL_UldamanEnt",	
			"CL_ZulFarrak",	
		},
		[ATLAS_DDL_LEVEL_60TO70] = {
			"CL_BlackwingLair",
			"CF_MoltenCore",	
			"CL_OnyxiasLair",
			--"CL_TheRuinsofAhnQiraj",
			--"CL_TheTempleofAhnQiraj",
			"CL_ZulGurub",
			--"CL_Naxxramas",
		},
	},
	[ATLAS_DDL_PARTYSIZE] = {
		[ATLAS_DDL_PARTYSIZE_5] = {
			"CL_BlackrockMountainEnt",
			"CL_BlackfathomDeepsA",
			"CL_BlackfathomDeepsB",
			"CL_BlackfathomDeepsC",
			"CL_BlackfathomDeepsEnt",
			"CL_BlackrockDepths",
			"CL_BlackrockSpireLower",
			"CL_BlackrockSpireUpper",
			"CL_TheDeadmines",
			"CL_TheDeadminesEnt",
			"CL_DireMaulEast",
			"CL_DireMaulEnt",
			"CL_DireMaulNorth",
			"CL_DireMaulWest",
			"CF_Gnomeregan",
			"CL_GnomereganEnt",
			"CF_MaraudonA",
			"CF_MaraudonB",
			"CL_MaraudonEnt",
			"CF_RagefireChasm",
			"CF_RazorfenDowns",
			"CF_RazorfenKraul",
			"CF_RuinsofLordaeron",
			"CL_SMArmory",
			"CL_SMCathedral",
			"CL_SMGraveyard",
			"CL_SMLibrary",
			"CL_ScarletMonasteryEnt",
			"CL_Scholomance",
			"CL_ShadowfangKeep",
			"CF_TheStockade",
			"CL_Stratholme",
			"CL_TheSunkenTemple",
			"CL_TheSunkenTempleEnt",
			"CF_Uldaman",
			"CL_UldamanEnt",
			"CF_WailingCaverns",
			"CF_WailingCavernsEnt",
			"CL_ZulFarrak",
			"CF_HallofThanes",
			"CF_ExcavationSiteWetlands",
			"CF_CityofDalaranA",
			"CF_CityofDalaranB"
		},
		[ATLAS_DDL_PARTYSIZE_20TO40] = {
			"CL_BlackrockMountainEnt",
			"CL_BlackwingLair",
			"CF_MoltenCore",
			"CL_OnyxiasLair",
			--"CL_TheTempleofAhnQiraj",
			--"CL_TheRuinsofAhnQiraj",
			"CL_ZulGurub",
			--"CL_Naxxramas",
		},
	},
	[ATLAS_DDL_TYPE] = {
		[ATLAS_DDL_TYPE_INSTANCE] = {
			"CL_BlackfathomDeepsA",
			"CL_BlackfathomDeepsB",
			"CL_BlackfathomDeepsC",
			"CL_BlackrockDepths",
			"CL_BlackwingLair",
			"CL_BlackrockSpireLower",
			"CL_BlackrockSpireUpper",
			"CL_TheDeadmines",
			"CL_DireMaulEast",
			"CL_DireMaulNorth",
			"CL_DireMaulWest",
			"CF_Gnomeregan",
			"CF_MaraudonA",
			"CF_MaraudonB",
			"CL_OnyxiasLair",
			"CF_MoltenCore",
			"CF_RagefireChasm",
			"CF_RazorfenDowns",
			"CF_RazorfenKraul",
			"CF_RuinsofLordaeron",
			"CL_SMArmory",
			"CL_SMCathedral",
			"CL_SMGraveyard",
			"CL_SMLibrary",
			"CL_Scholomance",
			"CL_ShadowfangKeep",
			"CL_Stratholme",
			"CF_TheStockade",
			"CL_TheSunkenTemple",
			"CF_Uldaman",
			"CF_WailingCaverns",
			"CL_ZulFarrak",
			"CL_ZulGurub",
			"CF_HallofThanes",
			"CF_ExcavationSiteWetlands",
			"CF_CityofDalaranA",
			"CF_CityofDalaranB",
			--"CL_TheTempleofAhnQiraj",
			--"CL_TheRuinsofAhnQiraj",
			--"CL_Naxxramas",
		},
		[ATLAS_DDL_TYPE_ENTRANCE] = {
			"CL_BlackrockMountainEnt",
			"CL_TheDeadminesEnt",
			"CL_ScarletMonasteryEnt",
			"CL_BlackfathomDeepsEnt",
			"CL_DireMaulEnt",
			"CL_GnomereganEnt",
			"CL_MaraudonEnt",
			"CL_TheSunkenTempleEnt",
			"CL_UldamanEnt",
			"CF_WailingCavernsEnt",
		},
	},
}
